import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/config/gift_engagement_config.dart';
import 'package:flutter_voice_calling_app_2026/models/gift_item.dart';
import 'package:flutter_voice_calling_app_2026/providers/gift_provider.dart';
import 'package:flutter_voice_calling_app_2026/providers/wallet_provider.dart';
import 'package:flutter_voice_calling_app_2026/services/gift_service.dart';
import 'package:flutter_voice_calling_app_2026/utils/gift_grouping.dart';

class _SequentialGiftService extends GiftService {
  int callCount = 0;

  @override
  Future<SendGiftResult> sendGift({
    required String accessToken,
    required String giftId,
    required String creatorId,
    required String callId,
    required String idempotencyKey,
  }) async {
    callCount++;
    return SendGiftResult(
      success: true,
      remainingBalance: 100 - callCount * 10,
      giftName: 'Rose',
      coinsSpent: 10,
      creatorCoins: 6,
      platformCoins: 4,
      giftTransactionId: 'txn-$callCount',
    );
  }
}

GiftItem get _rose => const GiftItem(id: 'r1', name: 'Rose', coinCost: 10);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gift send integration', () {
    late GiftProvider provider;
    late WalletProvider wallet;
    late _SequentialGiftService service;

    setUp(() {
      service = _SequentialGiftService();
      provider = GiftProvider(giftService: service);
      wallet = WalletProvider()..updateAuth('u1', 'token', initialCoins: 200);
      GiftEngagementConfig.enableGiftCombo = true;
      GiftEngagementConfig.enableMilestones = true;
    });

    tearDown(() {
      provider.dispose();
    });

    Future<void> sendRose(String key) => provider.sendGift(
          accessToken: 'token',
          gift: _rose,
          creatorId: 'c1',
          callId: 'call1',
          idempotencyKey: key,
          wallet: wallet,
        );

    test('combo progresses on rapid same-gift sends', () async {
      await sendRose('key-1');
      await sendRose('key-2');
      await sendRose('key-3');

      expect(provider.sessionGiftCount, 3);
      expect(provider.activeComboBadge?.count, 3);
      expect(provider.animationQueue.active.length, lessThanOrEqualTo(5));
      final grouped = groupSessionGifts(provider.sessionGifts);
      expect(grouped.first.displayLabel, 'Rose x3');
    });

    test('milestone fires on first gift', () async {
      await sendRose('key-m1');
      expect(provider.milestoneToast, '🎉 First Gift Sent');
      expect(provider.sessionGiftCount, 1);
    });

    test('micro celebration token increments', () async {
      expect(provider.microCelebrationToken, 0);
      await sendRose('key-mc');
      expect(provider.microCelebrationToken, 1);
    });

    test('clearSession resets combo and queue', () async {
      await sendRose('key-a');
      await sendRose('key-b');
      provider.clearSession();
      expect(provider.sessionGiftCount, 0);
      expect(provider.activeComboBadge, isNull);
      expect(provider.animationQueue.active, isEmpty);
    });
  });
}
