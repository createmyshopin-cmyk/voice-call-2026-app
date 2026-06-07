import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_voice_calling_app_2026/models/gift_item.dart';
import 'package:flutter_voice_calling_app_2026/providers/gift_catalog_provider.dart';
import 'package:flutter_voice_calling_app_2026/providers/gift_provider.dart';
import 'package:flutter_voice_calling_app_2026/providers/wallet_provider.dart';
import 'package:flutter_voice_calling_app_2026/widgets/gifts/gift_bottom_sheet.dart';

void main() {
  testWidgets('Gift bottom sheet shows catalog grid', (tester) async {
    final catalog = GiftCatalogProvider();
    final wallet = WalletProvider();
    wallet.updateAuth('user-1', 'token', initialCoins: 5000);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: catalog),
            ChangeNotifierProvider.value(value: wallet),
            ChangeNotifierProvider(create: (_) => GiftProvider()),
          ],
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => GiftBottomSheet.show(
                    context,
                    creatorId: 'creator-1',
                    callId: 'call-1',
                  ),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

  });
}
