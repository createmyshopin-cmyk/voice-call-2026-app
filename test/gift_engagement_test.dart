import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/models/gift_item.dart';
import 'package:flutter_voice_calling_app_2026/services/gift_recharge_messaging.dart';
import 'package:flutter_voice_calling_app_2026/utils/gift_grouping.dart';
import 'package:flutter_voice_calling_app_2026/models/gift_item.dart' show SessionGiftRecord;

void main() {
  group('Gift milestones', () {
    test('milestone messages at key counts', () {
      expect(milestoneMessageForCount(1), '🎉 First Gift Sent');
      expect(milestoneMessageForCount(5), '🌹 5 Gifts Sent');
      expect(milestoneMessageForCount(10), '👑 10 Gifts Sent');
      expect(milestoneMessageForCount(3), isNull);
    });
  });

  group('Recharge suggestions', () {
    test('suggests 500 coins for 50 balance at 10/min', () {
      final coins = GiftRechargeMessaging.suggestPackageCoins(
        walletBalance: 50,
        coinsPerMinute: 10,
        callDurationSeconds: 120,
      );
      expect(coins, 500);
    });

    test('emotional banner avoids low balance wording', () {
      final msg = GiftRechargeMessaging.emotionalBannerMessage(
        peerName: 'Amrutha Sharma',
        remainingMinutes: 5,
        messageIndex: 0,
      );
      expect(msg.toLowerCase(), isNot(contains('low balance')));
      expect(msg, contains('Amrutha'));
      expect(msg, contains('5 minutes remaining'));
    });

    test('rotates messages by index', () {
      final a = GiftRechargeMessaging.emotionalBannerMessage(
        peerName: 'Priya',
        remainingMinutes: 3,
        messageIndex: 0,
      );
      final b = GiftRechargeMessaging.emotionalBannerMessage(
        peerName: 'Priya',
        remainingMinutes: 3,
        messageIndex: 1,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('Gift grouping', () {
    test('groups duplicate roses', () {
      final grouped = groupSessionGifts([
        SessionGiftRecord(
          giftName: 'Rose',
          giftEmoji: '🌹',
          coinsSpent: 10,
          sentAt: DateTime.now(),
        ),
        SessionGiftRecord(
          giftName: 'Rose',
          giftEmoji: '🌹',
          coinsSpent: 10,
          sentAt: DateTime.now(),
        ),
        SessionGiftRecord(
          giftName: 'Princess Crown',
          giftEmoji: '👑',
          coinsSpent: 500,
          sentAt: DateTime.now(),
        ),
      ]);

      expect(grouped.length, 2);
      expect(grouped.first.displayLabel, 'Rose x2');
    });
  });

  group('Quick replies', () {
    test('personalized label maps to allowed API message', () {
      final options = buildGiftReplyOptions('Goutham Kumar');
      final named = options.firstWhere((o) => o.label.contains('Goutham'));
      expect(named.apiMessage, '❤️ Thank You');
    });
  });
}
