import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

/// Supabase configuration for Rozgar.
///
/// Initialize in main.dart before runApp:
///   await SupabaseConfig.initialize();
///
/// Then access the client anywhere:
///   SupabaseConfig.client
class SupabaseConfig {
  SupabaseConfig._();

  static final String _supabaseUrl = AppConfig.supabaseUrl;
  static final String _supabaseAnonKey = AppConfig.supabaseAnonKey;

  static Future<void>? _initFuture;

  /// Initialize the Supabase client. Must be called before `runApp`.
  /// Concurrent calls share a single underlying init future (no race).
  /// Throws [StateError] if required config is missing.
  static Future<void> initialize() async {
    AppConfig.validate();
    _initFuture ??= Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );
    try {
      await _initFuture!;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  /// The singleton Supabase client.
  static SupabaseClient get client => Supabase.instance.client;
}
