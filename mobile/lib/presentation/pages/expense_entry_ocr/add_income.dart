import 'package:flutter/material.dart';

import 'package:cashlytics/core/config/icons.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

class AddIncomePage extends StatefulWidget {
  final String accountName;
  final List<String> availableAccounts;

  const AddIncomePage({
    super.key,
    required this.accountName,
    required this.availableAccounts,
  });

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  final _transactionNameController = TextEditingController();
  final TextEditingController _totalIncomeController = TextEditingController();

  double _totalIncome = 0.0;

  // 1. New variable for the Recurrent feature
  bool _isRecurrent = false;

  String? _selectedAccount;
  String _selectedCategory = 'Salary';
  final List<String> _categories = [
    'Salary',
    'Allowance',
    'Bonus',
    'Dividend',
    'Investment',
    'Rental',
    'Refund',
    'Sale',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.accountName;
  }

  @override
  void dispose() {
    _totalIncomeController.dispose();
    super.dispose();
  }

  // Resolve an icon for an account by its name
  IconData _getAccountIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wallet')) return Icons.account_balance_wallet_rounded;
    if (lower.contains('ewallet') ||
        lower.contains('tng') ||
        lower.contains('touch')) {
      return Icons.phone_iphone_rounded;
    }
    if (lower.contains('card')) return Icons.credit_card_rounded;
    if (lower.contains('cash')) return Icons.payments_rounded;
    if (lower.contains('saving')) return Icons.savings_rounded;
    if (lower.contains('bank') || lower.contains('maybank')) {
      return Icons.account_balance_rounded;
    }
    return Icons.account_balance_wallet_rounded;
  }

  void _saveIncome() {
    final amountText = _totalIncomeController.text;
    if (amountText.isEmpty) return;

    final double amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) return;

    // 2. Prepare the simplified data object
    final newTransaction = {
      'amount': amount,
      'category': _selectedCategory,
      'isRecurrent': _isRecurrent, // The new boolean flag
      'date': DateTime.now(), // defaulting to now
      'accountName': _selectedAccount ?? widget.accountName,
    };

    Navigator.pop(context, newTransaction);
  }

  @override
  Widget build(BuildContext context) {
    // Capture the Primary Color
    final primaryColor = Theme.of(context).colorScheme.primary;

    final primaryTextColor = AppColors.getTextPrimary(context);
    final secondaryTextColor = AppColors.greyText;
    final backgroundColor = AppColors.white;
    final fieldColor = AppColors.greyLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
        title: Text(
          "New Income",
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
                const SizedBox(width: 12),
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
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                        dropdownColor: AppColors.white,
                        items: _categories
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

            // --- 2. Transaction Name Input ---
            const FormLabel(label: "Name", useGreyStyle: true),
            TextField(
              controller: _transactionNameController,
              decoration: CustomInputDecoration.simple(
                "e.g. August Salary",
                fieldColor,
              ),
            ),
            const SizedBox(height: 30),

            // --- 3. Amount Input ---
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
                    "Total Income",
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
                      controller: _totalIncomeController,
                      onChanged: (value) {
                        final cleanValue = value
                            .replaceAll(r'$', '')
                            .replaceAll(',', '');
                        setState(() {
                          _totalIncome = double.tryParse(cleanValue) ?? 0.0;
                        });
                      },
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
            const SizedBox(height: 30),

            // --- 4. Recurrent Switch (New Feature) ---
            Container(
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(12),
                border: _isRecurrent
                    ? Border.all(
                        color: primaryColor.withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : null,
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                activeThumbColor: primaryColor,
                title: Text(
                  "Repeat Monthly?",
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
                subtitle: Text(
                  "Automatically record this income every month",
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                value: _isRecurrent,
                onChanged: (bool value) {
                  setState(() {
                    _isRecurrent = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 40),

            // --- Save Button ---
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
                onPressed: _saveIncome,
                child: Text(
                  "Save Transaction",
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
}
