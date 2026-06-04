import 'package:dio/dio.dart';
import '../models/creator.dart';
import 'api_client.dart';

class CreatorsService {
  final Dio _dio;

  CreatorsService({required String accessToken, Dio? dio})
      : _dio = dio ?? createApiDio(accessToken: accessToken);

  /// GET /api/creators — requires user JWT (Firebase login).
  Future<List<Creator>> fetchActiveCreators() async {
    final response = await _dio.get('/api/creators');
    final data = response.data;
    if (data is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Invalid creators response',
      );
    }
    return data
        .map((item) => Creator.fromApiJson(item as Map<String, dynamic>))
        .toList();
  }
}
