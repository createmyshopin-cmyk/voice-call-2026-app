import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../screens/incoming_call_screen.dart';
import 'api_client.dart';
import 'gift_fcm_dispatcher.dart';
import 'incoming_call_coordinator.dart';

/// Top-level background handler — must be a top-level function, not a method.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // When the FCM payload includes a `notification` block, Android/iOS show
  // the system notification automatically in background/terminated states.
  // Data is available here for dedup/logging; UI dispatch happens on app resume.
  final type = message.data['type']?.toString();
  if (type == 'gift_received' || type == 'gift_reply') {
    debugPrint('[FCM:bg] gift event type=$type id=${message.data['giftTransactionId']}');
  }
}

class FCMService {
  /// Single navigator key shared with MaterialApp so we can push screens
  /// from outside the widget tree (foreground messages, notification taps).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static bool _handlersRegistered = false;
  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onOpenedSub;
  static StreamSubscription<String>? _tokenRefreshSub;
  static String? _lastAccessToken;

  /// Call once after the user logs in and accessToken is available.
  static Future<void> initialize(String accessToken) async {
    _lastAccessToken = accessToken;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token, accessToken);
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
      final auth = _lastAccessToken;
      if (auth != null) {
        _registerToken(newToken, auth);
      }
    });

    if (!_handlersRegistered) {
      _onMessageSub = FirebaseMessaging.onMessage.listen(_handleMessage);
      _onOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
      _handlersRegistered = true;
    }

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleMessage(initial);
      });
    }
  }

  static Future<void> shutdown() async {
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _onMessageSub = null;
    _onOpenedSub = null;
    _tokenRefreshSub = null;
    _handlersRegistered = false;
    _lastAccessToken = null;
  }

  static Future<void> _registerToken(
      String fcmToken, String accessToken) async {
    try {
      await apiDio.post(
        '/api/users/fcm-token',
        data: {'fcmToken': fcmToken},
        options: authOptions(accessToken),
      );
      debugPrint('FCM token registered: $fcmToken');
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  static void _handleMessage(RemoteMessage message) {
    final data = message.data;

    if (GiftFcmDispatcher.dispatch(data)) {
      return;
    }

    if (data['type'] != 'incoming_call') return;
    final callRequestId =
        data['callRequestId']?.toString() ?? data['callSessionId']?.toString() ?? '';

    if (!IncomingCallCoordinator.shouldPresent(callRequestId)) {
      debugPrint('FCM incoming_call ignored (duplicate/handled): $callRequestId');
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final nav = navigatorKey.currentState;
      if (nav == null) return;

      IncomingCallCoordinator.markPresenting(callRequestId);

      nav.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callerName: data['callerName'] ?? 'Unknown',
            callerAvatar: data['callerAvatar'] ?? '',
            channelName: data['channelName'] ?? '',
            callRequestId: callRequestId,
            agoraToken: data['agoraToken'] ?? '',
            agoraAppId: data['agoraAppId'] ?? '',
            isVideo: data['callType'] == 'video',
          ),
        ),
      );
    });
  }
}
