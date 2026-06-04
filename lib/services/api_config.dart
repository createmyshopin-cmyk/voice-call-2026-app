import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// Production API (Railway). Override at build time:
/// `flutter build apk --dart-define=API_BASE_URL=https://your-api.example.com`
const String _productionUrl =
    'https://backend-api-production-140f.up.railway.app';

String get apiBaseUrl {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;

  // Local backend only in debug (emulator / desktop).
  if (kDebugMode) {
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  return _productionUrl;
}
