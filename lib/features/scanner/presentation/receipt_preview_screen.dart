import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import '../../dashboard/providers/receipt_provider.dart';

class ReceiptPreviewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialData;
  final String imagePath;

  const ReceiptPreviewScreen({
    super.key,
    required this.initialData,
    required this.imagePath,
  });

  @override
  ConsumerState<ReceiptPreviewScreen> createState() =>
      _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends ConsumerState<ReceiptPreviewScreen> {
  late TextEditingController _merchantController;
  late TextEditingController _dateController;
  late TextEditingController _totalController;

  List<Map<String, dynamic>> _editableItems = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.initialData['merchant_name']?.toString(),
    );
    _dateController = TextEditingController(
      text: widget.initialData['date']?.toString(),
    );
    _totalController = TextEditingController(
      text: widget.initialData['total_amount']?.toString(),
    );

    if (widget.initialData['items'] != null) {
      for (var item in widget.initialData['items']) {
        _editableItems.add({
          'nameController': TextEditingController(
            text: item['item_name']?.toString(),
          ),
          'qtyController': TextEditingController(
            text: (item['quantity'] ?? 1).toString(),
          ),
          'priceController': TextEditingController(
            text: item['price']?.toString(),
          ),
          'category': item['category'] ?? 'Other',
        });
      }
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _dateController.dispose();
    _totalController.dispose();
    for (var item in _editableItems) {
      item['nameController'].dispose();
      item['qtyController'].dispose();
      item['priceController'].dispose();
    }
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _editableItems.add({
        'nameController': TextEditingController(),
        'qtyController': TextEditingController(text: '1'),
        'priceController': TextEditingController(),
        'category': 'Other',
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = _editableItems.removeAt(index);
      item['nameController'].dispose();
      item['qtyController'].dispose();
      item['priceController'].dispose();
    });
  }

  Future<void> _saveCorrectedData() async {
    setState(() => _isSaving = true);

    List<Map<String, dynamic>> finalItems = _editableItems.map((item) {
      return {
        'item_name': item['nameController'].text.trim(),
        'quantity': int.tryParse(item['qtyController'].text) ?? 1,
        'price': double.tryParse(item['priceController'].text) ?? 0.0,
        'category': item['category'],
      };
    }).toList();

    Map<String, dynamic> finalData = {
      'merchant_name': _merchantController.text.trim(),
      'date': _dateController.text.trim(),
      'total_amount': double.tryParse(_totalController.text) ?? 0.0,
      'receipt_category': widget.initialData['receipt_category'] ?? 'Other',
      'tax_amount': widget.initialData['tax_amount'],
      'items': finalItems,
    };

    try {
      await DatabaseHelper.instance.saveReceiptFromGemini(
        finalData,
        widget.imagePath,
      );
      await ref.read(dashboardProvider.notifier).refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt saved successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
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
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review Receipt',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFFE0F7FA),
            ),
            onPressed: _addNewItem,
            tooltip: 'Add missing item',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Main Details ---
                    _buildGlassContainer(
                      child: Column(
                        children: [
                          _buildTextField(
                            _merchantController,
                            'Merchant Name',
                            Icons.storefront_outlined,
                          ),
                          const Divider(color: Colors.white12, height: 1),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _dateController,
                                  'YYYY-MM-DD',
                                  Icons.calendar_today_outlined,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.white12,
                              ),
                              Expanded(
                                child: _buildTextField(
                                  _totalController,
                                  'Total (₹)',
                                  Icons.currency_rupee_outlined,
                                  isNumber: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      'Line Items',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Line Items
                    ..._editableItems.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildGlassContainer(
                          child: Column(
                            children: [
                              // Top Row: Item Name + Delete Button
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      item['nameController'],
                                      'Item Name',
                                      Icons.fastfood_outlined,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.redAccent,
                                      size: 22,
                                    ),
                                    onPressed: () => _removeItem(index),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white12, height: 1),
                              // Bottom Row: Quantity + Price
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: _buildTextField(
                                      item['qtyController'],
                                      'Qty',
                                      Icons.numbers_rounded,
                                      isNumber: true,
                                      isCenter: true,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 50,
                                    color: Colors.white12,
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildTextField(
                                      item['priceController'],
                                      'Total Price',
                                      Icons.currency_rupee_outlined,
                                      isNumber: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Glowing Gradient Save Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: _isSaving ? null : _saveCorrectedData,
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
                            'Confirm & Save',
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
    );
  }

  // Helper widget to generate consistent text fields
  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isNumber = false,
    bool isCenter = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textAlign: isCenter ? TextAlign.center : TextAlign.start,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        prefixIcon: isCenter
            ? null
            : Icon(icon, color: Colors.white54, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isCenter ? 15 : 12,
        ),
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
