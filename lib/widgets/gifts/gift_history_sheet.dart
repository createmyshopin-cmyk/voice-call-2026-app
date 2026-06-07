import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/home_theme.dart';
import '../../models/gift_item.dart';
import '../../providers/auth_provider.dart';
import '../../services/gift_service.dart';
import '../../utils/gift_grouping.dart';

class GiftHistorySheet extends StatefulWidget {
  const GiftHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const GiftHistorySheet(),
    );
  }

  @override
  State<GiftHistorySheet> createState() => _GiftHistorySheetState();
}

class _GiftHistorySheetState extends State<GiftHistorySheet> {
  bool _loading = true;
  List<GroupedGiftLine> _grouped = [];
  final GiftService _service = GiftService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final rows = await _service.fetchSenderHistory(token);
      final records = rows.map((row) {
        final name = row['giftName'] as String? ??
            (row['gift'] as Map?)?['name'] as String? ??
            'Gift';
        final coins = (row['coinsSpent'] as num?)?.toInt() ??
            (row['coin_cost'] as num?)?.toInt() ??
            0;
        return SessionGiftRecord(
          giftName: name,
          giftEmoji: GiftItem(name: name, id: '', coinCost: coins).emoji,
          coinsSpent: coins,
          sentAt: DateTime.tryParse(row['createdAt']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _grouped = groupSessionGifts(records);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Gift History',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: HomeTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_grouped.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No gifts sent yet',
                style: GoogleFonts.poppins(color: HomeTheme.textSecondary),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _grouped.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  final g = _grouped[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${g.giftEmoji} ${g.displayLabel}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: HomeTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${g.totalCoins} Coins',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: HomeTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
