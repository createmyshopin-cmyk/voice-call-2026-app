import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/wallet_provider.dart';

class CoinPackage {
  final int coins;
  final String price;
  final double priceValue;
  final String talkTime;
  final String? badge;
  final IconData icon;

  const CoinPackage({
    required this.coins,
    required this.price,
    required this.priceValue,
    required this.talkTime,
    this.badge,
    required this.icon,
  });
}

class CoinRechargeScreen extends StatefulWidget {
  const CoinRechargeScreen({super.key});

  @override
  State<CoinRechargeScreen> createState() => _CoinRechargeScreenState();
}

class _CoinRechargeScreenState extends State<CoinRechargeScreen> {
  List<CoinPackage> _packages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio(BaseOptions(
        baseUrl: kIsWeb
            ? 'http://localhost:5000'
            : (Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000'),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.get('/api/coin-packages');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (mounted) {
          setState(() {
            _packages = data.asMap().entries.map((entry) {
              final item = entry.value;
              final baseCoins = item['coins'] as int? ?? 100;
              final bonusCoins = item['bonusCoins'] as int? ?? 0;
              final totalCoins = baseCoins + bonusCoins;
              final priceCents = item['price'] as int? ?? 99;
              final priceVal = priceCents / 100.0;
              final name = item['name'] as String? ?? 'Coin Package';

              IconData icon;
              if (baseCoins <= 100) {
                icon = Icons.wallet_giftcard;
              } else if (baseCoins <= 500) {
                icon = Icons.stars;
              } else if (baseCoins <= 1000) {
                icon = Icons.monetization_on;
              } else if (baseCoins <= 2000) {
                icon = Icons.diamond;
              } else {
                icon = Icons.military_tech;
              }

              String? badge;
              if (name.toLowerCase().contains('vip') || baseCoins >= 5000) {
                badge = 'VIP DEAL';
              } else if (name.toLowerCase().contains('value') || baseCoins == 2000) {
                badge = 'BEST VALUE';
              } else if (name.toLowerCase().contains('popular') || baseCoins == 500) {
                badge = 'POPULAR';
              } else if (bonusCoins > 0) {
                badge = '+$bonusCoins BONUS';
              }

              return CoinPackage(
                coins: totalCoins,
                price: '\$${priceVal.toStringAsFixed(2)}',
                priceValue: priceVal,
                talkTime: '${totalCoins ~/ 10} mins calling',
                badge: badge,
                icon: icon,
              );
            }).toList();
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

  @override
  Widget build(BuildContext context) {
    final coinProvider = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: SafeArea(
          child: Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button & Title
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF333333), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recharge Coins',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF333333),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Current Wallet Balance
                Container(
                  width: 110,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF1493), Color(0xFFFF4DA6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF1493).withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
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
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prompt info banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1493).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on, color: Color(0xFFFF1493), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instantly Connect',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        Text(
                          'Choose a package below to recharge your wallet. Calling rates are as low as 10 Coins/min.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Packages Section Title
            Text(
              'Select Coin Package',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),

            // Grid of Packages
            _isLoading && _packages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _packages.length,
                    itemBuilder: (context, index) {
                      final package = _packages[index];
                      return _buildPackageCard(package);
                    },
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Build a single Package Card widget
  Widget _buildPackageCard(CoinPackage package) {
    return ScalePressedButton(
      onTap: () => _openCheckoutSheet(package),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: package.badge != null ? const Color(0xFFFF1493).withOpacity(0.3) : const Color(0xFFEAEAEA),
                width: package.badge != null ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Illustration
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1493).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(package.icon, color: const Color(0xFFFF1493), size: 28),
                ),
                const SizedBox(height: 12),

                // Coins Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${package.coins}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),

                // Talk time equivalent
                Text(
                  package.talkTime,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF777777),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                // Price Badge
                Container(
                  width: double.infinity,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF1493), Color(0xFFFF4DA6)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      package.price,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Optional Badges at the top-right
          if (package.badge != null)
            Positioned(
              top: -8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC85CFF), Color(0xFF8A2BE2)],
                  ),
                ),
                child: Text(
                  package.badge!,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
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
      builder: (context) => _CheckoutSheet(package: package),
    );
  }
}

// --- CHECKOUT BOTTOM SHEET WIDGET ---
class _CheckoutSheet extends StatefulWidget {
  final CoinPackage package;
  const _CheckoutSheet({required this.package});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> with SingleTickerProviderStateMixin {
  int _selectedPaymentMethod = 0; // 0: Card, 1: GooglePay, 2: UPI
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

  void _processPayment() {
    setState(() {
      _isProcessing = true;
    });

    // Simulate Payment Gateway verification delay
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
        _animController.forward();

        // Close after show success dialog
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            // Add coins to provider
            Provider.of<WalletProvider>(context, listen: false).addCoins(widget.package.coins);
            Navigator.pop(context); // Close bottom sheet
            
            // Show Success Notification toast
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Successfully added ${widget.package.coins} Coins!'),
                  ],
                ),
                backgroundColor: const Color(0xFF00A86B),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Top border radius sheet
    return Container(
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
          // Drag handle indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          if (!_isProcessing && !_isSuccess) ...[
            // Main Checkout Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Checkout',
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
            const Divider(color: Color(0xFFEAEAEA)),
            const SizedBox(height: 12),

            // Package Summary Details
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
                          '${widget.package.coins} Coins Package',
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

            // Choose Payment Method Header
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Payment Method',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Payment Option 1: Card
            _buildPaymentMethodOption(
              index: 0,
              icon: Icons.credit_card,
              label: 'Credit / Debit Card',
              subtitle: 'Visa, Mastercard, RuPay',
            ),
            const SizedBox(height: 8),

            // Payment Option 2: GooglePay
            _buildPaymentMethodOption(
              index: 1,
              icon: Icons.account_balance_wallet,
              label: 'Google Pay',
              subtitle: 'Instant secure checkout',
            ),
            const SizedBox(height: 8),

            // Payment Option 3: UPI
            _buildPaymentMethodOption(
              index: 2,
              icon: Icons.phone_android,
              label: 'UPI Auto-Pay',
              subtitle: 'Pay via PhonePe, GPay, Paytm',
            ),
            const SizedBox(height: 24),

            // Pay Button
            ScalePressedButton(
              onTap: _processPayment,
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ECC71), Color(0xFF00A86B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A86B).withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Secure Pay ${widget.package.price}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '🔒 Encrypted SSL Secure Checkout Connection',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ] else if (_isProcessing) ...[
            // Processing Screen
            const SizedBox(height: 40),
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
                strokeWidth: 5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Processing Payment...',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please do not close the app or tap the back button',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 40),
          ] else if (_isSuccess) ...[
            // Success Screen
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
              'Payment Successful!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.package.coins} Coins have been added to your wallet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  // Payment Option selection tile
  Widget _buildPaymentMethodOption({
    required int index,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    bool isSelected = _selectedPaymentMethod == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF1493).withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF1493) : const Color(0xFFEAEAEA),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF1493).withOpacity(0.1) : const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFFFF1493) : const Color(0xFF777777),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF777777),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFFFF1493) : const Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
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
