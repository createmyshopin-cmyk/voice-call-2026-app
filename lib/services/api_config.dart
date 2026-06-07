import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// Production API. Override at build time:
/// `flutter build apk --dart-define=API_BASE_URL=https://api.creomine.com`
const String productionApiUrl = 'https://api.creomine.com';

/// Hostname extracted from [apiBaseUrl] (no scheme/path).
String get apiHost {
  final uri = Uri.parse(apiBaseUrl);
  return uri.host;
}

/// Startup health probe — `GET /health` on the API root (no `/api` prefix).
String get apiHealthUrl => '$apiBaseUrl/health';

String get apiBaseUrl {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) {
    assert(
      envUrl.startsWith('https://'),
      'API_BASE_URL must use HTTPS in production builds.',
    );
    assert(
      kDebugMode || !_isLocalOrPrivateUrl(envUrl),
      'API_BASE_URL cannot be local/private in release builds.',
    );
    return envUrl;
  }

  // Local backend only when explicitly requested (emulator debug).
  // Never used in release/profile builds — physical devices cannot reach 10.0.2.2.
  const useLocalApi = bool.fromEnvironment('USE_LOCAL_API', defaultValue: false);
  if (kDebugMode && useLocalApi) {
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  return productionApiUrl;
}

bool _isLocalOrPrivateUrl(String url) {
  final host = Uri.parse(url).host.toLowerCase();
  if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
    return true;
  }
  if (host.startsWith('192.168.') ||
      host.startsWith('10.') ||
      host.startsWith('172.')) {
    return true;
  }
  return false;
}
