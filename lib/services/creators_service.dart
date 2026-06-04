import 'package:dio/dio.dart';

import '../models/creator.dart';
import 'api_config.dart';

class CreatorsService {
  final Dio _dio;

  CreatorsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  /// Fetches active creators from GET /api/creators (backed by Supabase when configured).
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
