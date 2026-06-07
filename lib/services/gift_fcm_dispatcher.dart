import 'package:flutter/foundation.dart';

/// Bridges FCM data payloads to in-app gift handlers without tight coupling.
class GiftFcmDispatcher {
  GiftFcmDispatcher._();

  static final Set<String> _handledKeys = <String>{};

  static void Function(Map<String, dynamic> data)? onGiftReceived;
  static void Function(Map<String, dynamic> data)? onGiftReply;

  static bool dispatch(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == 'gift_received') {
      final key = data['giftTransactionId']?.toString() ??
          '${data['senderId']}_${data['giftName']}_${data['createdAt']}';
      if (key.isNotEmpty && _handledKeys.contains(key)) {
        debugPrint('[GiftFcm] duplicate gift_received ignored: $key');
        return true;
      }
      if (key.isNotEmpty) _handledKeys.add(key);
      onGiftReceived?.call(data);
      return true;
    }
    if (type == 'gift_reply') {
      final key = data['giftTransactionId']?.toString() ??
          '${data['creatorName']}_${data['message']}';
      if (key.isNotEmpty && _handledKeys.contains('reply:$key')) {
        debugPrint('[GiftFcm] duplicate gift_reply ignored: $key');
        return true;
      }
      if (key.isNotEmpty) _handledKeys.add('reply:$key');
      onGiftReply?.call(data);
      return true;
    }
    return false;
  }

  static void clearSession() {
    _handledKeys.clear();
  }
}
