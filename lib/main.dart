import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/network/api_diagnostics.dart';
import 'core/network/network_service.dart';
import 'services/api_client.dart';
import 'services/realtime_listener_status_service.dart';
import 'services/supabase_config.dart';
import 'widgets/app_lifecycle_handler.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/creator_provider.dart';
import 'providers/creator_heartbeat_provider.dart';
import 'providers/call_history_provider.dart';
import 'providers/network_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_profile_screen.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'widgets/common/app_shimmer.dart';
import 'widgets/network/network_gate.dart';

late final NetworkService networkService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Must be registered before runApp so the isolate is ready for background messages
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  networkService = NetworkService();
  final networkProvider = NetworkProvider(networkService);
  await networkProvider.initialize();

  bindApiDiagnosticsConnectionType(() => networkService.connectionType);
  await logApiStartupDiagnostics(networkService: networkService);
  await SupabaseConfig.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NetworkProvider>.value(value: networkProvider),

        // 1. Auth is the root — everything depends on it
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // 2. Wallet reacts to auth login/logout only — not profile refresh.
        // initialCoins seeds balance once per user id; never on every notifyListeners.
        ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
          create: (_) => WalletProvider(),
          update: (_, auth, wallet) => wallet!
            ..updateAuth(
              auth.user?.uid,
              auth.accessToken,
              initialCoins: auth.user?.coins,
            ),
        ),

        // 3. Creators list reacts to auth changes (re-fetch on login)
        ChangeNotifierProxyProvider<AuthProvider, CreatorProvider>(
          create: (_) => CreatorProvider(
            realtimeService: RealtimeListenerStatusService(
              networkService: networkService,
            ),
          ),
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
      child: const AppLifecycleHandler(child: MyApp()),
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
      builder: (context, child) {
        return NetworkGate(child: child ?? const SizedBox.shrink());
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isInitializing) {
            return const AuthInitSkeleton();
          }
          if (auth.isAuthenticated &&
              (auth.user?.onboardingCompleted ?? false)) {
            return const HomeScreen();
          }
          if (auth.needsOnboarding) {
            return const CreateProfileScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
