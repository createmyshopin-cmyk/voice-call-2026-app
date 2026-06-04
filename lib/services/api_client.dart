import 'package:dio/dio.dart';
import 'api_config.dart';

/// Shared Dio factory — always pass [accessToken] for protected /api routes.
Dio createApiDio({String? accessToken}) {
  return Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: accessToken != null && accessToken.isNotEmpty
          ? {'Authorization': 'Bearer $accessToken'}
          : null,
    ),
  );
}
