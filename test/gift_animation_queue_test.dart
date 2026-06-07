import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/services/gift_animation_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GiftAnimationQueue', () {
    test('caps active animations at five', () {
      final queue = GiftAnimationQueue();
      for (var i = 0; i < 7; i++) {
        queue.enqueue(
          giftId: 'g$i',
          animationKey: 'rose',
          emoji: '🌹',
          giftName: 'Rose',
        );
      }
      expect(queue.active.length, lessThanOrEqualTo(5));
      queue.dispose();
    });

    test('updates combo on same gift', () {
      final queue = GiftAnimationQueue();
      queue.showOrUpdateCombo(
        giftId: 'rose',
        animationKey: 'rose',
        emoji: '🌹',
        giftName: 'Rose',
        comboCount: 2,
        isPremium: false,
      );
      queue.showOrUpdateCombo(
        giftId: 'rose',
        animationKey: 'rose',
        emoji: '🌹',
        giftName: 'Rose',
        comboCount: 3,
        isPremium: false,
      );
      expect(queue.active.length, 1);
      expect(queue.active.first.comboCount, 3);
      queue.dispose();
    });
  });
}
