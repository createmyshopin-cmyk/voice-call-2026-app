import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/api_error_message.dart';

class ListenerApplicationScreen extends StatefulWidget {
  const ListenerApplicationScreen({super.key});

  @override
  State<ListenerApplicationScreen> createState() => _ListenerApplicationScreenState();
}

const Color _kSurface = Color(0xFF080E1A);
const Color _kSurfaceCard = Color(0xFF131A28);
const Color _kBorder = Color(0xFF1E2637);
const Color _kPrimary = Color(0xFFBA9EFF);
const Color _kPrimaryGradientEnd = Color(0xFF8455EF);
const Color _kOnSurface = Color(0xFFE0E5F6);
const Color _kOnSurfaceVariant = Color(0xFFA6ABBB);
const Color _kError = Color(0xFFFF8A8A);

class _ListenerApplicationScreenState extends State<ListenerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  String? _selectedAvatarUrl;
  final List<String> _selectedLanguages = [];
  
  final List<String> _availableLanguages = [
    'English',
    'Malayalam',
    'Tamil',
    'Telugu',
    'Hindi',
    'Kannada',
  ];

  final List<String> _sampleAvatars = [
    'https://i.pravatar.cc/150?u=L1',
    'https://i.pravatar.cc/150?u=L2',
    'https://i.pravatar.cc/150?u=L3',
    'https://i.pravatar.cc/150?u=L4',
    'https://i.pravatar.cc/150?u=L5',
    'https://i.pravatar.cc/150?u=L6',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        setState(() {
          _nameController.text = auth.user!.displayName;
          _selectedAvatarUrl = auth.user!.avatarUrl ?? _sampleAvatars[0];
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleLanguage(String lang) {
    setState(() {
      if (_selectedLanguages.contains(lang)) {
        _selectedLanguages.remove(lang);
      } else {
        _selectedLanguages.add(lang);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedAvatarUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile photo')),
      );
      return;
    }

    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one language')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    try {
      await auth.applyForListener(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        languages: _selectedLanguages,
        profileImage: _selectedAvatarUrl!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileSaveErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final status = auth.creatorStatus;

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kSurfaceCard,
        title: Text(
          'Switch to Listener',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (status == 'none' || status == 'rejected') ...[
                _buildFormSection(auth),
              ] else ...[
                _buildStatusSection(status),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Text
          Text(
            'Become a Listener',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share conversations, connect with people, and earn through calls.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _kOnSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Profile Image Picker
          Text(
            'Select Profile Photo *',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kOnSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _sampleAvatars.length,
              itemBuilder: (context, index) {
                final url = _sampleAvatars[index];
                final isSelected = _selectedAvatarUrl == url;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatarUrl = url),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _kPrimary : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(url),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Display Name
          Text(
            'Display Name *',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: _inputDecoration('Enter display name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Display name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Bio
          Text(
            'Bio *',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: _inputDecoration('Tell callers about yourself...'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bio description is required';
              }
              if (value.trim().length < 10) {
                return 'Bio must be at least 10 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Languages Selector
          Text(
            'Languages *',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kOnSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _availableLanguages.map((lang) {
              final isSelected = _selectedLanguages.contains(lang);
              return FilterChip(
                label: Text(
                  lang,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => _toggleLanguage(lang),
                backgroundColor: _kSurfaceCard,
                selectedColor: _kPrimary,
                checkmarkColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? _kPrimary : _kBorder),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),

          // Submit button
          GestureDetector(
            onTap: auth.isLoading ? null : _submit,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kPrimaryGradientEnd],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Center(
                child: auth.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                      )
                    : Text(
                        'Submit Application',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(String status) {
    Color statusColor = Colors.amber;
    String statusTitle = 'Pending Review';
    IconData statusIcon = Icons.pending_actions_rounded;
    String statusMessage = '';

    if (status == 'pending') {
      statusColor = Colors.amber;
      statusTitle = 'Pending Review';
      statusIcon = Icons.hourglass_empty_rounded;
      statusMessage = 'Your listener application is under review.\nWe will notify you once approved.';
    } else if (status == 'suspended') {
      statusColor = Colors.grey;
      statusTitle = 'Suspended';
      statusIcon = Icons.block_flipped;
      statusMessage = 'Your listener profile has been suspended.\nPlease contact admin support for details.';
    }

    return Card(
      color: _kSurfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _kBorder, width: 1.5),
      ),
      elevation: 0,
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Listener Application',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusTitle,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _kOnSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: _kOnSurfaceVariant),
      filled: true,
      fillColor: _kSurfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kError, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
