import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';

// 1. Simple class to hold all our calculated dashboard data
class DashboardState {
  final List<Map<String, dynamic>> receipts;
  final double totalSpentThisMonth;
  final Map<String, double> categoryTotals;
  final bool isLoading;

  DashboardState({
    this.receipts = const [],
    this.totalSpentThisMonth = 0.0,
    this.categoryTotals = const {},
    this.isLoading = true,
  });
}

// 2. Notifier that fetches and processes the SQLite data
class ReceiptNotifier extends StateNotifier<DashboardState> {
  ReceiptNotifier() : super(DashboardState()) {
    refreshData();
  }

  Future<void> refreshData() async {
    state = DashboardState(isLoading: true, receipts: state.receipts);

    final rawReceipts = await DatabaseHelper.instance.getAllReceipts();
    
    double monthlyTotal = 0.0;
    Map<String, double> catTotals = {};

    final now = DateTime.now();

    for (var receipt in rawReceipts) {
      final date = DateTime.parse(receipt['purchase_date']);
      final amount = receipt['total_amount'] as double;
      final category = receipt['category_name'] ?? 'Other';

      if (date.month == now.month && date.year == now.year) {
        monthlyTotal += amount;
        
        if (catTotals.containsKey(category)) {
          catTotals[category] = catTotals[category]! + amount;
        } else {
          catTotals[category] = amount;
        }
      }
    }

    state = DashboardState(
      receipts: rawReceipts,
      totalSpentThisMonth: monthlyTotal,
      categoryTotals: catTotals,
      isLoading: false,
    );
  }
}

final dashboardProvider = StateNotifierProvider<ReceiptNotifier, DashboardState>((ref) {
  return ReceiptNotifier();
});