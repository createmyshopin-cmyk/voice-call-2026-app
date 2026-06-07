import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/gift_item.dart';
import '../../providers/gift_catalog_provider.dart';
import '../../providers/gift_provider.dart';
import '../../providers/wallet_provider.dart';

class GiftBottomSheet extends StatelessWidget {
  final String creatorId;
  final String callId;
  final VoidCallback? onInsufficientBalance;

  const GiftBottomSheet({
    super.key,
    required this.creatorId,
    required this.callId,
    this.onInsufficientBalance,
  });

  static Future<void> show(
    BuildContext context, {
    required String creatorId,
    required String callId,
    VoidCallback? onInsufficientBalance,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GiftBottomSheet(
        creatorId: creatorId,
        callId: callId,
        onInsufficientBalance: onInsufficientBalance,
      ),
    );
  }

  String _formatCoins(int amount) =>
      NumberFormat.decimalPattern().format(amount);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final wallet = context.watch<WalletProvider>();
    final catalog = context.watch<GiftCatalogProvider>();
    final giftProvider = context.watch<GiftProvider>();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: screenHeight * 0.75,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117).withOpacity(0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send a Gift',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Gifts send instantly',
                            style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            '${_formatCoins(wallet.balance)} Coins',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: catalog.isLoading && !catalog.hasCatalog
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF1493),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: catalog.gifts.length,
                        itemBuilder: (context, index) {
                          final gift = catalog.gifts[index];
                          final isSending =
                              giftProvider.sendingGiftId == gift.id;
                          return _GiftCard(
                            gift: gift,
                            isSending: isSending,
                            onTap: () => _onGiftTap(
                              context,
                              gift,
                              wallet,
                              giftProvider,
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '⚡ Gifts will be sent instantly',
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onGiftTap(
    BuildContext context,
    GiftItem gift,
    WalletProvider wallet,
    GiftProvider giftProvider,
  ) async {
    if (giftProvider.sendingGiftId != null) return;

    final token = wallet.accessToken;
    if (token == null) return;

    if (wallet.balance < gift.coinCost) {
      Navigator.pop(context);
      onInsufficientBalance?.call();
      return;
    }

    final idempotencyKey = const Uuid().v4();
    final result = await _sendWithRetrySnackBar(
      context,
      idempotencyKey: idempotencyKey,
      gift: gift,
      wallet: wallet,
      giftProvider: giftProvider,
    );

    if (!context.mounted || result == null) return;

    if (!result.duplicate) {
      Navigator.pop(context);
    }
  }

  Future<SendGiftResult?> _sendWithRetrySnackBar(
    BuildContext context, {
    required String idempotencyKey,
    required GiftItem gift,
    required WalletProvider wallet,
    required GiftProvider giftProvider,
  }) async {
    var result = await giftProvider.sendGift(
      accessToken: wallet.accessToken!,
      gift: gift,
      creatorId: creatorId,
      callId: callId,
      idempotencyKey: idempotencyKey,
      wallet: wallet,
    );

    if (!context.mounted) return result;
    if (result != null) return result;

    final msg = giftProvider.lastError ?? 'Could not send gift';
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () async {
            final retry = await giftProvider.sendGift(
              accessToken: wallet.accessToken!,
              gift: gift,
              creatorId: creatorId,
              callId: callId,
              idempotencyKey: idempotencyKey,
              wallet: wallet,
            );
            if (retry != null && context.mounted && !retry.duplicate) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
    return null;
  }
}

class _GiftCard extends StatelessWidget {
  final GiftItem gift;
  final bool isSending;
  final VoidCallback onTap;

  const _GiftCard({
    required this.gift,
    required this.isSending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSending ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF1493).withOpacity(0.15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(gift.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                gift.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (isSending)
                Text(
                  'Sending...',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF1493),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1493),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${gift.coinCost} Coins',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
