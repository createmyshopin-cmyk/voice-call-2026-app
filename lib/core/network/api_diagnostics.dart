import 'dart:async' show TimeoutException;
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kProfileMode, kReleaseMode;

import '../../services/api_config.dart';
import 'network_service.dart';
import 'network_status.dart';

/// Release-safe logs — filter logcat with: `adb logcat -s flutter`
void _log(String tag, String message) {
  final line = '[$tag] $message';
  developer.log(line, name: tag);
  // ignore: avoid_print
  print(line);
}

void apiLog(String message) => _log('API', message);
void networkLog(String message) => _log('NETWORK', message);
void dnsLog(String message) => _log('DNS', message);

/// Legacy alias used by Dio interceptors.
void apiNetworkLog(String message) => apiLog(message);

/// Startup diagnostics: base URL, link type, internet, DNS, and health check.
Future<void> logApiStartupDiagnostics({
  required NetworkService networkService,
}) async {
  apiLog('BASE_URL=$apiBaseUrl');
  networkLog('connectionType=${networkService.connectionType.name}');
  networkLog('internetReachable=${networkService.internetReachable}');
  networkLog('backendReachable=${networkService.backendReachable}');
  apiLog(
    'build: debug=$kDebugMode profile=$kProfileMode release=$kReleaseMode',
  );

  await probeDns(apiHost);
  await probeApiHealth();
}

Future<void> probeDns(String host) async {
  dnsLog('Resolving $host');
  try {
    final addresses = await InternetAddress.lookup(host).timeout(
      const Duration(seconds: 8),
    );
    if (addresses.isEmpty) {
      dnsLog('Resolution Failed — no addresses returned');
      return;
    }
    dnsLog(
      'Resolution Success — ${addresses.map((a) => a.address).join(', ')}',
    );
  } on SocketException catch (e) {
    dnsLog(
      'Resolution Failed — ${e.message} '
      '(osError: ${e.osError?.message}, errno: ${e.osError?.errorCode})',
    );
  } on TimeoutException catch (e) {
    dnsLog('Resolution Failed — timeout: $e');
  } catch (e) {
    dnsLog('Resolution Failed — $e');
  }
}

Future<void> probeApiHealth() async {
  final uri = Uri.parse(apiHealthUrl);
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 10));
    final response = await request.close().timeout(const Duration(seconds: 10));
    final code = response.statusCode;
    client.close(force: true);

    if (code >= 200 && code < 500) {
      apiLog('Health Check Success — status=$code url=$apiHealthUrl');
    } else {
      apiLog('Health Check Failed — status=$code url=$apiHealthUrl');
    }
  } on SocketException catch (e) {
    apiLog(
      'Health Check Failed — ${e.message} '
      '(osError: ${e.osError?.message}, errno: ${e.osError?.errorCode})',
    );
  } on TimeoutException catch (e) {
    apiLog('Health Check Failed — timeout: $e');
  } catch (e) {
    apiLog('Health Check Failed — $e');
  }
}

/// Dio interceptor that logs every request/error in release builds.
class ApiDiagnosticsInterceptor extends Interceptor {
  ConnectionType Function()? _connectionTypeReader;

  void bindConnectionType(ConnectionType Function() reader) {
    _connectionTypeReader = reader;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final connection = _connectionTypeReader?.call() ?? ConnectionType.unknown;
    apiLog(
      'REQUEST ${options.method} ${options.uri} '
      '(baseUrl=${options.baseUrl}, connection=${connection.name})',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    apiLog('RESPONSE ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final inner = err.error;
    final connection = _connectionTypeReader?.call() ?? ConnectionType.unknown;
    final buffer = StringBuffer()
      ..write('ERROR ${err.type} ${err.requestOptions.uri}')
      ..write(' connection=${connection.name}')
      ..write(' message=${err.message}');
    if (inner is SocketException) {
      buffer
        ..write(' socket=${inner.message}')
        ..write(' osError=${inner.osError?.message}')
        ..write(' errno=${inner.osError?.errorCode}');
    } else if (inner != null) {
      buffer.write(' inner=$inner');
    }
    apiLog(buffer.toString());
    handler.next(err);
  }
}
