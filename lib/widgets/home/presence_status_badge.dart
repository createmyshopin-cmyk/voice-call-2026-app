import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/home_theme.dart';
import '../../utils/home_responsive.dart';
import 'pulsing_online_dot.dart';

/// Green online or grey offline presence pill for creator cards.
class PresenceStatusBadge extends StatelessWidget {
  final bool isOnline;
  final bool compact;

  const PresenceStatusBadge({
    super.key,
    required this.isOnline,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HomeResponsive.w(context, compact ? 5 : 8),
        vertical: HomeResponsive.w(context, compact ? 2 : 4),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HomeResponsive.w(context, 10)),
        boxShadow: HomeTheme.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOnline)
            PulsingOnlineDot(size: HomeResponsive.w(context, compact ? 6 : 8))
          else
            Container(
              width: HomeResponsive.w(context, compact ? 6 : 8),
              height: HomeResponsive.w(context, compact ? 6 : 8),
              decoration: const BoxDecoration(
                color: Color(0xFF9CA3AF),
                shape: BoxShape.circle,
              ),
            ),
          if (!compact) ...[
            SizedBox(width: HomeResponsive.w(context, 4)),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: GoogleFonts.poppins(
                fontSize: HomeResponsive.w(context, compact ? 9 : 11),
                fontWeight: FontWeight.w600,
                color: isOnline ? HomeTheme.textPrimary : const Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
