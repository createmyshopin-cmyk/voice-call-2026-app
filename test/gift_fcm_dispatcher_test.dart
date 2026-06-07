import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/services/gift_fcm_dispatcher.dart';

void main() {
  group('GiftFcmDispatcher', () {
    tearDown(() {
      GiftFcmDispatcher.onGiftReceived = null;
      GiftFcmDispatcher.onGiftReply = null;
      GiftFcmDispatcher.clearSession();
    });

    test('dispatches gift_received once per transaction', () {
      var count = 0;
      GiftFcmDispatcher.onGiftReceived = (_) => count++;

      final data = {
        'type': 'gift_received',
        'giftTransactionId': 'tx-abc',
        'senderName': 'Goutham',
        'giftName': 'Princess Crown',
        'giftCoins': '500',
      };

      expect(GiftFcmDispatcher.dispatch(data), isTrue);
      expect(GiftFcmDispatcher.dispatch(data), isTrue);
      expect(count, 1);
    });

    test('dispatches gift_reply', () {
      String? creatorName;
      GiftFcmDispatcher.onGiftReply = (data) {
        creatorName = data['creatorName']?.toString();
      };

      GiftFcmDispatcher.dispatch({
        'type': 'gift_reply',
        'giftTransactionId': 'tx-reply-1',
        'creatorName': 'Amrutha',
        'message': '❤️ Thank You',
      });

      expect(creatorName, 'Amrutha');
    });

    test('ignores duplicate gift_reply', () {
      var count = 0;
      GiftFcmDispatcher.onGiftReply = (_) => count++;

      final data = {
        'type': 'gift_reply',
        'giftTransactionId': 'tx-reply-dup',
        'creatorName': 'Amrutha',
        'message': '❤️ Thank You',
      };

      GiftFcmDispatcher.dispatch(data);
      GiftFcmDispatcher.dispatch(data);
      expect(count, 1);
    });
  });
}
