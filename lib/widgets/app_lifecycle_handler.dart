import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/creator_heartbeat_provider.dart';

/// Marks creator offline when the app is closed or sent to background.
class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({super.key, required this.child});

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only mark offline when the process is torn down — not on brief backgrounding
    // (listeners may still receive incoming calls via FCM while backgrounded).
    if (state == AppLifecycleState.detached) {
      context.read<CreatorHeartbeatProvider>().goOfflineOnBackground();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
