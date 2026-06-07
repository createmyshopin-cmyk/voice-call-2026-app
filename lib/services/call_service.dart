import 'package:dio/dio.dart';
import '../models/call_history_item.dart';
import 'api_client.dart';

/// Pending incoming call for a creator (GET /api/calls/requests/pending)
class PendingCallRequest {
  final String id;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final bool isVideo;
  final String createdAt;

  const PendingCallRequest({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.isVideo,
    required this.createdAt,
  });

  factory PendingCallRequest.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'voice';
    return PendingCallRequest(
      id: json['id'] as String,
      callerId: json['callerId'] as String? ?? '',
      callerName: json['callerName'] as String? ?? 'Caller',
      callerAvatar: json['callerAvatar'] as String? ??
          'https://i.pravatar.cc/150?u=caller',
      isVideo: type == 'video',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

/// Result returned by POST /api/calls/request
class CallRequestResult {
  final String callRequestId;
  final String? callSessionId;
  final String channelName;
  final String agoraToken;
  final String agoraAppId;
  final String status;

  const CallRequestResult({
    required this.callRequestId,
    this.callSessionId,
    required this.channelName,
    required this.agoraToken,
    required this.agoraAppId,
    this.status = 'pending',
  });

  factory CallRequestResult.fromJson(Map<String, dynamic> data) {
    final request = data['callRequest'] as Map<String, dynamic>? ?? {};
    final session = data['callSession'] as Map<String, dynamic>?;
    return CallRequestResult(
      callRequestId: request['id'] as String? ?? '',
      callSessionId: session?['id'] as String? ?? request['callId'] as String?,
      channelName: data['channelName'] as String? ??
          request['channelName'] as String? ??
          '',
      agoraToken: data['agoraToken'] as String? ?? '',
      agoraAppId: data['agoraAppId'] as String? ?? '',
      status: _normalizeRequestStatus(
        request['status'] as String? ?? data['status'] as String? ?? 'requested',
      ),
    );
  }
}

/// Result returned by PATCH /api/calls/requests/:id/accept
class AcceptCallResult {
  final String callSessionId;
  final String channelName;
  final String agoraToken;
  final String agoraAppId;

  const AcceptCallResult({
    required this.callSessionId,
    required this.channelName,
    required this.agoraToken,
    required this.agoraAppId,
  });

  factory AcceptCallResult.fromJson(Map<String, dynamic> data) {
    final session = data['callSession'] as Map<String, dynamic>;
    return AcceptCallResult(
      callSessionId: session['id'] as String,
      channelName: data['channelName'] as String? ?? session['channelName'] as String? ?? '',
      agoraToken: data['agoraToken'] as String? ?? '',
      agoraAppId: data['agoraAppId'] as String? ?? '',
    );
  }
}

/// Result returned by POST /api/calls/active/:id/end
class EndCallResult {
  final int coinsDeducted;
  final int? newBalance;

  const EndCallResult({required this.coinsDeducted, this.newBalance});

  factory EndCallResult.fromJson(Map<String, dynamic> data) {
    return EndCallResult(
      coinsDeducted: data['coinsDeducted'] as int? ??
          data['coinsSpent'] as int? ??
          0,
      newBalance: data['newBalance'] as int?,
    );
  }
}

String _normalizeRequestStatus(String raw) {
  switch (raw) {
    case 'pending':
      return 'requested';
    case 'completed':
      return 'accepted';
    default:
      return raw;
  }
}

class CallService {
  final Dio _dio;

  CallService({Dio? dio}) : _dio = dio ?? apiDio;

  Map<String, String> _authHeaders(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
      };

  /// POST /api/calls/request — creates a pending call request
  Future<CallRequestResult> requestCall({
    required String accessToken,
    required String listenerId,
    required bool isVideo,
  }) async {
    final response = await _dio.post(
      '/api/calls/request',
      data: {
        'listenerId': listenerId,
        'type': isVideo ? 'video' : 'voice',
      },
      options: Options(headers: _authHeaders(accessToken)),
    );

    final data = response.data;
    if (data is! Map<String, dynamic> || data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Call request failed',
      );
    }

    return CallRequestResult.fromJson(data);
  }

  /// GET /api/calls/requests/:id/status — poll until accepted / rejected / missed
  Future<Map<String, dynamic>> getCallRequestStatus({
    required String accessToken,
    required String callRequestId,
  }) async {
    final response = await _dio.get(
      '/api/calls/requests/$callRequestId/status',
      options: Options(headers: _authHeaders(accessToken)),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final status = data['status'];
      if (status is String) {
        data['status'] = _normalizeRequestStatus(status);
      }
      return data;
    }
    return {};
  }

  /// PATCH /api/calls/active/:sessionId/status — ringing or ongoing
  Future<void> updateCallStatus({
    required String accessToken,
    required String sessionId,
    required String status,
  }) async {
    await _dio.patch(
      '/api/calls/active/$sessionId/status',
      data: {'status': status},
      options: Options(headers: _authHeaders(accessToken)),
    );
  }

  /// GET /api/calls/requests/pending — incoming requests for creator
  Future<List<PendingCallRequest>> getPendingRequests({
    required String accessToken,
  }) async {
    final response = await _dio.get(
      '/api/calls/requests/pending',
      options: Options(headers: _authHeaders(accessToken)),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) return [];
    final list = data['requests'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(PendingCallRequest.fromJson)
        .toList();
  }

  /// POST /api/calls/:id/accept (creator)
  Future<AcceptCallResult> acceptCall({
    required String accessToken,
    required String callRequestId,
  }) async {
    final response = await _dio.post(
      '/api/calls/$callRequestId/accept',
      options: Options(headers: _authHeaders(accessToken)),
    );

    final data = response.data;
    if (data is! Map<String, dynamic> || data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to accept call',
      );
    }

    return AcceptCallResult.fromJson(data);
  }

  /// POST /api/calls/:id/reject (creator)
  Future<void> rejectCall({
    required String accessToken,
    required String callRequestId,
  }) async {
    await _dio.post(
      '/api/calls/$callRequestId/reject',
      options: Options(headers: _authHeaders(accessToken)),
    );
  }

  /// Accept call — POST /api/calls/:id/accept
  Future<AcceptCallResult> acceptCallRequest({
    required String accessToken,
    required String callRequestId,
  }) =>
      acceptCall(accessToken: accessToken, callRequestId: callRequestId);

  /// Reject call — POST /api/calls/:id/reject
  Future<void> rejectCallRequest({
    required String accessToken,
    required String callRequestId,
  }) =>
      rejectCall(accessToken: accessToken, callRequestId: callRequestId);

  /// POST /api/calls/requests/:id/missed
  Future<void> markCallRequestMissed({
    required String accessToken,
    required String callRequestId,
  }) async {
    await _dio.post(
      '/api/calls/requests/$callRequestId/missed',
      options: Options(headers: _authHeaders(accessToken)),
    );
  }

  /// GET /api/calls/history — completed/missed sessions for the signed-in user
  Future<List<CallHistoryItem>> fetchCallHistory({
    required String accessToken,
  }) async {
    final response = await _dio.get(
      '/api/calls/history',
      options: Options(headers: _authHeaders(accessToken)),
    );

    final data = response.data;
    if (data is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Invalid call history response',
      );
    }

    return data
        .map((item) => CallHistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/calls/agora-token — backend generates a short-lived RTC token
  Future<Map<String, dynamic>> fetchAgoraToken({
    required String accessToken,
    required String channelName,
    int uid = 0,
  }) async {
    final response = await _dio.post(
      '/api/calls/agora-token',
      data: {
        'channelName': channelName,
        'uid': uid,
        'role': 'publisher',
      },
      options: Options(headers: _authHeaders(accessToken)),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  /// POST /api/calls/active/:sessionId/end
  Future<EndCallResult> endCall({
    required String accessToken,
    required String sessionId,
    required int durationSeconds,
    String? endedReason,
  }) async {
    final response = await _dio.post(
      '/api/calls/active/$sessionId/end',
      data: {
        'duration': durationSeconds,
        if (endedReason != null) 'endedReason': endedReason,
      },
      options: Options(headers: _authHeaders(accessToken)),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return EndCallResult.fromJson(data);
    }
    return const EndCallResult(coinsDeducted: 0);
  }
}
