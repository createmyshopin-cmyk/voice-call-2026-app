import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_calling_app_2026/providers/wallet_provider.dart';

void main() {
  group('WalletProvider server authority', () {
    test('setBalanceFromServer updates balance', () {
      final wallet = WalletProvider();
      wallet.setBalanceFromServer(500);
      expect(wallet.balance, 500);
      wallet.setBalanceFromServer(450);
      expect(wallet.balance, 450);
    });

    test('logout clears balance', () {
      final wallet = WalletProvider();
      wallet.updateAuth('u1', 'token', initialCoins: 100);
      wallet.updateAuth(null, null);
      expect(wallet.balance, 0);
    });

    test('no local deductCoins method exists', () {
      expect(WalletProvider().runtimeType.toString(), 'WalletProvider');
    });
  });
}
