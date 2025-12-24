import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class AddIncomePage extends StatefulWidget {
  final String accountName;

  const AddIncomePage({super.key, required this.accountName});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  final TextEditingController _amountController = TextEditingController();

  // 1. New variable for the Recurrent feature
  bool _isRecurrent = false;

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
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Salary':
        return Icons.work_rounded;
      case 'Allowance':
        return Icons.volunteer_activism_rounded;
      case 'Bonus':
        return Icons.stars_rounded;
      case 'Dividend':
        return Icons.trending_up_rounded;
      case 'Investment':
        return Icons.account_balance_rounded;
      case 'Rental':
        return Icons.home_work_rounded;
      case 'Refund':
        return Icons.refresh_rounded;
      case 'Sale':
        return Icons.storefront_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  void _saveIncome() {
    final amountText = _amountController.text;
    if (amountText.isEmpty) return;

    final double amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) return;

    // 2. Prepare the simplified data object
    final newTransaction = {
      'amount': amount,
      'category': _selectedCategory,
      'isRecurrent': _isRecurrent, // The new boolean flag
      'date': DateTime.now(), // defaulting to now
      'accountName': widget.accountName,
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
            // --- 1. Amount Input ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    "Amount",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextField(
                    controller: _amountController,
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
                      // --- FIXED: Placeholder set to 0.00 ---
                      hintText: r"$0.00",
                      hintStyle: TextStyle(
                        color: primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. Category Dropdown ---
            Text(
              "Category",
              style: AppTypography.labelLarge.copyWith(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                  dropdownColor: AppColors.white,
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(cat),
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            cat,
                            style: AppTypography.bodySmall.copyWith(
                              color: primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. Recurrent Switch (New Feature) ---
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
