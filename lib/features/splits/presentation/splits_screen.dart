import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../dashboard/providers/receipt_provider.dart';

class SplitsScreen extends ConsumerWidget {
  const SplitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the dashboard provider, but grab ALL receipts, not just this month's
    final dashboardState = ref.watch(dashboardProvider);
    final receipts = dashboardState.allReceipts;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Split Bills',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildGlassContainer(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          if (receipts.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'No receipts found. Scan a bill to start splitting costs with PERSON_1 or your other friends!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: receipts.length,
                itemBuilder: (context, index) {
                  final receipt = receipts[index];
                  final rawDate = DateTime.parse(receipt['purchase_date']);
                  final formattedDate = DateFormat(
                    'dd MMM yyyy',
                  ).format(rawDate);
                  final formattedAmount = NumberFormat.currency(
                    symbol: '₹',
                    decimalDigits: 2,
                  ).format(receipt['total_amount']);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildSplitCard(
                      context: context,
                      merchantName: receipt['merchant_name'],
                      date: formattedDate,
                      totalAmount: formattedAmount,
                      onTap: () {
                        // TODO: Navigate to the Line-Item Assignment Screen!
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Line-item assignment screen coming next!',
                            ),
                            backgroundColor: Colors.teal,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 80), // Padding to avoid the floating notch
        ],
      ),
    );
  }

  Widget _buildSplitCard({
    required BuildContext context,
    required String merchantName,
    required String date,
    required String totalAmount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Color(0xFFE0F7FA),
                    ),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF8BBD0,
                          ), // Pastel Pink to match the theme
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF8BBD0).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Split It',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
