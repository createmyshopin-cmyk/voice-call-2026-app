import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/core/network/api_exception.dart';
import 'package:flutter_voice_calling_app_2026/models/gift_item.dart';
import 'package:flutter_voice_calling_app_2026/providers/gift_provider.dart';
import 'package:flutter_voice_calling_app_2026/providers/wallet_provider.dart';
import 'package:flutter_voice_calling_app_2026/services/gift_service.dart';

class _FakeGiftService extends GiftService {
  _FakeGiftService(this.responses);

  final List<Object> responses;
  int callCount = 0;
  final List<String> keysUsed = [];

  @override
  Future<SendGiftResult> sendGift({
    required String accessToken,
    required String giftId,
    required String creatorId,
    required String callId,
    required String idempotencyKey,
  }) async {
    callCount++;
    keysUsed.add(idempotencyKey);
    final next = responses[callCount - 1];
    if (next is ApiException) throw next;
    if (next is Exception) throw next;
    return next as SendGiftResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retries transient errors with same idempotency key', () async {
    const key = '550e8400-e29b-41d4-a716-446655440000';
    final fake = _FakeGiftService([
      const ApiException(message: 'timeout', type: ApiExceptionType.timeout),
      const SendGiftResult(
        success: true,
        remainingBalance: 90,
        giftName: 'Rose',
        coinsSpent: 10,
        creatorCoins: 6,
        platformCoins: 4,
        giftTransactionId: 'txn-1',
        duplicate: true,
      ),
    ]);

    final provider = GiftProvider(giftService: fake);
    final wallet = WalletProvider()..updateAuth('u1', 'token', initialCoins: 100);
    const gift = GiftItem(id: 'g1', name: 'Rose', coinCost: 10);

    final result = await provider.sendGift(
      accessToken: 'token',
      gift: gift,
      creatorId: 'c1',
      callId: 'call1',
      idempotencyKey: key,
      wallet: wallet,
    );

    expect(result, isNotNull);
    expect(fake.callCount, 2);
    expect(fake.keysUsed, everyElement(key));
    expect(fake.keysUsed.length, 2);
  });
}
