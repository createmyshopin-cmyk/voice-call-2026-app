/// Prevents duplicate incoming-call UI for the same [callRequestId]
/// (FCM + listener poll, or multiple FCM handler registrations).
class IncomingCallCoordinator {
  IncomingCallCoordinator._();

  static final Set<String> _handledRequestIds = <String>{};
  static String? _activeIncomingRequestId;

  /// Whether we should show incoming UI for this request.
  static bool shouldPresent(String callRequestId) {
    if (callRequestId.isEmpty) return false;
    if (_handledRequestIds.contains(callRequestId)) return false;
    if (_activeIncomingRequestId == callRequestId) return false;
    return true;
  }

  static void markPresenting(String callRequestId) {
    if (callRequestId.isEmpty) return;
    _activeIncomingRequestId = callRequestId;
  }

  /// Call when the request is accepted, rejected, cancelled, missed, or the call ended.
  static void markHandled(String callRequestId) {
    if (callRequestId.isEmpty) return;
    _handledRequestIds.add(callRequestId);
    if (_activeIncomingRequestId == callRequestId) {
      _activeIncomingRequestId = null;
    }
  }

  static void clearPresenting() {
    _activeIncomingRequestId = null;
  }
}
