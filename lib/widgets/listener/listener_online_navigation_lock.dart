import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom-nav index for the Listener dashboard (listener role only).
const int kListenerDashboardTabIndex = 3;

/// Tabs blocked while the listener is online.
const Set<int> kListenerOnlineBlockedTabIndices = {0, 1, 2, 4};

bool isListenerTabBlockedWhenOnline(int tabIndex) =>
    kListenerOnlineBlockedTabIndices.contains(tabIndex);

enum ListenerOnlineExitChoice { stayOnline, goOffline }

/// Shows the navigation lock dialog when a listener tries to leave while online.
Future<ListenerOnlineExitChoice?> showListenerOnlineExitDialog(
  BuildContext context,
) {
  return showDialog<ListenerOnlineExitChoice>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'You are currently online',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          'You must go offline before leaving the Listener Dashboard.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.45,
            color: const Color(0xFF4B5563),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              ListenerOnlineExitChoice.stayOnline,
            ),
            child: Text(
              'Stay Online',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              ListenerOnlineExitChoice.goOffline,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8A2BE2),
            ),
            child: Text(
              'Go Offline & Continue',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    },
  );
}
