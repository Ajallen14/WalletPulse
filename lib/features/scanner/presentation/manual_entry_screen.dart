import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';
import '../../dashboard/providers/receipt_provider.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Other';
  bool _isSaving = false;

  final List<String> _categories = [
    'Groceries',
    'Food & Dining',
    'Travel & Transport',
    'Shopping & Retail',
    'Electronics',
    'Health & Pharmacy',
    'Home & Maintenance',
    'Entertainment',
    'Utility Bills',
    'Other',
  ];

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Brings in your custom colors and icons from the dashboard
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF8BBD0), // Pastel Pink highlights
              onPrimary: Colors.black,
              surface: Color(0xFF2C2C2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_amountController.text.isEmpty ||
        double.tryParse(_amountController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final manualData = {
        'merchant_name': _merchantController.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'total_amount': double.parse(_amountController.text.trim()),
        'tax_amount': null,
        'receipt_category': _selectedCategory,
        'items': [],
      };

      await DatabaseHelper.instance.saveReceiptFromGemini(manualData, '');
      await ref.read(dashboardProvider.notifier).refreshData();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          'Manual Entry',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'How much did you spend?',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Giant Amount Input (Fintech Style)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 40,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IntrinsicWidth(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                hintStyle: TextStyle(color: Colors.white24),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Glassmorphic Details Card
                      _buildGlassContainer(
                        child: Column(
                          children: [
                            // Merchant Name Field
                            TextFormField(
                              controller: _merchantController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                              decoration: const InputDecoration(
                                hintText: 'Merchant Name',
                                hintStyle: TextStyle(color: Colors.white38),
                                prefixIcon: Icon(
                                  Icons.storefront_outlined,
                                  color: Colors.white54,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white12, height: 1),

                            // Date Selector
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: const Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.white54,
                              ),
                              title: Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white24,
                                size: 16,
                              ),
                              onTap: () => _selectDate(context),
                            ),
                            const Divider(color: Colors.white12, height: 1),

                            // Category Selector with Icons
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                dropdownColor: const Color(0xFF262628),
                                icon: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white24,
                                  size: 16,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                items: _categories.map((String category) {
                                  final style = _getCategoryStyling(category);
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: style['color'].withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            style['icon'],
                                            color: style['color'],
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(category),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null)
                                    setState(
                                      () => _selectedCategory = newValue,
                                    );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Glowing Gradient Save Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: GestureDetector(
                  onTap: _isSaving ? null : _saveExpense,
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE0F7FA), Color(0xFFF8BBD0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF8BBD0).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black87,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Save Expense',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }
}
