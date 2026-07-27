/// App configuration — reads from --dart-define.
/// Pass at build time:
///   flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx --dart-define=GOOGLE_MAPS_API_KEY=xxx
///
/// For VS Code, use the provided .vscode/launch.json which includes all defines.
/// For CI/CD, set these via your build pipeline secrets.
/// See .env.example for the list of required variables.
class AppConfig {
  AppConfig._();

  static String get supabaseUrl =>
      const String.fromEnvironment('SUPABASE_URL');

  static String get supabaseAnonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Google Maps API key. For Android, key must also be in AndroidManifest.xml.
  /// For web, key must also be in web/index.html.
  static String get googleMapsApiKey =>
      const String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// Groq API key (primary AI provider — Llama 3.3 70B).
  static String get groqApiKey =>
      const String.fromEnvironment('GROQ_API_KEY');

  /// Mistral API key (fallback AI provider).
  static String get mistralApiKey =>
      const String.fromEnvironment('MISTRAL_API_KEY');

  /// Throws a clear error if required config is missing.
  /// Call before Supabase initialization.
  static void validate() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required --dart-define variables: ${missing.join(', ')}.\n'
        'Run with: flutter run ${missing.map((k) => '--dart-define=$k=<value>').join(' ')}\n'
        'Or use .vscode/launch.json which includes dev defaults.',
      );
    }
  }
}
