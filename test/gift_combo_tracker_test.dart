import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/models/gift_item.dart';
import 'package:flutter_voice_calling_app_2026/services/gift_combo_tracker.dart';

GiftItem _rose() => const GiftItem(id: 'r1', name: 'Rose', coinCost: 10);

void main() {
  group('GiftComboTracker', () {
    test('first send is not a combo continuation', () {
      final tracker = GiftComboTracker(windowSeconds: 10);
      final state = tracker.record(_rose());
      expect(state.count, 1);
      expect(state.isContinuation, isFalse);
    });

    test('same gift within window increments combo', () {
      final tracker = GiftComboTracker(windowSeconds: 10);
      tracker.record(_rose());
      final state = tracker.record(_rose());
      expect(state.count, 2);
      expect(state.isContinuation, isTrue);
      expect(state.displayLabel, contains('x2'));
    });

    test('third rose becomes x3 combo', () {
      final tracker = GiftComboTracker(windowSeconds: 10);
      tracker.record(_rose());
      tracker.record(_rose());
      final state = tracker.record(_rose());
      expect(state.count, 3);
      expect(state.displayLabel, '🌹 Rose x3 Combo');
    });
  });
}
