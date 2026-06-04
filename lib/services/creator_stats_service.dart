import 'package:dio/dio.dart';
import 'api_client.dart';

class CreatorEarningRecord {
  final double creatorShare;
  final DateTime createdAt;

  CreatorEarningRecord({required this.creatorShare, required this.createdAt});

  factory CreatorEarningRecord.fromJson(Map<String, dynamic> json) {
    return CreatorEarningRecord(
      creatorShare: (json['creatorShare'] as num? ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Live creator analytics from GET /api/creators/earnings-history + call history.
class CreatorStatsService {
  final Dio _dio;

  CreatorStatsService({required String accessToken})
      : _dio = createApiDio(accessToken: accessToken);

  Future<List<CreatorEarningRecord>> fetchEarningsHistory() async {
    final response = await _dio.get('/api/creators/earnings-history');
    final data = response.data;
    if (data is! List) return [];
    return data
        .map((e) => CreatorEarningRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Last 7 days (Mon–Sun order) creator share totals for chart.
  static List<int> weeklyCoinsFromEarnings(List<CreatorEarningRecord> records) {
    final now = DateTime.now();
    final days = List<int>.filled(7, 0);
    for (final r in records) {
      final diff = now.difference(r.createdAt).inDays;
      if (diff >= 0 && diff < 7) {
        final weekdayIndex = r.createdAt.weekday - 1; // Mon=0
        days[weekdayIndex] += r.creatorShare.round();
      }
    }
    return days;
  }

  static double totalCoins(List<CreatorEarningRecord> records) =>
      records.fold(0.0, (sum, r) => sum + r.creatorShare);
}
