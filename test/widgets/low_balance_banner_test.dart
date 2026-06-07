import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_voice_calling_app_2026/providers/recharge_prompt_provider.dart';
import 'package:flutter_voice_calling_app_2026/widgets/gifts/low_balance_widgets.dart';

void main() {
  testWidgets('Low balance banner shows at 5 minutes', (tester) async {
    final prompt = RechargePromptProvider();
    prompt.setCallContext(coinsPerMinute: 10, peerName: 'Amrutha');
    prompt.updateBalance(50);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: prompt,
          child: Scaffold(
            body: LowBalanceBanner(onTopUp: () {}),
          ),
        ),
      ),
    );

    expect(find.text('Top Up'), findsOneWidget);
    expect(find.byType(LowBalanceBanner), findsOneWidget);
  });

  testWidgets('Sticky card shows at critical balance', (tester) async {
    final prompt = RechargePromptProvider();
    prompt.setCallContext(coinsPerMinute: 10, peerName: 'Amrutha');
    prompt.updateBalance(15);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: prompt,
          child: Scaffold(
            body: LowBalanceStickyCard(onTopUp: () {}),
          ),
        ),
      ),
    );

    expect(find.text('Top Up Now'), findsOneWidget);
  });
}
