import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// App Store Server API v2 credentials
const APP_STORE_KEY_ID = Deno.env.get("APP_STORE_KEY_ID") ?? "";
const APP_STORE_ISSUER_ID = Deno.env.get("APP_STORE_ISSUER_ID") ?? "";
const APP_STORE_PRIVATE_KEY = Deno.env.get("APP_STORE_PRIVATE_KEY") ?? "";

interface ReceiptRequest {
  original_transaction_id: string;
  product_id: string;
  user_id: string;
}

function tierForProduct(productId: string): string {
  if (productId.includes("premium")) return "premium";
  if (productId.includes("standard")) return "standard";
  return "free";
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Validate JWT
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

  try {
    const body: ReceiptRequest = await req.json();

    // Upsert subscription record
    const tier = tierForProduct(body.product_id);

    const { error: upsertError } = await supabase
      .from("user_subscriptions")
      .upsert(
        {
          user_id: user.id,
          product_id: body.product_id,
          tier: tier,
          status: "active",
          original_transaction_id: body.original_transaction_id,
        },
        {
          onConflict: "user_id,product_id",
        }
      );

    if (upsertError) {
      return new Response(
        JSON.stringify({ error: "Failed to update subscription" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Update user quota based on tier
    const minutesForTier: Record<string, number> = {
      free: 10,
      standard: 120,
      premium: 120,
    };

    await supabase.from("user_quotas").upsert(
      {
        user_id: user.id,
        tier: tier,
        free_minutes_remaining: minutesForTier[tier] ?? 10,
        updated_at: new Date().toISOString(),
      },
      {
        onConflict: "user_id",
      }
    );

    return new Response(
      JSON.stringify({ success: true, tier }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid request body" }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }
});
