import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/home_theme.dart';
import '../../utils/home_responsive.dart';
import 'scale_pressed_button.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final Widget? leading;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.leading,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = HomeResponsive.w(context, 20);
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, HomeResponsive.w(context, 10)),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: HomeResponsive.w(context, 6)),
          ],
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: HomeResponsive.w(context, 20),
                fontWeight: FontWeight.w700,
                color: HomeTheme.textPrimary,
                height: 1.2,
              ),
            ),
          ),
          if (actionLabel != null)
            ScalePressedButton(
              onTap: onAction ?? () {},
              pressedScale: 0.96,
              child: Text(
                actionLabel!,
                style: GoogleFonts.poppins(
                  fontSize: HomeResponsive.w(context, 16),
                  fontWeight: FontWeight.w600,
                  color: HomeTheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
