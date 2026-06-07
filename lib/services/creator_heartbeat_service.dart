import 'package:dio/dio.dart';

import 'api_client.dart';

/// Creator presence: online/offline toggle + heartbeat while online.
class CreatorHeartbeatService {
  static const heartbeatInterval = Duration(seconds: 30);

  final Dio _dio;

  CreatorHeartbeatService({Dio? dio}) : _dio = dio ?? apiDio;

  Future<void> setOnline(String accessToken) async {
    await _dio.post(
      '/api/creators/online',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }

  Future<void> setOffline(String accessToken) async {
    await _dio.post(
      '/api/creators/offline',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }

  Future<void> sendHeartbeat(String accessToken) async {
    await _dio.post(
      '/api/creators/heartbeat',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }
}
