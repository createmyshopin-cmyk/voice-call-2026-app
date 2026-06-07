import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/services/balance_prediction_service.dart';

void main() {
  group('BalancePredictionService', () {
    test('remainingMinutes divides balance by rate', () {
      expect(
        BalancePredictionService.remainingMinutes(
          walletBalance: 50,
          coinsPerMinute: 10,
        ),
        5.0,
      );
    });

    test('low balance warning at 5 minutes', () {
      expect(
        LowBalanceLevelResolver.resolve(
          walletBalance: 50,
          coinsPerMinute: 10,
        ),
        LowBalanceLevel.warning,
      );
    });

    test('critical at 2 minutes or less', () {
      expect(
        LowBalanceLevelResolver.resolve(
          walletBalance: 20,
          coinsPerMinute: 10,
        ),
        LowBalanceLevel.critical,
      );
    });

    test('formatTalkTime for recharge packages', () {
      expect(
        BalancePredictionService.formatTalkTime(330, 10),
        '≈ 33 mins',
      );
    });
  });
}
