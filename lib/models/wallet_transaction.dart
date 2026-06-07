import 'package:intl/intl.dart';

/// A wallet coin transaction fetched from GET /api/wallets/transactions.
class WalletTransaction {
  final String id;
  final String userId;
  final String userName;
  final String type; // 'call_deduction' | 'recharge' | 'admin_adjustment_add' | 'admin_adjustment_deduct' | 'refund'
  final int amount;
  final int balanceAfter;
  final String? referenceId;
  final String? description;
  final DateTime date;

  const WalletTransaction({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.referenceId,
    this.description,
    required this.date,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      userName: json['userName'] as String? ?? json['user_name'] as String? ?? '',
      type: json['type'] as String? ?? 'recharge',
      amount: (json['amount'] as num? ?? 0).toInt(),
      balanceAfter: (json['balanceAfter'] as num? ?? json['balance_after'] as num? ?? 0).toInt(),
      referenceId: json['referenceId'] as String? ?? json['reference_id'] as String?,
      description: json['description'] as String? ?? json['description'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Check if the transaction represents added coins (recharge, admin bonus, etc.)
  bool get isCredit => amount > 0;

  /// Display title for the transaction list row
  String get displayTitle {
    switch (type) {
      case 'recharge':
        return 'Coins Added';
      case 'call_deduction':
        return description?.toLowerCase().contains('video') == true ? 'Video Call' : 'Voice Call';
      case 'refund':
        return 'Coins Refunded';
      case 'admin_adjustment_add':
      case 'admin_adjustment_deduct':
        return 'Wallet Adjustment';
      default:
        return 'Wallet Transaction';
    }
  }

  /// Display date string formatted to match: "Today, 09:32 PM" or "Yesterday, 10:22 PM"
  String formattedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final localDate = date.toLocal();
    final checkDate = DateTime(localDate.year, localDate.month, localDate.day);

    final timeStr = DateFormat('hh:mm a').format(localDate);

    if (checkDate == today) {
      return 'Today, $timeStr';
    } else if (checkDate == yesterday) {
      return 'Yesterday, $timeStr';
    } else {
      return '${DateFormat('dd MMM yyyy').format(localDate)}, $timeStr';
    }
  }
}
