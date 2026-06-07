import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/gift_item.dart';
import '../utils/gift_grouping.dart';

class CallSummaryScreen extends StatelessWidget {
  final String peerName;
  final int callDurationSeconds;
  final int callCoins;
  final int giftCoins;
  final int totalCoins;
  final bool isCreatorView;
  final int? callEarnings;
  final int? giftEarnings;
  final int? totalEarnings;
  final List<SessionGiftRecord> giftsSent;
  final List<GiftSummaryEntry> giftsReceived;

  const CallSummaryScreen({
    super.key,
    required this.peerName,
    required this.callDurationSeconds,
    required this.callCoins,
    required this.giftCoins,
    required this.totalCoins,
    this.isCreatorView = false,
    this.callEarnings,
    this.giftEarnings,
    this.totalEarnings,
    this.giftsSent = const [],
    this.giftsReceived = const [],
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    final groupedSent = groupSessionGifts(giftsSent);
    final groupedReceived = groupReceivedGifts(giftsReceived);
    final topGift = topGiftByCount(groupedReceived);
    final giftCount = giftsReceived.length;

    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Call Summary',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              peerName,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatDuration(callDurationSeconds),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            if (isCreatorView) ...[
              _SummaryRow(
                label: 'Call Earnings',
                value: '${formatter.format(callEarnings ?? callCoins)} Coins',
              ),
              _SummaryRow(
                label: 'Gift Earnings',
                value: '${formatter.format(giftEarnings ?? giftCoins)} Coins',
              ),
              _SummaryRow(
                label: 'Total Earnings',
                value:
                    '${formatter.format(totalEarnings ?? (callEarnings ?? callCoins) + (giftEarnings ?? giftCoins))} Coins',
                highlight: true,
              ),
              if (giftCount > 0) ...[
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Gift Count',
                  value: '$giftCount',
                ),
                if (topGift != null)
                  _SummaryRow(
                    label: 'Top Gift',
                    value: '${topGift.giftEmoji} ${topGift.giftName}',
                  ),
              ],
            ] else ...[
              _SummaryRow(
                label: 'Call Coins',
                value: '${formatter.format(callCoins)} Coins',
              ),
              _SummaryRow(
                label: 'Gift Coins',
                value: '${formatter.format(giftCoins)} Coins',
              ),
              _SummaryRow(
                label: 'Total Coins',
                value: '${formatter.format(totalCoins)} Coins',
                highlight: true,
              ),
            ],
            if (groupedSent.isNotEmpty || groupedReceived.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                isCreatorView ? 'Gifts Received' : 'Gifts Sent',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              if (!isCreatorView)
                ...groupedSent.map(
                  (g) => _GiftListTile(
                    title: '${g.giftEmoji} ${g.displayLabel}',
                    coins: g.totalCoins,
                  ),
                ),
              if (isCreatorView)
                ...groupedReceived.map(
                  (g) => _GiftListTile(
                    title: '${g.giftEmoji} ${g.displayLabel}',
                    coins: g.totalCoins,
                  ),
                ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1493),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: const Color(0xFFFF1493).withOpacity(0.5))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: highlight ? const Color(0xFFFF1493) : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftListTile extends StatelessWidget {
  final String title;
  final int coins;

  const _GiftListTile({required this.title, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            '$coins Coins',
            style: GoogleFonts.poppins(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
