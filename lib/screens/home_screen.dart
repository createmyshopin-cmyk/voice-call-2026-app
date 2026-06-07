import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/avatar_assets.dart';
import '../constants/home_theme.dart';
import '../models/creator.dart';
import '../providers/auth_provider.dart';
import '../providers/creator_heartbeat_provider.dart';
import '../providers/creator_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/listener/listener_online_navigation_lock.dart';
import '../providers/call_history_provider.dart';
import '../models/call_history_item.dart';
import '../services/call_service.dart';
import '../utils/api_error_message.dart';
import '../utils/home_responsive.dart';
import 'call_details_screen.dart';
import 'calling_screen.dart' hide ScalePressedButton;
import '../widgets/call_history_card.dart';
import '../widgets/home/featured_listener_card.dart';
import '../widgets/home/home_animations.dart';
import '../widgets/home/home_empty_state.dart';
import '../widgets/home/home_error_card.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_skeleton_loader.dart';
import '../widgets/home/promo_banner.dart';
import '../widgets/home/scale_pressed_button.dart';
import '../widgets/home/section_header.dart';
import '../widgets/home/wallet_hero_card.dart';
import '../widgets/home/home_category_chips.dart';
import '../widgets/home/home_lazy_sections.dart';
import '../widgets/home/lazy_horizontal_list.dart';
import '../widgets/home/listener_list_row_card.dart';
import '../widgets/home/pulsing_online_dot.dart';
import '../widgets/home/recent_joined_avatar.dart';
import '../widgets/home/top_rated_card.dart';
import 'recharge_screen.dart' hide ScalePressedButton;
import 'calls_screen.dart' hide ScalePressedButton;
import 'profile_screen.dart' hide ScalePressedButton;
import 'listener_dashboard_screen.dart' hide ScalePressedButton;
import 'listener_application_screen.dart';
import 'agora_debug_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  int? _lastLoggedBalance;
  bool _onlineExitDialogOpen = false;

  final Set<String> _favouriteCreatorIds = {};
  final HomeLazySections _lazySections = HomeLazySections();
  final ScrollController _homeScrollController = ScrollController();
  String _selectedCategory = 'all';

  static const _categoryIds = [
    'relationship',
    'marriage',
    'friendship',
    'love',
    'family',
  ];

  void _logDisplayedBalance(WalletProvider coinProvider, String surface) {
    if (_lastLoggedBalance == coinProvider.balance) return;
    _lastLoggedBalance = coinProvider.balance;
    debugPrint(
      '[HomeScreen] $surface displayed balance=${coinProvider.balance}',
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.accessToken != null) {
        context.read<WalletProvider>().loadWallet(reason: 'homeInit');
        final cp = context.read<CreatorProvider>();
        if (cp.creators.isEmpty && !cp.isLoading) {
          cp.fetchCreators();
        }
        final hp = context.read<CallHistoryProvider>();
        if (hp.items.isEmpty && !hp.isLoading) {
          hp.fetchHistory();
        }
      }
    });
    _lazySections.addListener(_onLazySectionsChanged);
  }

  void _onLazySectionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _lazySections.removeListener(_onLazySectionsChanged);
    _lazySections.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getTabs(AuthProvider authProvider) {
    if (authProvider.isListener) {
      return [
        {
          'label': 'Home',
          'icon': Icons.home_outlined,
          'activeIcon': Icons.home,
        },
        {
          'label': 'Calls',
          'icon': Icons.phone_outlined,
          'activeIcon': Icons.phone,
        },
        {
          'label': 'Wallet',
          'icon': Icons.account_balance_wallet_outlined,
          'activeIcon': Icons.account_balance_wallet,
        },
        {
          'label': 'Listener',
          'icon': Icons.headphones_outlined,
          'activeIcon': Icons.headphones,
        },
        {
          'label': 'Profile',
          'icon': Icons.person_outline,
          'activeIcon': Icons.person,
        },
      ];
    } else {
      return [
        {
          'label': 'Home',
          'icon': Icons.home_outlined,
          'activeIcon': Icons.home,
        },
        {
          'label': 'Calls',
          'icon': Icons.phone_outlined,
          'activeIcon': Icons.phone,
        },
        {
          'label': 'Wallet',
          'icon': Icons.account_balance_wallet_outlined,
          'activeIcon': Icons.account_balance_wallet,
        },
        {
          'label': 'Profile',
          'icon': Icons.person_outline,
          'activeIcon': Icons.person,
        },
      ];
    }
  }

  bool _isListenerOnlineLocked(AuthProvider auth, CreatorHeartbeatProvider heartbeat) =>
      auth.isListener && heartbeat.isActive;

  Future<void> _handleBlockedNavigationWhileOnline(int targetTabIndex) async {
    if (_onlineExitDialogOpen || !mounted) return;
    _onlineExitDialogOpen = true;
    final choice = await showListenerOnlineExitDialog(context);
    _onlineExitDialogOpen = false;
    if (!mounted || choice == null || choice == ListenerOnlineExitChoice.stayOnline) {
      return;
    }

    await context.read<CreatorHeartbeatProvider>().goOfflineAndWait();
    if (!mounted) return;
    setState(() => _currentTabIndex = targetTabIndex);
  }

  Future<void> _handleOnlineBackPress() async {
    if (_onlineExitDialogOpen || !mounted) return;
    _onlineExitDialogOpen = true;
    final choice = await showListenerOnlineExitDialog(context);
    _onlineExitDialogOpen = false;
    if (!mounted || choice == null || choice == ListenerOnlineExitChoice.stayOnline) {
      return;
    }
    await context.read<CreatorHeartbeatProvider>().goOfflineAndWait();
    if (!mounted) return;
    await SystemNavigator.pop();
  }

  void _onBottomNavTap(AuthProvider auth, CreatorHeartbeatProvider heartbeat, int index) {
    final isOnlineLocked = _isListenerOnlineLocked(auth, heartbeat);
    if (isOnlineLocked && isListenerTabBlockedWhenOnline(index)) {
      unawaited(_handleBlockedNavigationWhileOnline(index));
      return;
    }
    setState(() => _currentTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final coinProvider = context.watch<WalletProvider>();
    final authProvider = context.watch<AuthProvider>();
    final heartbeat = context.watch<CreatorHeartbeatProvider>();
    _logDisplayedBalance(coinProvider, 'build');
    final isListener = authProvider.isListener;
    final isOnlineLocked = _isListenerOnlineLocked(authProvider, heartbeat);
    final maxTabs = isListener ? 5 : 4;
    final activeIndex = _currentTabIndex.clamp(0, maxTabs - 1);

    final isListenerDashboardTab = isListener && (activeIndex == kListenerDashboardTabIndex);
    final isDarkBg = isListenerDashboardTab;

    final isHomeTab = activeIndex == 0;
    final showStickyPromo = _showsStickyPromo(activeIndex);
    final stickyBottomInset = showStickyPromo
        ? HomeResponsive.stickyPromoClearance(context)
        : HomeResponsive.bottomNavHeight(context);

    return PopScope(
      canPop: !isOnlineLocked,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (isOnlineLocked) {
          unawaited(_handleOnlineBackPress());
        }
      },
      child: Scaffold(
      backgroundColor: isDarkBg
          ? const Color(0xFF080E1A)
          : (isHomeTab ? HomeTheme.screenBackground : const Color(0xFFF8F8F8)),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(bottom: stickyBottomInset),
                child: _buildTabContent(activeIndex, authProvider, coinProvider),
              ),
            ),
            if (showStickyPromo)
              Positioned(
                left: 0,
                right: 0,
                bottom: HomeResponsive.bottomNavHeight(context),
                child: ColoredBox(
                  color: activeIndex == 0
                      ? HomeTheme.screenBackground
                      : const Color(0xFFF8F8F8),
                  child: PromoBanner(onRecharge: _navigateToRecharge),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNavBar(authProvider, heartbeat, activeIndex),
            ),
          ],
        ),
      ),
      ),
    );
  }

  bool _showsStickyPromo(int tabIndex) => tabIndex <= 2;

  // Build content area depending on the selected tab
  Widget _buildTabContent(int activeIndex, AuthProvider authProvider, WalletProvider coinProvider) {
    final isListener = authProvider.isListener;
    if (isListener) {
      switch (activeIndex) {
        case 0:
          return _buildHomeView(coinProvider);
        case 1:
          return CallsScreen(
            favoriteUsers: _favouriteCreatorIds,
            onToggleFavorite: _toggleFavorite,
            onInitiateCall: (listenerId, name, avatarUrl, isVideo) {
              _initiateCall(listenerId, name, avatarUrl, isVideo);
            },
          );
        case 2:
          return const CoinRechargeScreen(isTab: true);
        case 3:
          return const ListenerDashboardScreen(isTab: true);
        case 4:
          return ProfileScreen(
            onTabChanged: (index) {
              _onBottomNavTap(
                authProvider,
                context.read<CreatorHeartbeatProvider>(),
                index,
              );
            },
          );
        default:
          return _buildHomeView(coinProvider);
      }
    } else {
      switch (activeIndex) {
        case 0:
          return _buildHomeView(coinProvider);
        case 1:
          return CallsScreen(
            favoriteUsers: _favouriteCreatorIds,
            onToggleFavorite: _toggleFavorite,
            onInitiateCall: (listenerId, name, avatarUrl, isVideo) {
              _initiateCall(listenerId, name, avatarUrl, isVideo);
            },
          );
        case 2:
          return const CoinRechargeScreen(isTab: true);
        case 3:
          return ProfileScreen(
            onTabChanged: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
          );
        default:
          return _buildHomeView(coinProvider);
      }
    }
  }

  // --- HOME VIEW (390px ref · CustomScrollView · white background) ---
  Widget _buildHomeView(WalletProvider coinProvider) {
    final authProvider = context.watch<AuthProvider>();
    final creatorProvider = context.watch<CreatorProvider>();
    final creators = creatorProvider.creators;
    final isLoading = creatorProvider.isLoading;
    final error = creatorProvider.error;

    final userName = authProvider.user?.displayName ?? '';
    final avatarUrl = authProvider.user?.avatarUrl ?? AvatarAssets.defaultAvatar;

    return ColoredBox(
      color: HomeTheme.screenBackground,
      child: Column(
        children: [
          _buildStickyHomeHeader(
            coinProvider: coinProvider,
            userName: userName,
            avatarUrl: avatarUrl,
          ),
          Expanded(
            child: RefreshIndicator(
              color: HomeTheme.primary,
              onRefresh: () async {
                _lazySections.reset();
                await Future.wait([
                  context.read<CreatorProvider>().fetchCreators(),
                  context.read<WalletProvider>().loadWallet(reason: 'homePullRefresh'),
                ]);
              },
              child: isLoading && creators.isEmpty
                  ? const HomeSkeletonLoader(contentOnly: true)
                  : CustomScrollView(
                      controller: _homeScrollController,
                      cacheExtent: HomeResponsive.w(context, 480),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: _buildHomeContentSlivers(
                        creators: creators,
                        error: error,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyHomeHeader({
    required WalletProvider coinProvider,
    required String userName,
    required String avatarUrl,
  }) {
    final sectionGap = HomeResponsive.sectionGap(context);
    return ColoredBox(
      color: HomeTheme.screenBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HomeHeader(
            userName: userName,
            avatarUrl: avatarUrl,
            onNotificationTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
          ),
          SizedBox(height: HomeResponsive.w(context, 16)),
          WalletHeroCard(
            balance: coinProvider.balance,
            onRecharge: _navigateToRecharge,
          ),
          SizedBox(height: sectionGap),
          HomeCategoryChips(
            selectedId: _selectedCategory,
            onSelected: (id) {
              setState(() {
                _selectedCategory = id;
                _lazySections.reset();
              });
            },
          ),
          SizedBox(height: HomeResponsive.w(context, 8)),
        ],
      ),
    );
  }

  List<Widget> _buildHomeContentSlivers({
    required List<Creator> creators,
    required String? error,
  }) {
    final filtered = _filterByCategory(creators);
    final onlineCreators = filtered.where((c) => c.isOnline).toList();
    final topRated = List<Creator>.from(filtered)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    var recentlyJoined = filtered.where((c) => c.isNew).toList();
    if (recentlyJoined.isEmpty && filtered.length > 1) {
      recentlyJoined = filtered.take(8).toList();
    }

    _lazySections.syncTotals(
      featuredTotal: 1,
      onlineTotal: onlineCreators.length,
      topRatedTotal: topRated.length.clamp(0, 10),
      recentTotal: recentlyJoined.length,
    );

    final featuredCreator = _pickFeaturedCreator(filtered.isNotEmpty ? filtered : creators);
    final sectionGap = HomeResponsive.sectionGap(context);
    final bottomInset = HomeResponsive.w(context, 12);
    final listRowH = ListenerListRowCard.rowHeight(context);

    final slivers = <Widget>[];

    if (creators.isEmpty && error != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: HomeErrorCard(
            message: error,
            onRetry: () => context.read<CreatorProvider>().fetchCreators(),
          ),
        ),
      );
    } else if (creators.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: HomeEmptyState(
            onRefresh: () => context.read<CreatorProvider>().fetchCreators(),
          ),
        ),
      );
    } else if (filtered.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: HomeEmptyState(
            message: 'No listeners in this category yet.',
            subtitle: 'Try another category or refresh.',
            onRefresh: () => context.read<CreatorProvider>().fetchCreators(),
          ),
        ),
      );
    } else {
      slivers.addAll([
        SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
        const SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Featured Listener',
            actionLabel: 'View all',
          ),
        ),
        SliverToBoxAdapter(
          child: StaggerFadeIn(
            index: 0,
            child: FeaturedListenerCard(
              creator: featuredCreator,
              isFavorite: _favouriteCreatorIds.contains(featuredCreator.id),
              onFavoriteToggle: () => _toggleFavorite(featuredCreator.id),
              onTap: () => _showCreatorProfile(featuredCreator),
              onVoiceCall: () => _startCall(featuredCreator, false),
              onVideoCall: () => _startCall(featuredCreator, true),
            ),
          ),
        ),
      ]);

      if (onlineCreators.isNotEmpty) {
        slivers.addAll(_buildListenerSectionSlivers(
          title: 'Online Listeners',
          creators: onlineCreators,
          visibleCount: _lazySections.onlineVisible,
          onLoadMore: () => _lazySections.loadMoreOnline(onlineCreators.length),
          sectionGap: sectionGap,
          listRowH: listRowH,
          sectionKey: 'online',
          lazy: true,
          leading: PulsingOnlineDot(size: HomeResponsive.w(context, 9)),
        ));
      }

      if (topRated.isNotEmpty) {
        final topRatedTotal = topRated.length.clamp(0, 10);
        final topRatedList = topRated.take(topRatedTotal).toList();
        final topRatedCount =
            _lazySections.topRatedVisible.clamp(0, topRatedList.length);
        final topRatedH = TopRatedCard.cardHeight(context);
        slivers.add(
          HomeLazyViewportSection(
            estimatedExtent: sectionGap + HomeResponsive.w(context, 36) + topRatedH,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: sectionGap),
                const SectionHeader(
                  title: 'Top Rated',
                  actionLabel: 'View all',
                  leading: Icon(
                    Icons.star_rounded,
                    color: HomeTheme.starYellow,
                    size: 20,
                  ),
                ),
                LazyHorizontalList(
                  height: topRatedH,
                  itemCount: topRatedCount,
                  onNearEnd: topRatedCount < topRatedList.length
                      ? () => _lazySections.loadMoreTopRated(topRatedList.length)
                      : null,
                  itemBuilder: (context, index) {
                    final creator = topRatedList[index];
                    return TopRatedCard(
                      key: ValueKey('top-${creator.id}'),
                      creator: creator,
                      onTap: () => _showCreatorProfile(creator),
                      onVoiceCall: () => _startCall(creator, false),
                      onVideoCall: () => _startCall(creator, true),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }

      if (recentlyJoined.isNotEmpty) {
        final recentCount =
            _lazySections.recentVisible.clamp(0, recentlyJoined.length);
        final recentH = HomeResponsive.w(context, 88);
        slivers.add(
          HomeLazyViewportSection(
            estimatedExtent: sectionGap + HomeResponsive.w(context, 36) + recentH,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: sectionGap),
                const SectionHeader(
                  title: 'Recently Joined',
                  actionLabel: 'View all',
                ),
                LazyHorizontalList(
                  height: recentH,
                  itemSpacing: 16,
                  itemCount: recentCount,
                  onNearEnd: recentCount < recentlyJoined.length
                      ? () => _lazySections.loadMoreRecent(recentlyJoined.length)
                      : null,
                  itemBuilder: (context, index) {
                    final creator = recentlyJoined[index];
                    return RecentJoinedAvatar(
                      key: ValueKey('recent-${creator.id}'),
                      creator: creator,
                      onTap: () => _showCreatorProfile(creator),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }

    }

    slivers.add(SliverToBoxAdapter(child: SizedBox(height: bottomInset)));
    return slivers;
  }

  List<Creator> _filterByCategory(List<Creator> creators) {
    if (_selectedCategory == 'all') return creators;
    return creators.asMap().entries.where((entry) {
      final category = _categoryIds[entry.key % _categoryIds.length];
      return category == _selectedCategory;
    }).map((entry) => entry.value).toList();
  }

  Creator _pickFeaturedCreator(List<Creator> creators) {
    final online = creators.where((c) => c.isOnline).toList();
    if (online.isNotEmpty) {
      online.sort((a, b) => b.rating.compareTo(a.rating));
      return online.first;
    }
    final sorted = List<Creator>.from(creators)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.first;
  }

  void _toggleFavorite(String creatorId) {
    setState(() {
      if (_favouriteCreatorIds.contains(creatorId)) {
        _favouriteCreatorIds.remove(creatorId);
      } else {
        _favouriteCreatorIds.add(creatorId);
      }
    });
  }

  List<Widget> _buildListenerSectionSlivers({
    required String title,
    required List<Creator> creators,
    required int visibleCount,
    required VoidCallback onLoadMore,
    required double sectionGap,
    required double listRowH,
    required String sectionKey,
    bool lazy = false,
    Widget? leading,
  }) {
    final count = visibleCount.clamp(0, creators.length);
    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: sectionGap),
        SectionHeader(title: title, actionLabel: 'View all', leading: leading),
      ],
    );

    final listSliver = SliverList.builder(
      itemCount: count,
      itemBuilder: (context, index) {
        if (index == count - 1 && count < creators.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
        }
        final creator = creators[index];
        return ListenerListRowCard(
          key: ValueKey('$sectionKey-${creator.id}'),
          creator: creator,
          isFavorite: _favouriteCreatorIds.contains(creator.id),
          onFavoriteToggle: () => _toggleFavorite(creator.id),
          onTap: () => _showCreatorProfile(creator),
          onVoiceCall: () => _startCall(creator, false),
          onVideoCall: () => _startCall(creator, true),
        );
      },
    );

    if (!lazy) {
      return [
        SliverToBoxAdapter(child: header),
        listSliver,
      ];
    }

    return [
      HomeLazyViewportSection(
        estimatedExtent: sectionGap + HomeResponsive.w(context, 36) + (listRowH * count),
        child: header,
      ),
      listSliver,
    ];
  }

  void _navigateToRecharge() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CoinRechargeScreen()),
    ).then((_) {
      if (mounted) {
        context.read<WalletProvider>().loadWallet(reason: 'rechargePop');
      }
    });
  }

  void _startCall(Creator creator, bool isVideo) {
    if (!creator.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listener Offline'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!creator.isVoiceAvailable) return;
    final coinProvider = context.read<WalletProvider>();
    if (coinProvider.balance < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum 50 coins required to start a call. Please recharge.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _initiateCall(creator.id, creator.name, creator.avatar, isVideo);
  }

  void _showCreatorProfile(Creator creator) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HomeTheme.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: HomeTheme.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      creator.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: HomeTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                creator.languagesLabel,
                style: GoogleFonts.poppins(color: HomeTheme.textSecondary),
              ),
              if (creator.rating > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '★ ${creator.rating.toStringAsFixed(1)} · ${creator.lastSeenLabel}',
                  style: GoogleFonts.poppins(color: HomeTheme.textSecondary, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ScalePressedButton(
                      onTap: () {
                        Navigator.pop(context);
                        _startCall(creator, false);
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: HomeTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Voice Call',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ScalePressedButton(
                      onTap: () {
                        Navigator.pop(context);
                        _startCall(creator, true);
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: HomeTheme.primary),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Video Call',
                          style: GoogleFonts.poppins(
                            color: HomeTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(callRequestErrorMessage(e)),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- FIXED BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavBar(
    AuthProvider authProvider,
    CreatorHeartbeatProvider heartbeat,
    int activeIndex,
  ) {
    final isListener = authProvider.isListener;
    final isOnlineLocked = _isListenerOnlineLocked(authProvider, heartbeat);
    final isListenerDashboardTab = isListener && (activeIndex == kListenerDashboardTabIndex);
    final isDark = isListenerDashboardTab;

    final tabs = _getTabs(authProvider);

    return Container(
      height: HomeResponsive.w(context, 76),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1320) : HomeTheme.screenBackground,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isBlocked =
              isOnlineLocked && isListenerTabBlockedWhenOnline(index);
          return _buildBottomNavItem(
            authProvider,
            heartbeat,
            activeIndex,
            tab['icon'] as IconData,
            tab['activeIcon'] as IconData,
            tab['label'] as String,
            index,
            isBlocked: isBlocked,
          );
        }),
      ),
    );
  }

  Widget _buildBottomNavItem(
    AuthProvider authProvider,
    CreatorHeartbeatProvider heartbeat,
    int activeIndex,
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    int index, {
    bool isBlocked = false,
  }) {
    final isActive = activeIndex == index;
    final isListener = authProvider.isListener;
    final isListenerDashboardTab =
        isListener && (activeIndex == kListenerDashboardTabIndex);
    final isDark = isListenerDashboardTab;
    final inactiveColor =
        isDark ? const Color(0xFF707584) : const Color(0xFF9CA3AF);
    final blockedColor = isDark
        ? const Color(0xFF4A4F5C)
        : const Color(0xFFD1D5DB);
    final iconSize = HomeResponsive.w(context, 24);

    Color iconColor;
    Color labelColor;
    if (isBlocked) {
      iconColor = blockedColor;
      labelColor = blockedColor;
    } else if (isActive) {
      iconColor = HomeTheme.primary;
      labelColor = HomeTheme.primary;
    } else {
      iconColor = inactiveColor;
      labelColor = inactiveColor;
    }

    return Opacity(
      opacity: isBlocked ? 0.45 : 1.0,
      child: ScalePressedButton(
        onTap: () => _onBottomNavTap(authProvider, heartbeat, index),
        pressedScale: isBlocked ? 1.0 : 0.94,
        child: SizedBox(
          width: HomeResponsive.w(context, 72),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : inactiveIcon,
                color: iconColor,
                size: iconSize,
              ),
              SizedBox(height: HomeResponsive.w(context, 3)),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: HomeResponsive.w(context, 11),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
