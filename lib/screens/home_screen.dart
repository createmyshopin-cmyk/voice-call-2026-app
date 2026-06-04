import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/creator_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/call_history_provider.dart';
import '../models/call_history_item.dart';
import '../services/call_service.dart';
import 'call_details_screen.dart';
import 'calling_screen.dart';
import '../widgets/call_history_card.dart';
import 'recharge_screen.dart';
import 'listener_dashboard_screen.dart';
import 'agora_debug_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  String _selectedFilter = 'All';

  // Track Favourites locally
  final Set<String> _favouriteUsers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger a fresh fetch if the list is empty (e.g. first load)
      final cp = context.read<CreatorProvider>();
      if (cp.creators.isEmpty && !cp.isLoading) {
        cp.fetchCreators();
      }
      final hp = context.read<CallHistoryProvider>();
      if (hp.items.isEmpty && !hp.isLoading) {
        hp.fetchHistory();
      }
    });
  }

  // Derives the filtered display list from CreatorProvider
  List<Map<String, dynamic>> _getFilteredUsers(List<Map<String, dynamic>> allUsers) {
    if (_selectedFilter == 'Chats \u00b7 FREE') {
      return allUsers.where((u) => u['isChatAvailable'] == true).toList();
    } else if (_selectedFilter == 'New') {
      return allUsers.where((u) => u['isNew'] == true).toList();
    }
    return allUsers;
  }

  Widget _buildCreatorsList(
    List<Map<String, dynamic>> filteredUsers,
    WalletProvider coinProvider, {
    bool isLoading = false,
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    if (isLoading && filteredUsers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
            ),
          ),
        ],
      );
    }

    if (errorMessage != null && filteredUsers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 200),
        children: [
          Icon(Icons.cloud_off, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF777777)),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: onRetry,
              child: Text('Retry', style: GoogleFonts.poppins(color: const Color(0xFFFF1493))),
            ),
          ),
        ],
      );
    }

    if (filteredUsers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 200),
        children: [
          Text(
            'No creators available right now.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF777777)),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 200),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user, coinProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinProvider = context.watch<WalletProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: _currentTabIndex == 3 ? const Color(0xFF080E1A) : const Color(0xFFF8F8F8),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Screen content based on current active bottom tab
            Positioned.fill(
              child: _buildTabContent(authProvider, coinProvider),
            ),

            // Fixed Bottom Navigation Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavBar(),
            ),

            // Floating Random Match Button (Visible only on the Home Tab)
            if (_currentTabIndex == 0)
              Positioned(
                bottom: 110,
                right: 20,
                child: BouncingRandomButton(
                  onTap: _startRandomMatch,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build content area depending on the selected tab
  Widget _buildTabContent(AuthProvider authProvider, WalletProvider coinProvider) {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeView(coinProvider);
      case 1:
        return _buildRecentView();
      case 2:
        return _buildFavouriteView();
      case 3:
        return _buildProfileView(authProvider, coinProvider);
      default:
        return _buildHomeView(coinProvider);
    }
  }

  // --- HOME VIEW ---
  Widget _buildHomeView(WalletProvider coinProvider) {
    final creatorProvider = context.watch<CreatorProvider>();
    final allUsers = creatorProvider.creators
        .map((c) => c.toUserCardMap())
        .toList();
    final filteredUsers = _getFilteredUsers(allUsers);

    return Column(
      children: [
        // Top Header
        _buildTopHeader(coinProvider),

        // Filter Tabs Row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterTab('Chats \u00b7 FREE'),
                const SizedBox(width: 12),
                _buildFilterTab('All'),
                const SizedBox(width: 12),
                _buildFilterTab('New'),
              ],
            ),
          ),
        ),

        // Live creators from GET /api/creators (Supabase via backend)
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF1493),
            onRefresh: () => context.read<CreatorProvider>().fetchCreators(),
            child: _buildCreatorsList(
              filteredUsers,
              coinProvider,
              isLoading: creatorProvider.isLoading,
              errorMessage: creatorProvider.error,
              onRetry: () => context.read<CreatorProvider>().fetchCreators(),
            ),
          ),
        ),
      ],
    );
  }

  // --- RECENT VIEW (GET /api/calls/history) ---
  Widget _buildRecentView() {
    final auth = context.watch<AuthProvider>();
    final historyProvider = context.watch<CallHistoryProvider>();
    final creators = context.watch<CreatorProvider>().creators;
    final userId = auth.user?.uid ?? '';

    String avatarFor(CallHistoryItem call) {
      final otherId = call.otherPartyId(userId);
      final match = creators.where((c) => c.id == otherId);
      if (match.isNotEmpty) return match.first.avatar;
      final name = call.otherPartyName(userId);
      return 'https://i.pravatar.cc/150?u=$name';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            'Recent Calls',
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF1493),
            onRefresh: () => historyProvider.fetchHistory(),
            child: _buildRecentCallsList(
              historyProvider,
              userId,
              avatarFor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCallsList(
    CallHistoryProvider historyProvider,
    String userId,
    String Function(CallHistoryItem) avatarFor,
  ) {
    if (historyProvider.isLoading && historyProvider.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
            ),
          ),
        ],
      );
    }

    if (historyProvider.error != null && historyProvider.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 200),
        children: [
          Icon(Icons.cloud_off, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            historyProvider.error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF777777)),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => historyProvider.fetchHistory(),
              child: Text('Retry', style: GoogleFonts.poppins(color: const Color(0xFFFF1493))),
            ),
          ),
        ],
      );
    }

    if (historyProvider.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 200),
        children: [
          Icon(Icons.history, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No calls yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          Text(
            'Your completed calls will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF777777)),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      itemCount: historyProvider.items.length,
      itemBuilder: (context, index) {
        final call = historyProvider.items[index];
        final avatar = avatarFor(call);

        return CallHistoryCard(
          call: call,
          currentUserId: userId,
          isCreatorView: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CallDetailsScreen(
                  call: call,
                  currentUserId: userId,
                  avatarUrl: avatar,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- FAVOURITE VIEW ---
  Widget _buildFavouriteView() {
    final allUsers = context.read<CreatorProvider>().creators
        .map((c) => c.toUserCardMap())
        .toList();
    final favorites = allUsers.where((u) => _favouriteUsers.contains(u['name'])).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            'Favourites',
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        Expanded(
          child: favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border, size: 64, color: Color(0xFF777777)),
                      const SizedBox(height: 16),
                      Text(
                        'No favourites added yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the heart icon on any user card.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final user = favorites[index];
                    return _buildUserCard(user, context.watch<WalletProvider>());
                  },
                ),
        ),
      ],
    );
  }

  // --- PROFILE VIEW ---
  Widget _buildProfileView(AuthProvider authProvider, WalletProvider coinProvider) {
    String uidText = authProvider.user?.uid ?? 'a066dfb3-';
    if (uidText.length > 9) {
      uidText = '${uidText.substring(0, 9)}-';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 1. Top Card (Avatar & UID)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2637),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Top Right Pencil edit button
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile edit is coming soon!')),
                      );
                    },
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                ),
                // Avatar + Name column
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 106,
                        height: 106,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF424855).withOpacity(0.5),
                        ),
                        alignment: Alignment.center,
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDOP4FplSKyT3BfvOwZNGB_Hbamv85ajgLxN149snQwvYJ6mtcWe5XUW6ho4JDpgPPu7J_ejkrjQSS8fD__9JiHbpyoOSKHVJ8AtROBAaNiXKsf70Mv43lFx78hB39d7hdYu4tCKOx6cT4LQLQnZWhE4iMaYQeRx64Abti4ceA87z9KX5bGM_xdj32byrKrRo6K8B2_97XcPpmuc3_PN9iTdik5-9uwgxbPWHPqhEzBSQdAv18RJKoZ0PVepL8S220Mr3OPrKaz9rk'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        uidText,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Menu Card (Wallet, Transactions, etc.)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E2637),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildProfileMenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Wallet',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CoinRechargeScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildProfileMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Transactions',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transactions list is coming soon!')),
                    );
                  },
                ),
                _buildDivider(),
                _buildProfileMenuItem(
                  icon: Icons.translate_outlined,
                  title: 'Language Settings',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language settings is coming soon!')),
                    );
                  },
                ),
                _buildDivider(),
                _buildProfileMenuItem(
                  icon: Icons.loop_outlined,
                  title: 'Switch to Listener',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListenerDashboardScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildProfileMenuItem(
                  icon: Icons.headset_mic_outlined,
                  title: 'Help & Support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support ticket system is coming soon!')),
                    );
                  },
                ),
                _buildDivider(),
                _buildProfileMenuItem(
                  icon: Icons.bug_report_outlined,
                  title: 'Agora Debug',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AgoraDebugScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildProfileMenuItem(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Account Settings',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account settings is coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Log Out Card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E2637),
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildProfileMenuItem(
              icon: Icons.logout_outlined,
              title: 'Log Out',
              onTap: () async {
                await authProvider.signOut();
              },
            ),
          ),

          // 4. Version Info
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              'version 1.1.22',
              style: GoogleFonts.poppins(
                color: const Color(0xFF707584),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ScalePressedButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF707584),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Color(0xFF424855),
      height: 1,
      thickness: 0.8,
      indent: 20,
      endIndent: 20,
    );
  }

  // --- HEADER WIDGET ---
  Widget _buildTopHeader(WalletProvider coinProvider) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Title
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF1493), Color(0xFFFF4DA6)],
                    ),
                  ),
                  child: const Icon(
                    Icons.forum,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'HI ma',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF333333),
                          height: 1.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Where Feelings Connect',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF777777),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Coin Wallet Button
          ScalePressedButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoinRechargeScreen()),
              );
            },
            child: Container(
              width: 110,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF1493), Color(0xFFFF4DA6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1493).withOpacity(0.25),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Gold Coin Circle
                  Container(
                    width: 26,
                    height: 26,
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
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Coins Amount
                  Text(
                    '${coinProvider.balance}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FILTER TAB BUTTON ---
  Widget _buildFilterTab(String label) {
    bool isActive = _selectedFilter == label;
    return ScalePressedButton(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFFFF1493), Color(0xFFFF4DA6)],
                )
              : null,
          color: isActive ? null : Colors.white,
          border: isActive ? null : Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label.contains('Chats')) ...[
                Icon(
                  Icons.chat_bubble_outline,
                  color: isActive ? Colors.white : const Color(0xFF333333),
                  size: 16,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF333333),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- USER PROFILE CARD WIDGET ---
  Widget _buildUserCard(Map<String, dynamic> user, WalletProvider coinProvider) {
    final name = user['name'] as String;
    final isNew = user['isNew'] as bool;
    final isOnline = user['isOnline'] as bool;
    final lastSeenLabel =
        user['lastSeenLabel'] as String? ?? (isOnline ? 'Online' : 'Offline');
    final isVoiceAvailable = user['isVoiceAvailable'] as bool;
    final isChatAvailable = user['isChatAvailable'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Profile Avatar Stack
          Stack(
            alignment: Alignment.center,
            children: [
              // Soft pink ring
              Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF1493), Color(0xFFFF4DA6)],
                  ),
                ),
              ),
              // White space border ring
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              // Actual Avatar Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(user['avatar']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Online (green pulse) or offline (gray) dot on avatar
              Positioned(
                bottom: 0,
                right: 0,
                child: isOnline
                    ? const PulsingOnlineDot()
                    : Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9E9E9E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Right side: Name, Badge, CTAs
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // User Name & Badges Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Optional New User Badge
                    if (isNew) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF1493), Color(0xFFFF4DA6)],
                          ),
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Favourite Heart Toggle
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_favouriteUsers.contains(name)) {
                            _favouriteUsers.remove(name);
                          } else {
                            _favouriteUsers.add(name);
                          }
                        });
                      },
                      child: Icon(
                        _favouriteUsers.contains(name) ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFFFF1493),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lastSeenLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF707584),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // CTA Buttons Row (Voice Call & Chat)
                Row(
                  children: [
                    // Voice Call CTA
                    Expanded(
                      child: _buildCTAButton(
                        isAvailable: isVoiceAvailable,
                        icon: Icons.phone,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC85CFF), Color(0xFF8A2BE2)],
                        ),
                        labelText: '10/min',
                        onTap: () {
                          if (coinProvider.balance >= 50) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF131A28),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: const BorderSide(color: Color(0xFF424855)),
                                ),
                                title: Text(
                                  'Choose Call Type',
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  'Connect with $name via high-quality audio or video streaming.',
                                  style: GoogleFonts.poppins(color: const Color(0xFFA6ABBb)),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _initiateCall(user['id'] as String, name, user['avatar'] as String, false);
                                    },
                                    child: Text('Voice (10 coins/m)', style: GoogleFonts.poppins(color: const Color(0xFFBA9EFF))),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _initiateCall(user['id'] as String, name, user['avatar'] as String, true);
                                    },
                                    child: Text('Video (20 coins/m)', style: GoogleFonts.poppins(color: const Color(0xFF2ECC71))),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Minimum 50 coins required to start a call. Please recharge.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Chat CTA
                    Expanded(
                      child: _buildCTAButton(
                        isAvailable: isChatAvailable,
                        icon: Icons.chat_bubble,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2ECC71), Color(0xFF00A86B)],
                        ),
                        labelText: '60/min',
                        onTap: () async {
                          if (coinProvider.balance >= 60) {
                            await coinProvider.deductCoins(60);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Chat started with $name! 60 coins deducted.'),
                                  backgroundColor: const Color(0xFF00A86B),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Insufficient coins for Chat! Tap the wallet to claim free coins.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CTA CALL / CHAT BUTTON BUILDER ---
  Widget _buildCTAButton({
    required bool isAvailable,
    required IconData icon,
    required LinearGradient gradient,
    required String labelText,
    required VoidCallback onTap,
  }) {
    if (!isAvailable) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: const Color(0xFF9E9E9E), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Unavailable',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ScalePressedButton(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  // Gold coin icon inside button
                  Container(
                    width: 18,
                    height: 18,
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
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    labelText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- INITIATE CALL SESSION VIA BACKEND ---
  Future<void> _initiateCall(
    String listenerId,
    String name,
    String avatarUrl,
    bool isVideoCall,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final coinProvider = Provider.of<WalletProvider>(context, listen: false);
    final accessToken = auth.accessToken;

    if (accessToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to start a call.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 1. Minimum balance check (50 coins required to start a call)
    if (coinProvider.balance < 50) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Minimum 50 coins required to start a call. Please recharge.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 2. Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
        ),
      ),
    );

    try {
      final result = await CallService().requestCall(
        accessToken: accessToken,
        listenerId: listenerId,
        isVideo: isVideoCall,
      );

      await coinProvider.loadWallet();

      // Dismiss loading indicator
      if (mounted) Navigator.pop(context);

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallingScreen(
              channelName: result.channelName,
              displayName: name,
              avatarUrl: avatarUrl,
              isVideoCall: isVideoCall,
              callRequestId: result.callRequestId,
              callSessionId: result.callSessionId,
              agoraToken: result.agoraToken,
              agoraAppId: result.agoraAppId,
            ),
          ),
        );

        if (mounted) {
          coinProvider.loadWallet();
        }
      }
    } catch (e) {
      // Dismiss loading indicator
      if (mounted) Navigator.pop(context);
      
      String errorMsg = 'Failed to connect call.';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          errorMsg = data['message'].toString();
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- RANDOM MATCH ACTION ---
  void _startRandomMatch() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Matching',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _MatchingDialog(
            onlineUsers: context.read<CreatorProvider>().creators
                .map((c) => c.toUserCardMap())
                .toList());
      },
    ).then((matchedUser) {
      if (!mounted) return;
      if (matchedUser != null && matchedUser is Map<String, dynamic>) {
        final name = matchedUser['name'] as String;
        final isVideo = matchedUser['name'] == 'Arjun' || matchedUser['name'] == 'Vijay';
        _initiateCall(matchedUser['id'] as String, name, matchedUser['avatar'] as String, isVideo);
      }
    });
  }

  // --- FIXED BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavBar() {
    bool isDark = _currentTabIndex == 3;
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1320) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
          _buildBottomNavItem(Icons.access_time, Icons.access_time_filled, 'Recent', 1),
          _buildBottomNavItem(Icons.favorite_border, Icons.favorite, 'Favourite', 2),
          _buildBottomNavItem(Icons.person_outline, Icons.person, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData inactiveIcon, IconData activeIcon, String label, int index) {
    bool isActive = _currentTabIndex == index;
    bool isDark = _currentTabIndex == 3;
    Color inactiveColor = isDark ? const Color(0xFF707584) : const Color(0xFF777777);

    return ScalePressedButton(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      child: Container(
        width: 80,
        color: Colors.transparent, // expand touch target area
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive)
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFF1493), Color(0xFFFF4DA6)],
                ).createShader(bounds),
                child: Icon(
                  activeIcon,
                  color: Colors.white,
                  size: 26,
                ),
              )
            else
              Icon(
                inactiveIcon,
                color: inactiveColor,
                size: 26,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFFFF1493) : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PULSING ONLINE INDICATOR RING ---
class PulsingOnlineDot extends StatefulWidget {
  const PulsingOnlineDot({super.key});

  @override
  State<PulsingOnlineDot> createState() => _PulsingOnlineDotState();
}

class _PulsingOnlineDotState extends State<PulsingOnlineDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF2ECC71),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
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

// --- BOUNCING RANDOM MATCH BUTTON ---
class BouncingRandomButton extends StatefulWidget {
  final VoidCallback onTap;
  const BouncingRandomButton({super.key, required this.onTap});

  @override
  State<BouncingRandomButton> createState() => _BouncingRandomButtonState();
}

class _BouncingRandomButtonState extends State<BouncingRandomButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
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
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: child,
        );
      },
      child: ScalePressedButton(
        onTap: widget.onTap,
        child: Container(
          width: 220,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: const LinearGradient(
              colors: [Color(0xFF007AFF), Color(0xFF00C6FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007AFF).withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shuffle, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Random',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SPINNING RADAR MATCHING DIALOG ---
class _MatchingDialog extends StatefulWidget {
  final List<Map<String, dynamic>> onlineUsers;
  const _MatchingDialog({super.key, required this.onlineUsers});

  @override
  State<_MatchingDialog> createState() => _MatchingDialogState();
}

class _MatchingDialogState extends State<_MatchingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Automatically resolve match after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        // Choose a random user from online list who is available
        final onlineUsers = widget.onlineUsers
            .where((u) => u['isOnline'] == true && u['isVoiceAvailable'] == true)
            .toList();
        if (onlineUsers.isNotEmpty) {
          onlineUsers.shuffle();
          Navigator.pop(context, onlineUsers.first);
        } else {
          Navigator.pop(context, null);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.75),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulse waves
                ...List.generate(3, (index) {
                  final delay = index * 0.6;
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double progress = (_controller.value + delay) % 1.0;
                      double scale = progress * 3.5;
                      double opacity = (1.0 - progress) * 0.7;
                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF007AFF),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
                // Center icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007AFF), Color(0xFF00C6FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shuffle,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Text(
              'Connecting Feelings...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Searching for an active user',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
