/// Runtime configuration, sourced from `--dart-define` flags so no secret is
/// ever committed. All keys are optional: when absent, the matching live
/// integration is skipped and the app falls back to its static demo data.
///
/// Run with real data like:
/// ```
/// flutter run \
///   --dart-define=EBIRD_API_KEY=xxxx \
///   --dart-define=XENO_CANTO_API_KEY=yyyy
/// ```
///
/// Get the keys (both free):
///   eBird       -> https://ebird.org/api/keygen
///   xeno-canto  -> https://xeno-canto.org  (account settings, after sign-up)
abstract final class AppConfig {
  static const ebirdApiKey = String.fromEnvironment('EBIRD_API_KEY');
  static const xenoCantoApiKey = String.fromEnvironment('XENO_CANTO_API_KEY');

  /// Supabase backend (real accounts/friends/sightings). When absent the app
  /// runs entirely on local demo data with biometric demo auth.
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// eBird taxonomy is open, but recent-observations needs a key.
  static bool get hasEbirdKey => ebirdApiKey.isNotEmpty;
  static bool get hasXenoCantoKey => xenoCantoApiKey.isNotEmpty;

  /// True when a Supabase project is configured → use the real backend.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
