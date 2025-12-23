import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class AddTransferPage extends StatefulWidget {
  final String fromAccountName;
  final List<String> availableAccounts; 

  const AddTransferPage({
    super.key,
    required this.fromAccountName,
    required this.availableAccounts,
  });

  @override
  State<AddTransferPage> createState() => _AddTransferPageState();
}

class _AddTransferPageState extends State<AddTransferPage> {
  final TextEditingController _amountController = TextEditingController();
  
  String? _selectedToAccount;
  late List<String> _validToAccounts;

  @override
  void initState() {
    super.initState();
    // Filter the list: You cannot transfer money to the same account you are taking it from
    _validToAccounts = widget.availableAccounts
        .where((name) => name != widget.fromAccountName)
        .toList();

    // Default to the first available account if possible
    if (_validToAccounts.isNotEmpty) {
      _selectedToAccount = _validToAccounts[0];
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveTransfer() {
    final amountText = _amountController.text;
    if (amountText.isEmpty || _selectedToAccount == null) return;

    final double amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) return;

    final transferData = {
      'amount': amount,
      'fromAccount': widget.fromAccountName,
      'toAccount': _selectedToAccount,
      'date': DateTime.now(),
      'type': 'transfer', 
    };

    Navigator.pop(context, transferData);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Capture the Primary Color
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
          "Transfer Funds",
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
                // UPDATED: Uses Primary Color tint
                color: primaryColor.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    "Amount to Transfer",
                    // UPDATED: Uses Primary Color
                    style: AppTypography.bodySmall.copyWith(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: AppTypography.headline1.copyWith(
                      color: primaryColor, // UPDATED: Uses Primary Color
                      fontSize: 40,
                    ),
                    cursorColor: primaryColor, // UPDATED: Uses Primary Color
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: r"$0.00",
                      hintStyle: AppTypography.headline1.copyWith(
                        color: AppColors.greyText.withOpacity(0.3),
                        fontSize: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. From Account (Read Only) ---
            Text("From", style: AppTypography.labelLarge.copyWith(color: AppColors.greyText)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)), 
              ),
              child: Row(
                children: [
                  const Icon(Icons.output_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    widget.fromAccountName,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow Visual
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Icon(Icons.arrow_downward_rounded, color: AppColors.greyText),
              ),
            ),

            // --- 3. To Account (Dropdown) ---
            Text("To", style: AppTypography.labelLarge.copyWith(color: AppColors.greyText)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)), 
              ),
              child: _validToAccounts.isEmpty 
              ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text("No other accounts available", style: TextStyle(color: Colors.grey)),
                )
              : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedToAccount,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.success),
                  dropdownColor: AppColors.white,
                  items: _validToAccounts.map((accountName) {
                    return DropdownMenuItem(
                      value: accountName,
                      child: Row(
                        children: [
                          const Icon(Icons.input_rounded, color: AppColors.success, size: 20),
                          const SizedBox(width: 12),
                          Text(accountName, style: AppTypography.bodySmall.copyWith(color: primaryTextColor)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedToAccount = val!),
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // --- Save Button ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // UPDATED: Uses Primary Color
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _validToAccounts.isEmpty ? null : _saveTransfer,
                child: Text(
                  "Transfer Now",
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