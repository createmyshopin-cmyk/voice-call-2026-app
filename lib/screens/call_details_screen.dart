import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/call_history_item.dart';

class CallDetailsScreen extends StatelessWidget {
  final CallHistoryItem call;
  final String currentUserId;
  final String? avatarUrl;
  final bool isCreatorView;

  const CallDetailsScreen({
    super.key,
    required this.call,
    required this.currentUserId,
    this.avatarUrl,
    this.isCreatorView = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = call.otherPartyName(currentUserId);
    final avatar = avatarUrl ?? 'https://i.pravatar.cc/150?u=$name';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
        title: Text(
          'Call Details',
          style: GoogleFonts.poppins(
            color: const Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _headerCard(name, avatar),
          const SizedBox(height: 20),
          _sectionTitle('Session'),
          _detailTile(
            Icons.info_outline,
            'Status',
            call.statusLabel(),
            statusColor: _statusColor(call.status),
          ),
          _detailTile(
            call.isVideo ? Icons.videocam : Icons.call,
            'Type',
            call.isVideo ? 'Video call' : 'Voice call',
          ),
          _detailTile(Icons.timer_outlined, 'Duration', call.formattedDuration()),
          _detailTile(
            Icons.monetization_on_outlined,
            isCreatorView ? 'Coins earned' : 'Coins used',
            '${call.coinsDeducted}',
          ),
          const SizedBox(height: 16),
          _sectionTitle('Timing'),
          _detailTile(Icons.calendar_today_outlined, 'Started', call.formattedStartedAt()),
          if (call.endedAt != null)
            _detailTile(
              Icons.schedule,
              'Ended',
              call.relativeEndTime(),
            ),
          const SizedBox(height: 16),
          _sectionTitle('Reference'),
          _detailTile(Icons.tag, 'Call ID', call.id, mono: true),
          if (call.channelName != null && call.channelName!.isNotEmpty)
            _detailTile(Icons.link, 'Channel', call.channelName!, mono: true),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF2ECC71);
      case 'missed':
      case 'rejected':
        return const Color(0xFFE74C3C);
      case 'cancelled':
        return const Color(0xFF95A5A6);
      default:
        return const Color(0xFF333333);
    }
  }

  Widget _headerCard(String name, String avatar) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 44, backgroundImage: NetworkImage(avatar)),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            call.relativeEndTime(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF999999),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _detailTile(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
    bool mono = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF1493), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF777777),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: mono ? 12 : 15,
                fontWeight: FontWeight.w600,
                color: statusColor ?? const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
