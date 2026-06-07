import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/models/gift_item.dart';
import 'package:flutter_voice_calling_app_2026/providers/gift_overlay_provider.dart';

void main() {
  group('GiftOverlayProvider', () {
    test('queues overlays sequentially', () async {
      final provider = GiftOverlayProvider();

      provider.enqueueLocal(GiftOverlayEvent(
        giftTransactionId: 'tx-1',
        senderId: 'u1',
        senderName: 'Goutham',
        giftName: 'Princess Crown',
        giftCoins: 500,
        creatorCoins: 300,
        receivedAt: DateTime.now(),
      ));

      expect(provider.current?.senderName, 'Goutham');
      expect(provider.queueLength, 0);

      provider.enqueueLocal(GiftOverlayEvent(
        giftTransactionId: 'tx-2',
        senderId: 'u2',
        senderName: 'Alex',
        giftName: 'Rose',
        giftCoins: 10,
        creatorCoins: 6,
        receivedAt: DateTime.now(),
      ));

      expect(provider.queueLength, 1);

      provider.dismissCurrent();
      expect(provider.current?.senderName, 'Alex');

      provider.dispose();
    });

    test('tracks session gift earnings', () {
      final provider = GiftOverlayProvider();

      provider.enqueueLocal(GiftOverlayEvent(
        giftTransactionId: 'tx-1',
        senderId: 'u1',
        senderName: 'Goutham',
        giftName: 'Princess Crown',
        giftCoins: 500,
        creatorCoins: 300,
        receivedAt: DateTime.now(),
      ));

      expect(provider.sessionGiftEarnings, 300);
      expect(provider.sessionReceived.length, 1);
      provider.dispose();
    });
  });
}
