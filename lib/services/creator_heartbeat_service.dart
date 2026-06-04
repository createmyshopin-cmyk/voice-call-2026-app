import 'package:dio/dio.dart';

import 'api_config.dart';

/// POST /api/creators/heartbeat — updates creator last_seen_at on the server.
class CreatorHeartbeatService {
  static const heartbeatInterval = Duration(seconds: 45);

  final Dio _dio;

  CreatorHeartbeatService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  Future<void> sendHeartbeat(String accessToken) async {
    await _dio.post(
      '/api/creators/heartbeat',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }
}
