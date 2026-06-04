import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'language_selection_screen.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  String? _selectedGender;

  static const Color kSurface = Color(0xFF080E1A);
  static const Color kPrimary = Color(0xFFBA9EFF);
  static const Color kPrimaryDim = Color(0xFF8455EF);
  static const Color kOnSurface = Color(0xFFE0E5F6);
  static const Color kOnSurfaceVariant = Color(0xFFA6ABBB);
  static const Color kSurfaceContainerLow = Color(0xFF0D1320);
  static const Color kSurfaceContainerHighest = Color(0xFF1E2637);
  static const Color kSurfaceContainerLowest = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kPrimary.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'What\'s your\ngender?',
                    style: GoogleFonts.manrope(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: kOnSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This helps us personalize your experience.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: kOnSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Gender Cards
                  _buildGenderCard(
                    label: 'Male',
                    icon: Icons.male,
                    value: 'male',
                  ),
                  const SizedBox(height: 20),
                  _buildGenderCard(
                    label: 'Female',
                    icon: Icons.female,
                    value: 'female',
                  ),

                  
                  const Spacer(),
                  
                  // Continue Button
                  GestureDetector(
                    onTap: _selectedGender != null ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LanguageSelectionScreen(
                            selectedGender: _selectedGender!,
                          ),
                        ),
                      );
                    } : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: _selectedGender != null 
                          ? const LinearGradient(colors: [kPrimary, kPrimaryDim])
                          : null,
                        color: _selectedGender == null ? kSurfaceContainerHighest : null,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: _selectedGender != null ? [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ] : [],
                      ),
                      child: Center(
                        child: Text(
                          'Continue',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _selectedGender != null ? kSurfaceContainerLowest : kOnSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard({required String label, required IconData icon, required String value}) {
    bool isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary.withOpacity(0.1) : kSurfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? kPrimary : kOnSurfaceVariant,
            ),
            const SizedBox(width: 20),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isSelected ? kOnSurface : kOnSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: kPrimary),
          ],
        ),
      ),
    );
  }
}
