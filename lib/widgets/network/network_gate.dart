import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/call_history_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../screens/network/no_internet_screen.dart';

/// Wraps the app: shows [NoInternetScreen] when offline and runs background recovery.
class NetworkGate extends StatefulWidget {
  final Widget child;

  const NetworkGate({super.key, required this.child});

  @override
  State<NetworkGate> createState() => _NetworkGateState();
}

class _NetworkGateState extends State<NetworkGate> {
  NetworkProvider? _networkProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _networkProvider = context.read<NetworkProvider>();
      _networkProvider!.registerRecoveryCallback(_onReconnect);
    });
  }

  @override
  void dispose() {
    _networkProvider?.unregisterRecoveryCallback(_onReconnect);
    super.dispose();
  }

  Future<void> _onReconnect() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.accessToken == null) return;

    await Future.wait([
      auth.refreshUser(),
      context.read<WalletProvider>().loadWallet(reason: 'networkRecovery'),
      context.read<CreatorProvider>().fetchCreators(),
      context.read<CallHistoryProvider>().fetchHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkProvider>();

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (network.isDisconnected)
          const Positioned.fill(child: NoInternetScreen()),
      ],
    );
  }
}
