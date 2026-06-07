import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint, kDebugMode;

import '../core/network/api_exception.dart';
import '../services/api_client.dart';
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
  final String role;
  final String creatorStatus;
  final bool isCreator;

  /// Profile display name — always prefers [fullName] over legacy [name].
  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    return name.trim();
  }

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
    this.role = 'user',
    this.creatorStatus = 'none',
    this.isCreator = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName'] as String? ?? json['full_name'] as String?;
    final legacyName = json['name'] as String? ?? '';
    final resolvedName = (fullName?.trim().isNotEmpty == true)
        ? fullName!.trim()
        : legacyName.trim();
    return AppUser(
      uid: json['id'] as String,
      name: resolvedName,
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
      role: json['role'] as String? ?? 'user',
      creatorStatus: json['creatorStatus'] as String? ?? json['creator_status'] as String? ?? 'none',
      isCreator: json['isCreator'] as bool? ?? json['is_creator'] as bool? ?? false,
    );
  }
}

class AuthProvider with ChangeNotifier {
  AppUser? _user;
  String? _accessToken;
  String? _verificationId;
  int? _forceResendingToken;
  String? _pendingPhoneE164;
  bool _phoneAuthAutoVerified = false;
  Future<void>? _inFlightAutoVerify;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _lastError;
  String? _creatorStatus;
  Map<String, dynamic>? _listenerProfile;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Dio _dio = apiDio;

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
  String? get verificationId => _verificationId;
  bool get hasVerificationInProgress =>
      _verificationId != null && _verificationId!.isNotEmpty;
  bool get phoneAuthAutoVerified => _phoneAuthAutoVerified;

  String get creatorStatus => _creatorStatus ?? _user?.creatorStatus ?? 'none';

  /// Approved/active creator — unlocks listener mode and earnings UI.
  bool get isActiveCreator {
    if (creatorStatus == 'suspended') return false;
    if (creatorStatus == 'active' || creatorStatus == 'approved') return true;
    if (_user?.isCreator == true) return true;
    return _user?.role == 'creator';
  }

  bool get isListener => isActiveCreator;
  Map<String, dynamic>? get listenerProfile => _listenerProfile;

  Future<void> applyForListener({
    required String name,
    required String bio,
    required List<String> languages,
    required String profileImage,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }
    _setLoading(true);
    _lastError = null;
    try {
      final response = await _dio.post(
        '/api/creators',
        data: {
          'name': name,
          'bio': bio,
          'languages': languages,
          'profileImage': profileImage,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _creatorStatus = 'pending';
        final data = response.data as Map<String, dynamic>;
        _listenerProfile = data['creator'] as Map<String, dynamic>?;
        notifyListeners();
      } else {
        throw Exception('Failed to submit listener application');
      }
    } on DioException catch (e) {
      final ex = ApiException.from(e);
      if (!ex.isNoInternet) _lastError = ex.message;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchListenerProfile() async {
    final uid = _user?.uid;
    if (_accessToken == null || uid == null) {
      return;
    }
    try {
      final response = await _dio.get(
        '/api/creators/$uid',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );

      if (response.statusCode == 200) {
        _listenerProfile = response.data as Map<String, dynamic>;
        final statusVal = _listenerProfile?['status'] as String?;
        if (statusVal != null && statusVal.isNotEmpty) {
          _creatorStatus = statusVal;
        } else if (_user?.isCreator == true) {
          _creatorStatus = 'active';
        } else {
          _creatorStatus = 'none';
        }
      } else if (_user?.isCreator == true) {
        _creatorStatus = 'active';
      } else {
        _creatorStatus = 'none';
        _listenerProfile = null;
      }
      notifyListeners();
    } catch (e) {
      if (_user?.isCreator != true) {
        _creatorStatus = 'none';
        _listenerProfile = null;
      } else {
        _creatorStatus = 'active';
      }
      notifyListeners();
    }
  }

  Future<void> refreshRole() async {
    await loadProfile();
    await fetchListenerProfile();
  }

  /// Reload profile from API (includes users.coins for legacy surfaces).
  /// Does not drive wallet UI — WalletProvider ignores auth refresh for balance.
  Future<void> refreshUser() async {
    await loadProfile();
    debugPrint(
      '[AuthProvider] refreshUser => users.coins=${_user?.coins}',
    );
  }

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
      } else {
        await _restoreOtpState();
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

  void _logOtp(String message) {
    debugPrint('[OTP] $message');
  }

  void setVerificationId(String id, {int? resendToken}) {
    _verificationId = id;
    if (resendToken != null) {
      _forceResendingToken = resendToken;
    }
    _logOtp('verificationId saved');
    final phone = _pendingPhoneE164;
    if (phone != null) {
      unawaited(SessionStorage.saveOtpState(
        verificationId: id,
        phoneE164: phone,
      ));
    }
    notifyListeners();
  }

  Future<void> clearVerificationId({bool notify = true}) async {
    _verificationId = null;
    _forceResendingToken = null;
    _phoneAuthAutoVerified = false;
    _inFlightAutoVerify = null;
    await SessionStorage.clearOtpState();
    if (notify) notifyListeners();
  }

  Future<void> _restoreOtpState() async {
    if (isAuthenticated) return;
    final savedId = await SessionStorage.readVerificationId();
    if (savedId == null || savedId.isEmpty) return;
    _verificationId = savedId;
    _pendingPhoneE164 ??= await SessionStorage.readPendingPhone();
    _logOtp('verificationId restored from storage');
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

  Future<void> _handleAutoVerification(PhoneAuthCredential credential) async {
    _phoneAuthAutoVerified = true;
    _logOtp('Auto verification success');
    await _firebaseAuth.signInWithCredential(credential);
    _logOtp('Firebase sign-in success');
    await loginWithFirebase();
    _logOtp('Backend login success');
    await clearVerificationId(notify: false);
  }

  Future<void> _awaitInFlightAutoVerify() async {
    final inFlight = _inFlightAutoVerify;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {
        // Caller surfaces errors via lastError / rethrow from sendPhoneOtp.
      }
      return;
    }

    // codeSent can finish before verificationCompleted starts on Android.
    if (!isAuthenticated && !hasFirebaseSession) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final delayed = _inFlightAutoVerify;
      if (delayed != null) {
        try {
          await delayed;
        } catch (_) {}
      }
    }

    if (hasFirebaseSession && !isAuthenticated) {
      _logOtp('Firebase session detected after send — completing backend login');
      await loginWithFirebase();
      await clearVerificationId(notify: false);
    }
  }

  /// Sends an SMS OTP via Firebase Phone Authentication.
  Future<void> sendPhoneOtp(String phoneE164, {bool isResend = false}) async {
    _setLoading(true);
    _lastError = null;
    _pendingPhoneE164 = phoneE164;
    _phoneAuthAutoVerified = false;
    _inFlightAutoVerify = null;

    if (isResend) {
      _logOtp('resend OTP requested');
    } else {
      _logOtp('verifyPhoneNumber started');
    }

    final completer = Completer<void>();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneE164,
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _forceResendingToken : null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _logOtp('verificationCompleted');
          _inFlightAutoVerify = _handleAutoVerification(credential);
          try {
            await _inFlightAutoVerify;
            if (!completer.isCompleted) completer.complete();
          } catch (e) {
            _phoneAuthAutoVerified = false;
            if (!completer.isCompleted) completer.completeError(e);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _logOtp('verificationFailed: ${e.code}');
          _lastError = e.message ?? 'Phone verification failed';
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _logOtp('codeSent');
          setVerificationId(verificationId, resendToken: resendToken);
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _logOtp('timeout — manual OTP entry still allowed');
          setVerificationId(verificationId);
        },
      );

      await completer.future;
      await _awaitInFlightAutoVerify();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Verifies the SMS code, signs into Firebase, and exchanges the ID token with the API.
  Future<void> verifyPhoneOtp(String smsCode) async {
    _logOtp('verifyOtp clicked');
    _logOtp(
      'verificationId value: ${hasVerificationInProgress ? "present" : "null"}',
    );

    if (_inFlightAutoVerify != null) {
      _logOtp('waiting for in-flight auto-verification');
      try {
        await _inFlightAutoVerify;
      } catch (_) {}
    }

    if (isAuthenticated) {
      _logOtp('Already authenticated — skipping manual OTP');
      await clearVerificationId();
      return;
    }

    if (hasFirebaseSession && _accessToken == null) {
      _logOtp('Firebase session exists — completing backend login');
      await loginWithFirebase();
      await clearVerificationId();
      return;
    }

    final verificationId = _verificationId;
    if (verificationId == null) {
      if (hasFirebaseSession) {
        await loginWithFirebase();
        await clearVerificationId();
        return;
      }
      throw StateError(
        'Verification expired. Please request a new OTP.',
      );
    }

    _setLoading(true);
    _lastError = null;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      await _firebaseAuth.signInWithCredential(credential);
      _logOtp('Firebase sign-in success');
      await _logFirebaseUserSession('after-otp');
      await clearVerificationId(notify: false);
    } on FirebaseAuthException catch (e) {
      _lastError = e.message ?? 'Invalid verification code';
      rethrow;
    } finally {
      _setLoading(false);
    }

    await loginWithFirebase();
    _logOtp('Backend login success');
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
      final ex = ApiException.from(e);
      if (!ex.isNoInternet) _lastError = ex.message;
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
      if (_user?.isCreator == true &&
          (_creatorStatus == null || _creatorStatus == 'none')) {
        _creatorStatus = 'active';
      }
      debugPrint(
        '[AuthProvider] loadProfile => users.coins=${_user?.coins}',
      );
      notifyListeners();
      await fetchListenerProfile();
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
    _pendingPhoneE164 = null;
    _lastError = null;
    await clearVerificationId(notify: false);
    notifyListeners();
  }
}
