import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import '../screens/create_profile_screen.dart';
import '../screens/home_screen.dart';

/// Navigates to Home or CreateProfile after a successful phone auth flow.
void navigateAfterPhoneAuth(
  BuildContext context,
  AuthProvider auth, {
  String source = 'unknown',
}) {
  final onboarded = auth.user?.onboardingCompleted == true;
  final destination =
      onboarded ? const HomeScreen() : const CreateProfileScreen();
  debugPrint(
    '[OTP] Navigation -> ${onboarded ? "Home" : "CreateProfile"} (source: $source)',
  );
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => destination),
  );
}
