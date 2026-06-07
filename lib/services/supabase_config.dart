import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client for Realtime presence on `creator_profiles`.
///
/// Override at build time if needed:
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
class SupabaseConfig {
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Production project (anon key is safe client-side with RLS).
  static const String _productionUrl =
      'https://rxlvgfgksahgiiccorzx.supabase.co';
  static const String _productionAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4bHZnZmdrc2FoZ2lpY2Nvcnp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA1MDYyMjQsImV4cCI6MjA5NjA4MjIyNH0.-ex5A641biubDe0PfQpi8BBtGQ9dfAXB_kvU_mHXxuY';

  static String get url =>
      _envUrl.isNotEmpty ? _envUrl : _productionUrl;

  static String get anonKey =>
      _envAnonKey.isNotEmpty ? _envAnonKey : _productionAnonKey;

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) return;
    if (Supabase.instance.isInitialized) return;
    await Supabase.initialize(
      url: url,
      anonKey: anonKey, // ignore: deprecated_member_use
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
