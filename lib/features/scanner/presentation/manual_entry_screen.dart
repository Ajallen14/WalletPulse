import 'dart:ui';
import 'package:flutter/material.dart';
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
    'Groceries', 'Food & Dining', 'Travel & Transport', 'Shopping & Retail',
    'Electronics', 'Health & Pharmacy', 'Home & Maintenance', 'Entertainment',
    'Utility Bills', 'Other'
  ];

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
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
              primary: Color(0xFFE0F7FA),
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

    setState(() => _isSaving = true);

    try {
      final manualData = {
        'merchant_name': _merchantController.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'total_amount': double.parse(_amountController.text.trim()),
        'tax_amount': null,
        'receipt_category': _selectedCategory,
        'items': [], // No line items for manual entry
      };

      await DatabaseHelper.instance.saveReceiptFromGemini(manualData, '');
      
      // Refresh the dashboard
      await ref.read(dashboardProvider.notifier).refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved successfully!'), backgroundColor: Colors.teal),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e'), backgroundColor: Colors.redAccent),
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Manual Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGlassContainer(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _merchantController,
                        label: 'Merchant Name',
                        icon: Icons.storefront_outlined,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      _buildTextField(
                        controller: _amountController,
                        label: 'Total Amount (₹)',
                        icon: Icons.currency_rupee_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter an amount';
                          if (double.tryParse(value) == null) return 'Please enter a valid number';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildGlassContainer(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined, color: Colors.white70),
                        title: const Text('Date', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                        onTap: () => _selectDate(context),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          dropdownColor: const Color(0xFF2C2C2E),
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.category_outlined, color: Colors.white70),
                            prefixIconConstraints: BoxConstraints(minWidth: 40),
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          items: _categories.map((String category) {
                            return DropdownMenuItem(value: category, child: Text(category));
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) setState(() => _selectedCategory = newValue);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0F7FA),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Save Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
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
          child: child,
        ),
      ),
    );
  }
}