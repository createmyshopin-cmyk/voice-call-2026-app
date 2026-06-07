import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/call_history_provider.dart';
import '../models/call_history_item.dart';
import '../models/wallet_transaction.dart';
import '../services/api_client.dart';
import '../widgets/common/app_shimmer.dart';
import '../widgets/wallet/wallet_lazy_sections.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Matches backend `coin_packages.id` (UUID). Display fields (coins, price, name) are never sent to create-order.
final RegExp _coinPackageUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

bool _isCoinPackageUuid(String value) => _coinPackageUuid.hasMatch(value);

Map<String, dynamic> _asPackageJsonMap(dynamic item) {
  if (item is Map<String, dynamic>) return item;
  if (item is Map) return Map<String, dynamic>.from(item);
  throw FormatException('Expected package object, got ${item.runtimeType}');
}

/// Reads only the DB primary key — never coins, price, name, or list index.
String? _packageUuidFromJson(Map<String, dynamic> item) {
  final raw = item['id'] ?? item['packageId'] ?? item['package_id'];
  if (raw == null) return null;
  final id = raw.toString().trim();
  return _isCoinPackageUuid(id) ? id : null;
}

class CoinPackage {
  /// UUID from `coin_packages.id` — this is the only value sent as create-order `packageId`.
  final String id;
  final int coins;
  final String price;
  final double priceValue;
  final String talkTime;
  final String? badge;
  final IconData icon;
  final String? extraText;
  final bool isMostPopular;

  const CoinPackage({
    required this.id,
    required this.coins,
    required this.price,
    required this.priceValue,
    required this.talkTime,
    this.badge,
    required this.icon,
    this.extraText,
    this.isMostPopular = false,
  });

  @override
  String toString() =>
      'CoinPackage(id: $id, coins: $coins, priceValue: $priceValue)';
}

class CoinRechargeScreen extends StatefulWidget {
  final bool isTab;
  const CoinRechargeScreen({super.key, this.isTab = false});

  @override
  State<CoinRechargeScreen> createState() => _CoinRechargeScreenState();
}

class _CoinRechargeScreenState extends State<CoinRechargeScreen> {
  List<CoinPackage> _packages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final WalletLazySections _walletLazy = WalletLazySections();

  @override
  void initState() {
    super.initState();
    _walletLazy.addListener(_onWalletLazyChanged);
    _scrollController.addListener(_onWalletScroll);
    _fetchPackages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchTransactions();
    });
  }

  void _onWalletLazyChanged() {
    if (mounted) setState(() {});
  }

  void _onWalletScroll() {
    if (!_scrollController.hasClients) return;
    final metrics = _scrollController.position;
    if (metrics.pixels < metrics.maxScrollExtent - 180) return;
    final total = context.read<WalletProvider>().transactions.length;
    _walletLazy.loadMoreTransactions(total);
  }

  @override
  void dispose() {
    _walletLazy.removeListener(_onWalletLazyChanged);
    _walletLazy.dispose();
    _scrollController.removeListener(_onWalletScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPackages() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final token = context.read<AuthProvider>().accessToken;
      if (token == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      final response = await apiDio.get(
        '/api/payments/packages',
        options: authOptions(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (mounted) {
          setState(() {
            _packages = data
                .map((raw) {
                  final item = _asPackageJsonMap(raw);
                  final packageId = _packageUuidFromJson(item);
                  if (packageId == null) {
                    debugPrint(
                      'SKIP package — invalid/missing UUID. '
                      'raw id=${item['id']} packageId=${item['packageId']} '
                      'coins=${item['coins']} price=${item['price']} name=${item['name']}',
                    );
                    return null;
                  }

                  final baseCoins = item['coins'] as int? ?? 100;
                  final bonusCoins = item['bonusCoins'] as int? ?? 0;
                  final totalCoins = baseCoins + bonusCoins;
                  final priceVal = (item['price'] as num? ?? 99).toDouble();
                  final name = item['name'] as String? ?? 'Coin Package';

                  String? extraText;
                  if (baseCoins > 0 && bonusCoins > 0) {
                    final pct = (bonusCoins / baseCoins) * 100;
                    extraText = '${pct.toStringAsFixed(0)}% EXTRA';
                  }

                  // Force matching for reference design consistency
                  if (totalCoins == 3000) extraText = '5% EXTRA';
                  if (totalCoins == 6000) extraText = '10% EXTRA';
                  if (totalCoins == 12000) extraText = '15% EXTRA';
                  if (totalCoins == 25000) extraText = '20% EXTRA';

                  bool isMostPopular = name.toLowerCase().contains('popular') || totalCoins == 6000;
                  String? badge = isMostPopular ? 'Most Popular' : null;

                  IconData icon;
                  if (totalCoins <= 1000) {
                    icon = Icons.wallet_giftcard;
                  } else if (totalCoins <= 3000) {
                    icon = Icons.stars;
                  } else if (totalCoins <= 6000) {
                    icon = Icons.monetization_on;
                  } else if (totalCoins <= 12000) {
                    icon = Icons.diamond;
                  } else {
                    icon = Icons.military_tech;
                  }

                  final pkg = CoinPackage(
                    id: packageId,
                    coins: totalCoins,
                    price: '₹${priceVal.toStringAsFixed(0)}',
                    priceValue: priceVal,
                    talkTime: '${totalCoins ~/ 10} mins calling',
                    badge: badge,
                    icon: icon,
                    extraText: extraText,
                    isMostPopular: isMostPopular,
                  );
                  debugPrint('LOADED PACKAGE: $pkg');
                  return pkg;
                })
                .whereType<CoinPackage>()
                .toList();

            // Sort by coins ascending (lowest to highest)
            _packages.sort((a, b) => a.coins.compareTo(b.coins));
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching coin packages: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatCoins(int amount) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(amount);
  }

  String _getPackageImage(int coins) {
    if (coins <= 1500) {
      return 'assets/illustrations/coin_stack_1000.png';
    } else if (coins <= 4000) {
      return 'assets/illustrations/coin_stack_3000.png';
    } else if (coins <= 8000) {
      return 'assets/illustrations/coin_stack_6000.png';
    } else if (coins <= 15000) {
      return 'assets/illustrations/coin_sack_12000.png';
    } else {
      return 'assets/illustrations/coin_chest_25000.png';
    }
  }

  void _scrollToTransactions() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinProvider = context.watch<WalletProvider>();
    final historyProvider = context.watch<CallHistoryProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.uid ?? '';

    // Load call history if empty
    if (historyProvider.items.isEmpty && !historyProvider.isLoading && historyProvider.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        historyProvider.fetchHistory();
      });
    }

    _walletLazy.syncTotals(
      transactionTotal: coinProvider.transactions.length,
      packageTotal: _packages.length,
    );
    final transactionCount = _walletLazy.transactionVisible
        .clamp(0, coinProvider.transactions.length);
    final packageCount =
        _walletLazy.packageVisible.clamp(0, _packages.length);
    final allTransactionsVisible =
        transactionCount >= coinProvider.transactions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button & Title
                Row(
                  children: [
                    if (!widget.isTab) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF333333), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      'Wallet',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                // Help and History buttons
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Wallet Support', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            content: Text(
                              'Need help with your wallet or payments? Contact us at support@voicecallapp.com or call our helpline.',
                              style: GoogleFonts.poppins(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Close', style: GoogleFonts.poppins(color: const Color(0xFFFF1493), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.help_outline_rounded, color: Color(0xFF333333), size: 22),
                            const SizedBox(height: 2),
                            Text(
                              'Help',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        _walletLazy.showAllTransactions(
                          context.read<WalletProvider>().transactions.length,
                        );
                        _scrollToTransactions();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_rounded, color: Color(0xFF333333), size: 22),
                            const SizedBox(height: 2),
                            Text(
                              'History',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF1493),
        onRefresh: () async {
          _walletLazy.reset();
          await Future.wait([
            _fetchPackages(),
            coinProvider.fetchTransactions(),
            if (authProvider.accessToken != null)
              coinProvider.loadWallet(reason: 'rechargePullRefresh', accessToken: authProvider.accessToken),
          ]);
        },
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: 480,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // 1. Available Balance Card (Pink/Reddish Gradient)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF1E6F), Color(0xFFFF0055)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF1E6F).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Card Header
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Balance',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Coins badge circle
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'C',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _formatCoins(coinProvider.balance),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 34,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      // Open Coin details or help sheet
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(24),
                                            topRight: Radius.circular(24),
                                          ),
                                        ),
                                        builder: (context) => Container(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'About Coins',
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF333333)),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Coins are the official in-app currency used to connect with your favorite creators/listeners.\n\n• 1 Coin is equivalent to ₹1.\n• Connecting on Voice or Video call deducts coins from your wallet per minute.\n• Coins never expire once purchased.',
                                                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF666666), height: 1.5),
                                              ),
                                              const SizedBox(height: 20),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFFF1493),
                                                  minimumSize: const Size(double.infinity, 48),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                                ),
                                                child: Text('Got it', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          'Coins',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.9), size: 10),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Card Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 1 Coin = 1 INR Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '1 Coin = ₹1',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.info_outline, color: Colors.white, size: 11),
                                  ],
                                ),
                              ),
                              // Recharge Now button
                              InkWell(
                                onTap: () {
                                  if (_packages.isNotEmpty) {
                                    _openCheckoutSheet(_packages.first);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Recharge Now',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFFF0055),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF0055), size: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Floating Stars Decors
                    Positioned(
                      top: 15,
                      right: 130,
                      child: Icon(Icons.star_rounded, color: Colors.white.withOpacity(0.4), size: 10),
                    ),
                    Positioned(
                      top: 40,
                      right: 25,
                      child: Icon(Icons.star_rounded, color: Colors.white.withOpacity(0.6), size: 14),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 140,
                      child: Icon(Icons.star_rounded, color: Colors.white.withOpacity(0.3), size: 8),
                    ),
                    // Floating Coins Illustration on the right
                    Positioned(
                      right: 8,
                      bottom: 25,
                      child: Image.asset(
                        'assets/illustrations/balance_coins_header.png',
                        height: 105,
                        fit: BoxFit.contain,
                        errorBuilder: (context, _, __) => const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Quick Actions Header & Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: const Color(0xFF222222),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildQuickActionItem(Icons.card_giftcard_rounded, 'Offers', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No active offers right now! Check back later.')),
                      );
                    }),
                    _buildQuickActionItem(Icons.local_activity_outlined, 'Coupons', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coupons feature coming soon.')),
                      );
                    }),
                    _buildQuickActionItem(Icons.calendar_today_outlined, 'Daily Bonus', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Collect your daily bonus from the Home tab!')),
                      );
                    }),
                    _buildQuickActionItem(Icons.favorite_border_rounded, 'Refer & Earn', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite friends to earn free talk time coins.')),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Buy Coins Header, Best Value Indicator & horizontal list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Buy Coins',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Best Value',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF1493),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Color(0xFFFF1493), size: 14),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _isLoading && _packages.isEmpty
                  ? const HorizontalCardsSkeleton(
                      cardWidth: 140,
                      cardHeight: 180,
                    )
                  : SizedBox(
                      height: 195,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is! ScrollUpdateNotification &&
                              notification is! ScrollEndNotification) {
                            return false;
                          }
                          final metrics = notification.metrics;
                          if (metrics.pixels >= metrics.maxScrollExtent - 80) {
                            _walletLazy.loadMorePackages(_packages.length);
                          }
                          return false;
                        },
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          cacheExtent: 320,
                          itemCount: packageCount,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final package = _packages[index];
                            return RepaintBoundary(
                              child: SizedBox(
                                width: 125,
                                child: _buildPackageCardRedesignedHorizontal(
                                  package,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              // View All Packs Flat Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All available coin packages are shown above.')),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View All Packs',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF1493),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF1493), size: 10),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: const Color(0xFF222222),
                  ),
                ),
                if (coinProvider.transactions.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      if (allTransactionsVisible) {
                        _walletLazy.reset();
                      } else {
                        _walletLazy.showAllTransactions(
                          coinProvider.transactions.length,
                        );
                      }
                    },
                    child: Text(
                      allTransactionsVisible ? 'Show Less' : 'View All',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFF1493),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (coinProvider.isLoadingTransactions &&
            coinProvider.transactions.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildHistoryShimmer(),
            ),
          )
        else if (coinProvider.transactions.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildHistoryEmptyState(),
            ),
          )
        else
          SliverList.builder(
            itemCount: transactionCount,
            itemBuilder: (context, index) {
              if (index == transactionCount - 1 &&
                  transactionCount < coinProvider.transactions.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _walletLazy.loadMoreTransactions(
                    coinProvider.transactions.length,
                  );
                });
              }
              final tx = coinProvider.transactions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RepaintBoundary(
                  child: _buildTransactionItem(
                    tx,
                    historyProvider,
                    currentUserId,
                  ),
                ),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF1E6F), Color(0xFFFF0055)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                      // Gift Box Coin overflow illustration
                      Image.asset(
                        'assets/illustrations/gift_box_coins.png',
                        height: 52,
                        fit: BoxFit.contain,
                        errorBuilder: (context, _, __) => const SizedBox(),
                      ),
                      const SizedBox(width: 12),
                      // Banner Copy
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Get 20% Extra Coins',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'On your first recharge today!',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Action button
                      InkWell(
                        onTap: () {
                          // Open checkout for best package
                          final bestPackage = _packages.firstWhere(
                            (p) => p.coins >= 6000,
                            orElse: () => _packages.isNotEmpty ? _packages.last : const CoinPackage(id: '', coins: 0, price: '', priceValue: 0.0, talkTime: '', icon: Icons.star),
                          );
                          if (bestPackage.id.isNotEmpty) {
                            _openCheckoutSheet(bestPackage);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Recharge Now',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFF0055),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF0055), size: 8),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: widget.isTab ? 16.0 : 30.0),
        ),
      ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFF3F3F3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFFF1493), size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF555555),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPackageCardRedesignedHorizontal(CoinPackage package) {
    return ScalePressedButton(
      onTap: () => _openCheckoutSheet(package),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: package.isMostPopular ? const Color(0xFFFF1493) : const Color(0xFFEAEAEA),
                width: package.isMostPopular ? 1.8 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: package.isMostPopular
                      ? const Color(0xFFFF1493).withOpacity(0.08)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: package.isMostPopular ? 10 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Coins Count
                Text(
                  _formatCoins(package.coins),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF222222),
                  ),
                ),
                Text(
                  'Coins',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: const Color(0xFF777777),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),

                // Package Image
                Expanded(
                  child: Image.asset(
                    _getPackageImage(package.coins),
                    fit: BoxFit.contain,
                    errorBuilder: (context, _, __) => Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1493).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(package.icon, color: const Color(0xFFFF1493), size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Price Badge Pill (Solid Pink with White Text)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1493),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF1493).withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    package.price,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),

                // Extra text (e.g. 5% EXTRA) below the price
                if (package.extraText != null)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF1493).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      package.extraText!,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFF1493),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // "Most Popular" Tag
          if (package.isMostPopular)
            Positioned(
              top: 0,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFFFF1493),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF1493).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Most Popular',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx, CallHistoryProvider historyProvider, String currentUserId) {
    IconData icon;
    Color iconColor = const Color(0xFFFF1493);
    Color bgCircleColor = const Color(0xFFFFF0F5);
    String subtitle = '';

    if (tx.type == 'recharge') {
      icon = Icons.add_circle_outline_rounded;
      subtitle = tx.referenceId != null ? 'Order #${tx.referenceId}' : 'Recharge package';
    } else if (tx.type == 'call_deduction') {
      // Find matching call in history
      final call = historyProvider.items.firstWhere(
        (c) => c.id == tx.referenceId,
        orElse: () => CallHistoryItem(
          id: '',
          callerId: '',
          callerName: '',
          creatorId: '',
          creatorName: '',
          type: tx.description?.toLowerCase().contains('video') == true ? 'video' : 'voice',
          status: '',
          durationSeconds: 0,
          coinsDeducted: tx.amount.abs(),
          startedAt: tx.date,
        ),
      );

      icon = call.isVideo ? Icons.videocam_rounded : Icons.call_rounded;
      if (call.id.isNotEmpty) {
        subtitle = 'With ${call.otherPartyName(currentUserId)}';
      } else {
        subtitle = tx.description ?? 'Call Session';
      }
    } else if (tx.type == 'refund') {
      icon = Icons.replay_rounded;
      subtitle = tx.description ?? 'Coins Refunded';
    } else {
      icon = tx.amount >= 0 ? Icons.add_rounded : Icons.remove_rounded;
      subtitle = tx.description ?? 'Wallet Adjustment';
    }

    final isPositive = tx.amount > 0;
    final amountText = isPositive ? '+${_formatCoins(tx.amount)}' : _formatCoins(tx.amount);
    final amountColor = isPositive ? const Color(0xFF2ECC71) : const Color(0xFFFF2A6D);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F2F2), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Circular Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgCircleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),

          // Transaction Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.displayTitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF777777),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Amount and Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tx.formattedDate(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryShimmer() {
    return Column(
      children: List.generate(3, (index) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Color(0xFFEEEEEE), shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 14, color: const Color(0xFFEEEEEE)),
                  const SizedBox(height: 6),
                  Container(width: 150, height: 10, color: const Color(0xFFEEEEEE)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(width: 40, height: 14, color: const Color(0xFFEEEEEE)),
                const SizedBox(height: 6),
                Container(width: 60, height: 10, color: const Color(0xFFEEEEEE)),
              ],
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildHistoryEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recharge your wallet or start calling to log transactions here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  // Opens Checkout Payment Sheet
  void _openCheckoutSheet(CoinPackage package) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _PaymentFlowSheet(package: package),
    );
  }
}

// --- Payment flow: pay → Razorpay → green success (no method picker after pay) ---
class _PaymentFlowSheet extends StatefulWidget {
  final CoinPackage package;
  const _PaymentFlowSheet({required this.package});

  @override
  State<_PaymentFlowSheet> createState() => _PaymentFlowSheetState();
}

class _PaymentFlowSheetState extends State<_PaymentFlowSheet> with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _isSuccess = false;
  bool _razorpayOpen = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Razorpay _razorpay;
  String? _internalPaymentId;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.bounceOut);

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _animController.dispose();
    super.dispose();
  }

  String _paymentErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      debugPrint('Payment API error body: $data');
      if (data is Map) {
        final message = data['message'];
        if (message is List) return message.join(', ');
        if (message != null) return message.toString();
        final error = data['error'];
        if (error != null) return error.toString();
      }
      return e.message ?? 'Network error (${e.response?.statusCode ?? 'no response'})';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  String? _paymentIdFromResponse(Map<String, dynamic>? payment) {
    if (payment == null) return null;
    return payment['id'] as String? ?? payment['paymentId'] as String?;
  }

  Future<void> _creditCoinsAfterVerify(Map<String, dynamic> verifyBody) async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final token = auth.accessToken;
    if (token == null) throw Exception('Please sign in to recharge.');

    debugPrint('Calling /payments/verify');
    debugPrint('Verify request body: $verifyBody');
    final verifyRes = await apiDio.post(
      '/api/payments/verify',
      data: verifyBody,
      options: authOptions(token),
    );
    debugPrint('Verify Response: ${verifyRes.data}');

    int? verifiedBalance;
    if (verifyRes.data is Map) {
      final verifyData = Map<String, dynamic>.from(verifyRes.data as Map);
      final rawBalance =
          verifyData['newBalance'] ?? verifyData['new_balance'];
      if (rawBalance is num) {
        verifiedBalance = rawBalance.toInt();
      } else if (rawBalance is String) {
        verifiedBalance = int.tryParse(rawBalance);
      }
      if (verifiedBalance != null) {
        wallet.setBalanceFromServer(verifiedBalance);
      } else {
        final payment = verifyData['payment'];
        if (payment is Map) {
          final added = payment['coinsAdded'] ?? payment['coins_added'];
          if (added is num) {
            wallet.setBalanceFromServer(wallet.balance + added.toInt());
          }
        }
      }
    }

    // Confirm via /api/wallet (won't downgrade after postVerify — see WalletProvider).
    await wallet.loadWallet(reason: 'postVerify', accessToken: token);
    await auth.refreshUser();

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _razorpayOpen = false;
      _isSuccess = true;
    });
    _animController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Successfully added ${widget.package.coins} coins!'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00A86B),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('ORDER ID: ${response.orderId}');
    debugPrint('PAYMENT ID: ${response.paymentId}');
    debugPrint('SIGNATURE: ${response.signature}');
    debugPrint('Internal paymentId: $_internalPaymentId, mounted: $mounted');

    if (!mounted) return;

    if (response.orderId == null ||
        response.paymentId == null ||
        response.signature == null) {
      debugPrint('Recharge verification skipped: missing Razorpay callback fields');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment succeeded but verification data was incomplete. Contact support.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _razorpayOpen = false;
      _isSuccess = false;
    });
    try {
      final verifyBody = <String, dynamic>{
        'razorpayOrderId': response.orderId,
        'razorpayPaymentId': response.paymentId,
        'razorpaySignature': response.signature,
      };
      if (_internalPaymentId != null) {
        verifyBody['paymentId'] = _internalPaymentId;
      }
      await _creditCoinsAfterVerify(verifyBody);
    } catch (e) {
      debugPrint('Recharge verification error: $e');
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification failed: ${_paymentErrorMessage(e)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _razorpayOpen = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? "Unknown Error"}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    final token = context.read<AuthProvider>().accessToken;
    final selectedPackage = widget.package;
    final packageId = selectedPackage.id;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to recharge.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('SELECTED PACKAGE: $selectedPackage');
    debugPrint('PACKAGE ID SENT: $packageId');
    debugPrint('PACKAGE TYPE: ${packageId.runtimeType}');

    if (!_isCoinPackageUuid(packageId)) {
      debugPrint(
        'BLOCKED create-order — packageId is not a UUID. '
        'coins=${selectedPackage.coins} price=${selectedPackage.priceValue}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid package. Pull to refresh and try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final createOrderPayload = <String, String>{'packageId': packageId};
      debugPrint('CREATE-ORDER PAYLOAD: $createOrderPayload');

      final orderRes = await apiDio.post(
        '/api/payments/create-order',
        data: createOrderPayload,
        options: authOptions(token),
      );

      final orderData = orderRes.data as Map<String, dynamic>;
      final razorpayOrder = orderData['razorpayOrder'] as Map<String, dynamic>?;
      final payment = orderData['payment'] as Map<String, dynamic>?;

      _internalPaymentId = _paymentIdFromResponse(payment);

      if (razorpayOrder == null || _internalPaymentId == null) {
        throw Exception('Could not initialize payment order');
      }

      final orderId = razorpayOrder['id']?.toString() ?? '';
      final keyId = razorpayOrder['keyId']?.toString() ?? '';
      final mockCheckout = orderData['mockCheckout'] == true ||
          orderId.startsWith('order_mock_') ||
          keyId.startsWith('rzp_test_mock');

      // Server could not create a real Razorpay order — do not skip the payment UI.
      if (mockCheckout) {
        throw Exception(
          'Razorpay is not available on the server. '
          'Set RAZORPAY_KEY_ID (rzp_test_...) and RAZORPAY_KEY_SECRET on Railway, redeploy, then try again.',
        );
      }

      if (!orderId.startsWith('order_')) {
        throw Exception('Invalid payment order from server');
      }

      final amount = razorpayOrder['amount'];

      setState(() {
        _isProcessing = true;
        _razorpayOpen = true;
      });

      final options = {
        'key': keyId,
        'amount': amount is int ? amount : int.tryParse('$amount') ?? 0,
        'currency': razorpayOrder['currency'] ?? 'INR',
        'name': 'Voice Calling App',
        'description': '${widget.package.coins} Coins',
        'order_id': orderId,
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#FF1493'},
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Create order error: $e');
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_paymentErrorMessage(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing && !_isSuccess,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
            if (!_isSuccess)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEAEA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(height: 20),

            if (_isSuccess) ...[
              _buildSuccessView(),
            ] else if (_isProcessing) ...[
              _buildProcessingView(),
            ] else ...[
              _buildConfirmPayView(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmPayView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confirm recharge',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: const Color(0xFF333333),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF777777)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF1493).withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.monetization_on, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.package.coins} Coins',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Text(
                      widget.package.talkTime,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                widget.package.price,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFFFF1493),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'You will pay securely via Razorpay (UPI, card, wallet).',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF777777)),
        ),
        const SizedBox(height: 20),
        ScalePressedButton(
          onTap: _processPayment,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF2ECC71), Color(0xFF00A86B)],
              ),
            ),
            child: Center(
              child: Text(
                'Pay ${widget.package.price}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              _razorpayOpen ? const Color(0xFF00A86B) : const Color(0xFFFF1493),
            ),
            strokeWidth: 4,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _razorpayOpen ? 'Complete payment in Razorpay' : 'Confirming payment...',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _razorpayOpen
              ? 'Finish payment there, then return to this app'
              : 'Adding coins to your wallet',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF777777)),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2ECC71).withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Payment done!',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: const Color(0xFF2ECC71),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${widget.package.coins} coins added to your wallet',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// --- SCALE PRESSED BUTTON REUSED ---
class ScalePressedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const ScalePressedButton({
    super.key,
    required this.child,
    required this.onTap,
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
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
