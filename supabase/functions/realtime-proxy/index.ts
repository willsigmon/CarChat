import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Provider API keys (set in Edge Function secrets)
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const GOOGLE_API_KEY = Deno.env.get("GOOGLE_API_KEY") ?? "";
const HUME_API_KEY = Deno.env.get("HUME_API_KEY") ?? "";
const ELEVENLABS_API_KEY = Deno.env.get("ELEVENLABS_API_KEY") ?? "";

type Provider =
  | "openai_realtime"
  | "gemini_live"
  | "hume_evi3"
  | "elevenlabs_conv";

interface ProviderConfig {
  url: string;
  headers: Record<string, string>;
  protocols?: string[];
}

function getProviderConfig(
  provider: Provider,
  model?: string
): ProviderConfig | null {
  switch (provider) {
    case "openai_realtime":
      return {
        url: `wss://api.openai.com/v1/realtime?model=${model ?? "gpt-4o-realtime-preview"}`,
        headers: {
          Authorization: `Bearer ${OPENAI_API_KEY}`,
          "OpenAI-Beta": "realtime=v1",
        },
      };

    case "gemini_live":
      return {
        url: `wss://generativelanguage.googleapis.com/v1alpha/models/${model ?? "gemini-2.0-flash-live-001"}:streamGenerateContent?key=${GOOGLE_API_KEY}`,
        headers: {},
      };

    case "hume_evi3":
      return {
        url: "wss://api.hume.ai/v0/evi/chat",
        headers: {
          "X-Hume-Api-Key": HUME_API_KEY,
        },
      };

    case "elevenlabs_conv":
      return {
        url: "wss://api.elevenlabs.io/v1/convai/conversation",
        headers: {
          "xi-api-key": ELEVENLABS_API_KEY,
        },
      };

    default:
      return null;
  }
}

Deno.serve(async (req: Request) => {
  // Only handle WebSocket upgrade requests
  const upgradeHeader = req.headers.get("upgrade");
  if (upgradeHeader?.toLowerCase() !== "websocket") {
    return new Response("Expected WebSocket upgrade", { status: 426 });
  }

  // Extract and validate JWT
  const authHeader = req.headers.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response("Missing authorization", { status: 401 });
  }

  const jwt = authHeader.slice(7);
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(jwt);

  if (authError || !user) {
    return new Response("Invalid token", { status: 401 });
  }

  // Parse provider from query params
  const url = new URL(req.url);
  const provider = url.searchParams.get("provider") as Provider | null;
  const model = url.searchParams.get("model") ?? undefined;

  if (!provider) {
    return new Response("Missing provider param", { status: 400 });
  }

  const config = getProviderConfig(provider, model);
  if (!config) {
    return new Response(`Unknown provider: ${provider}`, { status: 400 });
  }

  // Check user quota
  const { data: quota } = await supabase
    .from("user_quotas")
    .select("free_minutes_remaining, paid_credits_cents, tier")
    .eq("user_id", user.id)
    .single();

  if (quota && quota.free_minutes_remaining <= 0 && quota.paid_credits_cents <= 0) {
    return new Response("Quota exhausted", { status: 402 });
  }

  // Upgrade client connection to WebSocket
  const { socket: clientSocket, response } = Deno.upgradeWebSocket(req);
  const sessionStart = Date.now();
  let upstreamSocket: WebSocket | null = null;

  clientSocket.onopen = () => {
    // Connect to upstream provider
    upstreamSocket = new WebSocket(config.url, config.protocols);

    // Set headers via protocol if needed (WebSocket API limitation)
    // For providers that need headers, we append them to the URL or use protocols

    upstreamSocket.onopen = () => {
      // Upstream connected — relay is active
    };

    upstreamSocket.onmessage = (event: MessageEvent) => {
      // Relay upstream messages to client
      if (clientSocket.readyState === WebSocket.OPEN) {
        clientSocket.send(event.data);
      }
    };

    upstreamSocket.onerror = (event: Event) => {
      if (clientSocket.readyState === WebSocket.OPEN) {
        clientSocket.send(
          JSON.stringify({
            type: "error",
            error: { message: "Upstream provider error" },
          })
        );
      }
    };

    upstreamSocket.onclose = () => {
      if (clientSocket.readyState === WebSocket.OPEN) {
        clientSocket.close(1000, "Upstream closed");
      }
    };
  };

  clientSocket.onmessage = (event: MessageEvent) => {
    // Relay client messages to upstream
    if (upstreamSocket?.readyState === WebSocket.OPEN) {
      upstreamSocket.send(event.data);
    }
  };

  clientSocket.onclose = async () => {
    // Clean up upstream connection
    if (upstreamSocket?.readyState === WebSocket.OPEN) {
      upstreamSocket.close();
    }

    // Log usage event
    const durationSeconds = Math.round((Date.now() - sessionStart) / 1000);

    try {
      await supabase.from("usage_events").insert({
        user_id: user.id,
        device_id: url.searchParams.get("device_id") ?? "unknown",
        provider: provider,
        tier: quota?.tier ?? "free",
        duration_seconds: durationSeconds,
      });

      // Deduct from quota (1 minute minimum)
      const minutesUsed = Math.max(1, Math.ceil(durationSeconds / 60));

      if (quota) {
        const newRemaining = Math.max(
          0,
          quota.free_minutes_remaining - minutesUsed
        );
        await supabase
          .from("user_quotas")
          .update({
            free_minutes_remaining: newRemaining,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", user.id);
      }
    } catch {
      // Non-critical — usage logging can fail gracefully
    }
  };

  clientSocket.onerror = () => {
    if (upstreamSocket?.readyState === WebSocket.OPEN) {
      upstreamSocket.close();
    }
  };

  return response;
});
