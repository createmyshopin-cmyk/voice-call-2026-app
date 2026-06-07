import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../screens/incoming_call_screen.dart';
import 'api_client.dart';
import 'incoming_call_coordinator.dart';

/// Top-level background handler — must be a top-level function, not a method.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // System automatically shows the notification from the FCM payload.
  // Nothing else needed here; tap handling is done in onMessageOpenedApp.
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

  /// Call once after the user logs in and accessToken is available.
  static Future<void> initialize(String accessToken) async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token, accessToken);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      _registerToken(newToken, accessToken);
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
    if (message.data['type'] != 'incoming_call') return;

    final data = message.data;
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
