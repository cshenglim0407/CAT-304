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
  late TextEditingController _transactionNameController;

  final List<Map<String, TextEditingController>> _expenseItems = [];

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
    
    // --- 1. PARSE TOTAL AMOUNT ---
    double rawAmount = 0.0;
    if (widget.transaction['rawAmount'] != null) {
      rawAmount = (widget.transaction['rawAmount'] as num).toDouble();
    } else {
      String amtStr = widget.transaction['amount'].toString();
      String cleanStr = amtStr.replaceAll(RegExp(r'[^0-9.]'), '');
      rawAmount = double.tryParse(cleanStr) ?? 0.0;
    }
    _amountController = TextEditingController(text: rawAmount.toStringAsFixed(2));

    // --- 2. SETUP NAME CONTROLLER ---
    _transactionNameController = TextEditingController(text: widget.transaction['title'] ?? '');

    // --- 3. INITIALIZE ITEMS ---
    if (_type == 'expense') {
      _initExpenseItems(rawAmount);
    }
    
    // --- 4. CATEGORY & ACCOUNT ---
    String? initialCat = widget.transaction['category'];
    List<String> targetList = (_type == 'income') ? _incomeCategories : _expenseCategories;
    
    if (initialCat != null && targetList.contains(initialCat)) {
        _selectedCategory = initialCat;
    } else {
        _selectedCategory = targetList.isNotEmpty ? targetList[0] : 'Others';
    }
    
    _selectedToAccount = widget.transaction['toAccount'];
  }

  void _initExpenseItems(double totalAmount) {
    if (widget.transaction['items'] != null && (widget.transaction['items'] as List).isNotEmpty) {
      final savedItems = widget.transaction['items'] as List;
      for (var item in savedItems) {
        String q = (item['qty'] ?? '1').toString();
        // Ensure initial prices are formatted to 2 decimals
        double pVal = (item['unitPrice'] ?? item['price'] ?? 0).toDouble();
        String p = pVal.toStringAsFixed(2);
        
        String n = (item['name'] ?? '').toString();
        _addExpenseItemRow(name: n, qty: q, price: p);
      }
    } else {
      String itemName = widget.transaction['itemName'] ?? widget.transaction['title'] ?? '';
      dynamic rawQty = widget.transaction['qty'];
      dynamic rawUP = widget.transaction['unitPrice'];
      
      String qtyStr = (rawQty != null) ? rawQty.toString() : "1";
      // Ensure initial fallback price is formatted
      double upVal = (rawUP != null) ? rawUP.toDouble() : totalAmount;
      String uPriceStr = upVal.toStringAsFixed(2);

      _addExpenseItemRow(name: itemName, qty: qtyStr, price: uPriceStr);
    }
  }

  void _addExpenseItemRow({String name = '', String qty = '1', String price = '0.00'}) {
    final nameCtrl = TextEditingController(text: name);
    final qtyCtrl = TextEditingController(text: qty);
    final priceCtrl = TextEditingController(text: price);

    qtyCtrl.addListener(_calculateExpenseTotal);
    priceCtrl.addListener(_calculateExpenseTotal);

    setState(() {
      _expenseItems.add({
        'name': nameCtrl,
        'qty': qtyCtrl,
        'price': priceCtrl,
      });
    });
    
    _calculateExpenseTotal();
  }

  void _removeExpenseItemRow(int index) {
    if (_expenseItems.length > 1) {
      final removed = _expenseItems[index];
      removed['name']?.dispose();
      removed['qty']?.dispose();
      removed['price']?.dispose();

      setState(() {
        _expenseItems.removeAt(index);
      });
      _calculateExpenseTotal();
    }
  }

  void _calculateExpenseTotal() {
    double total = 0.0;
    for (var item in _expenseItems) {
      final q = double.tryParse(item['qty']?.text ?? '0') ?? 0.0;
      final p = double.tryParse(item['price']?.text ?? '0') ?? 0.0;
      total += (q * p);
    }
    _amountController.text = total.toStringAsFixed(2);
  }

  // --- NEW: Helper to format price to 2 decimals ---
  void _formatPriceField(TextEditingController controller) {
    final text = controller.text;
    if (text.isNotEmpty) {
      final val = double.tryParse(text);
      if (val != null) {
        // Only update if it actually changes the visual string (avoids cursor jumping unnecessarily)
        final formatted = val.toStringAsFixed(2);
        if (formatted != text) {
          controller.text = formatted;
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionNameController.dispose();
    for (var item in _expenseItems) {
      item['name']?.dispose();
      item['qty']?.dispose();
      item['price']?.dispose();
    }
    super.dispose();
  }

  void _saveChanges() {
    double newAmount = double.tryParse(_amountController.text) ?? 0.0;
    String newTitle = _transactionNameController.text.trim();
    List<Map<String, dynamic>> finalItems = [];

    if (_type == 'expense') {
      for (var item in _expenseItems) {
        String n = item['name']!.text.trim();
        String q = item['qty']!.text.trim();
        String p = item['price']!.text.trim();
        
        if (n.isNotEmpty) {
          finalItems.add({
            'name': n,
            'qty': double.tryParse(q) ?? 1.0,
            'unitPrice': double.tryParse(p) ?? 0.0,
          });
        }
      }
      
      if (newTitle.isEmpty) {
         List<String> names = finalItems.map((e) => e['name'] as String).toList();
         newTitle = names.isNotEmpty ? names.join(", ") : (_selectedCategory ?? "Expense");
      }
    } 
    else if (_type == 'transfer') {
      if (_selectedToAccount == null) return; 
      newTitle = "Transfer to $_selectedToAccount";
    } 
    else {
      if (newTitle.isEmpty) newTitle = _selectedCategory ?? "Income";
    }

    final updatedTransaction = {
      ...widget.transaction,
      'title': newTitle,
      'rawAmount': newAmount,
      'amount': (_type == 'income' ? '+ \$' : '- \$') + newAmount.toStringAsFixed(2),
      'isRecurrent': _isRecurrent,
      'category': _selectedCategory,
      'toAccount': _selectedToAccount,
      'items': finalItems,
    };

    if (_type == 'expense' && _expenseItems.isNotEmpty) {
       updatedTransaction['itemName'] = _expenseItems[0]['name']!.text;
    }

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
        _buildAmountBox(color, readOnly: false), 
        const SizedBox(height: 20),
        TextField(
            controller: _transactionNameController, 
            decoration: _inputDecoration(hint: "Income Source")
        ),
        const SizedBox(height: 20),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
        ),
        const SizedBox(height: 8),
        _buildDropdown(
          label: null,
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
        _buildAmountBox(color, readOnly: false),
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
        _buildAmountBox(color, readOnly: true),
        const SizedBox(height: 20),
        
        const Text("Transaction Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
            controller: _transactionNameController, 
            decoration: _inputDecoration(hint: "e.g. Grocery Shopping")
        ),
        const SizedBox(height: 20),
        
        const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildDropdown(
          label: null,
          value: _selectedCategory,
          items: _expenseCategories,
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
        const SizedBox(height: 30),
        
        const Text("Items List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),

        ...List.generate(_expenseItems.length, (index) {
           return _buildExpenseItemRow(index);
        }),
      ],
    );
  }

  Widget _buildExpenseItemRow(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Item ${index + 1}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (_expenseItems.length > 1)
                InkWell(
                  onTap: () => _removeExpenseItemRow(index),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                )
            ],
          ),
          const SizedBox(height: 8),
          
          TextField(
            controller: _expenseItems[index]['name'], 
            decoration: _inputDecoration(hint: "Item name (e.g. Milk)")
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expenseItems[index]['qty'],
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(hint: "Qty", label: "Qty"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _expenseItems[index]['price'],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(hint: "0.00", label: "Unit Price"),
                  // --- CHANGE: Auto-format on focus loss ---
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                    _formatPriceField(_expenseItems[index]['price']!);
                  },
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                    _formatPriceField(_expenseItems[index]['price']!);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBox(Color color, {required bool readOnly}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(readOnly ? "Total Amount" : "Amount", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          TextField(
            controller: _amountController,
            readOnly: readOnly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 40, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({String? label, required String? value, required List<String> items, required Function(String?) onChanged}) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              hint: Text("Select ${label ?? 'Option'}"),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint, String? label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: AppColors.greyLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}