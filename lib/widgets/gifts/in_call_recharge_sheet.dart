import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/recharge_prompt_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../screens/recharge_screen.dart';
import '../../services/api_client.dart';
import '../../services/balance_prediction_service.dart';

const _targetCoinAmounts = [500, 1000, 2000, 5000];

class InCallRechargeSheet extends StatefulWidget {
  final int coinsPerMinute;

  const InCallRechargeSheet({super.key, this.coinsPerMinute = 10});

  static Future<void> show(
    BuildContext context, {
    int coinsPerMinute = 10,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InCallRechargeSheet(coinsPerMinute: coinsPerMinute),
    );
  }

  @override
  State<InCallRechargeSheet> createState() => _InCallRechargeSheetState();
}

class _InCallRechargeSheetState extends State<InCallRechargeSheet> {
  List<CoinPackage> _packages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await apiDio.get(
        '/api/payments/packages',
        options: authOptions(token),
      );
      final data = response.data as List<dynamic>;
      final all = <CoinPackage>[];
      for (final raw in data) {
        final item = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw as Map);
        final id = item['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final base = (item['coins'] as num?)?.toInt() ?? 0;
        final bonus = (item['bonusCoins'] as num?)?.toInt() ?? 0;
        final coins = base + bonus;
        final price = (item['price'] as num?)?.toDouble() ?? 0;
        all.add(CoinPackage(
          id: id,
          coins: coins,
          price: '₹${price.toStringAsFixed(0)}',
          priceValue: price,
          talkTime: BalancePredictionService.formatTalkTime(
            coins,
            widget.coinsPerMinute,
          ),
          icon: Icons.monetization_on,
        ));
      }

      final selected = <CoinPackage>[];
      for (final target in _targetCoinAmounts) {
        CoinPackage? best;
        var bestDiff = 999999;
        for (final p in all) {
          final diff = (p.coins - target).abs();
          if (diff < bestDiff) {
            bestDiff = diff;
            best = p;
          }
        }
        if (best != null && !selected.any((s) => s.id == best!.id)) {
          selected.add(best);
        }
      }

      if (mounted) {
        setState(() {
          _packages = selected.isNotEmpty ? selected : all.take(4).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPayment(CoinPackage package) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RechargePaymentSheet(
        package: package,
        inCallMode: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final prompt = context.watch<RechargePromptProvider>();
    final recommendedCoins = prompt.suggestedPackageCoins;
    final height = MediaQuery.of(context).size.height * 0.72;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'Top Up Coins',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Call will continue without any break',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF1493)),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _packages.length,
                    itemBuilder: (context, index) {
                      final pkg = _packages[index];
                      final isRecommended = pkg.coins == recommendedCoins;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isRecommended
                                ? const Color(0xFFFF1493)
                                : Colors.white12,
                            width: isRecommended ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${pkg.coins} Coins',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isRecommended) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF1493),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '⭐ Recommended',
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
                                    BalancePredictionService.formatTalkTime(
                                      pkg.coins,
                                      widget.coinsPerMinute,
                                    ),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _openPayment(pkg),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF1493),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(pkg.price),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Balance: ${wallet.balance} Coins',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
