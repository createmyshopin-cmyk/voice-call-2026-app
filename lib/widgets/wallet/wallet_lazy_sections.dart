import 'package:flutter/material.dart';

/// Client-side lazy batches for the wallet tab (no paginated API).
class WalletLazySections extends ChangeNotifier {
  static const int transactionBatch = 6;
  static const int packageBatch = 4;

  int transactionVisible = transactionBatch;
  int packageVisible = packageBatch;

  void reset() {
    transactionVisible = transactionBatch;
    packageVisible = packageBatch;
    notifyListeners();
  }

  void syncTotals({
    required int transactionTotal,
    required int packageTotal,
  }) {
    transactionVisible = transactionVisible.clamp(0, transactionTotal);
    packageVisible = packageVisible.clamp(0, packageTotal);
  }

  void loadMoreTransactions(int total) {
    if (transactionVisible >= total) return;
    transactionVisible =
        (transactionVisible + transactionBatch).clamp(0, total);
    notifyListeners();
  }

  void showAllTransactions(int total) {
    if (transactionVisible >= total) return;
    transactionVisible = total;
    notifyListeners();
  }

  void loadMorePackages(int total) {
    if (packageVisible >= total) return;
    packageVisible = (packageVisible + packageBatch).clamp(0, total);
    notifyListeners();
  }
}
