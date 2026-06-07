import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/gift_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gift_overlay_provider.dart';
import '../../providers/gift_provider.dart';

class CreatorGiftOverlay extends StatelessWidget {
  const CreatorGiftOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GiftOverlayProvider>(
      builder: (context, overlay, _) {
        final event = overlay.current;
        if (event == null) return const SizedBox.shrink();

        return Positioned(
          left: 16,
          right: 16,
          bottom: 140,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 250),
            child: _OverlayCard(event: event),
          ),
        );
      },
    );
  }
}

class _OverlayCard extends StatelessWidget {
  final GiftOverlayEvent event;

  const _OverlayCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final giftProvider = context.read<GiftProvider>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF1493).withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1493).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFF1493).withOpacity(0.2),
                backgroundImage: event.senderAvatar != null &&
                        event.senderAvatar!.isNotEmpty
                    ? CachedNetworkImageProvider(event.senderAvatar!)
                    : null,
                child: event.senderAvatar == null || event.senderAvatar!.isEmpty
                    ? Text(
                        event.senderName.isNotEmpty
                            ? event.senderName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.senderName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'sent ${event.giftName} ${event.giftEmoji}',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${event.giftCoins} Coins',
                      style: GoogleFonts.poppins(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(event.giftEmoji, style: const TextStyle(fontSize: 36)),
            ],
          ),
          const SizedBox(height: 12),
          _QuickReplyRow(
            senderName: event.senderName,
            onReply: (apiMessage) async {
              final token = auth.accessToken;
              if (token == null) return;
              await giftProvider.replyToGift(
                accessToken: token,
                giftTransactionId: event.giftTransactionId,
                message: apiMessage,
              );
              if (context.mounted) {
                context.read<GiftOverlayProvider>().dismissCurrent();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _QuickReplyRow extends StatelessWidget {
  final String senderName;
  final ValueChanged<String> onReply;

  const _QuickReplyRow({
    required this.senderName,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final options = buildGiftReplyOptions(senderName);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                opt.label,
                style: GoogleFonts.poppins(fontSize: 11),
              ),
              backgroundColor: const Color(0xFFFF1493).withOpacity(0.15),
              side: BorderSide(color: const Color(0xFFFF1493).withOpacity(0.4)),
              onPressed: () => onReply(opt.apiMessage),
            ),
          );
        }).toList(),
      ),
    );
  }
}
