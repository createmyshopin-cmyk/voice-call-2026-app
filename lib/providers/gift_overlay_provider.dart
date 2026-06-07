import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/gift_item.dart';
import '../services/gift_fcm_dispatcher.dart';

class GiftOverlayProvider with ChangeNotifier {
  final List<GiftOverlayEvent> _queue = [];
  final List<GiftSummaryEntry> _sessionReceived = [];
  GiftOverlayEvent? _current;
  Timer? _hideTimer;
  bool _isProcessing = false;

  GiftOverlayEvent? get current => _current;
  bool get hasOverlay => _current != null;
  int get queueLength => _queue.length;
  List<GiftSummaryEntry> get sessionReceived =>
      List.unmodifiable(_sessionReceived);
  int get sessionGiftEarnings =>
      _sessionReceived.fold(0, (sum, g) => sum + g.coins);

  GiftOverlayProvider() {
    GiftFcmDispatcher.onGiftReceived = _onGiftReceived;
    GiftFcmDispatcher.onGiftReply = _onGiftReply;
  }

  void Function(String creatorName, String message)? onGiftReplyToast;

  void _onGiftReceived(Map<String, dynamic> data) {
    final event = GiftOverlayEvent.fromFcm(data);
    if (event.giftTransactionId.isEmpty) return;
    _enqueue(event);
  }

  void _onGiftReply(Map<String, dynamic> data) {
    final creatorName = data['creatorName']?.toString() ?? 'Creator';
    final message = data['message']?.toString() ?? '';
    onGiftReplyToast?.call(creatorName, message);
  }

  void enqueueLocal(GiftOverlayEvent event) => _enqueue(event);

  void _enqueue(GiftOverlayEvent event) {
    _sessionReceived.add(GiftSummaryEntry(
      senderName: event.senderName,
      giftName: event.giftName,
      giftEmoji: event.giftEmoji,
      coins: event.creatorCoins > 0 ? event.creatorCoins : event.giftCoins,
    ));
    _queue.add(event);
    if (!_isProcessing) _processNext();
    notifyListeners();
  }

  void _processNext() {
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }
    _isProcessing = true;
    _current = _queue.removeAt(0);
    notifyListeners();

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      _current = null;
      notifyListeners();
      _processNext();
    });
  }

  void dismissCurrent() {
    _hideTimer?.cancel();
    _current = null;
    notifyListeners();
    _processNext();
  }

  void clear() {
    _hideTimer?.cancel();
    _queue.clear();
    _sessionReceived.clear();
    _current = null;
    _isProcessing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    if (GiftFcmDispatcher.onGiftReceived != null) {
      GiftFcmDispatcher.onGiftReceived = null;
    }
    if (GiftFcmDispatcher.onGiftReply != null) {
      GiftFcmDispatcher.onGiftReply = null;
    }
    super.dispose();
  }
}
