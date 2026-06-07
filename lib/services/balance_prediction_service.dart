/// Predicts remaining call time from wallet balance and per-minute rate.
class BalancePredictionService {
  /// Returns fractional minutes remaining (e.g. 5.0 = five minutes).
  static double remainingMinutes({
    required int walletBalance,
    required int coinsPerMinute,
  }) {
    if (coinsPerMinute <= 0) return double.infinity;
    return walletBalance / coinsPerMinute;
  }

  static int remainingWholeMinutes({
    required int walletBalance,
    required int coinsPerMinute,
  }) {
    final mins = remainingMinutes(
      walletBalance: walletBalance,
      coinsPerMinute: coinsPerMinute,
    );
    if (mins.isInfinite) return 999;
    return mins.floor();
  }

  /// Approximate talk time label for recharge packages.
  static String formatTalkTime(int coins, int coinsPerMinute) {
    if (coinsPerMinute <= 0) return '';
    final mins = (coins / coinsPerMinute).floor();
    if (mins < 60) return '≈ $mins mins';
    final hours = (mins / 60).floor();
    final rem = mins % 60;
    if (rem == 0) return '≈ ${hours}h';
    return '≈ ${hours}h ${rem}m';
  }
}

enum LowBalanceLevel {
  none,
  warning, // <= 5 min
  critical, // <= 2 min
}

class LowBalanceLevelResolver {
  static LowBalanceLevel resolve({
    required int walletBalance,
    required int coinsPerMinute,
  }) {
    final mins = BalancePredictionService.remainingWholeMinutes(
      walletBalance: walletBalance,
      coinsPerMinute: coinsPerMinute,
    );
    if (mins <= 2) return LowBalanceLevel.critical;
    if (mins <= 5) return LowBalanceLevel.warning;
    return LowBalanceLevel.none;
  }
}
