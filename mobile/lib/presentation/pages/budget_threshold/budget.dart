import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';
import 'package:cashlytics/presentation/pages/budget_threshold/budget_overview.dart';

enum BudgetType {
  user('U', 'Overall', Icons.account_balance_wallet_rounded),
  category('C', 'Category', Icons.grid_view_rounded),
  account('A', 'Account', Icons.credit_card_rounded);

  final String code;
  final String label;
  final IconData icon;
  const BudgetType(this.code, this.label, this.icon);
}

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _formKey = GlobalKey<FormState>();
  
  // State
  BudgetType _selectedType = BudgetType.user;
  final TextEditingController _amountController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  
  // Selection IDs
  String? _selectedCategoryId;
  String? _selectedAccountId;

  // --- Category Data ---
  final List<Map<String, dynamic>> _categories = [
    {'id': '1', 'name': 'Transport', 'icon': Icons.directions_car_filled_rounded},
    {'id': '2', 'name': 'Entertainment', 'icon': Icons.movie_creation_rounded},
    {'id': '3', 'name': 'Utilities', 'icon': Icons.bolt_rounded},
    {'id': '4', 'name': 'Healthcare', 'icon': Icons.medical_services_rounded},
    {'id': '5', 'name': 'Shopping', 'icon': Icons.shopping_bag_rounded},
    {'id': '6', 'name': 'Travel', 'icon': Icons.flight_takeoff_rounded},
    {'id': '7', 'name': 'Education', 'icon': Icons.school_rounded},
    {'id': '8', 'name': 'Rent', 'icon': Icons.home_rounded},
    {'id': '9', 'name': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  // --- Account Data ---
  final List<Map<String, dynamic>> _accounts = [
    {'id': '1', 'name': 'Cash', 'icon': Icons.payments_rounded},
    {'id': '2', 'name': 'Bank', 'icon': Icons.account_balance_rounded},
    {'id': '3', 'name': 'E-Wallet', 'icon': Icons.account_balance_wallet_rounded},
    {'id': '4', 'name': 'Credit Card', 'icon': Icons.credit_card_rounded},
    {'id': '5', 'name': 'Investment', 'icon': Icons.trending_up_rounded},
    {'id': '6', 'name': 'Loan', 'icon': Icons.monetization_on_rounded},
    {'id': '7', 'name': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date, {bool showYear = false}) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = date.day;
    final month = months[date.month - 1];
    if (showYear) {
      return '$day $month ${date.year}';
    }
    return '$day $month';
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.getSurface(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

Future<void> _saveBudget() async {
  if (!_formKey.currentState!.validate()) return;
  
  // Check if date range is selected
  if (_selectedDateRange == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a date range")),
    );
    return;
  }

  // Parse the amount safely
  final cleanAmount = _amountController.text.replaceAll(',', '');
  final threshold = double.tryParse(cleanAmount); 

  if (threshold == null) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid amount format")),
    );
    return;
  }

  // 1. Logic to get the correct Name and Icon
  String budgetName = 'Overall Limit';
  IconData budgetIcon = Icons.account_balance_wallet_rounded;
  String typeLabel = _selectedType.label;

  if (_selectedType == BudgetType.category) {
    // Find the name of the selected category
    final category = _categories.firstWhere(
      (element) => element['id'] == _selectedCategoryId,
      orElse: () => {'name': 'Unknown Category', 'icon': Icons.category},
    );
    budgetName = category['name'];
    budgetIcon = category['icon'];
  } else if (_selectedType == BudgetType.account) {
    // Find the name of the selected account
    final account = _accounts.firstWhere(
      (element) => element['id'] == _selectedAccountId,
      orElse: () => {'name': 'Unknown Account', 'icon': Icons.credit_card},
    );
    budgetName = account['name'];
    budgetIcon = account['icon'];
  }

  // 2. Create the Budget Data Map
  final newBudget = {
    'id': DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
    'name': budgetName,
    'type': typeLabel,
    'icon': budgetIcon,
    'spent': 0.0, // Start with 0 spent
    'amount': threshold,
    'days_left': _selectedDateRange!.duration.inDays,
  };

  // 3. Show Success Message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Budget created for $budgetName!"),
      backgroundColor: Colors.green,
    ),
  );

  Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetOverviewPage(newBudget: newBudget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double pageMargin = 22.0;

    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: pageMargin, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppBackButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                  
                  Text(
                    "Create Goal",
                    style: AppTypography.headline3.copyWith(
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // 👇 CHANGED: Replaced SizedBox with an Icon Button
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BudgetOverviewPage(), // Passing empty map
                        ),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.greyLight.withValues(alpha: 0.5)),
                      ),
                      child: Icon(
                        Icons.list_alt_rounded, 
                        color: AppColors.getTextPrimary(context),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Scrollable Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: pageMargin),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text("I want to control spending for...", 
                        style: AppTypography.labelLarge.copyWith(color: AppColors.grey)),
                      const SizedBox(height: 16),
                      
                      // Type Cards
                      SizedBox(
                        height: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: BudgetType.values.map((type) {
                            final isSelected = _selectedType == type;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedType = type),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(right: type == BudgetType.account ? 0 : 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : AppColors.getSurface(context),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.greyLight,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0,4))
                                    ] : [],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(type.icon, 
                                        color: isSelected ? Colors.white : AppColors.grey, size: 28),
                                      const SizedBox(height: 8),
                                      Text(
                                        type.label,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isSelected ? Colors.white : AppColors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Threshold Amount
                      Center(
                        child: Column(
                          children: [
                            Text("MY LIMIT IS", 
                              style: AppTypography.labelSmall.copyWith(letterSpacing: 1.5, color: AppColors.grey)),
                            const SizedBox(height: 8),
                            // Fix: Use SizedBox instead of IntrinsicWidth to avoid layout crash
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: AppTypography.headline1.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 42,
                                ),
                                decoration: InputDecoration(
                                  prefixText: "RM ",
                                  prefixStyle: AppTypography.headline1.copyWith(
                                    color: AppColors.grey,
                                    fontSize: 42,
                                  ),
                                  border: InputBorder.none,
                                  hintText: "0.00",
                                  hintStyle: TextStyle(color: AppColors.greyLight.withValues(alpha: 0.5)),
                                  // Optional: Custom underline if desired
                                  // enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.greyLight)),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Enter amount';
                                  if (double.tryParse(val) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            // Decorative underline
                            Container(height: 2, width: 150, color: AppColors.greyLight.withValues(alpha: 0.3)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Dynamic Dropdowns with Unique Keys
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _selectedType == BudgetType.category 
                          ? _buildDropdownField(
                              const ValueKey('category_dropdown'), // UNIQUE KEY for logic fix
                              "Select Category",
                              "Category", // Placeholder Text
                              _categories,
                              _selectedCategoryId,
                              (val) => setState(() => _selectedCategoryId = val),
                            )
                          : _selectedType == BudgetType.account
                            ? _buildDropdownField(
                                const ValueKey('account_dropdown'), // UNIQUE KEY for logic fix
                                "Select Account",
                                "Account", // Placeholder Text
                                _accounts,
                                _selectedAccountId,
                                (val) => setState(() => _selectedAccountId = val),
                              )
                            : const SizedBox.shrink(),
                      ),

                      if (_selectedType != BudgetType.user) const SizedBox(height: 24),

                      // Date Range Picker
                      Text("Duration", style: AppTypography.labelLarge),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDateRange,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.getSurface(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.greyLight),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedDateRange == null 
                                      ? "Select Dates" 
                                      : "${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end, showYear: true)}",
                                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  if (_selectedDateRange != null)
                                    Text(
                                      "${_selectedDateRange!.duration.inDays} Days",
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.grey, fontSize: 10),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grey),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // --- Pinned Bottom Button ---
            Padding(
              padding: const EdgeInsets.all(pageMargin),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    "Set Limit",
                    style: AppTypography.headline1.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated Widget to accept Key and hintText
  Widget _buildDropdownField(
    Key key, // New Parameter for Unique Key
    String label, 
    String hintText, // New parameter for Placeholder
    List<Map<String, dynamic>> items, 
    String? currentValue, 
    Function(String?) onChanged,
  ) {
    return Column(
      key: key, // Apply Key here
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          // --- Placeholder Logic ---
          hint: Text(
            hintText,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.grey, // Placeholder put grey color
            ),
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.greyLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.greyLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.getSurface(context),
          ),
          dropdownColor: AppColors.getSurface(context),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item['id'] as String,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item['name'] as String,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}