import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/api_client.dart';
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

  const CoinPackage({
    required this.id,
    required this.coins,
    required this.price,
    required this.priceValue,
    required this.talkTime,
    this.badge,
    required this.icon,
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
      final token = context.read<AuthProvider>().accessToken;
      if (token == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      final dio = createApiDio(accessToken: token);
      final response = await dio.get('/api/payments/packages');
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

                  final pkg = CoinPackage(
                    id: packageId,
                    coins: totalCoins,
                    price: '₹${priceVal.toStringAsFixed(0)}',
                    priceValue: priceVal,
                    talkTime: '${totalCoins ~/ 10} mins calling',
                    badge: badge,
                    icon: icon,
                  );
                  debugPrint('LOADED PACKAGE: $pkg');
                  return pkg;
                })
                .whereType<CoinPackage>()
                .toList();
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
                      if (!widget.isTab) ...[
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF333333), size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                      ],
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Illustration
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1493).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(package.icon, color: const Color(0xFFFF1493), size: 24),
                ),
                const SizedBox(height: 8),

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
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) throw Exception('Please sign in to recharge.');

    final dio = createApiDio(accessToken: token);
    debugPrint('Calling /payments/verify');
    debugPrint('Verify request body: $verifyBody');
    final verifyRes = await dio.post('/api/payments/verify', data: verifyBody);
    debugPrint('Verify Response: ${verifyRes.data}');

    final verifyData = verifyRes.data;
    final wallet = context.read<WalletProvider>();
    final auth = context.read<AuthProvider>();

    if (verifyData is Map) {
      final serverBalance = verifyData['newBalance'] ?? verifyData['new_balance'];
      if (serverBalance is num) {
        wallet.setBalanceFromServer(serverBalance.toInt());
      }
    }

    // Sequential: verify RPC balance first, then confirm via /api/wallet.
    // refreshUser last — must not trigger wallet reload (see WalletProvider.updateAuth).
    await wallet.loadWallet(reason: 'postVerify');
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
      final dio = createApiDio(accessToken: token);

      final createOrderPayload = <String, String>{'packageId': packageId};
      debugPrint('CREATE-ORDER PAYLOAD: $createOrderPayload');

      final orderRes = await dio.post(
        '/api/payments/create-order',
        data: createOrderPayload,
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
