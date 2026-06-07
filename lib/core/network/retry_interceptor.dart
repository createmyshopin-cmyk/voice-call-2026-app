import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'api_diagnostics.dart';

/// Retries transient network failures with exponential-style backoff.
///
/// Attempt 1 → wait 2s, attempt 2 → wait 4s, attempt 3 → wait 6s.
class RetryInterceptor extends Interceptor {
  static const _retryCountKey = 'retryCount';
  static const _maxRetries = 3;
  static const _delays = [2, 4, 6];

  final Dio dio;

  RetryInterceptor(this.dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final extra = err.requestOptions.extra;
    final attempt = (extra[_retryCountKey] as int? ?? 0);
    if (attempt >= _maxRetries) {
      apiNetworkLog(
        'Retry exhausted (${_maxRetries}x) for ${err.requestOptions.uri}',
      );
      return handler.next(err);
    }

    final delaySeconds = _delays[attempt.clamp(0, _delays.length - 1)];
    apiNetworkLog(
      'Retry ${attempt + 1}/$_maxRetries in ${delaySeconds}s '
      'for ${err.requestOptions.uri} (${err.type})',
    );
    await Future<void>.delayed(Duration(seconds: delaySeconds));

    final options = err.requestOptions;
    options.extra[_retryCountKey] = attempt + 1;

    try {
      final response = await dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    } catch (e) {
      return handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.cancel) return false;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    final inner = err.error;
    if (inner is SocketException || inner is TimeoutException) {
      return true;
    }

    // 502/503/504 — temporary server unavailability
    final code = err.response?.statusCode;
    if (code == 502 || code == 503 || code == 504) return true;

    return false;
  }
}
