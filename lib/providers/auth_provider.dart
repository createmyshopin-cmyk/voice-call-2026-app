import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint, kDebugMode;

import '../services/api_config.dart';
import '../services/fcm_service.dart';
import '../services/session_storage.dart';
import '../services/users_service.dart';

class AppUser {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final int coins;
  final String status;
  final String? firebaseUid;
  final String? fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? avatarUrl;
  final String? language;
  final bool onboardingCompleted;

  AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.coins,
    required this.status,
    this.firebaseUid,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.avatarUrl,
    this.language,
    this.onboardingCompleted = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName'] as String? ??
        json['full_name'] as String? ??
        json['name'] as String?;
    return AppUser(
      uid: json['id'] as String,
      name: fullName ?? json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      coins: json['coins'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      firebaseUid: json['firebase_uid'] as String? ?? json['firebaseUid'] as String?,
      fullName: fullName,
      dateOfBirth:
          json['dateOfBirth'] as String? ?? json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      language: json['language'] as String?,
      onboardingCompleted:
          json['onboardingCompleted'] as bool? ??
          json['onboarding_completed'] as bool? ??
          false,
    );
  }
}

class AuthProvider with ChangeNotifier {
  AppUser? _user;
  String? _accessToken;
  String? _verificationId;
  int? _forceResendingToken;
  String? _pendingPhoneE164;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _lastError;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final UsersService _usersService = UsersService();

  AuthProvider() {
    _restoreSession();
  }

  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _accessToken != null && _user != null;
  bool get hasFirebaseSession => _firebaseAuth.currentUser != null;
  bool get needsOnboarding =>
      !_isInitializing &&
      hasFirebaseSession &&
      (_user == null || !(_user?.onboardingCompleted ?? false));
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  String? get pendingPhoneE164 => _pendingPhoneE164;

  /// Restores Firebase session from disk, then re-exchanges for API JWT on cold start.
  Future<void> _restoreSession() async {
    try {
      await _firebaseAuth.authStateChanges().first;

      final cachedToken = await SessionStorage.readAccessToken();
      if (cachedToken != null) {
        _accessToken = cachedToken;
        try {
          await loadProfile();
          FCMService.initialize(_accessToken!);
          return;
        } catch (e) {
          debugPrint('Cached JWT invalid, re-exchanging: $e');
          _accessToken = null;
          await SessionStorage.clearAccessToken();
        }
      }

      if (_firebaseAuth.currentUser != null) {
        await loginWithFirebase();
      }
    } catch (e) {
      debugPrint('Session restore failed: $e');
      _lastError = e.toString();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Debug verification: confirms a real Firebase phone user and ID token (not mock).
  Future<void> _logFirebaseUserSession(String step) async {
    if (!kDebugMode) return;
    final user = _firebaseAuth.currentUser;
    debugPrint('[FirebaseAuth/$step] uid: ${user?.uid}');
    debugPrint('[FirebaseAuth/$step] phone: ${user?.phoneNumber}');
    final token = await user?.getIdToken();
    if (token == null) {
      debugPrint('[FirebaseAuth/$step] token: null');
    } else {
      debugPrint(
        '[FirebaseAuth/$step] token: ${token.substring(0, token.length.clamp(0, 24))}...',
      );
    }
  }

  /// Sends an SMS OTP via Firebase Phone Authentication.
  Future<void> sendPhoneOtp(String phoneE164, {bool isResend = false}) async {
    _setLoading(true);
    _lastError = null;
    _pendingPhoneE164 = phoneE164;

    final completer = Completer<void>();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneE164,
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _forceResendingToken : null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _firebaseAuth.signInWithCredential(credential);
            await loginWithFirebase();
            if (!completer.isCompleted) completer.complete();
          } catch (e) {
            if (!completer.isCompleted) completer.completeError(e);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _lastError = e.message ?? 'Phone verification failed';
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _forceResendingToken = resendToken;
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

      await completer.future;
    } finally {
      _setLoading(false);
    }
  }

  /// Verifies the SMS code, signs into Firebase, and exchanges the ID token with the API.
  Future<void> verifyPhoneOtp(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      throw StateError('No verification in progress. Request a new OTP.');
    }

    _setLoading(true);
    _lastError = null;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      await _firebaseAuth.signInWithCredential(credential);
      await _logFirebaseUserSession('after-otp');
      _verificationId = null;
      _forceResendingToken = null;
    } on FirebaseAuthException catch (e) {
      _lastError = e.message ?? 'Invalid verification code';
      rethrow;
    } finally {
      _setLoading(false);
    }

    await loginWithFirebase();
  }

  /// Exchanges the current Firebase session for an API JWT and loads the user profile.
  Future<void> loginWithFirebase() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw StateError('Not signed in with Firebase');
    }

    _setLoading(true);
    _lastError = null;

    try {
      await _logFirebaseUserSession('before-backend-login');
      final firebaseToken = await firebaseUser.getIdToken(true);
      if (firebaseToken == null || firebaseToken.isEmpty) {
        throw Exception('Failed to retrieve Firebase ID token');
      }

      final response = await _dio.post(
        '/api/auth/firebase-login',
        data: {'firebaseToken': firebaseToken},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Backend authentication failed');
      }

      final data = response.data as Map<String, dynamic>;
      _accessToken = data['accessToken'] as String;
      await SessionStorage.saveAccessToken(_accessToken!);
      await loadProfile();
      FCMService.initialize(_accessToken!);
      if (kDebugMode) {
        debugPrint('[Backend] firebase-login OK — userId: ${_user?.uid}, phone: ${_user?.phone}');
        debugPrint(
          '[Backend] api JWT: ${_accessToken!.substring(0, _accessToken!.length.clamp(0, 24))}...',
        );
      }
      notifyListeners();
    } on DioException catch (e) {
      _lastError = e.response?.data?.toString() ?? e.message;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// One-time onboarding: full name, DOB, gender, avatar.
  Future<void> completeOnboarding({
    required String fullName,
    required String dateOfBirth,
    required String gender,
    required String avatarUrl,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }
    _setLoading(true);
    _lastError = null;
    try {
      final result = await _usersService.completeOnboarding(
        accessToken: _accessToken!,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        avatarUrl: avatarUrl,
      );
      await _applyProfileUpdateResult(result);
    } finally {
      _setLoading(false);
    }
  }

  /// Post-onboarding edits: full name and avatar only.
  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? language,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }
    final result = await _usersService.updateProfile(
      accessToken: _accessToken!,
      fullName: fullName,
      avatarUrl: avatarUrl,
      language: language,
    );
    await _applyProfileUpdateResult(result);
  }

  Future<void> _applyProfileUpdateResult(Map<String, dynamic> result) async {
    final userJson = result['user'];
    if (userJson is Map<String, dynamic>) {
      _user = AppUser.fromJson(userJson);
      notifyListeners();
    } else {
      await loadProfile();
    }
  }

  Future<void> loadProfile() async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await _dio.get(
      '/api/auth/me',
      options: Options(
        headers: {'Authorization': 'Bearer $_accessToken'},
      ),
    );

    if (response.statusCode == 200) {
      _user = AppUser.fromJson(response.data as Map<String, dynamic>);
      notifyListeners();
    } else if (response.statusCode == 401) {
      _accessToken = null;
      await SessionStorage.clearAccessToken();
      throw Exception('Session expired');
    } else {
      throw Exception('Failed to load profile');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await SessionStorage.clearAccessToken();
    _user = null;
    _accessToken = null;
    _verificationId = null;
    _forceResendingToken = null;
    _pendingPhoneE164 = null;
    _lastError = null;
    notifyListeners();
  }
}
