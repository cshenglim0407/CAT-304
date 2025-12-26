import 'package:flutter/material.dart';

import 'package:cashlytics/core/config/icons.dart';
import 'package:cashlytics/core/utils/math_formatter.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

import 'package:cashlytics/data/services/ocr_service.dart';
import 'package:cashlytics/data/services/receipt_picker.dart';
import 'package:cashlytics/data/models/ocr_result.dart';

class AddExpensePage extends StatefulWidget {
  final String accountName;
  final List<String> availableAccounts;
  final String category;
  final List<String> availableCategories;

  const AddExpensePage({
    super.key,
    required this.accountName,
    required this.availableAccounts,
    required this.category,
    required this.availableCategories,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  // Controller for the overall Transaction Name (e.g. "Grocery Run")
  final TextEditingController _transactionNameController =
      TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // OCR service
  final OCRService _ocrService = OCRService();

  // List of items
  final List<Map<String, TextEditingController>> _items = [];

  String? _selectedAccount;
  String? _selectedCategory;
  double _totalPrice = 0.0;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.accountName;
    _selectedCategory = widget.category;
    _addNewItem();
  }

  @override
  void dispose() {
    _transactionNameController.dispose();
    _totalPriceController.dispose();
    _descriptionController.dispose();
    for (var item in _items) {
      item['name']?.dispose();
      item['qty']?.dispose();
      item['price']?.dispose();
    }
    super.dispose();
  }

  void _addNewItem() {
    final nameParams = TextEditingController();
    final qtyParams = TextEditingController();
    final priceParams = TextEditingController();

    qtyParams.addListener(_calculateTotal);
    priceParams.addListener(_calculateTotal);

    setState(() {
      _items.add({'name': nameParams, 'qty': qtyParams, 'price': priceParams});
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      final removed = _items[index];
      removed['name']?.dispose();
      removed['qty']?.dispose();
      removed['price']?.dispose();

      setState(() {
        _items.removeAt(index);
      });
      _calculateTotal();
    } else {
      _items[0]['name']?.clear();
      _items[0]['qty']?.clear();
      _items[0]['price']?.clear();
      _calculateTotal();
    }
  }

  void _calculateTotal() {
    double tempTotal = 0.0;
    for (var item in _items) {
      final qty = double.tryParse(item['qty']?.text ?? '0') ?? 0.0;
      final price = double.tryParse(item['price']?.text ?? '0') ?? 0.0;
      tempTotal += (qty * price);
    }
    setState(() {
      _totalPrice = tempTotal;
      _totalPriceController.text = tempTotal == 0
          ? ""
          : MathFormatter.formatCurrency(tempTotal);
    });
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _pickDate() async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _scanReceiptAndPrefill() async {
    final image = await ReceiptPicker.pickReceipt();
    if (image == null) return;

    try {
      final OcrResult result = await _ocrService.scanReceipt(image);

      setState(() {
        if (result.merchant != null &&
            _transactionNameController.text.isEmpty) {
          _transactionNameController.text = result.merchant!;
        }

        if (result.date != null) {
          _selectedDate = result.date!;
        }

        if (result.total != null && _items.isNotEmpty) {
          _items[0]['qty']?.text = '1';
          _items[0]['price']?.text = result.total!.toStringAsFixed(2);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OCR failed: $e')));
    }
  }

  // In AddExpensePage.dart

  void _saveExpense() {
    if (_totalPrice <= 0 || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter at least one item and price"),
        ),
      );
      return;
    }

    // 1. Determine Main Transaction Name
    String finalTitle;
    if (_transactionNameController.text.trim().isNotEmpty) {
      finalTitle = _transactionNameController.text.trim();
    } else {
      // Auto-generate: "Milk, Bread, Rice"
      List<String> names = [];
      for (var item in _items) {
        if (item['name']!.text.isNotEmpty) {
          names.add(item['name']!.text);
        }
      }
      finalTitle = names.isNotEmpty ? names.join(", ") : widget.category;
    }

    // 2. Prepare the list of items to save
    // We must convert Controllers to simple Strings here
    List<Map<String, dynamic>> itemsList = _items.map((item) {
      return {
        'name': item['name']!.text,
        'qty': item['qty']!.text,
        'unitPrice': item['price']!.text,
      };
    }).toList();

    final newTransaction = {
      'amount': _totalPrice,
      'category': _selectedCategory ?? widget.category,
      'itemName': finalTitle, // Main title
      'quantity': _items.length > 1 ? '1' : _items[0]['qty']!.text,
      'unitPrice': _items.length > 1
          ? _totalPrice.toString()
          : _items[0]['price']!.text,
      'date': _selectedDate,
      'accountName': _selectedAccount ?? widget.accountName,
      'items': itemsList, // <--- CRITICAL FIX: Sending the list
      'description': _descriptionController.text.trim(),
    };

    Navigator.pop(context, newTransaction);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = AppColors.white;
    final fieldColor = AppColors.greyLight;
    final primaryTextColor = AppColors.getTextPrimary(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
        title: Text(
          "Add Expense",
          style: AppTypography.headline3.copyWith(color: primaryTextColor),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Header Badges ---
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAccount ?? widget.accountName,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                        dropdownColor: AppColors.white,
                        items: widget.availableAccounts
                            .map(
                              (acc) => DropdownMenuItem(
                                value: acc,
                                child: Row(
                                  children: [
                                    Icon(
                                      getAccountTypeIcon(acc),
                                      color: primaryColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        acc,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedAccount = val!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory ?? widget.category,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                        dropdownColor: AppColors.white,
                        items: widget.availableCategories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  children: [
                                    Icon(
                                      getExpenseIcon(cat),
                                      color: primaryColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        cat,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 1b. Scan Receipt Button ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.document_scanner),
                label: const Text("Scan Receipt"),
                onPressed: _scanReceiptAndPrefill,
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. Transaction Name ---
            const FormLabel(label: "Name", useGreyStyle: true),
            TextField(
              controller: _transactionNameController,
              decoration: CustomInputDecoration.simple(
                "e.g. Weekly Groceries",
                fieldColor,
              ),
            ),
            const SizedBox(height: 20),

            // --- 2b. Description (Optional) ---
            const FormLabel(
              label: "Description (optional)",
              useGreyStyle: true,
            ),
            TextField(
              controller: _descriptionController,
              decoration: CustomInputDecoration.simple(
                "Add a description...",
                fieldColor,
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. Date Input ---
            Text(
              "Date",
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.greyText,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_selectedDate),
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200, thickness: 2),
            const SizedBox(height: 20),

            // --- 4. DYNAMIC ITEMS LIST ---
            Text(
              "Items",
              style: AppTypography.headline3.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),

            Column(
              children: List.generate(_items.length, (index) {
                return _buildItemRow(index, fieldColor);
              }),
            ),

            // --- 5. Add Item Button ---
            Center(
              child: TextButton.icon(
                onPressed: _addNewItem,
                icon: Icon(Icons.add_circle, color: primaryColor),
                label: Text(
                  "Add Another Item",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- 6. TOTAL EXPENSE DISPLAY ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    "Total Expense (Read-Only)",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _totalPriceController,
                      enabled: false,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: r"$0.00",
                        hintStyle: TextStyle(
                          color: primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200, thickness: 2),
            const SizedBox(height: 20),

            // --- 7. Save Button ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _saveExpense,
                child: Text(
                  "SAVE EXPENSE",
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget for a single Item Row ---
  Widget _buildItemRow(int index, Color fieldColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Item ${index + 1}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              if (_items.length > 1)
                InkWell(
                  onTap: () => _removeItem(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Item Name
          const FormLabel(label: "Item Name", useGreyStyle: true),
          TextField(
            controller: _items[index]['name'],
            decoration: CustomInputDecoration.simple("e.g. Milk", fieldColor),
          ),
          const SizedBox(height: 12),

          // Qty & Price Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(label: "Quantity", useGreyStyle: true),
                    TextField(
                      controller: _items[index]['qty'],
                      keyboardType: TextInputType.number,
                      decoration: CustomInputDecoration.simple("1", fieldColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(label: "Unit Price", useGreyStyle: true),
                    TextField(
                      controller: _items[index]['price'],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: CustomInputDecoration.simple(
                        "0.00",
                        fieldColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
