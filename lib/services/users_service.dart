import 'package:dio/dio.dart';

import 'api_client.dart';

class UsersService {
  final Dio _dio;

  UsersService({Dio? dio}) : _dio = dio ?? apiDio;

  Future<Map<String, dynamic>> completeOnboarding({
    required String accessToken,
    required String fullName,
    required String dateOfBirth,
    required String gender,
    required String avatarUrl,
  }) async {
    final response = await _dio.post(
      '/api/users/complete-onboarding',
      data: {
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'avatarUrl': avatarUrl,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    String? fullName,
    String? avatarUrl,
    String? language,
  }) async {
    final response = await _dio.patch(
      '/api/users/profile',
      data: {
        if (fullName != null) 'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (language != null) 'language': language,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return response.data as Map<String, dynamic>;
  }
}
