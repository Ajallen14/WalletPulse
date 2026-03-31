import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';

class SplitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> receipt;
  const SplitDetailScreen({super.key, required this.receipt});

  @override
  State<SplitDetailScreen> createState() => _SplitDetailScreenState();
}

class _SplitDetailScreenState extends State<SplitDetailScreen> {
  List<Map<String, dynamic>> _lineItems = [];
  bool _isLoading = true;
  
  final Map<String, List<String>> _itemAssignments = {};
  
  final List<String> _friends = ['Me', 'PERSON_1', 'Sarah'];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await DatabaseHelper.instance.getLineItems(widget.receipt['id']);
    setState(() {
      _lineItems = items;
      _isLoading = false;
      for (var item in items) {
        _itemAssignments[item['id']] = [];
      }
    });
  }

  void _toggleAssignment(String itemId, String person) {
    setState(() {
      final assignedTo = _itemAssignments[itemId]!;
      if (assignedTo.contains(person)) {
        assignedTo.remove(person);
      } else {
        assignedTo.add(person);
      }
    });
  }

  double _calculateTotalFor(String person) {
    double total = 0.0;
    for (var item in _lineItems) {
      final assignedTo = _itemAssignments[item['id']]!;
      if (assignedTo.contains(person)) {
        total += (item['price'] / assignedTo.length);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final formattedTotal = NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(widget.receipt['total_amount']);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(widget.receipt['merchant_name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(formattedTotal, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Main Content
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFFF8BBD0))))
            else if (_lineItems.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No line items found for this receipt.', style: TextStyle(color: Colors.white54)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _lineItems.length,
                  itemBuilder: (context, index) {
                    final item = _lineItems[index];
                    final itemId = item['id'];
                    final price = NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(item['price']);
                    final assignedTo = _itemAssignments[itemId]!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildGlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Item Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(item['item_name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                                Text(price, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Interactive Avatar Row
                            Row(
                              children: _friends.map((friend) {
                                final isSelected = assignedTo.contains(friend);
                                return GestureDetector(
                                  onTap: () => _toggleAssignment(itemId, friend),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFF8BBD0) : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFF8BBD0) : Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Text(
                                      friend,
                                      style: TextStyle(
                                        color: isSelected ? Colors.black87 : Colors.white54,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Bottom Summary Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _friends.map((friend) {
                        final total = NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(_calculateTotalFor(friend));
                        return Column(
                          children: [
                            Text(friend, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(total, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Save splits to database
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE0F7FA),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Save Splits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, required EdgeInsets padding}) {
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