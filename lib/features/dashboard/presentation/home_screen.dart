import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/receipt_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    if (dashboardState.isLoading && dashboardState.receipts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE0F7FA)),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFFE0F7FA),
        backgroundColor: const Color(0xFF2C2C2E),
        onRefresh: () => ref.read(dashboardProvider.notifier).refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 30),
              _buildSpendingSummary(dashboardState.totalSpentThisMonth),
              const SizedBox(height: 30),
              _buildChartSection(dashboardState),
              const SizedBox(height: 40),
              const Text(
                'Recent Receipts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // List of scanned receipts
              if (dashboardState.receipts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'No receipts yet. Tap the scanner to begin!',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dashboardState.receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = dashboardState.receipts[index];
                    final rawDate = DateTime.parse(receipt['purchase_date']);
                    final formattedDate = DateFormat(
                      'dd-MM-yyyy',
                    ).format(rawDate);
                    final formattedAmount = NumberFormat.currency(
                      symbol: '₹',
                      decimalDigits: 2,
                    ).format(receipt['total_amount']);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildReceiptCard(
                        merchantName: receipt['merchant_name'],
                        category: receipt['category_name'] ?? 'Other',
                        date: formattedDate,
                        totalAmount: formattedAmount,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildGlassContainer(
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.notifications_none, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSpendingSummary(double totalSpent) {
    final formattedTotal = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    ).format(totalSpent);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildGlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: const [
              Text('This Month', style: TextStyle(color: Colors.white)),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
            ],
          ),
        ),
        RichText(
          text: TextSpan(
            text: 'Total Spent  ',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
            children: [
              TextSpan(
                text: formattedTotal,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(DashboardState state) {
    final formattedTotal = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    ).format(state.totalSpentThisMonth);

    // Pie chart sections based on  SQLite
    List<PieChartSectionData> sections = [];
    if (state.categoryTotals.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: Colors.white12,
          value: 1,
          radius: 15,
          showTitle: false,
        ),
      );
    } else {
      state.categoryTotals.forEach((category, amount) {
        final style = _getCategoryStyling(category);
        sections.add(
          PieChartSectionData(
            color: style['color'],
            value: amount,
            radius: 15,
            showTitle: false,
          ),
        );
      });
    }

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 75,
              startDegreeOffset: -90,
              sections: sections,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedTotal,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Total this month',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategoryStyling(String category) {
    switch (category) {
      case 'Groceries':
        return {
          'icon': Icons.local_grocery_store_outlined,
          'color': const Color(0xFFE1BEE7),
        };
      case 'Food & Dining':
        return {
          'icon': Icons.restaurant_outlined,
          'color': const Color(0xFFB2DFDB),
        };
      case 'Travel & Transport':
        return {
          'icon': Icons.directions_car_outlined,
          'color': const Color(0xFFFFCCBC),
        };
      case 'Shopping & Retail':
        return {
          'icon': Icons.shopping_bag_outlined,
          'color': const Color(0xFFF8BBD0),
        };
      case 'Electronics':
        return {
          'icon': Icons.devices_other_outlined,
          'color': const Color(0xFFFFF9C4),
        };
      case 'Health & Pharmacy':
        return {
          'icon': Icons.medical_services_outlined,
          'color': const Color(0xFFC8E6C9),
        };
      case 'Home & Maintenance':
        return {
          'icon': Icons.home_repair_service_outlined,
          'color': const Color(0xFFD7CCC8),
        };
      case 'Entertainment':
        return {
          'icon': Icons.sports_esports_outlined,
          'color': const Color(0xFFBBDEFB),
        };
      case 'Utility Bills':
        return {'icon': Icons.bolt_outlined, 'color': const Color(0xFFB3E5FC)};
      case 'Other':
      default:
        return {
          'icon': Icons.receipt_long_outlined,
          'color': const Color(0xFFCFD8DC),
        };
    }
  }

  Widget _buildReceiptCard({
    required String merchantName,
    required String category,
    required String date,
    required String totalAmount,
  }) {
    final style = _getCategoryStyling(category);

    return _buildGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: style['color'],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(style['icon'], color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalAmount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    required EdgeInsets padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
