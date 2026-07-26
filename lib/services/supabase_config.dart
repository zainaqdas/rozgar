import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration for Rozgar.
///
/// Initialize in main.dart before runApp:
///   await SupabaseConfig.initialize();
///
/// Then access the client anywhere:
///   SupabaseConfig.client
class SupabaseConfig {
  SupabaseConfig._();

  static const String _supabaseUrl = 'https://hjnhudboyjkagicosrba.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhqbmh1ZGJveWprYWdpY29zcmJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5OTE1NDksImV4cCI6MjEwMDU2NzU0OX0.sZSX5ciEA8VfBi_ARU6zY7DYPlEcPmJBT0SIXuwGIAs';

  static bool _initialized = false;

  /// Initialize the Supabase client. Must be called before `runApp`.
  static Future<void> initialize() async {
    if (_initialized) return;      await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );
    _initialized = true;
  }

  /// The singleton Supabase client.
  static SupabaseClient get client => Supabase.instance.client;
}
