import 'package:dio/dio.dart';

import '../models/gift_item.dart';
import '../utils/gift_grouping.dart';
import 'api_client.dart';

class CreatorGiftStats {
  final int todayGifts;
  final int weekGifts;
  final int monthGifts;
  final int lifetimeGifts;
  final int totalGiftCoins;
  final int totalGiftEarnings;

  const CreatorGiftStats({
    required this.todayGifts,
    required this.weekGifts,
    required this.monthGifts,
    required this.lifetimeGifts,
    required this.totalGiftCoins,
    required this.totalGiftEarnings,
  });

  factory CreatorGiftStats.fromJson(Map<String, dynamic> json) {
    return CreatorGiftStats(
      todayGifts: (json['today'] as num?)?.toInt() ?? 0,
      weekGifts: (json['week'] as num?)?.toInt() ?? 0,
      monthGifts: (json['month'] as num?)?.toInt() ?? 0,
      lifetimeGifts: (json['lifetime'] as num?)?.toInt() ?? 0,
      totalGiftCoins: (json['totalGiftCoins'] as num?)?.toInt() ?? 0,
      totalGiftEarnings: (json['totalGiftEarnings'] as num?)?.toInt() ?? 0,
    );
  }
}

class CreatorRecentGift {
  final String giftName;
  final String giftEmoji;
  final int coins;
  final String senderFirstName;
  final DateTime? createdAt;

  const CreatorRecentGift({
    required this.giftName,
    required this.giftEmoji,
    required this.coins,
    required this.senderFirstName,
    this.createdAt,
  });
}

class CreatorGiftService {
  final Dio _dio = apiDio;

  Future<CreatorGiftStats> fetchStats(String accessToken) async {
    final res = await _dio.get(
      '/api/listener/gifts/stats',
      options: authOptions(accessToken),
    );
    return CreatorGiftStats.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<List<CreatorRecentGift>> fetchRecent(String accessToken) async {
    final res = await _dio.get(
      '/api/listener/gifts/recent',
      options: authOptions(accessToken),
    );
    final list = res.data as List<dynamic>;
    return list.map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final gift = row['gift'] as Map<String, dynamic>? ??
          row['gifts'] as Map<String, dynamic>?;
      final user = row['sender'] as Map<String, dynamic>? ??
          row['users'] as Map<String, dynamic>?;
      final name = gift?['name'] as String? ?? 'Gift';
      final senderName = user?['full_name'] as String? ??
          user?['name'] as String? ??
          'Someone';
      final coins = (row['coins_spent'] as num?)?.toInt() ??
          (row['coinCost'] as num?)?.toInt() ??
          0;
      return CreatorRecentGift(
        giftName: name,
        giftEmoji: GiftItem(name: name, id: '', coinCost: coins).emoji,
        coins: coins,
        senderFirstName: firstNameOnly(senderName),
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      );
    }).toList();
  }

  CreatorGiftInsights aggregateToday(List<CreatorRecentGift> recent) {
    final now = DateTime.now();
    final today = recent.where((g) {
      if (g.createdAt == null) return true;
      return g.createdAt!.year == now.year &&
          g.createdAt!.month == now.month &&
          g.createdAt!.day == now.day;
    }).toList();

    final counts = <String, int>{};
    final senders = <String, int>{};
    var coins = 0;
    for (final g in today) {
      coins += g.coins;
      counts[g.giftName] = (counts[g.giftName] ?? 0) + 1;
      senders[g.senderFirstName] = (senders[g.senderFirstName] ?? 0) + 1;
    }

    String? topGift;
    var topCount = 0;
    counts.forEach((name, c) {
      if (c > topCount) {
        topCount = c;
        topGift = name;
      }
    });

    String? topSender;
    var senderCount = 0;
    senders.forEach((name, c) {
      if (c > senderCount) {
        senderCount = c;
        topSender = name;
      }
    });

    return CreatorGiftInsights(
      giftsReceived: today.length,
      giftCoins: coins,
      topGiftName: topGift,
      mostActiveSender: topSender,
    );
  }
}

class CreatorGiftInsights {
  final int giftsReceived;
  final int giftCoins;
  final String? topGiftName;
  final String? mostActiveSender;

  const CreatorGiftInsights({
    required this.giftsReceived,
    required this.giftCoins,
    this.topGiftName,
    this.mostActiveSender,
  });
}
