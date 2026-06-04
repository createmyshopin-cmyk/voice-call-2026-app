import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/creator_provider.dart';
import 'providers/creator_heartbeat_provider.dart';
import 'providers/call_history_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/gender_selection_screen.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Must be registered before runApp so the isolate is ready for background messages
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(
    MultiProvider(
      providers: [
        // 1. Auth is the root — everything depends on it
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // 2. Wallet reacts to auth changes
        ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
          create: (_) => WalletProvider(),
          update: (_, auth, wallet) =>
              wallet!..updateAuth(auth.user?.uid, auth.accessToken),
        ),

        // 3. Creators list reacts to auth changes (re-fetch on login)
        ChangeNotifierProxyProvider<AuthProvider, CreatorProvider>(
          create: (_) => CreatorProvider(),
          update: (_, auth, creators) =>
              creators!..onAuthChanged(auth.accessToken),
        ),

        // 4. Creator presence heartbeat (listener/creator panel)
        ChangeNotifierProxyProvider<AuthProvider, CreatorHeartbeatProvider>(
          create: (_) => CreatorHeartbeatProvider(),
          update: (_, auth, heartbeat) =>
              heartbeat!..onAuthChanged(auth.accessToken),
        ),

        ChangeNotifierProxyProvider<AuthProvider, CallHistoryProvider>(
          create: (_) => CallHistoryProvider(),
          update: (_, auth, history) =>
              history!..onAuthChanged(auth.accessToken),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Calling App',
      navigatorKey: FCMService.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isInitializing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (auth.isAuthenticated &&
              (auth.user?.onboardingCompleted ?? false)) {
            return const HomeScreen();
          }
          if (auth.needsOnboarding) {
            return const GenderSelectionScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
