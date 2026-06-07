import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/home_theme.dart';
import '../../utils/home_responsive.dart';
import 'scale_pressed_button.dart';

class HomeCategoryChip {
  final String id;
  final String label;
  final IconData icon;

  const HomeCategoryChip({
    required this.id,
    required this.label,
    required this.icon,
  });
}

const homeCategoryChips = [
  HomeCategoryChip(id: 'all', label: 'All', icon: Icons.grid_view_rounded),
  HomeCategoryChip(id: 'relationship', label: 'Relationship', icon: Icons.favorite_outline_rounded),
  HomeCategoryChip(id: 'marriage', label: 'Marriage', icon: Icons.diversity_1_rounded),
  HomeCategoryChip(id: 'friendship', label: 'Friendship', icon: Icons.people_outline_rounded),
  HomeCategoryChip(id: 'love', label: 'Love', icon: Icons.favorite_rounded),
  HomeCategoryChip(id: 'family', label: 'Family', icon: Icons.home_outlined),
];

class HomeCategoryChips extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;

  const HomeCategoryChips({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final h = HomeResponsive.w(context, 40);
    return SizedBox(
      height: h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: HomeResponsive.w(context, 20)),
        itemCount: homeCategoryChips.length,
        separatorBuilder: (_, __) => SizedBox(width: HomeResponsive.w(context, 8)),
        itemBuilder: (context, index) {
          final chip = homeCategoryChips[index];
          final selected = chip.id == selectedId;
          return ScalePressedButton(
            onTap: () => onSelected(chip.id),
            pressedScale: 0.96,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: HomeResponsive.w(context, 14)),
              decoration: BoxDecoration(
                color: selected ? HomeTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(HomeResponsive.w(context, 20)),
                border: Border.all(
                  color: selected ? HomeTheme.primary : HomeTheme.primary.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: selected ? HomeTheme.softShadow : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    chip.icon,
                    size: HomeResponsive.w(context, 16),
                    color: selected ? Colors.white : HomeTheme.primary,
                  ),
                  SizedBox(width: HomeResponsive.w(context, 6)),
                  Text(
                    chip.label,
                    style: GoogleFonts.poppins(
                      fontSize: HomeResponsive.w(context, 13),
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : HomeTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
