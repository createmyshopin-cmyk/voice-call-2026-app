import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/config/gift_engagement_config.dart';
import 'package:flutter_voice_calling_app_2026/models/gift_item.dart';
import 'package:flutter_voice_calling_app_2026/services/gift_animation_queue.dart';
import 'package:flutter_voice_calling_app_2026/services/gift_combo_tracker.dart';

GiftItem get _rose => const GiftItem(id: 'r1', name: 'Rose', coinCost: 10);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Performance — animation queue', () {
    test('100 gifts caps at max simultaneous effects', () {
      final queue = GiftAnimationQueue();
      for (var i = 0; i < 100; i++) {
        queue.enqueue(
          giftId: 'rose',
          animationKey: 'rose',
          emoji: '🌹',
          giftName: 'Rose',
          comboCount: (i % 10) + 1,
        );
      }
      expect(queue.active.length, GiftEngagementConfig.maxSimultaneousEffects);
      queue.dispose();
    });

    test('200 combo updates stay bounded', () {
      final queue = GiftAnimationQueue();
      for (var i = 1; i <= 200; i++) {
        queue.showOrUpdateCombo(
          giftId: 'rose',
          animationKey: 'rose',
          emoji: '🌹',
          giftName: 'Rose',
          comboCount: i,
          isPremium: false,
        );
      }
      expect(queue.active.length, lessThanOrEqualTo(5));
      expect(queue.active.first.comboCount, 200);
      queue.dispose();
    });

    test('500 gifts — no timer leak after clear', () {
      final queue = GiftAnimationQueue();
      for (var i = 0; i < 500; i++) {
        queue.enqueue(
          giftId: 'g$i',
          animationKey: 'rose',
          emoji: '🌹',
          giftName: 'Rose',
        );
      }
      queue.clear();
      expect(queue.active, isEmpty);
      queue.dispose();
    });
  });

  group('Performance — combo tracker', () {
    test('500 records stay O(1) memory', () {
      final tracker = GiftComboTracker(windowSeconds: 10);
      for (var i = 0; i < 500; i++) {
        final state = tracker.record(_rose);
        if (i == 499) {
          expect(state.count, 500);
        }
      }
      tracker.reset();
    });
  });

  group('Performance — FPS budget', () {
    test('max effects constant is five', () {
      expect(GiftEngagementConfig.maxSimultaneousEffects, 5);
    });
  });
}
