import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/services/gift_fcm_dispatcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GiftFcmDispatcher', () {
    tearDown(() => GiftFcmDispatcher.clearSession());

    test('deduplicates gift_received by transaction id', () {
      var count = 0;
      GiftFcmDispatcher.onGiftReceived = (_) => count++;

      const data = {
        'type': 'gift_received',
        'giftTransactionId': 'txn-abc',
        'senderName': 'Arjun',
        'giftName': 'Rose',
      };

      expect(GiftFcmDispatcher.dispatch(data), isTrue);
      expect(GiftFcmDispatcher.dispatch(data), isTrue);
      expect(count, 1);
    });

    test('deduplicates gift_reply', () {
      var count = 0;
      GiftFcmDispatcher.onGiftReply = (_) => count++;

      const data = {
        'type': 'gift_reply',
        'giftTransactionId': 'txn-reply',
        'creatorName': 'Priya',
        'message': 'Thank you',
      };

      GiftFcmDispatcher.dispatch(data);
      GiftFcmDispatcher.dispatch(data);
      expect(count, 1);
    });
  });
}
