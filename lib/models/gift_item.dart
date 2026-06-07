class GiftItem {
  final String id;
  final String name;
  final int coinCost;
  final String? iconUrl;
  final double creatorSharePercent;
  final double platformSharePercent;

  const GiftItem({
    required this.id,
    required this.name,
    required this.coinCost,
    this.iconUrl,
    this.creatorSharePercent = 60,
    this.platformSharePercent = 40,
  });

  factory GiftItem.fromJson(Map<String, dynamic> json) {
    return GiftItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Gift',
      coinCost: (json['coinCost'] as num?)?.toInt() ??
          (json['coin_cost'] as num?)?.toInt() ??
          0,
      iconUrl: json['iconUrl'] as String? ?? json['icon_url'] as String?,
      creatorSharePercent:
          (json['creatorSharePercent'] as num?)?.toDouble() ??
              (json['creator_share_percent'] as num?)?.toDouble() ??
              60,
      platformSharePercent:
          (json['platformSharePercent'] as num?)?.toDouble() ??
              (json['platform_share_percent'] as num?)?.toDouble() ??
              40,
    );
  }

  /// Visual emoji fallback when no icon URL (matches backend catalog).
  String get emoji {
    switch (name.toLowerCase()) {
      case 'rose':
        return '🌹';
      case 'heart':
        return '❤️';
      case 'cute cat':
        return '🐱';
      case 'puppy':
        return '🐶';
      case 'gift box':
        return '🎁';
      case 'princess crown':
        return '👑';
      case 'diamond':
        return '💎';
      case 'diamond ring':
        return '💍';
      default:
        return '🎁';
    }
  }

  bool get isPremiumGift {
    if (coinCost >= 500) return true;
    final n = name.toLowerCase();
    return n == 'princess crown' ||
        n == 'diamond' ||
        n == 'diamond ring' ||
        n == 'fantasy castle';
  }

  /// Animation style key for sender overlay.
  String get animationKey {
    switch (name.toLowerCase()) {
      case 'rose':
        return 'rose';
      case 'heart':
        return 'heart';
      case 'cute cat':
        return 'cat';
      case 'puppy':
        return 'puppy';
      case 'gift box':
        return 'box';
      case 'princess crown':
        return 'crown';
      case 'diamond':
        return 'diamond';
      case 'diamond ring':
        return 'ring';
      default:
        return 'default';
    }
  }
}

class SendGiftResult {
  final bool success;
  final int remainingBalance;
  final int coinsSpent;
  final int creatorCoins;
  final int platformCoins;
  final String giftName;
  final String giftTransactionId;
  final bool duplicate;

  const SendGiftResult({
    required this.success,
    required this.remainingBalance,
    required this.coinsSpent,
    required this.creatorCoins,
    required this.platformCoins,
    required this.giftName,
    required this.giftTransactionId,
    this.duplicate = false,
  });

  factory SendGiftResult.fromJson(Map<String, dynamic> json) {
    return SendGiftResult(
      success: json['success'] as bool? ?? true,
      remainingBalance: (json['remainingBalance'] as num?)?.toInt() ?? 0,
      coinsSpent: (json['coinsSpent'] as num?)?.toInt() ?? 0,
      creatorCoins: (json['creatorCoins'] as num?)?.toInt() ?? 0,
      platformCoins: (json['platformCoins'] as num?)?.toInt() ?? 0,
      giftName: json['giftName'] as String? ?? '',
      giftTransactionId: json['giftTransactionId'] as String? ?? '',
      duplicate: json['duplicate'] as bool? ?? false,
    );
  }
}

class SessionGiftRecord {
  final String giftName;
  final String giftEmoji;
  final int coinsSpent;
  final String? giftTransactionId;
  final DateTime sentAt;

  const SessionGiftRecord({
    required this.giftName,
    required this.giftEmoji,
    required this.coinsSpent,
    this.giftTransactionId,
    required this.sentAt,
  });
}

/// Creator overlay queue item (FCM or local).
class GiftOverlayEvent {
  final String giftTransactionId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String giftName;
  final int giftCoins;
  final int creatorCoins;
  final DateTime receivedAt;

  const GiftOverlayEvent({
    required this.giftTransactionId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.giftName,
    required this.giftCoins,
    required this.creatorCoins,
    required this.receivedAt,
  });

  factory GiftOverlayEvent.fromFcm(Map<String, dynamic> data) {
    return GiftOverlayEvent(
      giftTransactionId: data['giftTransactionId']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'User',
      senderAvatar: data['senderAvatar']?.toString(),
      giftName: data['giftName']?.toString() ?? 'Gift',
      giftCoins: int.tryParse(data['giftCoins']?.toString() ?? '') ?? 0,
      creatorCoins: int.tryParse(data['creatorCoins']?.toString() ?? '') ?? 0,
      receivedAt: DateTime.now(),
    );
  }

  String get giftEmoji {
    return GiftItem(name: giftName, id: '', coinCost: giftCoins).emoji;
  }

  bool get isPremiumGift =>
      giftCoins >= 500 ||
      GiftItem(name: giftName, id: '', coinCost: giftCoins).isPremiumGift;

  String get animationKey =>
      GiftItem(name: giftName, id: '', coinCost: giftCoins).animationKey;
}

class GiftSummaryEntry {
  final String senderName;
  final String giftName;
  final String giftEmoji;
  final int coins;

  const GiftSummaryEntry({
    required this.senderName,
    required this.giftName,
    required this.giftEmoji,
    required this.coins,
  });
}

/// Backend-allowed reply strings (do not change without API update).
const kGiftReplyApiMessages = [
  '❤️ Thank You',
  '🙏 Appreciate It',
  '🔥 You\'re Amazing',
  '✨ Made My Day',
];

@Deprecated('Use kGiftReplyOptions')
const kGiftReplyMessages = kGiftReplyApiMessages;

class GiftReplyOption {
  final String label;
  final String apiMessage;

  const GiftReplyOption({
    required this.label,
    required this.apiMessage,
  });
}

List<GiftReplyOption> buildGiftReplyOptions(String senderFullName) {
  final first = senderFullName.trim().isEmpty
      ? 'Friend'
      : senderFullName.trim().split(RegExp(r'\s+')).first;

  return [
    const GiftReplyOption(label: '❤️ Thank You', apiMessage: '❤️ Thank You'),
    const GiftReplyOption(label: '🙏 Appreciate It', apiMessage: '🙏 Appreciate It'),
    const GiftReplyOption(
      label: '🔥 You\'re Amazing',
      apiMessage: '🔥 You\'re Amazing',
    ),
    const GiftReplyOption(label: '✨ Made My Day', apiMessage: '✨ Made My Day'),
    const GiftReplyOption(
      label: '🥰 That\'s So Sweet',
      apiMessage: '✨ Made My Day',
    ),
    GiftReplyOption(
      label: '💖 Thank You $first',
      apiMessage: '❤️ Thank You',
    ),
    const GiftReplyOption(
      label: '🌹 You Made Me Smile',
      apiMessage: '🙏 Appreciate It',
    ),
    const GiftReplyOption(
      label: '😊 You\'re Very Kind',
      apiMessage: '🙏 Appreciate It',
    ),
    const GiftReplyOption(
      label: '❤️ Sending Love Back',
      apiMessage: '❤️ Thank You',
    ),
  ];
}

String? milestoneMessageForCount(int count) {
  switch (count) {
    case 1:
      return '🎉 First Gift Sent';
    case 5:
      return '🌹 5 Gifts Sent';
    case 10:
      return '👑 10 Gifts Sent';
    case 25:
      return '💎 25 Gifts Sent';
    case 50:
      return '✨ 50 Gifts Sent';
    case 100:
      return '🔥 100 Gifts Sent';
    default:
      return null;
  }
}
