import 'package:dio/dio.dart';

import '../core/network/api_diagnostics.dart';
import '../core/network/network_logger.dart';
import '../core/network/network_status.dart';
import '../core/network/retry_interceptor.dart';
import 'api_config.dart';

Dio? _sharedDio;
ApiDiagnosticsInterceptor? _apiDiagnostics;

/// Global Dio instance with timeouts, logging, and retry interceptors.
Dio get apiDio {
  _sharedDio ??= _buildDio();
  return _sharedDio!;
}

/// Shared Dio factory — pass [accessToken] via [authOptions] on each request.
Dio createApiDio({String? accessToken}) => apiDio;

/// Binds live connection type into API request logs (call after [NetworkService] init).
void bindApiDiagnosticsConnectionType(ConnectionType Function() reader) {
  _apiDiagnostics?.bindConnectionType(reader);
}

Dio _buildDio() {
  apiNetworkLog('Initializing Dio with baseUrl=$apiBaseUrl');

  final diagnostics = ApiDiagnosticsInterceptor();
  _apiDiagnostics = diagnostics;

  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    diagnostics,
    NetworkLogger(),
    RetryInterceptor(dio),
  ]);

  return dio;
}

/// Per-request auth header helper.
Options authOptions(String accessToken, {Options? base}) {
  return (base ?? Options()).copyWith(
    headers: {
      ...?base?.headers,
      'Authorization': 'Bearer $accessToken',
    },
  );
}
