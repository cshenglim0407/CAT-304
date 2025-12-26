import 'package:cashlytics/presentation/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class AddTransferPage extends StatefulWidget {
  final String fromAccountName;
  final List<String> availableAccounts;
  // Optional initial data to prefill when used for editing/duplication
  final Map<String, dynamic>? initialData;

  const AddTransferPage({
    super.key,
    required this.fromAccountName,
    required this.availableAccounts,
    this.initialData,
  });

  @override
  State<AddTransferPage> createState() => _AddTransferPageState();
}

class _AddTransferPageState extends State<AddTransferPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionNameController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late String _fromAccount;
  String? _selectedToAccount;
  late List<String> _validToAccounts;

  @override
  void initState() {
    super.initState();
    // Determine the correct from account
    _fromAccount = widget.fromAccountName;

    // Prefill from initialData if provided (for editing/duplication)
    final init = widget.initialData;
    if (init != null) {
      final String? initFrom = init['fromAccount']?.toString();
      if (initFrom != null && widget.availableAccounts.contains(initFrom)) {
        _fromAccount = initFrom;
      }

      // Title
      final String? title = init['title']?.toString();
      if (title != null) {
        _transactionNameController.text = title;
      }
      // Description
      final String? desc = init['description']?.toString();
      if (desc != null) {
        _descriptionController.text = desc;
      }
      // Amount
      final dynamic rawAmt = init['rawAmount'] ?? init['amount'];
      if (rawAmt != null) {
        final double amt = (rawAmt is num)
            ? rawAmt.toDouble()
            : double.tryParse(rawAmt.toString()) ?? 0.0;
        if (amt > 0) {
          _amountController.text = amt.toStringAsFixed(2);
        }
      }
    }

    // Filter the list: cannot transfer to the same account as from
    _validToAccounts = widget.availableAccounts
        .where((name) => name != _fromAccount)
        .toList();

    // Default To account
    if (_validToAccounts.isNotEmpty) {
      _selectedToAccount ??= _validToAccounts[0];
    }

    // If initialData provided a valid to account, apply it now (after filtering)
    if (init != null) {
      final String? toAcct = init['toAccount']?.toString();
      if (toAcct != null && _validToAccounts.contains(toAcct)) {
        _selectedToAccount = toAcct;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTransfer() {
    final amountText = _amountController.text;
    if (amountText.isEmpty || _selectedToAccount == null) return;

    final double amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) return;

    final description = _descriptionController.text.trim();

    final transferData = {
      'title': _transactionNameController.text.trim().isNotEmpty
          ? _transactionNameController.text.trim()
          : 'Transfer',
      'amount': amount,
      'fromAccount': _fromAccount,
      'toAccount': _selectedToAccount,
      'date': DateTime.now(),
      'type': 'transfer',
      'description': description.isNotEmpty ? description : null,
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
          widget.initialData != null ? "Edit Transfer" : "Add Transfer",
          style: AppTypography.headline3.copyWith(color: primaryTextColor),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. From Account (Read Only) ---
            FormLabel(label: "From", useGreyStyle: true),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.output_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    _fromAccount,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Arrow Visual
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: AppColors.greyText,
                ),
              ),
            ),

            // --- 2. To Account (Dropdown) ---
            FormLabel(label: "To", useGreyStyle: true),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: _validToAccounts.isEmpty
                  ? Row(
                      children: [
                        Icon(Icons.input_rounded, color: AppColors.success),
                        const SizedBox(width: 12),
                        Text(
                          "No other accounts available",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedToAccount,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.success,
                        ),
                        dropdownColor: AppColors.white,
                        items: _validToAccounts.map((accountName) {
                          return DropdownMenuItem(
                            value: accountName,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.input_rounded,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  accountName,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedToAccount = val!),
                      ),
                    ),
            ),

            const SizedBox(height: 20),
            Divider(color: AppColors.greyText.withValues(alpha: 0.3)),
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
                    "Total Transfer",
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

            const SizedBox(height: 40),

            // --- Save Button ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // UPDATED: Uses Primary Color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
