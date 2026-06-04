import 'package:dio/dio.dart';

import 'api_config.dart';

class UsersService {
  final Dio _dio;

  UsersService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    String? gender,
    String? language,
    bool? onboardingCompleted,
  }) async {
    final response = await _dio.patch(
      '/api/users/profile',
      data: {
        if (gender != null) 'gender': gender,
        if (language != null) 'language': language,
        if (onboardingCompleted != null) 'onboardingCompleted': onboardingCompleted,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return response.data as Map<String, dynamic>;
  }
}
