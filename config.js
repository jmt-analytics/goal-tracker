// Goal Tracker configuration
// Paste the two values from Supabase: Project Settings -> API (or "Connect" -> App Frameworks).
// The anon/publishable key is safe to put in a web page: row-level security
// in the database makes sure only you, signed in, can read or change your goals.
// Leave both blank to run in demo mode (data stays in this browser only).

window.GOAL_TRACKER_CONFIG = {
  supabaseUrl: "https://kxwftjweofhttzezeszu.supabase.co",      // e.g. "https://kxwftjweofhttzezeszu.supabase.co"
  supabaseAnonKey: "sb_publishable_Kv0lXuuDGSw-IhLjWiJFyQ_Br6M33MA"   // the long "anon" / "publishable" key
};

