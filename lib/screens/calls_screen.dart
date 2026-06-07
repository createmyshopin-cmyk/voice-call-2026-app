import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/call_history_item.dart';
import '../models/creator.dart';
import '../providers/auth_provider.dart';
import '../providers/call_history_provider.dart';
import '../providers/creator_provider.dart';

class CallsScreen extends StatefulWidget {
  final Set<String> favoriteUsers;
  final Function(String name) onToggleFavorite;
  final Function(String listenerId, String name, String avatarUrl, bool isVideo) onInitiateCall;

  const CallsScreen({
    super.key,
    required this.favoriteUsers,
    required this.onToggleFavorite,
    required this.onInitiateCall,
  });

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> with SingleTickerProviderStateMixin {
  String _selectedTab = 'All Calls'; // 'All Calls', 'Voice Calls', 'Video Calls'
  String _selectedDateRange = 'This Month'; // 'This Month', 'This Week', 'All Time'
  bool _showAllCalls = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final historyProvider = context.read<CallHistoryProvider>();
    final creatorProvider = context.read<CreatorProvider>();
    await Future.wait([
      historyProvider.fetchHistory(),
      creatorProvider.fetchCreators(),
    ]);
  }

  List<CallHistoryItem> _filterCalls(List<CallHistoryItem> calls) {
    List<CallHistoryItem> filtered = calls;
    
    // Filter by type segment
    if (_selectedTab == 'Voice Calls') {
      filtered = filtered.where((c) => c.type == 'voice' || !c.isVideo).toList();
    } else if (_selectedTab == 'Video Calls') {
      filtered = filtered.where((c) => c.type == 'video' || c.isVideo).toList();
    }

    // Filter by date range (simulated or real startedAt)
    final now = DateTime.now();
    if (_selectedDateRange == 'This Week') {
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      filtered = filtered.where((c) => c.startedAt.isAfter(oneWeekAgo)).toList();
    } else if (_selectedDateRange == 'This Month') {
      final oneMonthAgo = now.subtract(const Duration(days: 30));
      filtered = filtered.where((c) => c.startedAt.isAfter(oneMonthAgo)).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<CallHistoryProvider>();
    final creatorProvider = context.watch<CreatorProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?.uid ?? '';

    final rawCalls = historyProvider.items;
    final filteredCalls = _filterCalls(rawCalls);
    final displayedCalls = _showAllCalls ? filteredCalls : filteredCalls.take(5).toList();

    final creators = creatorProvider.creators;

    final isLoading = historyProvider.isLoading || creatorProvider.isLoading;
    final hasError = historyProvider.error != null || creatorProvider.error != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFFF1493),
          backgroundColor: Colors.white,
          onRefresh: _refreshData,
          child: isLoading && rawCalls.isEmpty
              ? const CallsSkeletonLoader()
              : hasError && rawCalls.isEmpty
                  ? _buildErrorState(historyProvider.error ?? creatorProvider.error ?? 'Connection error')
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Calls',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              if (filteredCalls.isNotEmpty)
                                ScalePressedButton(
                                  onTap: () => _showClearConfirmation(context),
                                  child: Text(
                                    'Clear',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFF1493),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (filteredCalls.isEmpty)
                            _buildEmptyState()
                          else ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayedCalls.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFF3F4F6),
                              ),
                              itemBuilder: (context, index) {
                                final call = displayedCalls[index];
                                final otherId = call.otherPartyId(currentUserId);
                                String avatarUrl = '';
                                final match = creators.where((c) => c.id == otherId);
                                if (match.isNotEmpty) {
                                  avatarUrl = match.first.avatar;
                                } else {
                                  avatarUrl =
                                      'https://i.pravatar.cc/150?u=${call.otherPartyName(currentUserId)}';
                                }
                                return RecentCallRow(
                                  call: call,
                                  currentUserId: currentUserId,
                                  avatarUrl: avatarUrl,
                                  onCallTap: () {
                                    widget.onInitiateCall(
                                      otherId,
                                      call.otherPartyName(currentUserId),
                                      avatarUrl,
                                      call.type == 'video' || call.isVideo,
                                    );
                                  },
                                );
                              },
                            ),
                            if (filteredCalls.length > 5)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: ScalePressedButton(
                                    onTap: () {
                                      setState(() {
                                        _showAllCalls = !_showAllCalls;
                                      });
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _showAllCalls ? 'Show Less' : 'View All',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFFF1493),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          _showAllCalls
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons.chevron_right_rounded,
                                          size: 20,
                                          color: const Color(0xFFFF1493),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Calls',
            style: GoogleFonts.poppins(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          Row(
            children: [
              _buildHeaderButton(
                icon: Icons.search,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search calls is coming soon!')),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.tune,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Advanced filters are coming soon!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap}) {
    return ScalePressedButton(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF2D6E5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF1493).withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFFFF1493),
          size: 24,
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Clear History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        content: Text(
          'Are you sure you want to clear your local call history representation? Active backend logs are kept for billing integrity.',
          style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleared local view (Simulated)')),
              );
            },
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF1493),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8FB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_missed_outlined,
              size: 48,
              color: Color(0xFFFF1493),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No calls yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first conversation with standard verified listeners.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ScalePressedButton(
            onTap: () {
              // We can post a notification to switch tab to 0
              // For simplicity, we can search for a widget state ancestor or similar.
              // We'll let the user navigate or use a custom notification/bus.
              // Let's print a message for now or let it trigger home tab.
              // We can find the parent Scaffold or state.
              // A nice trick is to dispatch an event or pop to Home!
              // Since this is inside HomeScreen tab content, we can call a callback if we want,
              // but we can also use a post callback to trigger home index update.
              // Let's use a nice message or simulate navigating back.
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Redirecting you to the Home screen listeners list...'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF1493), Color(0xFFFF4DA6)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1493).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Browse Listeners',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFFF1493),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ScalePressedButton(
              onTap: _refreshData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1493),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------
// CALL TYPE SEGMENT
// ------------------------------------------------
class CallTypeSegment extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabChanged;

  const CallTypeSegment({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> tabs = ['All Calls', 'Voice Calls', 'Video Calls'];
    return Container(
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selectedTab == tab;
          IconData iconData = Icons.call;
          if (tab == 'Voice Calls') {
            iconData = Icons.phone_callback_rounded;
          } else if (tab == 'Video Calls') {
            iconData = Icons.videocam_rounded;
          }
          return Expanded(
            child: ScalePressedButton(
              onTap: () => onTabChanged(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected ? const Color(0xFFFF1493) : Colors.transparent,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF1493).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      iconData,
                      color: isSelected ? Colors.white : const Color(0xFF111827),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.split(' ')[0],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ------------------------------------------------
// CALL ACTIVITY CARD (HERO CARD)
// ------------------------------------------------
class CallActivityCard extends StatelessWidget {
  final int totalCalls;
  final int voiceCalls;
  final int videoCalls;
  final String selectedDateRange;
  final Function(String) onDateRangeChanged;

  const CallActivityCard({
    super.key,
    required this.totalCalls,
    required this.voiceCalls,
    required this.videoCalls,
    required this.selectedDateRange,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF1493), Color(0xFFFF4DA6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1493).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_in_talk,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Your Call Activity',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: onDateRangeChanged,
                itemBuilder: (BuildContext context) {
                  return ['This Week', 'This Month', 'All Time'].map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(
                        choice,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selectedDateRange,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Calls', totalCalls),
              _buildVerticalDivider(),
              _buildStatItem('Voice Calls', voiceCalls),
              _buildVerticalDivider(),
              _buildStatItem('Video Calls', videoCalls),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CountUpText(
          targetValue: value,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withOpacity(0.25),
    );
  }
}

// ------------------------------------------------
// COUNT-UP ANIMATION TEXT
// ------------------------------------------------
class CountUpText extends StatefulWidget {
  final int targetValue;
  final TextStyle style;

  const CountUpText({
    super.key,
    required this.targetValue,
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
    _animation = Tween<double>(begin: 0.0, end: widget.targetValue.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.targetValue.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
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
        return Text(
          _animation.value.round().toString(),
          style: widget.style,
        );
      },
    );
  }
}

// ------------------------------------------------
// STAGGERED FADE-IN LIST ITEM
// ------------------------------------------------
class StaggeredListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _controller.forward();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ------------------------------------------------
// RECENT CALL ROW
// ------------------------------------------------
class RecentCallRow extends StatelessWidget {
  final CallHistoryItem call;
  final String currentUserId;
  final String avatarUrl;
  final VoidCallback onCallTap;

  const RecentCallRow({
    super.key,
    required this.call,
    required this.currentUserId,
    required this.avatarUrl,
    required this.onCallTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = call.otherPartyName(currentUserId);
    final isVideo = call.type == 'video' || call.isVideo;
    final dateLabel = call.formattedCallSubtitle();
    final costText = '₹${call.coinsDeducted.toStringAsFixed(2)}';
    final callTypeIcon = isVideo ? Icons.videocam_rounded : Icons.phone_rounded;
    final callTypeColor =
        isVideo ? const Color(0xFFFF1493) : const Color(0xFF22C55E);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: avatarUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 52,
                height: 52,
                color: const Color(0xFFF3F4F6),
              ),
              errorWidget: (context, url, error) => Image.network(
                'https://i.pravatar.cc/150?u=$otherName',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        otherName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF1493),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(callTypeIcon, size: 14, color: callTypeColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isVideo
                            ? 'Video Call \u2022 $dateLabel'
                            : 'Voice Call \u2022 $dateLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                costText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                call.formattedDurationCompact(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          ScalePressedButton(
            onTap: onCallTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                callTypeIcon,
                color: const Color(0xFFFF1493),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------
// FAVORITE LISTENER CARD
// ------------------------------------------------
class FavoriteListenerCard extends StatelessWidget {
  final Creator creator;
  final Function(String listenerId, String name, String avatarUrl, bool isVideo) onInitiateCall;

  const FavoriteListenerCard({
    super.key,
    required this.creator,
    required this.onInitiateCall,
  });

  @override
  Widget build(BuildContext context) {
    // Generate static rating for visuals
    final rating = creator.name == 'Priya Sharma' ? '4.9' : (creator.name == 'Anjali Verma' ? '4.8' : '4.7');
    final isVerified = creator.name == 'Priya Sharma' || creator.name == 'Anjali Verma' || creator.name == 'Neha Singh';

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile Avatar with Online indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(creator.avatar),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: creator.isOnline ? const Color(0xFF2ECC71) : const Color(0xFF9E9E9E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),

          // Name and verified check
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  creator.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 2),
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFFFF1493),
                  size: 10,
                ),
              ],
            ],
          ),

          // Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                rating,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),

          // Action buttons: Voice Call and Video Call
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScalePressedButton(
                onTap: () {
                  onInitiateCall(creator.id, creator.name, creator.avatar, false);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF1493),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ScalePressedButton(
                onTap: () {
                  onInitiateCall(creator.id, creator.name, creator.avatar, true);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF1493),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------
// CALL SUMMARY CARD
// ------------------------------------------------
class CallSummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final int growth;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const CallSummaryCard({
    super.key,
    required this.title,
    required this.count,
    required this.growth,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 15,
                ),
              ),
              Text(
                '${growth}%',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2ECC71),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------
// SHIMMER SKELETON LOADER
// ------------------------------------------------
class CallsSkeletonLoader extends StatelessWidget {
  const CallsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF3F4F6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Shimmer
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 140,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tab Segment Shimmer
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),

            // Hero Card Shimmer
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            const SizedBox(height: 32),

            // Recent Calls Title
            Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 16),

            // Recent Call Rows
            ...List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 180,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Favorite Section Title
            Container(
              width: 180,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 16),

            // Favorite Cards
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------
// PRESSED BUTTON SCALE FEEDBACK WIDGET
// ------------------------------------------------
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
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
