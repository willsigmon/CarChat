import Foundation
import Supabase

enum SupabaseConfig {
    // These should be set via environment or xcconfig in production
    static let url = URL(string: "https://your-project.supabase.co")!
    static let anonKey = "your-anon-key"
}

@MainActor
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)
