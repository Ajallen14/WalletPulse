import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';

class BalancesScreen extends StatefulWidget {
  const BalancesScreen({super.key});

  @override
  State<BalancesScreen> createState() => _BalancesScreenState();
}

class _BalancesScreenState extends State<BalancesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _groupedBalances = [];
  List<Map<String, dynamic>> _history = [];
  double _grandTotalOwed = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final rawDetails = await DatabaseHelper.instance.getDetailedBalances();
    final history = await DatabaseHelper.instance.getSplitHistory();

    Map<String, Map<String, dynamic>> grouped = {};
    double grandTotal = 0.0;

    for (var row in rawDetails) {
      String rawName = row['user_name'];
      String cleanName = rawName
          .trim()
          .split(' ')
          .map(
            (w) => w.isNotEmpty
                ? w[0].toUpperCase() + w.substring(1).toLowerCase()
                : '',
          )
          .join(' ');

      if (!grouped.containsKey(cleanName)) {
        grouped[cleanName] = {
          'totalOwed': 0.0,
          'bills': <Map<String, dynamic>>[],
        };
      }

      double owed = (row['amount_owed_for_bill'] as num).toDouble();
      grouped[cleanName]!['totalOwed'] += owed;
      grouped[cleanName]!['bills'].add({
        'merchant_name': row['merchant_name'],
        'purchase_date': row['purchase_date'],
        'amount': owed,
      });

      grandTotal += owed;
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final finalBalances = sortedKeys.map((k) {
      return {
        'name': k,
        'totalOwed': grouped[k]!['totalOwed'],
        'bills': grouped[k]!['bills'],
      };
    }).toList();

    setState(() {
      _groupedBalances = finalBalances;
      _history = history;
      _grandTotalOwed = grandTotal;
      _isLoading = false;
    });
  }

  Future<void> _markAsPaid(String friendName) async {
    await DatabaseHelper.instance.settleBalance(friendName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$friendName settled up!'),
          backgroundColor: Colors.teal,
        ),
      );
    }
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Friends & Balances',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE0F7FA)),
              )
            : RefreshIndicator(
                color: const Color(0xFFE0F7FA),
                backgroundColor: const Color(0xFF2C2C2E),
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grand Total
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'Total Owed to You',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              NumberFormat.currency(
                                symbol: '₹',
                                decimalDigits: 2,
                              ).format(_grandTotalOwed),
                              style: const TextStyle(
                                color: Color(0xFFE0F7FA),
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Expandable Friends List
                      const Text(
                        'Who Owes You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_groupedBalances.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'You are all settled up!',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        )
                      else
                        ..._groupedBalances.map((b) {
                          final friendName = b['name'];
                          final amount = NumberFormat.currency(
                            symbol: '₹',
                            decimalDigits: 2,
                          ).format(b['totalOwed']);
                          final bills = b['bills'] as List;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildGlassContainer(
                              padding: EdgeInsets.zero,
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(
                                      0xFFF8BBD0,
                                    ).withOpacity(0.2),
                                    child: Text(
                                      friendName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFFF8BBD0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    friendName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Owes $amount',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  iconColor: Colors.white54,
                                  collapsedIconColor: Colors.white54,
                                  children: [
                                    const Divider(
                                      color: Colors.white12,
                                      height: 1,
                                    ),
                                    Container(
                                      color: Colors.black12,
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Bills Breakdown',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Specific Bill details
                                          ...bills.map((bill) {
                                            final date = DateFormat('dd MMM')
                                                .format(
                                                  DateTime.parse(
                                                    bill['purchase_date'],
                                                  ),
                                                );
                                            final billAmount =
                                                NumberFormat.currency(
                                                  symbol: '₹',
                                                  decimalDigits: 2,
                                                ).format(bill['amount']);
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '${bill['merchant_name']} ($date)',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                  Text(
                                                    billAmount,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                          const SizedBox(height: 20),
                                          // Mark Paid Button
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _markAsPaid(friendName),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFE0F7FA,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: const Text(
                                                'Mark as Paid',
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 40),

                      // Split History List
                      const Text(
                        'Split History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_history.isEmpty)
                        const Center(
                          child: Text(
                            'No bills split yet.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      else
                        ..._history.map((receipt) {
                          final date = DateFormat(
                            'dd MMM yyyy',
                          ).format(DateTime.parse(receipt['purchase_date']));
                          final amount = NumberFormat.currency(
                            symbol: '₹',
                            decimalDigits: 2,
                          ).format(receipt['total_amount']);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                receipt['merchant_name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                date,
                                style: const TextStyle(color: Colors.white38),
                              ),
                              trailing: Text(
                                amount,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
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
