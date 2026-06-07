import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/models/gift_item.dart';
import 'package:flutter_voice_calling_app_2026/screens/call_summary_screen.dart';

void main() {
  testWidgets('Call summary groups duplicate gifts for user', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: CallSummaryScreen(
          peerName: 'Amrutha',
          callDurationSeconds: 300,
          callCoins: 50,
          giftCoins: 530,
          totalCoins: 580,
          giftsSent: [
            SessionGiftRecord(
              giftName: 'Rose',
              giftEmoji: '🌹',
              coinsSpent: 10,
              sentAt: now,
            ),
            SessionGiftRecord(
              giftName: 'Rose',
              giftEmoji: '🌹',
              coinsSpent: 10,
              sentAt: now,
            ),
            SessionGiftRecord(
              giftName: 'Rose',
              giftEmoji: '🌹',
              coinsSpent: 10,
              sentAt: now,
            ),
            SessionGiftRecord(
              giftName: 'Princess Crown',
              giftEmoji: '👑',
              coinsSpent: 500,
              sentAt: now,
            ),
            SessionGiftRecord(
              giftName: 'Diamond',
              giftEmoji: '💎',
              coinsSpent: 10,
              sentAt: now,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Gifts Sent'), findsOneWidget);
    expect(find.text('🌹 Rose x3'), findsOneWidget);
    expect(find.text('👑 Princess Crown'), findsOneWidget);
    expect(find.text('💎 Diamond'), findsOneWidget);
  });

  testWidgets('Creator recap shows top gift and count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CallSummaryScreen(
          peerName: 'Goutham',
          callDurationSeconds: 600,
          callCoins: 100,
          giftCoins: 30,
          totalCoins: 130,
          isCreatorView: true,
          giftEarnings: 18,
          giftsReceived: const [
            GiftSummaryEntry(
              senderName: 'Arjun',
              giftName: 'Rose',
              giftEmoji: '🌹',
              coins: 10,
            ),
            GiftSummaryEntry(
              senderName: 'Arjun',
              giftName: 'Rose',
              giftEmoji: '🌹',
              coins: 10,
            ),
            GiftSummaryEntry(
              senderName: 'Priya',
              giftName: 'Heart',
              giftEmoji: '❤️',
              coins: 10,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Top Gift'), findsOneWidget);
    expect(find.text('Gift Count'), findsOneWidget);
    expect(find.text('🌹 Rose'), findsOneWidget);
  });
}
