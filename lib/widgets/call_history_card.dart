import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/call_history_item.dart';

/// Call history list row matching the design spec (dark card + copy).
class CallHistoryCard extends StatelessWidget {
  final CallHistoryItem call;
  final String currentUserId;
  final bool isCreatorView;
  final VoidCallback? onTap;

  const CallHistoryCard({
    super.key,
    required this.call,
    required this.currentUserId,
    this.isCreatorView = false,
    this.onTap,
  });

  static const Color _cardColor = Color(0xFF2C2C2E);
  static const Color _labelColor = Color(0xFF9E9E9E);
  static const Color _valueColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final partyLabel = isCreatorView ? 'User Name' : 'Creator Name';
    final partyValue = call.otherPartyName(currentUserId);
    final amountLabel = isCreatorView ? 'Earnings' : 'Coins Used';
    final amountValue = isCreatorView
        ? '+${call.coinsDeducted}'
        : '${call.coinsDeducted}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(partyLabel, partyValue.isNotEmpty ? partyValue : '—'),
                  const SizedBox(height: 14),
                  _field('Date', call.formattedDate()),
                  const SizedBox(height: 14),
                  _field('Duration', call.formattedDuration()),
                  const SizedBox(height: 14),
                  _field(
                    amountLabel,
                    amountValue,
                    valueColor:
                        isCreatorView ? const Color(0xFF2ECC71) : _valueColor,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => _copySummary(context),
                icon: const Icon(Icons.copy_rounded, color: _valueColor, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                tooltip: 'Copy details',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copySummary(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(
        text: call.copyableSummary(
          isCreatorView: isCreatorView,
          currentUserId: currentUserId,
        ),
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _field(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _labelColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor ?? _valueColor,
          ),
        ),
      ],
    );
  }
}
