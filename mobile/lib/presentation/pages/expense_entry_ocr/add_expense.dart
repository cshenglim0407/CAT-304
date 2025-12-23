import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class AddExpensePage extends StatefulWidget {
  final String accountName;
  final String category;

  const AddExpensePage({
    super.key,
    required this.accountName,
    required this.category,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _itemController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitPriceController = TextEditingController();
  
  double _totalPrice = 0.0;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_calculateTotal);
    _unitPriceController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _itemController.dispose();
    _qtyController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    setState(() {
      _totalPrice = qty * unitPrice;
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
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveExpense() {
    if (_totalPrice <= 0 || _itemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter item name and valid price")),
      );
      return;
    }

    final newTransaction = {
      'amount': _totalPrice,
      'category': widget.category,
      'itemName': _itemController.text,
      'quantity': _qtyController.text,
      'unitPrice': _unitPriceController.text,
      'date': _selectedDate,
      'accountName': widget.accountName,
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
                  child: _buildInfoBadge(
                    context, 
                    icon: Icons.category, 
                    label: widget.category, 
                    color: primaryColor 
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBadge(
                    context, 
                    icon: Icons.account_balance_wallet, 
                    label: widget.accountName, 
                    color: primaryColor 
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 2. TOTAL EXPENSE DISPLAY ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    "Total Expense",
                    style: TextStyle(
                      color: primaryColor, 
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Inner White Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        "\$${_totalPrice.toStringAsFixed(2)}",
                        style: TextStyle(
                          // UPDATED: Uses Grey if 0, otherwise uses Primary Color
                          color: _totalPrice == 0 ? Colors.grey[400] : primaryColor,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // --- 3. Date Input ---
            Text("Date to Spend", style: AppTypography.labelLarge.copyWith(color: AppColors.greyText)),
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
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- 4. Item Name ---
            _buildLabel("Item Name"),
            TextField(
              controller: _itemController,
              decoration: _inputDecoration("e.g. Chicken Rice", fieldColor),
            ),
            const SizedBox(height: 20),

            // --- 5. Quantity & Unit Price ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Quantity"),
                      TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("1", fieldColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Unit Price"),
                      TextField(
                        controller: _unitPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration("0.00", fieldColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- Save Button ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  // --- UI Helpers ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: AppTypography.labelLarge.copyWith(color: AppColors.greyText)),
    );
  }

  InputDecoration _inputDecoration(String hint, Color fillColor) {
    return InputDecoration(
      hintText: hint,
      // Ensure hint text is grey as well
      hintStyle: const TextStyle(color: Colors.grey), 
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildInfoBadge(BuildContext context, {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label, 
              style: AppTypography.bodySmall.copyWith(
                color: color, 
                fontWeight: FontWeight.bold,
                fontSize: 12
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}