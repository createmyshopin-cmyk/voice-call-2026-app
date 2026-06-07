import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Logs HTTP traffic in debug builds only.
class NetworkLogger extends Interceptor {
  static const _tag = '[Network]';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '$_tag --> ${options.method} ${options.uri}',
      );
      if (options.data != null) {
        debugPrint('$_tag     body: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '$_tag <-- ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '$_tag !! ${err.type} ${err.requestOptions.uri} — ${err.message}',
      );
      if (err.response?.data != null) {
        debugPrint('$_tag     response: ${err.response?.data}');
      }
    }
    handler.next(err);
  }
}
