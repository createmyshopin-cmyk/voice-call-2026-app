import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/creator_gift_service.dart';

class TodaysGiftsCard extends StatelessWidget {
  final CreatorGiftInsights insights;
  final bool isLoading;

  const TodaysGiftsCard({
    super.key,
    required this.insights,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF1493).withOpacity(0.25)),
      ),
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: Color(0xFFFF1493),
                  strokeWidth: 2,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      "Today's Gifts",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _row('Gift Count', '${insights.giftsReceived}'),
                const SizedBox(height: 8),
                _row('Gift Earnings', '${insights.giftCoins} Coins'),
                if (insights.topGiftName != null) ...[
                  const SizedBox(height: 8),
                  _row('Top Gift', insights.topGiftName!),
                ],
                if (insights.mostActiveSender != null) ...[
                  const SizedBox(height: 8),
                  _row('Most Active Sender', insights.mostActiveSender!),
                ],
              ],
            ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
