import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';

class EditTransactionPage extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final List<String> availableAccounts;
  final String currentAccountName;

  const EditTransactionPage({
    super.key, 
    required this.transaction,
    required this.availableAccounts,
    required this.currentAccountName,
  });

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  late TextEditingController _amountController;
  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  late TextEditingController _unitPriceController;

  late String _type;
  late bool _isRecurrent;
  String? _selectedCategory;
  String? _selectedToAccount;
  
  final List<String> _incomeCategories = [
    'Salary', 'Allowance', 'Bonus', 'Dividend', 'Investment', 'Rental', 'Refund', 'Sale', 'Others'
  ];
  final List<String> _expenseCategories = [
    'FOOD', 'TRANSPORT', 'ENTERTAINMENT', 'UTILITIES', 'HEALTHCARE',
    'SHOPPING', 'TRAVEL', 'EDUCATION', 'RENT', 'OTHER'
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.transaction['type'] ?? 'expense';
    _isRecurrent = widget.transaction['isRecurrent'] ?? false;
    
    // --- 1. SAFE AMOUNT PARSING ---
    double rawAmount = 0.0;
    if (widget.transaction['rawAmount'] != null) {
      rawAmount = (widget.transaction['rawAmount'] as num).toDouble();
    } else {
      String amtStr = widget.transaction['amount'].toString();
      String cleanStr = amtStr.replaceAll(RegExp(r'[^0-9.]'), '');
      rawAmount = double.tryParse(cleanStr) ?? 0.0;
    }

    _amountController = TextEditingController(text: rawAmount.toStringAsFixed(2));
    _nameController = TextEditingController(text: widget.transaction['title']);
    
    // --- 2. SAFE EXPENSE DATA PARSING (The Fix) ---
    // Handle Quantity (could be String or Int)
    dynamic rawQty = widget.transaction['qty'];
    String qtyStr = "1"; // Default
    if (rawQty != null) {
      qtyStr = rawQty.toString(); 
    }
    _qtyController = TextEditingController(text: qtyStr);

    // Handle Unit Price (could be String or Double)
    dynamic rawUP = widget.transaction['unitPrice'];
    double uPrice = rawAmount; // Default to total amount if missing
    if (rawUP != null) {
        if (rawUP is num) {
            uPrice = rawUP.toDouble();
        } else if (rawUP is String) {
            uPrice = double.tryParse(rawUP) ?? rawAmount;
        }
    }
    _unitPriceController = TextEditingController(text: uPrice.toStringAsFixed(2));
    
    // --- 3. CATEGORY LOGIC ---
    String? initialCat = widget.transaction['category'];
    if (_type == 'income') {
        if (initialCat != null && _incomeCategories.contains(initialCat)) {
            _selectedCategory = initialCat;
        } else {
            _selectedCategory = _incomeCategories[0];
        }
    } else {
        if (initialCat != null && _expenseCategories.contains(initialCat)) {
            _selectedCategory = initialCat;
        } else {
            _selectedCategory = _expenseCategories[0];
        }
    }
    
    _selectedToAccount = widget.transaction['toAccount'];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _qtyController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    double newAmount = double.tryParse(_amountController.text) ?? 0.0;
    String newTitle = _nameController.text;

    if (_type == 'transfer') {
      if (_selectedToAccount == null) return; 
      newTitle = "Transfer to $_selectedToAccount";
    } else if (_type == 'income') {
        newTitle = _selectedCategory ?? "Income";
    } 

    final updatedTransaction = {
      ...widget.transaction,
      'title': newTitle,
      'rawAmount': newAmount,
      'amount': (_type == 'income' ? '+ \$' : '- \$') + newAmount.toStringAsFixed(2),
      'isRecurrent': _isRecurrent,
      'category': _selectedCategory,
      'toAccount': _selectedToAccount,
      // Save numeric values safely
      'qty': double.tryParse(_qtyController.text) ?? 1,
      'unitPrice': double.tryParse(_unitPriceController.text) ?? newAmount,
    };

    Navigator.pop(context, updatedTransaction);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Edit ${_type[0].toUpperCase()}${_type.substring(1)}"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_type == 'income') _buildIncomeForm(primaryColor),
              if (_type == 'transfer') _buildTransferForm(primaryColor),
              if (_type == 'expense') _buildExpenseForm(primaryColor),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saveChanges,
                  child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeForm(Color color) {
    return Column(
      children: [
        _buildAmountBox(color), 
        const SizedBox(height: 20),
        _buildDropdown(
          label: "Category",
          value: _selectedCategory,
          items: _incomeCategories,
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: color,
          title: const Text("Recurring Income"),
          value: _isRecurrent,
          onChanged: (val) => setState(() => _isRecurrent = val),
        ),
      ],
    );
  }

  Widget _buildTransferForm(Color color) {
    final validAccounts = widget.availableAccounts.where((a) => a != widget.currentAccountName).toList();
    
    return Column(
      children: [
        _buildAmountBox(color),
        const SizedBox(height: 20),
        _buildDropdown(
          label: "Transfer To Account",
          value: _selectedToAccount ?? (validAccounts.isNotEmpty ? validAccounts[0] : null),
          items: validAccounts,
          onChanged: (val) => setState(() => _selectedToAccount = val),
        ),
      ],
    );
  }

  Widget _buildExpenseForm(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAmountBox(color), 
        const SizedBox(height: 20),
        _buildDropdown(
          label: "Category",
          value: _selectedCategory,
          items: _expenseCategories,
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
        const SizedBox(height: 20),
        const Text("Item Name", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(controller: _nameController, decoration: _inputDecoration()),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Quantity", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: _inputDecoration()),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Unit Price", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(controller: _unitPriceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDecoration()),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountBox(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text("Amount", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 40, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<String> items, required Function(String?) onChanged}) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              hint: Text("Select $label"),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.greyLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}