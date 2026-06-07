import 'package:dio/dio.dart';
import '../models/gift_item.dart';
import 'api_client.dart';

class GiftService {
  final Dio _dio = apiDio;

  Future<List<GiftItem>> fetchCatalog(String accessToken) async {
    final response = await _dio.get(
      '/api/gifts',
      options: authOptions(accessToken),
    );
    final data = response.data;
    if (data is! List) return [];
    return data
        .map((e) => GiftItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<SendGiftResult> sendGift({
    required String accessToken,
    required String giftId,
    required String creatorId,
    required String callId,
    required String idempotencyKey,
  }) async {
    final response = await _dio.post(
      '/api/gifts/send',
      data: {
        'giftId': giftId,
        'creatorId': creatorId,
        'callId': callId,
        'idempotencyKey': idempotencyKey,
      },
      options: authOptions(accessToken),
    );
    return SendGiftResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> replyToGift({
    required String accessToken,
    required String giftTransactionId,
    required String message,
  }) async {
    await _dio.post(
      '/api/gifts/reply',
      data: {
        'giftTransactionId': giftTransactionId,
        'message': message,
      },
      options: authOptions(accessToken),
    );
  }

  Future<List<Map<String, dynamic>>> fetchSenderHistory(
    String accessToken,
  ) async {
    final response = await _dio.get(
      '/api/gifts/history',
      options: authOptions(accessToken),
    );
    final data = response.data;
    if (data is! List) return [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
