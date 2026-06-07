import 'dart:math';

import '../config/gift_engagement_config.dart';

class GiftRechargeMessaging {
  GiftRechargeMessaging._();

  static final _random = Random();

  /// Emotional recharge copy — rotates randomly via [messageIndex].
  static String emotionalBannerMessage({
    required String peerName,
    required int remainingMinutes,
    int messageIndex = 0,
    LowBalanceTone tone = LowBalanceTone.warning,
  }) {
    if (!GiftEngagementConfig.enableEmotionalRecharge) {
      return 'Only $remainingMinutes min${remainingMinutes == 1 ? '' : 's'} remaining';
    }

    final firstName = peerName.split(' ').first;
    final mins = remainingMinutes.toString();

    final warningPool = [
      '❤️ Continue talking with $firstName\nOnly $mins minutes remaining',
      '💬 Enjoying your conversation?\nTop up and stay connected.',
      '❤️ Don\'t let the conversation end.\nRecharge and continue.',
    ];

    final criticalPool = [
      '❤️ Continue talking with $firstName\nOnly $mins minutes remaining',
      '💬 Enjoying your conversation?\nTop up and stay connected.',
      '❤️ Don\'t let the conversation end.\nRecharge and continue.',
    ];

    final pool = tone == LowBalanceTone.critical ? criticalPool : warningPool;
    final index = messageIndex.abs() % pool.length;
    return pool[index];
  }

  /// Suggested coin package for contextual highlight.
  static int suggestPackageCoins({
    required int walletBalance,
    required int coinsPerMinute,
    required int callDurationSeconds,
  }) {
    if (coinsPerMinute <= 0) return 500;

    final minsRemaining = walletBalance / coinsPerMinute;
    final callMins = callDurationSeconds / 60;
    // Buffer: at least 30 extra minutes or double remaining — whichever is larger.
    final targetMins = (minsRemaining + max(30.0, minsRemaining * 0.5 + callMins * 0.2))
        .ceil();
    final rawCoins = targetMins * coinsPerMinute;

    const tiers = [500, 1000, 2000, 5000];
    for (final tier in tiers) {
      if (tier >= rawCoins) return tier;
    }
    return tiers.last;
  }

  static int pickMessageIndex(String sessionSeed, int poolLength) {
    if (poolLength <= 1) return 0;
    return _random.nextInt(poolLength);
  }
}

enum LowBalanceTone {
  warning,
  critical,
}
