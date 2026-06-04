import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

String get apiBaseUrl {
  if (kIsWeb) return 'http://localhost:5000';
  if (Platform.isAndroid) return 'http://10.0.2.2:5000';
  return 'http://localhost:5000';
}
