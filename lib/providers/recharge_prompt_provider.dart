import 'package:flutter/foundation.dart';

import '../services/balance_prediction_service.dart';
import '../services/gift_recharge_messaging.dart';

class RechargePromptProvider with ChangeNotifier {
  int _coinsPerMinute = 10;
  int _callDurationSeconds = 0;
  String _peerName = 'them';
  String _sessionSeed = 'default';
  LowBalanceLevel _level = LowBalanceLevel.none;
  int _lastBalance = -1;
  int _messageIndex = 0;

  int get coinsPerMinute => _coinsPerMinute;
  int get callDurationSeconds => _callDurationSeconds;
  String get peerName => _peerName;
  LowBalanceLevel get level => _level;

  int get remainingMinutes => BalancePredictionService.remainingWholeMinutes(
        walletBalance: _lastBalance,
        coinsPerMinute: _coinsPerMinute,
      );

  int get suggestedPackageCoins => GiftRechargeMessaging.suggestPackageCoins(
        walletBalance: _lastBalance < 0 ? 0 : _lastBalance,
        coinsPerMinute: _coinsPerMinute,
        callDurationSeconds: _callDurationSeconds,
      );

  String get bannerMessage => GiftRechargeMessaging.emotionalBannerMessage(
        peerName: _peerName,
        remainingMinutes: remainingMinutes,
        messageIndex: _messageIndex,
        tone: LowBalanceTone.warning,
      );

  String get stickyMessage => GiftRechargeMessaging.emotionalBannerMessage(
        peerName: _peerName,
        remainingMinutes: remainingMinutes,
        messageIndex: _messageIndex + 1,
        tone: LowBalanceTone.critical,
      );

  void setCallContext({
    required int coinsPerMinute,
    String? peerName,
    String? sessionSeed,
  }) {
    var changed = false;
    if (_coinsPerMinute != coinsPerMinute) {
      _coinsPerMinute = coinsPerMinute;
      changed = true;
    }
    if (peerName != null && _peerName != peerName) {
      _peerName = peerName;
      changed = true;
    }
    if (sessionSeed != null && _sessionSeed != sessionSeed) {
      _sessionSeed = sessionSeed;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void updateCallDuration(int seconds) {
    if (_callDurationSeconds == seconds) return;
    _callDurationSeconds = seconds;
    notifyListeners();
  }

  void updateBalance(int balance) {
    final newLevel = LowBalanceLevelResolver.resolve(
      walletBalance: balance,
      coinsPerMinute: _coinsPerMinute,
    );
    if (_lastBalance == balance && _level == newLevel) return;

    if (newLevel != _level && newLevel != LowBalanceLevel.none) {
      _messageIndex = GiftRechargeMessaging.pickMessageIndex(
        '$_sessionSeed-${DateTime.now().millisecondsSinceEpoch}',
        3,
      );
    }

    _lastBalance = balance;
    _level = newLevel;
    notifyListeners();
  }

  void reset() {
    _level = LowBalanceLevel.none;
    _lastBalance = -1;
    _callDurationSeconds = 0;
    notifyListeners();
  }
}
