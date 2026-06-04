import 'package:dio/dio.dart';

/// Turns API/Dio failures into short, user-facing text (no stack traces).
String apiErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is DioException) {
    final fromServer = _messageFromResponseBody(error.response?.data);
    if (fromServer != null) return fromServer;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your internet connection.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        break;
    }

    final code = error.response?.statusCode;
    if (code == 401) {
      return 'Your session expired. Please sign in again.';
    }
    if (code == 403) {
      return 'You do not have permission to do that.';
    }
    if (code == 404) {
      return 'This item was not found. It may have expired—try again.';
    }
    if (code != null && code >= 500) {
      return 'Server error. Please try again in a moment.';
    }
  }

  if (error is Exception) {
    final raw = error.toString();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) {
      final inner = raw.substring(prefix.length).trim();
      if (inner.isNotEmpty && !inner.contains('DioException')) {
        return inner;
      }
    }
  }

  return fallback;
}

String callAcceptErrorMessage(Object error) => apiErrorMessage(
      error,
      fallback: 'Could not accept the call. Please try again.',
    );

String callRequestErrorMessage(Object error) => apiErrorMessage(
      error,
      fallback: 'Failed to start the call. Please try again.',
    );

String profileSaveErrorMessage(Object error) => apiErrorMessage(
      error,
      fallback: 'Could not save profile. Please try again.',
    );

String? _messageFromResponseBody(dynamic data) {
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
