import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

import '../constants/home_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/call_history_provider.dart';
import '../utils/home_responsive.dart';
import '../widgets/common/app_shimmer.dart';
import 'recharge_screen.dart' hide ScalePressedButton;
import 'listener_application_screen.dart';
import 'listener_dashboard_screen.dart' hide ScalePressedButton;

class ProfileScreen extends StatefulWidget {
  final Function(int)? onTabChanged;
  const ProfileScreen({super.key, this.onTabChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeInAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );
    _entryController.forward();

    // Fetch call history and wallet on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.accessToken != null) {
        context.read<WalletProvider>().loadWallet(reason: 'profileInit');
        context.read<CallHistoryProvider>().fetchHistory();
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final auth = context.read<AuthProvider>();
    if (auth.accessToken != null) {
      await Future.wait([
        auth.refreshRole(),
        context.read<WalletProvider>().loadWallet(reason: 'profileRefresh'),
        context.read<CallHistoryProvider>().fetchHistory(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final history = context.watch<CallHistoryProvider>();

    if (auth.isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: ProfileSkeletonLoader(),
      );
    }

    if (auth.user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _buildEmptyState(),
      );
    }

    final user = auth.user!;
    final isListener = auth.isListener;

    // Dynamically calculate call stats from CallHistoryProvider
    final userCalls = history.items;
    final totalCalls = userCalls.length;
    final voiceCalls = userCalls.where((c) => c.type == 'voice').length;
    final videoCalls = userCalls.where((c) => c.type == 'video').length;

    // Rating / reviews count
    final double ratingVal = isListener
        ? (auth.listenerProfile?['rating'] as num? ?? 4.8).toDouble()
        : 5.0;
    final int reviewsCount = isListener
        ? (auth.listenerProfile?['reviews_count'] as int? ??
            auth.listenerProfile?['completedCalls'] as int? ??
            230)
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: RefreshIndicator(
          color: HomeTheme.primary,
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                HomeResponsive.w(context, 20),
                HomeResponsive.w(context, 16),
                HomeResponsive.w(context, 20),
                HomeResponsive.w(context, 120), // Clearance for Bottom Navigation
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profile Header
                  _buildHeader(context),
                  SizedBox(height: HomeResponsive.w(context, 24)),

                  // 2. User Info Card Section
                  _buildUserInfoSection(context, auth, user, isListener, ratingVal, reviewsCount),
                  SizedBox(height: HomeResponsive.w(context, 24)),

                  // 3. Wallet Card
                  _buildWalletCard(context, wallet),
                  SizedBox(height: HomeResponsive.w(context, 24)),

                  // 4. Stats Cards Grid
                  _buildStatsSection(context, totalCalls, voiceCalls, videoCalls, ratingVal, isListener),
                  SizedBox(height: HomeResponsive.w(context, 24)),

                  // 5. Go Premium & Become a Listener dual cards
                  _buildPremiumBecomeListenerRow(context, auth, isListener),
                  SizedBox(height: HomeResponsive.w(context, 24)),

                  // 6. Menu Section
                  _buildMenuSection(context, auth, isListener),
                  SizedBox(height: HomeResponsive.w(context, 24)),

                  // 7. Logout Button
                  _buildLogoutButton(context, auth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: HomeResponsive.w(context, 42),
            fontWeight: FontWeight.bold,
            color: HomeTheme.textPrimary,
          ),
        ),
        Row(
          children: [
            // Notifications Badge Button
            _HeaderBadgeButton(
              icon: Icons.notifications_none_rounded,
              badgeCount: 3,
              onTap: () => _showNotificationsBottomSheet(context),
            ),
            SizedBox(width: HomeResponsive.w(context, 12)),
            // Settings Button
            ScalePressedButton(
              onTap: () => _showSettingsBottomSheet(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF2D6E5)),
                  boxShadow: HomeTheme.softShadow,
                ),
                child: const Icon(Icons.settings_outlined, color: HomeTheme.primary, size: 24),
              ),
            ),
          ],
        )
      ],
    );
  }

  // --- USER PROFILE SECTION ---
  Widget _buildUserInfoSection(
    BuildContext context,
    AuthProvider auth,
    AppUser user,
    bool isListener,
    double ratingVal,
    int reviewsCount,
  ) {
    final avatarUrl = user.avatarUrl ?? 'https://lh3.googleusercontent.com/aida-public/AB6AXuDOP4FplSKyT3BfvOwZNGB_Hbamv85ajgLxN149snQwvYJ6mtcWe5XUW6ho4JDpgPPu7J_ejkrjQSS8fD__9JiHbpyoOSKHVJ8AtROBAaNiXKsf70Mv43lFx78hB39d7hdYu4tCKOx6cT4LQLQnZWhE4iMaYQeRx64Abti4ceA87z9KX5bGM_xdj32byrKrRo6K8B2_97XcPpmuc3_PN9iTdik5-9uwgxbPWHPqhEzBSQdAv18RJKoZ0PVepL8S220Mr3OPrKaz9rk';
    final bioText = isListener
        ? (auth.listenerProfile?['bio'] as String? ?? 'Happy Listener 💗')
        : 'Happy Caller 💗';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with Scale In
            _AvatarScaleIn(
              avatarUrl: avatarUrl,
              onTap: () => _showEditProfileSheet(context, auth),
            ),
            SizedBox(width: HomeResponsive.w(context, 16)),
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: HomeResponsive.w(context, 22),
                            fontWeight: FontWeight.bold,
                            color: HomeTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Pink verified badge
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: HomeTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                      ),
                    ],
                  ),
                  SizedBox(height: HomeResponsive.w(context, 2)),
                  Text(
                    bioText,
                    style: GoogleFonts.poppins(
                      fontSize: HomeResponsive.w(context, 13),
                      color: HomeTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: HomeResponsive.w(context, 4)),
                  // Reviews & Stars
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star_rounded,
                            color: index < ratingVal.round()
                                ? HomeTheme.starYellow
                                : const Color(0xFFE5E7EB),
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ratingVal.toStringAsFixed(1)} ${isListener ? '($reviewsCount Reviews)' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: HomeResponsive.w(context, 12),
                          fontWeight: FontWeight.w600,
                          color: HomeTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: HomeResponsive.w(context, 4)),
                  // Online indicator
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: HomeTheme.onlineGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Online',
                        style: GoogleFonts.poppins(
                          fontSize: HomeResponsive.w(context, 12),
                          fontWeight: FontWeight.w600,
                          color: HomeTheme.onlineGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit Profile Button (Tablet-first or aligns next to info if fits)
            if (isWide) ...[
              SizedBox(width: HomeResponsive.w(context, 16)),
              _buildEditProfileButton(context, auth),
            ]
          ],
        );
      },
    );
  }

  // --- EDIT PROFILE OUTLINED BUTTON ---
  Widget _buildEditProfileButton(BuildContext context, AuthProvider auth) {
    return ScalePressedButton(
      onTap: () => _showEditProfileSheet(context, auth),
      child: Container(
        width: HomeResponsive.w(context, 140).clamp(110.0, 170.0),
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HomeTheme.primary, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_outlined, color: HomeTheme.primary, size: 16),
            const SizedBox(width: 6),
            Text(
              'Edit Profile',
              style: GoogleFonts.poppins(
                color: HomeTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WALLET CARD ---
  Widget _buildWalletCard(BuildContext context, WalletProvider wallet) {
    return _WalletSlideDown(
      child: Container(
        height: HomeResponsive.w(context, 170),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: HomeTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: HomeTheme.primary.withValues(alpha: 0.25),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Available Balance Labels & White buttons
              Padding(
                padding: EdgeInsets.all(HomeResponsive.w(context, 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: HomeResponsive.w(context, 14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            // Gold Coin badge
                            Container(
                              width: HomeResponsive.w(context, 32),
                              height: HomeResponsive.w(context, 32),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFDBA21),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'H',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: HomeResponsive.w(context, 16),
                                ),
                              ),
                            ),
                            SizedBox(width: HomeResponsive.w(context, 8)),
                            Flexible(
                              child: Text(
                                _formatCoins(wallet.balance),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: HomeResponsive.w(context, 48),
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            SizedBox(width: HomeResponsive.w(context, 6)),
                            Text(
                              'Coins',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: HomeResponsive.w(context, 14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Add Coins
                        ScalePressedButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CoinRechargeScreen()),
                            ).then((_) => wallet.loadWallet(reason: 'rechargeReturn'));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Add Coins',
                              style: GoogleFonts.poppins(
                                color: HomeTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: HomeResponsive.w(context, 12)),
                        // Transaction History
                        ScalePressedButton(
                          onTap: () => _showTransactionsBottomSheet(context, wallet),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              'Transaction History',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Floating Illustration (Infinite Bouncing Card)
              Positioned(
                right: HomeResponsive.w(context, -10),
                top: HomeResponsive.w(context, 10),
                child: BouncingIllustration(
                  child: Image.asset(
                    'assets/illustrations/balance_coins_header.png',
                    width: HomeResponsive.w(context, 160),
                    height: HomeResponsive.w(context, 130),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback illustration using simple CSS-style vector
                      return Container(
                        width: 120,
                        height: 100,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 72,
                          color: Colors.white24,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STATS SECTION ---
  Widget _buildStatsSection(
    BuildContext context,
    int totalCalls,
    int voiceCalls,
    int videoCalls,
    double ratingVal,
    bool isListener,
  ) {
    final cardW = (MediaQuery.sizeOf(context).width - HomeResponsive.w(context, 40) - 36) / 4;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatsCard(
          context: context,
          width: cardW,
          icon: Icons.phone_callback_rounded,
          color: const Color(0xFFFF4DA6),
          value: totalCalls,
          label: 'Total Calls',
        ),
        _buildStatsCard(
          context: context,
          width: cardW,
          icon: Icons.phone_rounded,
          color: const Color(0xFF2ECC71),
          value: voiceCalls,
          label: 'Voice Calls',
        ),
        _buildStatsCard(
          context: context,
          width: cardW,
          icon: Icons.videocam_rounded,
          color: const Color(0xFFBA9EFF),
          value: videoCalls,
          label: 'Video Calls',
        ),
        _buildStatsCard(
          context: context,
          width: cardW,
          icon: Icons.star_rounded,
          color: const Color(0xFFFDBA21),
          value: ratingVal,
          label: isListener ? 'Your Rating' : 'User Rating',
        ),
      ],
    );
  }

  Widget _buildStatsCard({
    required BuildContext context,
    required double width,
    required IconData icon,
    required Color color,
    required num value,
    required String label,
  }) {
    return Container(
      width: width,
      height: HomeResponsive.w(context, 130),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: HomeTheme.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(height: HomeResponsive.w(context, 8)),
          CountUpText(
            value: value,
            style: GoogleFonts.poppins(
              fontSize: HomeResponsive.w(context, 18),
              fontWeight: FontWeight.bold,
              color: HomeTheme.textPrimary,
            ),
          ),
          SizedBox(height: HomeResponsive.w(context, 2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: HomeResponsive.w(context, 10),
                fontWeight: FontWeight.w600,
                color: HomeTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _openCreatorDashboard(BuildContext context, AuthProvider auth) {
    if (widget.onTabChanged != null && auth.isActiveCreator) {
      widget.onTabChanged!(3);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ListenerDashboardScreen()),
    );
  }

  // --- PREMIUM + LISTENER / EARNINGS ROW ---
  Widget _buildPremiumBecomeListenerRow(BuildContext context, AuthProvider auth, bool isListener) {
    final isActiveCreator = auth.isActiveCreator;
    return Row(
      children: [
        // Card 1: Go Premium
        Expanded(
          child: PremiumGlowCard(
            child: Container(
              height: HomeResponsive.w(context, 140),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8FB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD1E8), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1493).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFF1493), size: 24),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF1493), size: 14),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Go Premium',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: HomeTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle_rounded, color: Color(0xFFFF1493), size: 12),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Unlock exclusive benefits & features.',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: HomeTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium subscriptions are coming soon!')),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        // Card 2: Start Earnings (active creator) or Become a Listener
        Expanded(
          child: FloatingCard(
            child: Container(
              height: HomeResponsive.w(context, 140),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8FB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD1E8), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4DA6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isActiveCreator ? Icons.payments_rounded : Icons.mic_rounded,
                          color: const Color(0xFFFF4DA6),
                          size: 24,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF4DA6), size: 14),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActiveCreator ? 'Start Earnings' : 'Become a Listener',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: HomeTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActiveCreator
                            ? 'Open your creator dashboard and earn from calls.'
                            : 'Start earning by helping people via calls.',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: HomeTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            onTap: () {
              if (isActiveCreator) {
                _openCreatorDashboard(context, auth);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ListenerApplicationScreen()),
                ).then((_) => auth.refreshRole());
              }
            },
          ),
        ),
      ],
    );
  }

  // --- MENU SECTION ---
  Widget _buildMenuSection(BuildContext context, AuthProvider auth, bool isListener) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: HomeTheme.softShadow,
      ),
      child: Column(
        children: [
          _buildMenuItem(
            index: 0,
            icon: Icons.favorite_outline_rounded,
            title: 'My Favorites',
            subtitle: 'Your favorite listeners',
            onTap: () {
              if (widget.onTabChanged != null) {
                widget.onTabChanged!(1); // Go to Calls Tab
              }
            },
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            index: 1,
            icon: Icons.history_rounded,
            title: 'Call History',
            subtitle: 'View your call history',
            onTap: () {
              if (widget.onTabChanged != null) {
                widget.onTabChanged!(1); // Go to Calls Tab
              }
            },
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            index: 2,
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Manage your notifications',
            onTap: () => _showNotificationsBottomSheet(context),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            index: 3,
            icon: Icons.card_giftcard_rounded,
            title: 'Gift History',
            subtitle: 'View gifts you\'ve sent',
            onTap: () => _showGiftHistoryBottomSheet(context),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            index: 4,
            icon: Icons.share_rounded,
            title: 'Invite & Earn',
            subtitle: 'Invite friends and earn coins',
            onTap: () => _showInviteBottomSheet(context),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            index: 5,
            icon: Icons.headset_mic_outlined,
            title: 'Help & Support',
            subtitle: 'Get help and support',
            onTap: () => _showHelpSupportBottomSheet(context),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            index: 6,
            icon: Icons.info_outline_rounded,
            title: 'About Us',
            subtitle: 'Learn more about us',
            onTap: () => _showAboutDialog(context),
          ),
          _buildMenuDivider(),
          // Highlighted Become a Listener special menu row
          _buildBecomeListenerMenuRow(context, auth, isListener),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _StaggerMenuItem(
      index: index,
      child: ScalePressedButton(
        onTap: onTap,
        pressedScale: 0.97,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: Colors.transparent,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8FB),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: HomeTheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: HomeTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: HomeTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD1D5DB), size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBecomeListenerMenuRow(BuildContext context, AuthProvider auth, bool isListener) {
    final isActiveCreator = auth.isActiveCreator;
    return ScalePressedButton(
      onTap: () {
        if (isActiveCreator) {
          _openCreatorDashboard(context, auth);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ListenerApplicationScreen()),
          ).then((_) => auth.refreshRole());
        }
      },
      pressedScale: 0.97,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF5FA), // Highlight background
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActiveCreator ? Icons.payments_rounded : Icons.star_border_purple500_rounded,
                color: HomeTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isActiveCreator ? 'Start Earnings' : 'Become a Listener',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: HomeTheme.primary,
                        ),
                      ),
                      if (!isActiveCreator) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: HomeTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    isActiveCreator
                        ? 'Go to your creator dashboard'
                        : 'Create your profile and start earning',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: HomeTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: HomeTheme.primary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return const Divider(
      color: Color(0xFFF3F4F6),
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    );
  }

  // --- LOGOUT BUTTON ---
  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return ScalePressedButton(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Text('Are you sure you want to sign out from Hi ma?', style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins(color: HomeTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Sign Out', style: GoogleFonts.poppins(color: HomeTheme.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await auth.signOut();
        }
      },
      child: Container(
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: HomeTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                color: HomeTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MOCK DETAILS BOTTOM SHEETS ---

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Notifications',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: HomeTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              _buildNotificationItem(
                title: 'Recharge Success 🪙',
                desc: 'Your recharge of 1,000 Coins was successful. Start calling listeners now!',
                time: '2 hours ago',
              ),
              const Divider(color: Color(0xFFF3F4F6)),
              _buildNotificationItem(
                title: 'New Gift Received 🎁',
                desc: 'Anjali Verma sent you a Magic Diamond emoji. Check your dashboard!',
                time: '1 day ago',
              ),
              const Divider(color: Color(0xFFF3F4F6)),
              _buildNotificationItem(
                title: 'Verified Listener approved! ✅',
                desc: 'Congratulations, Priya Sharma is now verified. Call her for a warm chat.',
                time: '3 days ago',
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({required String title, required String desc, required String time}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: HomeTheme.textPrimary)),
              Text(time, style: GoogleFonts.poppins(fontSize: 10, color: HomeTheme.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: HomeTheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Settings',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: HomeTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              _buildSettingsRow(icon: Icons.volume_up_outlined, title: 'Call Ringtone & Sounds'),
              _buildSettingsRow(icon: Icons.lock_outline_rounded, title: 'Privacy & Security'),
              _buildSettingsRow(icon: Icons.language_rounded, title: 'App Language'),
              _buildSettingsRow(icon: Icons.delete_outline_rounded, title: 'Delete Account', isDestructive: true),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsRow({required IconData icon, required String title, bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : HomeTheme.textPrimary;
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.redAccent : HomeTheme.primary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD1D5DB), size: 14),
          ],
        ),
      ),
    );
  }

  void _showGiftHistoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Gift History',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: HomeTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              _buildGiftHistoryItem(giftName: 'Sweet Rose 🌹', receiver: 'Priya Sharma', cost: 10, date: 'June 4, 2026'),
              const Divider(color: Color(0xFFF3F4F6)),
              _buildGiftHistoryItem(giftName: 'Shiny Crown 👑', receiver: 'Anjali Verma', cost: 50, date: 'May 28, 2026'),
              const Divider(color: Color(0xFFF3F4F6)),
              _buildGiftHistoryItem(giftName: 'Magic Diamond 💎', receiver: 'Neha Kapoor', cost: 100, date: 'May 12, 2026'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGiftHistoryItem({
    required String giftName,
    required String receiver,
    required int cost,
    required String date,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(giftName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: HomeTheme.textPrimary)),
              const SizedBox(height: 2),
              Text('Sent to $receiver', style: GoogleFonts.poppins(fontSize: 11, color: HomeTheme.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$cost Coins', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: HomeTheme.primary)),
              const SizedBox(height: 2),
              Text(date, style: GoogleFonts.poppins(fontSize: 10, color: HomeTheme.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  void _showTransactionsBottomSheet(BuildContext context, WalletProvider wallet) {
    wallet.fetchTransactions();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final walletWatch = context.watch<WalletProvider>();
            return Container(
              height: MediaQuery.sizeOf(context).height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Transaction History',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: HomeTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: walletWatch.isLoadingTransactions
                        ? const ListSkeletonLoader(itemCount: 8, itemHeight: 64)
                        : walletWatch.transactions.isEmpty
                            ? Center(
                                child: Text(
                                  'No transactions yet.',
                                  style: GoogleFonts.poppins(color: HomeTheme.textSecondary, fontSize: 14),
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: walletWatch.transactions.length,
                                itemBuilder: (context, index) {
                                  final tx = walletWatch.transactions[index];
                                  final isAddition = tx.amount > 0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (tx.description ?? '').isNotEmpty ? tx.description! : tx.displayTitle,
                                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: HomeTheme.textPrimary),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              tx.formattedDate(),
                                              style: GoogleFonts.poppins(fontSize: 10, color: HomeTheme.textSecondary, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${isAddition ? '+' : ''}${tx.amount} Coins',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isAddition ? HomeTheme.onlineGreen : HomeTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showInviteBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Invite & Earn 🎁',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: HomeTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Invite your friends to Hi ma. Once they complete their first recharge, both of you will get 100 bonus Coins!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: HomeTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              // Referral code copy area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD1E8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HIMA500',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: HomeTheme.primary, letterSpacing: 1.5),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: HomeTheme.primary),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Referral code copied successfully!'),
                            backgroundColor: HomeTheme.onlineGreen,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showHelpSupportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Help & Support',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: HomeTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'If you experience payment issues, voice calling drops, or need support with your profile, please reach out to us at:',
                style: GoogleFonts.poppins(fontSize: 13, color: HomeTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildSupportRow(icon: Icons.email_outlined, title: 'support@hima.com'),
              _buildSupportRow(icon: Icons.chat_bubble_outline_rounded, title: 'Live Support Chat (WhatsApp)'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportRow({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: HomeTheme.primary, size: 22),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: HomeTheme.textPrimary)),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('About Us', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi ma is a premium coin-based voice and video calling platform where feelings connect.', style: GoogleFonts.poppins()),
            const SizedBox(height: 12),
            Text('Version: 1.1.22', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('© 2026 Hi ma Inc.', style: GoogleFonts.poppins(color: HomeTheme.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins(color: HomeTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- EDIT PROFILE SHEET ---
  void _showEditProfileSheet(BuildContext context, AuthProvider auth) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: auth.user?.displayName);
    final avatarController = TextEditingController(text: auth.user?.avatarUrl);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Edit Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: HomeTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Full Name Input
                    TextFormField(
                      controller: nameController,
                      style: GoogleFonts.poppins(color: HomeTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        labelStyle: GoogleFonts.poppins(color: HomeTheme.textSecondary),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: HomeTheme.primary, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),

                    // Avatar URL Input
                    TextFormField(
                      controller: avatarController,
                      style: GoogleFonts.poppins(color: HomeTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Avatar Image URL',
                        labelStyle: GoogleFonts.poppins(color: HomeTheme.textSecondary),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: HomeTheme.primary, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ScalePressedButton(
                      onTap: isSaving
                          ? () {}
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isSaving = true);
                              try {
                                await auth.updateProfile(
                                  fullName: nameController.text.trim(),
                                  avatarUrl: avatarController.text.trim().isNotEmpty
                                      ? avatarController.text.trim()
                                      : null,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile updated successfully!'),
                                      backgroundColor: HomeTheme.onlineGreen,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to update profile. Please try again.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Container(
                        height: 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: HomeTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: isSaving
                            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                            : Text(
                                'Save Changes',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- EMPTY STATE ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 84, color: HomeTheme.primary),
            const SizedBox(height: 20),
            Text(
              'Profile Not Loaded',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HomeTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please sign in or retry loading your profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: HomeTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ScalePressedButton(
              onTap: _handleRefresh,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: HomeTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Retry Connection',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCoins(int amount) {
    final formatter = NumberFormat('#,##,###');
    try {
      return formatter.format(amount);
    } catch (_) {
      return amount.toString();
    }
  }
}

// Helpers for formatted coin counts
class NumberFormat {
  final String pattern;
  NumberFormat(this.pattern);

  String format(int value) {
    String str = value.toString();
    if (str.length <= 3) return str;
    String lastThree = str.substring(str.length - 3);
    String remaining = str.substring(0, str.length - 3);
    String out = '';
    while (remaining.length > 2) {
      out = ',${remaining.substring(remaining.length - 2)}$out';
      remaining = remaining.substring(0, remaining.length - 2);
    }
    return '$remaining$out,$lastThree';
  }
}

// --- SUB-WIDGETS & ANIMATIONS ---

class _HeaderBadgeButton extends StatefulWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _HeaderBadgeButton({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  State<_HeaderBadgeButton> createState() => _HeaderBadgeButtonState();
}

class _HeaderBadgeButtonState extends State<_HeaderBadgeButton> with SingleTickerProviderStateMixin {
  late AnimationController _badgeController;
  late Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _badgeScale = CurvedAnimation(parent: _badgeController, curve: Curves.elasticOut);
    
    // Delayed pop animation for badge on start
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _badgeController.forward();
    });
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScalePressedButton(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF2D6E5)),
              boxShadow: HomeTheme.softShadow,
            ),
            child: Icon(widget.icon, color: HomeTheme.primary, size: 24),
          ),
          if (widget.badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: ScaleTransition(
                scale: _badgeScale,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF1493),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                    child: Text(
                      '${widget.badgeCount}',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarScaleIn extends StatefulWidget {
  final String avatarUrl;
  final VoidCallback onTap;

  const _AvatarScaleIn({required this.avatarUrl, required this.onTap});

  @override
  State<_AvatarScaleIn> createState() => _AvatarScaleInState();
}

class _AvatarScaleInState extends State<_AvatarScaleIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Stack(
        children: [
          // Outer glowing avatar container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: HomeTheme.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: HomeTheme.primary.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.avatarUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: const Color(0xFFFFF8FB)),
                errorWidget: (context, url, error) => Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDOP4FplSKyT3BfvOwZNGB_Hbamv85ajgLxN149snQwvYJ6mtcWe5XUW6ho4JDpgPPu7J_ejkrjQSS8fD__9JiHbpyoOSKHVJ8AtROBAaNiXKsf70Mv43lFx78hB39d7hdYu4tCKOx6cT4LQLQnZWhE4iMaYQeRx64Abti4ceA87z9KX5bGM_xdj32byrKrRo6K8B2_97XcPpmuc3_PN9iTdik5-9uwgxbPWHPqhEzBSQdAv18RJKoZ0PVepL8S220Mr3OPrKaz9rk',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Floating Edit Button
          Positioned(
            bottom: 0,
            right: 0,
            child: ScalePressedButton(
              onTap: widget.onTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: HomeTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletSlideDown extends StatefulWidget {
  final Widget child;
  const _WalletSlideDown({required this.child});

  @override
  State<_WalletSlideDown> createState() => _WalletSlideDownState();
}

class _WalletSlideDownState extends State<_WalletSlideDown> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0.0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: widget.child,
    );
  }
}

class BouncingIllustration extends StatefulWidget {
  final Widget child;
  const BouncingIllustration({super.key, required this.child});

  @override
  State<BouncingIllustration> createState() => _BouncingIllustrationState();
}

class _BouncingIllustrationState extends State<BouncingIllustration> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: -12.0).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}

class PremiumGlowCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const PremiumGlowCard({super.key, required this.child, required this.onTap});

  @override
  State<PremiumGlowCard> createState() => _PremiumGlowCardState();
}

class _PremiumGlowCardState extends State<PremiumGlowCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 2.0, end: 12.0).animate(
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
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return ScalePressedButton(
          onTap: widget.onTap,
          pressedScale: 0.96,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF1493).withValues(alpha: 0.12),
                  blurRadius: _glowAnimation.value,
                  spreadRadius: _glowAnimation.value / 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class FloatingCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const FloatingCard({super.key, required this.child, required this.onTap});

  @override
  State<FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<FloatingCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
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
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return ScalePressedButton(
          onTap: widget.onTap,
          pressedScale: 0.96,
          child: Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class CountUpText extends StatefulWidget {
  final num value;
  final TextStyle style;

  const CountUpText({
    super.key,
    required this.value,
    required this.style,
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: widget.value.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: oldWidget.value.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        if (widget.value is int) {
          return Text(val.round().toString(), style: widget.style);
        } else {
          return Text(val.toStringAsFixed(1), style: widget.style);
        }
      },
    );
  }
}

class _StaggerMenuItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggerMenuItem({required this.index, required this.child});

  @override
  State<_StaggerMenuItem> createState() => _StaggerMenuItemState();
}

class _StaggerMenuItemState extends State<_StaggerMenuItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Stagger fade-in delay
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.child,
    );
  }
}

class ScalePressedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final bool enabled;

  const ScalePressedButton({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.96,
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
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
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

// --- SHIMMER SKELETON LOADER ---
class ProfileSkeletonLoader extends StatelessWidget {
  const ProfileSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(HomeResponsive.w(context, 20)),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFFF3F4F6),
          highlightColor: const Color(0xFFF9FAFB),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 140, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                  Row(
                    children: [
                      Container(width: 48, height: 48, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Container(width: 48, height: 48, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Avatar & Info
              Row(
                children: [
                  Container(width: 100, height: 100, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 120, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                        const SizedBox(height: 8),
                        Container(width: 160, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 8),
                        Container(width: 80, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Wallet Hero Card
              Container(
                width: double.infinity,
                height: 170,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return Container(
                    width: (MediaQuery.sizeOf(context).width - HomeResponsive.w(context, 40) - 36) / 4,
                    height: 130,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Dual row
              Row(
                children: [
                  Expanded(child: Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)))),
                  const SizedBox(width: 16),
                  Expanded(child: Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)))),
                ],
              ),
              const SizedBox(height: 24),

              // Menu
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
