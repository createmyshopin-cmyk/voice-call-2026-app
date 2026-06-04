import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/avatar_assets.dart';
import '../providers/auth_provider.dart';
import '../utils/api_error_message.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

const Color _kSurface = Color(0xFF080E1A);
const Color _kPrimary = Color(0xFFBA9EFF);
const Color _kPrimaryDim = Color(0xFF8455EF);
const Color _kOnSurface = Color(0xFFE0E5F6);
const Color _kOnSurfaceVariant = Color(0xFFA6ABBB);
const Color _kSurfaceContainerLow = Color(0xFF0D1320);
const Color _kSurfaceContainerHighest = Color(0xFF1E2637);
const Color _kSurfaceContainerLowest = Color(0xFF000000);
const Color _kError = Color(0xFFFF8A8A);

class _CreateProfileScreenState extends State<CreateProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  DateTime? _dateOfBirth;
  String? _gender;

  String? _nameError;
  String? _dobError;
  String? _genderError;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  String get _avatarAsset => AvatarAssets.assetPathForGender(_gender);

  String get _formattedDob {
    if (_dateOfBirth == null) return '';
    final d = _dateOfBirth!;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  bool _validate() {
    _nameError = null;
    _dobError = null;
    _genderError = null;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameError = 'Full name is required';
    } else if (name.length < 3) {
      _nameError = 'Name must be at least 3 characters';
    } else if (name.length > 30) {
      _nameError = 'Name must be at most 30 characters';
    }

    if (_dateOfBirth == null) {
      _dobError = 'Date of birth is required';
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (!_dateOfBirth!.isBefore(today)) {
        _dobError = 'Date of birth must be in the past';
      }
    }

    if (_gender != 'male' && _gender != 'female') {
      _genderError = 'Please select your gender';
    }

    setState(() {});
    return _nameError == null && _dobError == null && _genderError == null;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial =
        _dateOfBirth ?? DateTime(now.year - 22, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'Date of birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _kPrimary,
              onPrimary: _kSurfaceContainerLowest,
              surface: _kSurfaceContainerLow,
              onSurface: _kOnSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = DateTime(picked.year, picked.month, picked.day);
        _dobError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    final auth = context.read<AuthProvider>();
    try {
      if (!auth.isAuthenticated) {
        await auth.loginWithFirebase();
      }
      await auth.completeOnboarding(
        fullName: _nameController.text.trim(),
        dateOfBirth: _formattedDob,
        gender: _gender!,
        avatarUrl: _avatarAsset,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileSaveErrorMessage(e)),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final auth = context.watch<AuthProvider>();
    final isSubmitting = auth.isLoading;

    return Scaffold(
      backgroundColor: _kSurface,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -60,
            child: _glow(300, _kPrimary.withValues(alpha: 0.1)),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: _glow(360, _kPrimaryDim.withValues(alpha: 0.08)),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: _AvatarHero(assetPath: _avatarAsset)),
                            const SizedBox(height: 28),
                            Text(
                              'Create Your Profile',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: _kOnSurface,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Gender and birthday are permanent and cannot be changed later.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _kOnSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 32),
                            _SectionLabel('Full Name', required: true),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameController,
                              focusNode: _nameFocus,
                              onChanged: (_) {
                                if (_nameError != null) {
                                  setState(() => _nameError = null);
                                }
                              },
                              textCapitalization: TextCapitalization.words,
                              style: GoogleFonts.inter(
                                color: _kOnSurface,
                                fontSize: 16,
                              ),
                              decoration: _fieldDecoration(
                                hint: 'Your full name',
                                errorText: _nameError,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _SectionLabel('Date Of Birth', required: true),
                            const SizedBox(height: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _pickDateOfBirth,
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: _kSurfaceContainerLow,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _dobError != null
                                          ? _kError.withValues(alpha: 0.7)
                                          : _kSurfaceContainerHighest,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        color: _dateOfBirth != null
                                            ? _kPrimary
                                            : _kOnSurfaceVariant,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _dateOfBirth != null
                                              ? DateFormat('d MMMM yyyy')
                                                  .format(_dateOfBirth!)
                                              : 'Select date of birth',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color: _dateOfBirth != null
                                                ? _kOnSurface
                                                : _kOnSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: _kOnSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_dobError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _dobError!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _kError,
                                ),
                              ),
                            ],
                            const SizedBox(height: 26),
                            _SectionLabel('Gender', required: true),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 400;
                                final w = isWide
                                    ? (constraints.maxWidth - 12) / 2
                                    : constraints.maxWidth;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    SizedBox(
                                      width: w,
                                      child: _GenderCard(
                                        label: 'Male',
                                        emoji: '👨',
                                        selected: _gender == 'male',
                                        onTap: () => setState(() {
                                          _gender = 'male';
                                          _genderError = null;
                                        }),
                                      ),
                                    ),
                                    SizedBox(
                                      width: w,
                                      child: _GenderCard(
                                        label: 'Female',
                                        emoji: '👩',
                                        selected: _gender == 'female',
                                        onTap: () => setState(() {
                                          _gender = 'female';
                                          _genderError = null;
                                        }),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            if (_genderError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _genderError!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _kError,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomInset),
                      child: _ContinueButton(
                        label: 'Continue',
                        isLoading: isSubmitting,
                        onTap: isSubmitting ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: _kOnSurfaceVariant),
      filled: true,
      fillColor: _kSurfaceContainerLow,
      errorText: errorText,
      errorStyle: GoogleFonts.inter(fontSize: 12, color: _kError),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kSurfaceContainerHighest),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _kError.withValues(alpha: 0.7)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool required;

  const _SectionLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kOnSurface,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
      ],
    );
  }
}

class _AvatarHero extends StatelessWidget {
  final String assetPath;

  const _AvatarHero({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(assetPath),
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [_kPrimary, _kPrimaryDim],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3.5),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _kSurfaceContainerLow,
          ),
          child: ClipOval(
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person_rounded,
                size: 56,
                color: _kOnSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? _kPrimary.withValues(alpha: 0.14)
              : _kSurfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kPrimary : _kSurfaceContainerHighest,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: selected ? _kOnSurface : _kOnSurfaceVariant,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ContinueButton({
    required this.label,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null && !isLoading;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        height: 56,
        decoration: BoxDecoration(
          gradient: active || isLoading
              ? const LinearGradient(colors: [_kPrimary, _kPrimaryDim])
              : null,
          color: active || isLoading ? null : _kSurfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
          boxShadow: active || isLoading
              ? [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.3),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kSurfaceContainerLowest,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: active
                        ? _kSurfaceContainerLowest
                        : _kOnSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }
}
