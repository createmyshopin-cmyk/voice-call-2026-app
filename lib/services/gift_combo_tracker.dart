import '../models/gift_item.dart';

class GiftComboState {
  final String giftId;
  final String giftName;
  final String giftEmoji;
  final String animationKey;
  final int count;
  final bool isContinuation;

  const GiftComboState({
    required this.giftId,
    required this.giftName,
    required this.giftEmoji,
    required this.animationKey,
    required this.count,
    required this.isContinuation,
  });

  String get displayLabel =>
      count > 1 ? '$giftEmoji $giftName x$count Combo' : '$giftEmoji $giftName';
}

/// Client-side combo tracking — same gift within [windowSeconds].
class GiftComboTracker {
  GiftComboTracker({this.windowSeconds = 10});

  final int windowSeconds;
  String? _lastGiftId;
  DateTime? _lastSentAt;
  int _comboCount = 0;

  GiftComboState record(GiftItem gift) {
    final now = DateTime.now();
    final isContinuation = _lastGiftId == gift.id &&
        _lastSentAt != null &&
        now.difference(_lastSentAt!).inSeconds <= windowSeconds;

    if (isContinuation) {
      _comboCount++;
    } else {
      _comboCount = 1;
    }

    _lastGiftId = gift.id;
    _lastSentAt = now;

    return GiftComboState(
      giftId: gift.id,
      giftName: gift.name,
      giftEmoji: gift.emoji,
      animationKey: gift.animationKey,
      count: _comboCount,
      isContinuation: isContinuation && _comboCount > 1,
    );
  }

  void reset() {
    _lastGiftId = null;
    _lastSentAt = null;
    _comboCount = 0;
  }
}
