import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/creator_heartbeat_provider.dart';
import '../providers/call_history_provider.dart';
import '../services/call_service.dart';
import 'call_details_screen.dart';
import 'calling_screen.dart';
import '../widgets/call_history_card.dart';

class ListenerDashboardScreen extends StatefulWidget {
  const ListenerDashboardScreen({super.key});

  @override
  State<ListenerDashboardScreen> createState() => _ListenerDashboardScreenState();
}

class _ListenerDashboardScreenState extends State<ListenerDashboardScreen> {
  int _activeTab = 0; // 0: Earnings, 1: Payout, 2: History, 3: Reports
  bool _isOnline = false;
  Timer? _pendingPollTimer;
  final Set<String> _shownRequestIds = {};
  bool _incomingDialogOpen = false;
  final CallService _callService = CallService();
  double _withdrawableBalance = 28.50;

  @override
  void deactivate() {
    context.read<CreatorHeartbeatProvider>().setActive(false);
    super.deactivate();
  }

  @override
  void dispose() {
    _pendingPollTimer?.cancel();
    super.dispose();
  }

  void _toggleOnline(bool value) {
    setState(() => _isOnline = value);
    context.read<CreatorHeartbeatProvider>().setActive(value);
    _pendingPollTimer?.cancel();

    if (_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are online. Waiting for incoming calls…'),
          backgroundColor: Color(0xFF8A2BE2),
          duration: Duration(seconds: 3),
        ),
      );
      _pollPendingRequests();
      _pendingPollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _pollPendingRequests(),
      );
    } else {
      _shownRequestIds.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Calls will not be received.'),
          backgroundColor: Color(0xFFD73357),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pollPendingRequests() async {
    if (!mounted || !_isOnline || _incomingDialogOpen) return;

    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;

    try {
      final pending = await _callService.getPendingRequests(accessToken: token);
      for (final request in pending) {
        if (_shownRequestIds.contains(request.id)) continue;
        _shownRequestIds.add(request.id);
        if (mounted) {
          await _showIncomingCall(request);
        }
        break;
      }
    } catch (_) {
      // Backend may be offline; keep polling
    }
  }

  Future<void> _showIncomingCall(PendingCallRequest request) async {
    if (!mounted) return;
    _incomingDialogOpen = true;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Incoming Call',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return _IncomingCallPickupOverlay(
          name: request.callerName,
          avatar: request.callerAvatar,
          isVideo: request.isVideo,
          onDecline: () async {
            final token = context.read<AuthProvider>().accessToken;
            if (token != null) {
              try {
                await _callService.rejectCall(
                  accessToken: token,
                  callRequestId: request.id,
                );
              } catch (_) {}
            }
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          onAccept: () async {
            final token = context.read<AuthProvider>().accessToken;
            if (token == null) {
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              return;
            }

            try {
              final accepted = await _callService.acceptCall(
                accessToken: token,
                callRequestId: request.id,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallingScreen(
                    channelName: accepted.channelName,
                    displayName: request.callerName,
                    avatarUrl: request.callerAvatar,
                    isVideoCall: request.isVideo,
                    callRequestId: request.id,
                    callSessionId: accepted.callSessionId,
                    agoraToken: accepted.agoraToken,
                    agoraAppId: accepted.agoraAppId,
                  ),
                ),
              );
            } catch (e) {
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not accept the call. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );

    _incomingDialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1A), // Deep dark theme background
      body: SafeArea(
        child: Column(
          children: [
            // 1. Dashboard Header (Title & Online Toggle)
            _buildHeader(),

            // 2. Tab Navigation Row
            _buildTabsRow(),

            // 3. Tab Contents Layout
            Expanded(
              child: _buildActiveTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  // --- HEADER WIDGET ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF131A28),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2637), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back/Exit button & Title
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Listener Panel',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Earn per call',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF707584),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Active Status switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _isOnline ? const Color(0xFF2ECC71).withOpacity(0.1) : const Color(0xFF1E2637),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? const Color(0xFF2ECC71) : const Color(0xFF707584),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnline ? 'ONLINE' : 'OFFLINE',
                  style: GoogleFonts.poppins(
                    color: _isOnline ? const Color(0xFF2ECC71) : const Color(0xFF707584),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: _isOnline,
                  onChanged: _toggleOnline,
                  activeColor: const Color(0xFF2ECC71),
                  activeTrackColor: const Color(0xFF2ECC71).withOpacity(0.3),
                  inactiveThumbColor: const Color(0xFF707584),
                  inactiveTrackColor: const Color(0xFF080E1A),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TABS SELECTOR ---
  Widget _buildTabsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: const Color(0xFF0D1320),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTabButton('Earnings', 0, Icons.analytics_outlined),
          _buildTabButton('Payout', 1, Icons.account_balance_wallet_outlined),
          _buildTabButton('History', 2, Icons.history_toggle_off),
          _buildTabButton('Reports', 3, Icons.rate_review_outlined),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    bool isActive = _activeTab == index;
    return ScalePressedButton(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isActive ? const Color(0xFF1E2637) : Colors.transparent,
          border: isActive ? Border.all(color: const Color(0xFF424855).withOpacity(0.5)) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFBA9EFF) : const Color(0xFF707584),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF707584),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RENDERS THE VIEW FOR ACTIVE TAB ---
  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildEarningsTab();
      case 1:
        return _buildPayoutTab();
      case 2:
        return _buildHistoryTab();
      case 3:
        return _buildReportsTab();
      default:
        return _buildEarningsTab();
    }
  }

  // --- TAB 1: EARNINGS ANALYTICS TAB ---
  Widget _buildEarningsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Earning card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2637),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL EARNINGS',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA6ABBb),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'H',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '2,850 Coins',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Equivalent to \$28.50 USD',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2ECC71),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Custom Bar chart
          Text(
            'Weekly Earnings',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF131A28),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildWeeklyBar('M', 40, 60),
                    _buildWeeklyBar('T', 80, 120),
                    _buildWeeklyBar('W', 60, 90),
                    _buildWeeklyBar('T', 100, 150),
                    _buildWeeklyBar('F', 90, 135),
                    _buildWeeklyBar('S', 120, 180),
                    _buildWeeklyBar('S', 50, 75),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Extra Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCell('Talk Time', '420m', Icons.timer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCell('Picked Rate', '98.5%', Icons.check_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBar(String day, int coins, double height) {
    return Column(
      children: [
        Text(
          '$coins',
          style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFA6ABBb)),
        ),
        const SizedBox(height: 8),
        Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [Color(0xFFBA9EFF), Color(0xFFFF1493)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStatCell(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2637),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFBA9EFF), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(color: const Color(0xFFA6ABBb), fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: PAYOUT WITHDRAW TAB ---
  Widget _buildPayoutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Withdrawable balance card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2637),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WITHDRAWABLE CASH',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA6ABBb),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${_withdrawableBalance.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Minimum cash-out value is \$10.00.',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF707584),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Payout CTA Button
          ScalePressedButton(
            onTap: _withdrawableBalance >= 10.0
                ? _openPayoutDrawerSheet
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Minimum withdrawal is \$10.00')),
                    );
                  },
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: _withdrawableBalance >= 10.0
                    ? const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF00A86B)])
                    : null,
                color: _withdrawableBalance < 10.0 ? const Color(0xFF1E2637) : null,
                boxShadow: _withdrawableBalance >= 10.0
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00A86B).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'Request Payout Now',
                  style: GoogleFonts.poppins(
                    color: _withdrawableBalance >= 10.0 ? Colors.white : const Color(0xFF707584),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payout history note
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF131A28),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFBA9EFF), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Payouts are processed automatically every Tuesday. Funds take 2-3 business days to reach your account.',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFA6ABBb),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Opens Payout bottom sheet
  void _openPayoutDrawerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PayoutWithdrawSheet(
        amount: _withdrawableBalance,
        onSuccess: () {
          setState(() {
            _withdrawableBalance = 0.00;
          });
        },
      ),
    );
  }

  // --- TAB 3: CALLING HISTORY (GET /api/calls/history) ---
  Widget _buildHistoryTab() {
    final auth = context.watch<AuthProvider>();
    final historyProvider = context.watch<CallHistoryProvider>();
    final userId = auth.user?.uid ?? '';

    if (historyProvider.items.isEmpty && !historyProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        historyProvider.fetchHistory();
      });
    }

    if (historyProvider.isLoading && historyProvider.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A2BE2)),
        ),
      );
    }

    if (historyProvider.items.isEmpty) {
      return Center(
        child: Text(
          historyProvider.error ?? 'No call history yet',
          style: GoogleFonts.poppins(color: const Color(0xFFA6ABBb)),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF8A2BE2),
      onRefresh: () => historyProvider.fetchHistory(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        itemCount: historyProvider.items.length,
        itemBuilder: (context, index) {
          final call = historyProvider.items[index];
          final name = call.otherPartyName(userId);
          final avatar = 'https://i.pravatar.cc/150?u=$name';

          return CallHistoryCard(
            call: call,
            currentUserId: userId,
            isCreatorView: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallDetailsScreen(
                    call: call,
                    currentUserId: userId,
                    avatarUrl: avatar,
                    isCreatorView: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- TAB 4: REVIEWS & BUG REPORTS TAB ---
  Widget _buildReportsTab() {
    final List<Map<String, dynamic>> reviews = [
      {
        'user': 'Arjun',
        'rating': 5,
        'comment': 'Very helpful listener, helped me feel better! 💖',
        'time': '2d ago',
      },
      {
        'user': 'Vijay',
        'rating': 5,
        'comment': 'Warm voice and great advice. Thanks!',
        'time': '3d ago',
      },
      {
        'user': 'Sangeetha',
        'rating': 4,
        'comment': 'So friendly and easy to talk to!',
        'time': '1w ago',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviews stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2637),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RATING STATS',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFA6ABBb),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '4.92 / 5.0',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.star, color: Colors.amber, size: 48),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // User reviews list
          Text(
            'Caller Reviews',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...reviews.map((rev) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131A28),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rev['user'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        rev['time'],
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF707584),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        color: index < rev['rating'] ? Colors.amber : const Color(0xFF424855),
                        size: 14,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rev['comment'],
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFA6ABBb),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // Bug/User report button
          Text(
            'Support Center',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ScalePressedButton(
            onTap: _openReportDialog,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD73357).withOpacity(0.5)),
                color: const Color(0xFFD73357).withOpacity(0.05),
              ),
              child: Row(
                children: [
                  const Icon(Icons.report_problem_outlined, color: Color(0xFFD73357), size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Bug or File Dispute',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Report call abuse, payment issues, or system crashes.',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFA6ABBb),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 110), // Bottom navbar gap
        ],
      ),
    );
  }

  // Opens Mock Bug Report Dialog
  void _openReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131A28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF424855)),
        ),
        title: Text(
          'File a Report',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify report details below. Our support agents will contact you shortly.',
              style: GoogleFonts.poppins(color: const Color(0xFFA6ABBb), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter report details...',
                hintStyle: const TextStyle(color: Color(0xFF707584)),
                filled: true,
                fillColor: const Color(0xFF080E1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF424855)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFBA9EFF)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF707584))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted successfully!'),
                  backgroundColor: Color(0xFF2ECC71),
                ),
              );
            },
            child: Text('Submit', style: GoogleFonts.poppins(color: const Color(0xFFD73357))),
          ),
        ],
      ),
    );
  }
}

// --- PAYOUT WITHDRAW SHEET DRAWER ---
class _PayoutWithdrawSheet extends StatefulWidget {
  final double amount;
  final VoidCallback onSuccess;
  const _PayoutWithdrawSheet({required this.amount, required this.onSuccess});

  @override
  State<_PayoutWithdrawSheet> createState() => _PayoutWithdrawSheetState();
}

class _PayoutWithdrawSheetState extends State<_PayoutWithdrawSheet> with SingleTickerProviderStateMixin {
  int _selectedMethod = 0; // 0: Bank, 1: UPI, 2: PayPal
  bool _isProcessing = false;
  bool _isSuccess = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.bounceOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _withdrawFunds() {
    setState(() {
      _isProcessing = true;
    });

    // Simulate verification delay
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
        _animController.forward();

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            widget.onSuccess();
            Navigator.pop(context);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131A28),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF424855),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          if (!_isProcessing && !_isSuccess) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Withdraw Funds',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF707584)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Color(0xFF424855)),
            const SizedBox(height: 12),

            // Cash info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Withdrawing Amount',
                    style: GoogleFonts.poppins(color: const Color(0xFFA6ABBb), fontSize: 14),
                  ),
                  Text(
                    '\$${widget.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: const Color(0xFF2ECC71),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment selections
            _buildPayoutOption(0, Icons.account_balance, 'Bank Account Transfer', 'Takes 2-3 business days'),
            const SizedBox(height: 8),
            _buildPayoutOption(1, Icons.phone_iphone, 'Instant UPI Cashout', 'Paytm, PhonePe, GPay'),
            const SizedBox(height: 8),
            _buildPayoutOption(2, Icons.payment, 'PayPal Wallet', 'Charges 2.5% transaction fee'),
            const SizedBox(height: 24),

            // Submit Button
            ScalePressedButton(
              onTap: _withdrawFunds,
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFBA9EFF), Color(0xFFFF1493)],
                  ),
                ),
                child: Center(
                  child: Text(
                    'Confirm Payout Request',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ] else if (_isProcessing) ...[
            const SizedBox(height: 40),
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBA9EFF)),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Verifying details...',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Securing connection with Bank nodes',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF707584),
              ),
            ),
            const SizedBox(height: 40),
          ] else if (_isSuccess) ...[
            const SizedBox(height: 40),
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF2ECC71),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Disbursement Requested!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Funds will reach your account within 24 hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFFA6ABBb),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildPayoutOption(int index, IconData icon, String label, String sub) {
    bool isSel = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFBA9EFF).withOpacity(0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? const Color(0xFFBA9EFF) : const Color(0xFF424855),
            width: isSel ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSel ? const Color(0xFFBA9EFF) : const Color(0xFF707584), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    sub,
                    style: GoogleFonts.poppins(color: const Color(0xFF707584), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              isSel ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSel ? const Color(0xFFBA9EFF) : const Color(0xFF707584),
            ),
          ],
        ),
      ),
    );
  }
}

// --- FULLSCREEN RINGING SIMULATED INCOMING CALL OVERLAY ---
class _IncomingCallPickupOverlay extends StatefulWidget {
  final String name;
  final String avatar;
  final bool isVideo;
  final Future<void> Function() onDecline;
  final Future<void> Function() onAccept;

  const _IncomingCallPickupOverlay({
    required this.name,
    required this.avatar,
    this.isVideo = false,
    required this.onDecline,
    required this.onAccept,
  });

  @override
  State<_IncomingCallPickupOverlay> createState() => _IncomingCallPickupOverlayState();
}

class _IncomingCallPickupOverlayState extends State<_IncomingCallPickupOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 100),

            // Caller Portrait & Ringing pulse
            Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseScale.value,
                          child: Opacity(
                            opacity: _pulseOpacity.value,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFBA9EFF),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 162,
                      height: 162,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1E2637), width: 4),
                      ),
                    ),
                    CircleAvatar(
                      radius: 75,
                      backgroundImage: NetworkImage(widget.avatar),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Text(
                  widget.name,
                  style: GoogleFonts.poppins(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isVideo ? 'Incoming video call…' : 'Incoming voice call…',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFBA9EFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            // Controls Pickup vs Decline
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decline Button (Red)
                  ScalePressedButton(
                    onTap: () => widget.onDecline(),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD73357),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD73357).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(width: 50),
                  // Accept/Pickup Button (Green Gradient)
                  ScalePressedButton(
                    onTap: () => widget.onAccept(),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ADE80), Color(0xFF2ECC71)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2ECC71).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Icon(Icons.call, color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PRESSED BUTTON SCALE FEEDBACK ---
class ScalePressedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  const ScalePressedButton({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<ScalePressedButton> createState() => _ScalePressedButtonState();
}

class _ScalePressedButtonState extends State<ScalePressedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _controller.forward() : null,
      onTapUp: widget.enabled
          ? (_) {
              _controller.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
