import 'dart:async' show TimeoutException;
import 'dart:io';

import 'package:dio/dio.dart';

import 'network_status.dart';
import 'network_service.dart';

enum ApiExceptionType {
  noInternet,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  cancelled,
  unknown,
}

const _connectionMessage =
    'Unable to connect to server. Please check your internet connection and try again.';

const _dnsMessage =
    'Server could not be reached. Please try again in a few moments.';

/// Typed API failure with a safe, user-facing [message].
class ApiException implements Exception {
  final String message;
  final ApiExceptionType type;
  final int? statusCode;
  final Object? originalError;

  const ApiException({
    required this.message,
    required this.type,
    this.statusCode,
    this.originalError,
  });

  bool get isNoInternet => type == ApiExceptionType.noInternet;

  /// Builds an [ApiException] from any thrown value.
  static ApiException from(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
    NetworkService? networkService,
  }) {
    if (error is ApiException) return error;

    final offline = networkService?.status == NetworkStatus.disconnected;

    if (error is DioException) {
      if (_isDnsFailure(error)) {
        return const ApiException(
          message: _dnsMessage,
          type: ApiExceptionType.noInternet,
        );
      }

      if (offline || _isConnectionFailure(error)) {
        return const ApiException(
          message: _connectionMessage,
          type: ApiExceptionType.noInternet,
        );
      }

      final fromServer = _messageFromResponseBody(error.response?.data);
      if (fromServer != null) {
        return ApiException(
          message: fromServer,
          type: _typeFromStatusCode(error.response?.statusCode),
          statusCode: error.response?.statusCode,
          originalError: error,
        );
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const ApiException(
            message: _connectionMessage,
            type: ApiExceptionType.timeout,
          );
        case DioExceptionType.connectionError:
          return const ApiException(
            message: _connectionMessage,
            type: ApiExceptionType.noInternet,
          );
        case DioExceptionType.cancel:
          return const ApiException(
            message: 'Request cancelled.',
            type: ApiExceptionType.cancelled,
          );
        default:
          break;
      }

      final code = error.response?.statusCode;
      if (code != null) {
        return ApiException(
          message: _defaultMessageForCode(code),
          type: _typeFromStatusCode(code),
          statusCode: code,
          originalError: error,
        );
      }
    }

    if (error is SocketException) {
      return ApiException(
        message: _isDnsSocketFailure(error) ? _dnsMessage : _connectionMessage,
        type: ApiExceptionType.noInternet,
        originalError: error,
      );
    }

    if (error is TimeoutException) {
      return const ApiException(
        message: _connectionMessage,
        type: ApiExceptionType.timeout,
      );
    }

    if (error is Exception) {
      final raw = error.toString();
      if (_rawLooksLikeDnsFailure(raw)) {
        return const ApiException(
          message: _dnsMessage,
          type: ApiExceptionType.noInternet,
        );
      }
      if (_rawLooksLikeConnectionFailure(raw)) {
        return const ApiException(
          message: _connectionMessage,
          type: ApiExceptionType.noInternet,
        );
      }
      const prefix = 'Exception: ';
      if (raw.startsWith(prefix)) {
        final inner = raw.substring(prefix.length).trim();
        if (inner.isNotEmpty &&
            !inner.contains('DioException') &&
            !inner.contains('SocketException')) {
          return ApiException(
            message: inner,
            type: ApiExceptionType.unknown,
            originalError: error,
          );
        }
      }
    }

    return ApiException(
      message: fallback,
      type: ApiExceptionType.unknown,
      originalError: error,
    );
  }

  static bool _isConnectionFailure(DioException error) {
    if (error.type == DioExceptionType.connectionError) return true;
    final inner = error.error;
    return inner is SocketException && !_isDnsSocketFailure(inner);
  }

  static bool _isDnsFailure(DioException error) {
    final inner = error.error;
    if (inner is SocketException) return _isDnsSocketFailure(inner);
    final message = (error.message ?? '').toLowerCase();
    return _rawLooksLikeDnsFailure(message);
  }

  static bool _isDnsSocketFailure(SocketException error) {
    final message = error.message.toLowerCase();
    return message.contains('failed host lookup') ||
        message.contains('no address associated with hostname') ||
        error.osError?.errorCode == 7;
  }

  static bool _rawLooksLikeDnsFailure(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('failed host lookup') ||
        lower.contains('no address associated with hostname');
  }

  static bool _rawLooksLikeConnectionFailure(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('dioexception') ||
        lower.contains('connection error') ||
        lower.contains('connection refused');
  }

  static ApiExceptionType _typeFromStatusCode(int? code) {
    if (code == null) return ApiExceptionType.unknown;
    if (code == 401) return ApiExceptionType.unauthorized;
    if (code == 403) return ApiExceptionType.forbidden;
    if (code == 404) return ApiExceptionType.notFound;
    if (code >= 500) return ApiExceptionType.serverError;
    return ApiExceptionType.unknown;
  }

  static String _defaultMessageForCode(int code) {
    switch (code) {
      case 401:
        return 'Your session expired. Please sign in again.';
      case 403:
        return 'You do not have permission to do that.';
      case 404:
        return 'This item was not found. It may have expired—try again.';
      default:
        if (code >= 500) {
          return 'Server is temporarily unavailable.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  static String? _messageFromResponseBody(dynamic data) {
    if (data is! Map) return null;

    final message = data['message'];
    if (message is String) {
      final trimmed = message.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    if (message is List) {
      final lines = message
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) return lines.join('\n');
    }

    final errorField = data['error'];
    if (errorField is String && errorField.trim().isNotEmpty) {
      return errorField.trim();
    }

    return null;
  }

  @override
  String toString() => message;
}
