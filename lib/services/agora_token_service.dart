import 'package:dio/dio.dart';

import 'api_config.dart';

/// Response from POST /api/agora/token — tokens are always issued by the backend.
class AgoraTokenResponse {
  final String token;
  final String channelName;

  const AgoraTokenResponse({
    required this.token,
    required this.channelName,
  });

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> json) {
    return AgoraTokenResponse(
      token: json['token'] as String? ?? '',
      channelName: json['channelName'] as String? ?? '',
    );
  }
}

/// Fetches Agora RTC tokens from the backend. Never generate tokens in Flutter.
class AgoraTokenService {
  final Dio _dio;

  AgoraTokenService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  /// POST /api/agora/token
  Future<AgoraTokenResponse> fetchToken({
    required String accessToken,
    String? channelName,
  }) async {
    final response = await _dio.post(
      '/api/agora/token',
      data: {
        if (channelName != null && channelName.isNotEmpty)
          'channelName': channelName,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Invalid Agora token response',
      );
    }

    return AgoraTokenResponse.fromJson(data);
  }
}
