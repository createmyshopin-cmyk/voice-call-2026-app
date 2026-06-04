import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../screens/incoming_call_screen.dart';
import 'api_config.dart';

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

  /// Call once after the user logs in and accessToken is available.
  static Future<void> initialize(String accessToken) async {
    // 1. Request permission (Android 13+, iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Register current token with backend
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token, accessToken);
    }

    // 3. Re-register whenever token rotates
    _messaging.onTokenRefresh.listen((newToken) {
      _registerToken(newToken, accessToken);
    });

    // 4. Foreground messages — show IncomingCallScreen directly
    FirebaseMessaging.onMessage.listen(_handleMessage);

    // 5. Background notification tapped — app comes to foreground
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // 6. App was terminated, user tapped the notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      // Delay slightly so the navigator is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleMessage(initial);
      });
    }
  }

  static Future<void> _registerToken(
      String fcmToken, String accessToken) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
      await dio.post(
        '/api/users/fcm-token',
        data: {'fcmToken': fcmToken},
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      debugPrint('FCM token registered: $fcmToken');
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  static void _handleMessage(RemoteMessage message) {
    if (message.data['type'] != 'incoming_call') return;

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final data = message.data;
    nav.push(MaterialPageRoute(
      builder: (_) => IncomingCallScreen(
        callerName: data['callerName'] ?? 'Unknown',
        callerAvatar: data['callerAvatar'] ?? '',
        channelName: data['channelName'] ?? '',
        callRequestId: data['callRequestId'] ?? data['callSessionId'] ?? '',
        agoraToken: data['agoraToken'] ?? '',
        agoraAppId: data['agoraAppId'] ?? '',
        isVideo: data['callType'] == 'video',
      ),
    ));
  }
}
