import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/gift_engagement_config.dart';
import '../../providers/recharge_prompt_provider.dart';
import '../../services/balance_prediction_service.dart';

class LowBalanceBanner extends StatelessWidget {
  final VoidCallback onTopUp;

  const LowBalanceBanner({super.key, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    final prompt = context.watch<RechargePromptProvider>();
    if (prompt.level == LowBalanceLevel.none) {
      return const SizedBox.shrink();
    }

    final message = GiftEngagementConfig.enableEmotionalRecharge
        ? prompt.bannerMessage
        : 'Only ${prompt.remainingMinutes} min${prompt.remainingMinutes == 1 ? '' : 's'} remaining';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF1493).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF1493).withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: onTopUp,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF1493),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(
              'Top Up',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class LowBalanceStickyCard extends StatelessWidget {
  final VoidCallback onTopUp;

  const LowBalanceStickyCard({super.key, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    final prompt = context.watch<RechargePromptProvider>();
    if (prompt.level != LowBalanceLevel.critical) {
      return const SizedBox.shrink();
    }

    final message = GiftEngagementConfig.enableEmotionalRecharge
        ? prompt.stickyMessage
        : 'Your call will end in ${prompt.remainingMinutes} min${prompt.remainingMinutes == 1 ? '' : 's'}. Top up now to continue.';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF1493).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTopUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1493),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Top Up Now',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
