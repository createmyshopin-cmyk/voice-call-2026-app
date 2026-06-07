import '../core/network/api_exception.dart';
import '../core/network/network_service.dart';

/// Turns API failures into short, user-facing text (no stack traces).
String apiErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
  NetworkService? networkService,
}) {
  return ApiException.from(
    error,
    fallback: fallback,
    networkService: networkService,
  ).message;
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
