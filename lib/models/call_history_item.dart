import 'package:intl/intl.dart';

/// A completed or missed call session from GET /api/calls/history.
class CallHistoryItem {
  final String id;
  final String callerId;
  final String callerName;
  final String creatorId;
  final String creatorName;
  final String type;
  final String status;
  final int durationSeconds;
  final int coinsDeducted;
  final String? channelName;
  final DateTime startedAt;
  final DateTime? endedAt;

  const CallHistoryItem({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.creatorId,
    required this.creatorName,
    required this.type,
    required this.status,
    required this.durationSeconds,
    required this.coinsDeducted,
    this.channelName,
    required this.startedAt,
    this.endedAt,
  });

  factory CallHistoryItem.fromJson(Map<String, dynamic> json) {
    return CallHistoryItem(
      id: json['id'] as String? ?? '',
      callerId: json['callerId'] as String? ?? json['caller_id'] as String? ?? '',
      callerName: json['callerName'] as String? ?? json['caller_name'] as String? ?? '',
      creatorId: json['creatorId'] as String? ?? json['creator_id'] as String? ?? '',
      creatorName:
          json['creatorName'] as String? ?? json['creator_name'] as String? ?? '',
      type: json['type'] as String? ?? 'voice',
      status: json['status'] as String? ?? 'completed',
      durationSeconds: json['durationSeconds'] as int? ??
          json['duration_seconds'] as int? ??
          0,
      coinsDeducted: json['coinsDeducted'] as int? ??
          json['coinsSpent'] as int? ??
          json['coins_spent'] as int? ??
          json['coins_deducted'] as int? ??
          0,
      channelName: json['channelName'] as String? ?? json['channel_name'] as String?,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.now(),
      endedAt: DateTime.tryParse(json['endedAt'] as String? ?? '') ??
          DateTime.tryParse(json['ended_at'] as String? ?? ''),
    );
  }

  bool get isVideo => type == 'video';

  /// Name of the other party relative to [currentUserId].
  String otherPartyName(String currentUserId) {
    if (callerId == currentUserId) return creatorName;
    return callerName;
  }

  String otherPartyId(String currentUserId) {
    if (callerId == currentUserId) return creatorId;
    return callerId;
  }

  String formattedDuration() {
    if (durationSeconds <= 0) return '—';
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes == 0) return '${seconds}s';
    if (seconds == 0) return '$minutes min${minutes == 1 ? '' : 's'}';
    return '$minutes min ${seconds}s';
  }

  String relativeEndTime() {
    final ref = endedAt ?? startedAt;
    final diff = DateTime.now().difference(ref);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'Ended ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Ended ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Ended ${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(ref);
  }

  String formattedStartedAt() =>
      DateFormat('EEE, MMM d • h:mm a').format(startedAt);

  String formattedDate() {
    final ref = endedAt ?? startedAt;
    return DateFormat('MMM d, yyyy').format(ref);
  }

  /// Text copied when the user taps the copy icon on a history card.
  String copyableSummary({
    required bool isCreatorView,
    required String currentUserId,
  }) {
    final partyLabel = isCreatorView ? 'User Name' : 'Creator Name';
    final partyValue = otherPartyName(currentUserId);
    final amountLabel = isCreatorView ? 'Earnings' : 'Coins Used';
    final amountValue = isCreatorView
        ? '+$coinsDeducted coins'
        : '$coinsDeducted coins';

    return [
      '$partyLabel: $partyValue',
      'Date: ${formattedDate()}',
      'Duration: ${formattedDuration()}',
      '$amountLabel: $amountValue',
    ].join('\n');
  }

  String statusLabel() {
    switch (status) {
      case 'ended':
      case 'completed':
        return 'Completed';
      case 'missed':
        return 'Missed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
