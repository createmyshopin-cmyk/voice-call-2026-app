import 'dart:async' show Timer, unawaited;

import 'package:flutter/foundation.dart';

import '../config/gift_engagement_config.dart';
import '../core/network/api_exception.dart';
import '../models/gift_item.dart';
import '../services/gift_animation_queue.dart';
import '../services/gift_combo_tracker.dart';
import '../services/gift_micro_celebration.dart';
import '../services/gift_service.dart';
import 'wallet_provider.dart';

class GiftProvider with ChangeNotifier {
  GiftProvider({GiftService? giftService}) : _service = giftService ?? GiftService() {
    animationQueue.addListener(notifyListeners);
  }

  final GiftService _service;
  final GiftComboTracker _comboTracker = GiftComboTracker(
    windowSeconds: GiftEngagementConfig.comboWindowSeconds,
  );
  final GiftAnimationQueue animationQueue = GiftAnimationQueue();

  String? _sendingGiftId;
  String? _lastError;
  final List<SessionGiftRecord> _sessionGifts = [];
  int _sessionGiftCount = 0;
  String? _milestoneToast;
  Timer? _milestoneTimer;
  GiftComboState? _activeComboBadge;
  Timer? _comboBadgeTimer;
  int _microCelebrationToken = 0;

  String? get sendingGiftId => _sendingGiftId;
  String? get lastError => _lastError;
  String? get milestoneToast => _milestoneToast;
  GiftComboState? get activeComboBadge => _activeComboBadge;
  int get microCelebrationToken => _microCelebrationToken;
  int get sessionGiftCount => _sessionGiftCount;
  List<SessionGiftRecord> get sessionGifts => List.unmodifiable(_sessionGifts);
  int get sessionGiftCoins =>
      _sessionGifts.fold(0, (sum, g) => sum + g.coinsSpent);

  void clearSession() {
    _sessionGifts.clear();
    _sessionGiftCount = 0;
    _lastError = null;
    _sendingGiftId = null;
    _milestoneToast = null;
    _milestoneTimer?.cancel();
    _activeComboBadge = null;
    _comboBadgeTimer?.cancel();
    _microCelebrationToken = 0;
    _comboTracker.reset();
    animationQueue.clear();
    notifyListeners();
  }

  Future<SendGiftResult?> sendGift({
    required String accessToken,
    required GiftItem gift,
    required String creatorId,
    required String callId,
    required String idempotencyKey,
    required WalletProvider wallet,
  }) async {
    if (_sendingGiftId != null) return null;
    if (wallet.balance < gift.coinCost) {
      _lastError = 'Insufficient balance';
      notifyListeners();
      return null;
    }

    _sendingGiftId = gift.id;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _sendGiftWithIdempotentRetry(
        accessToken: accessToken,
        giftId: gift.id,
        creatorId: creatorId,
        callId: callId,
        idempotencyKey: idempotencyKey,
      );

      wallet.setBalanceFromServer(result.remainingBalance);

      if (!result.duplicate) {
        _sessionGifts.add(SessionGiftRecord(
          giftName: gift.name,
          giftEmoji: gift.emoji,
          coinsSpent: result.coinsSpent,
          giftTransactionId: result.giftTransactionId,
          sentAt: DateTime.now(),
        ));
        _sessionGiftCount++;
        _handlePostSendEffects(gift);
      }

      return result;
    } on ApiException catch (e) {
      _lastError = e.message;
      debugPrint('[GiftProvider] send failed: ${e.message}');
      return null;
    } catch (e) {
      _lastError = 'Could not send gift. Please try again.';
      debugPrint('[GiftProvider] send failed: $e');
      return null;
    } finally {
      _sendingGiftId = null;
      notifyListeners();
    }
  }

  /// Retries transient failures with the **same** [idempotencyKey] so a
  /// successful first attempt is never double-charged on network retry.
  Future<SendGiftResult> _sendGiftWithIdempotentRetry({
    required String accessToken,
    required String giftId,
    required String creatorId,
    required String callId,
    required String idempotencyKey,
    int maxAttempts = 3,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _service.sendGift(
          accessToken: accessToken,
          giftId: giftId,
          creatorId: creatorId,
          callId: callId,
          idempotencyKey: idempotencyKey,
        );
      } on ApiException catch (e) {
        lastError = e;
        final retryable = e.type == ApiExceptionType.timeout ||
            e.type == ApiExceptionType.noInternet ||
            e.type == ApiExceptionType.serverError;
        if (!retryable || attempt >= maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
      } catch (e) {
        lastError = e;
        if (attempt >= maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
      }
    }
    throw lastError ?? Exception('Gift send failed');
  }

  void _handlePostSendEffects(GiftItem gift) {
    unawaited(GiftMicroCelebration.onGiftSent());

    final isPremium = GiftEngagementConfig.enablePremiumAnimations &&
        gift.isPremiumGift;
    final combo = GiftEngagementConfig.enableGiftCombo
        ? _comboTracker.record(gift)
        : GiftComboState(
            giftId: gift.id,
            giftName: gift.name,
            giftEmoji: gift.emoji,
            animationKey: gift.animationKey,
            count: 1,
            isContinuation: false,
          );

    _microCelebrationToken++;

    if (GiftEngagementConfig.enableGiftCombo &&
        combo.isContinuation &&
        combo.count > 1) {
      _activeComboBadge = combo;
      _comboBadgeTimer?.cancel();
      _comboBadgeTimer = Timer(
        Duration(milliseconds: GiftEngagementConfig.comboAnimationMs),
        () {
          _activeComboBadge = null;
          notifyListeners();
        },
      );
      animationQueue.showOrUpdateCombo(
        giftId: gift.id,
        animationKey: gift.animationKey,
        emoji: gift.emoji,
        giftName: gift.name,
        comboCount: combo.count,
        isPremium: isPremium,
      );
    } else {
      animationQueue.enqueue(
        giftId: gift.id,
        animationKey: gift.animationKey,
        emoji: gift.emoji,
        giftName: gift.name,
        comboCount: 1,
        isPremium: isPremium,
      );
    }

    if (GiftEngagementConfig.enableMilestones) {
      final msg = milestoneMessageForCount(_sessionGiftCount);
      if (msg != null) {
        _milestoneToast = msg;
        _milestoneTimer?.cancel();
        _milestoneTimer = Timer(
          Duration(milliseconds: GiftEngagementConfig.milestoneCelebrationMs),
          () {
            _milestoneToast = null;
            notifyListeners();
          },
        );
      }
    }

    notifyListeners();
  }

  Future<bool> replyToGift({
    required String accessToken,
    required String giftTransactionId,
    required String message,
  }) async {
    if (!kGiftReplyApiMessages.contains(message)) {
      debugPrint('[GiftProvider] invalid reply message blocked: $message');
      return false;
    }
    try {
      await _service.replyToGift(
        accessToken: accessToken,
        giftTransactionId: giftTransactionId,
        message: message,
      );
      return true;
    } catch (e) {
      debugPrint('[GiftProvider] reply failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _milestoneTimer?.cancel();
    _comboBadgeTimer?.cancel();
    animationQueue.removeListener(notifyListeners);
    animationQueue.dispose();
    super.dispose();
  }
}
