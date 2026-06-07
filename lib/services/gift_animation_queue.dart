import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/gift_engagement_config.dart';

class GiftAnimationItem {
  final String id;
  final String giftId;
  final String animationKey;
  final String emoji;
  final String giftName;
  final int comboCount;
  final bool isPremium;

  const GiftAnimationItem({
    required this.id,
    required this.giftId,
    required this.animationKey,
    required this.emoji,
    required this.giftName,
    this.comboCount = 1,
    this.isPremium = false,
  });

  String get label => comboCount > 1
      ? '$emoji $giftName x$comboCount Combo'
      : giftName;
}

/// Queues sender-side animations; max [GiftEngagementConfig.maxSimultaneousEffects].
class GiftAnimationQueue extends ChangeNotifier {
  final List<GiftAnimationItem> _active = [];
  final Map<String, Timer> _timers = {};
  int _idCounter = 0;

  List<GiftAnimationItem> get active => List.unmodifiable(_active);

  void showOrUpdateCombo({
    required String giftId,
    required String animationKey,
    required String emoji,
    required String giftName,
    required int comboCount,
    required bool isPremium,
  }) {
    final existingIdx =
        _active.indexWhere((e) => e.giftId == giftId && e.comboCount < comboCount);
    if (existingIdx >= 0) {
      final existing = _active[existingIdx];
      _timers[existing.id]?.cancel();
      _active[existingIdx] = GiftAnimationItem(
        id: existing.id,
        giftId: giftId,
        animationKey: animationKey,
        emoji: emoji,
        giftName: giftName,
        comboCount: comboCount,
        isPremium: isPremium,
      );
      _scheduleRemoval(existing.id, GiftEngagementConfig.comboAnimationMs);
      notifyListeners();
      return;
    }
    enqueue(
      giftId: giftId,
      animationKey: animationKey,
      emoji: emoji,
      giftName: giftName,
      comboCount: comboCount,
      isPremium: isPremium,
      durationMs: isPremium
          ? GiftEngagementConfig.premiumAnimationMs
          : GiftEngagementConfig.comboAnimationMs,
    );
  }

  void enqueue({
    required String giftId,
    required String animationKey,
    required String emoji,
    required String giftName,
    int comboCount = 1,
    bool isPremium = false,
    int? durationMs,
  }) {
    while (_active.length >= GiftEngagementConfig.maxSimultaneousEffects) {
      final removed = _active.removeAt(0);
      _timers.remove(removed.id)?.cancel();
    }

    final id = 'anim_${++_idCounter}';
    _active.add(GiftAnimationItem(
      id: id,
      giftId: giftId,
      animationKey: animationKey,
      emoji: emoji,
      giftName: giftName,
      comboCount: comboCount,
      isPremium: isPremium,
    ));
    _scheduleRemoval(
      id,
      durationMs ??
          (isPremium
              ? GiftEngagementConfig.premiumAnimationMs
              : GiftEngagementConfig.comboAnimationMs),
    );
    notifyListeners();
  }

  void _scheduleRemoval(String id, int ms) {
    _timers[id]?.cancel();
    _timers[id] = Timer(Duration(milliseconds: ms), () {
      _active.removeWhere((e) => e.id == id);
      _timers.remove(id);
      notifyListeners();
    });
  }

  void clear() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _active.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
