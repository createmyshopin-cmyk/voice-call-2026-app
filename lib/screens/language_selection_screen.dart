import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final String selectedGender;

  const LanguageSelectionScreen({
    super.key,
    required this.selectedGender,
  });

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguageName;

  static const Color kSurface = Color(0xFF080E1A);
  static const Color kPrimary = Color(0xFFBA9EFF);
  static const Color kPrimaryDim = Color(0xFF8455EF);
  static const Color kOnSurface = Color(0xFFE0E5F6);
  static const Color kOnSurfaceVariant = Color(0xFFA6ABBB);
  static const Color kSurfaceContainerLow = Color(0xFF0D1320);
  static const Color kSurfaceContainerHighest = Color(0xFF1E2637);
  static const Color kSurfaceContainerLowest = Color(0xFF000000);

  final List<Map<String, String>> _languages = [
    {'name': 'Malayalam', 'native': 'മലയാളം', 'code': 'ml'},
    {'name': 'Tamil', 'native': 'தமிழ்', 'code': 'ta'},
    {'name': 'Kannada', 'native': 'ಕನ್ನಡ', 'code': 'kn'},
    {'name': 'Hindi', 'native': 'हिन्दी', 'code': 'hi'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kPrimary.withOpacity(0.08), Colors.transparent],
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
                    'Choose your\nlanguage',
                    style: GoogleFonts.manrope(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: kOnSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select the language you prefer for the app.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: kOnSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Language List
                  Expanded(
                    child: ListView.separated(
                      itemCount: _languages.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final lang = _languages[index];
                        return _buildLanguageCard(
                          name: lang['name']!,
                          nativeName: lang['native']!,
                        );
                      },
                    ),
                  ),
                  
                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40, top: 20),
                    child: GestureDetector(
                      onTap: _selectedLanguageName != null ? () async {
                        final auth = context.read<AuthProvider>();
                        try {
                          if (!auth.isAuthenticated) {
                            await auth.loginWithFirebase();
                          }
                          await auth.updateProfile(
                            gender: widget.selectedGender,
                            language: _selectedLanguageName,
                            onboardingCompleted: true,
                          );
                          if (context.mounted) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not save profile: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _selectedLanguageName != null 
                            ? const LinearGradient(colors: [kPrimary, kPrimaryDim])
                            : null,
                          color: _selectedLanguageName == null ? kSurfaceContainerHighest : null,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: _selectedLanguageName != null ? [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ] : [],
                        ),
                        child: Center(
                          child: Text(
                            'Get Started',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedLanguageName != null ? kSurfaceContainerLowest : kOnSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard({required String name, required String nativeName}) {
    bool isSelected = _selectedLanguageName == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguageName = name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? kOnSurface : kOnSurfaceVariant,
                  ),
                ),
                Text(
                  nativeName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isSelected ? kPrimary.withOpacity(0.8) : kOnSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ],
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
