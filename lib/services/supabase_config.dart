import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client for Realtime presence on `creator_profiles`.
///
/// Build with:
/// `flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...`
class SupabaseConfig {
  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static String get url => _url;
  static String get anonKey => _anonKey;

  static Future<void> initialize() async {
    if (!isConfigured) return;
    if (Supabase.instance.isInitialized) return;
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey, // ignore: deprecated_member_use
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
