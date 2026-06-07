import '../models/gift_item.dart';

class GroupedGiftLine {
  final String giftName;
  final String giftEmoji;
  final int count;
  final int totalCoins;

  const GroupedGiftLine({
    required this.giftName,
    required this.giftEmoji,
    required this.count,
    required this.totalCoins,
  });

  String get displayLabel =>
      count > 1 ? '$giftName x$count' : giftName;
}

List<GroupedGiftLine> groupSessionGifts(List<SessionGiftRecord> gifts) {
  final order = <String>[];
  final counts = <String, int>{};
  final coins = <String, int>{};
  final emojis = <String, String>{};

  for (final g in gifts) {
    final key = g.giftName;
    if (!counts.containsKey(key)) {
      order.add(key);
      emojis[key] = g.giftEmoji;
    }
    counts[key] = (counts[key] ?? 0) + 1;
    coins[key] = (coins[key] ?? 0) + g.coinsSpent;
  }

  return order
      .map(
        (name) => GroupedGiftLine(
          giftName: name,
          giftEmoji: emojis[name] ?? '🎁',
          count: counts[name] ?? 1,
          totalCoins: coins[name] ?? 0,
        ),
      )
      .toList();
}

List<GroupedGiftLine> groupReceivedGifts(List<GiftSummaryEntry> gifts) {
  final order = <String>[];
  final counts = <String, int>{};
  final coins = <String, int>{};
  final emojis = <String, String>{};

  for (final g in gifts) {
    final key = g.giftName;
    if (!counts.containsKey(key)) {
      order.add(key);
      emojis[key] = g.giftEmoji;
    }
    counts[key] = (counts[key] ?? 0) + 1;
    coins[key] = (coins[key] ?? 0) + g.coins;
  }

  return order
      .map(
        (name) => GroupedGiftLine(
          giftName: name,
          giftEmoji: emojis[name] ?? '🎁',
          count: counts[name] ?? 1,
          totalCoins: coins[name] ?? 0,
        ),
      )
      .toList();
}

GroupedGiftLine? topGiftByCount(List<GroupedGiftLine> grouped) {
  if (grouped.isEmpty) return null;
  return grouped.reduce((a, b) => a.count >= b.count ? a : b);
}

String firstNameOnly(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return 'Friend';
  return trimmed.split(RegExp(r'\s+')).first;
}
