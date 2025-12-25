import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';
import 'package:cashlytics/presentation/pages/budget_threshold/budget.dart';

class BudgetOverviewPage extends StatefulWidget {
  const BudgetOverviewPage({super.key});

  @override
  State<BudgetOverviewPage> createState() => _BudgetOverviewPageState();
}

class _BudgetOverviewPageState extends State<BudgetOverviewPage> {
  String _selectedFilter = 'All';

  // --- MOCK DATA ---
  final List<Map<String, dynamic>> _allBudgets = [
    {
      'id': '1',
      'title': 'Monthly Limit',
      'type': 'U',
      'icon': Icons.account_balance_wallet_rounded,
      'limit': 3000.00,
      'spent': 1250.00,
      'days_left': 15,
    },
    {
      'id': '2',
      'title': 'Food & Dining',
      'type': 'C',
      'icon': Icons.restaurant_menu_rounded,
      'limit': 800.00,
      'spent': 650.00,
      'days_left': 15,
    },
    {
      'id': '3',
      'title': 'Transport',
      'type': 'C',
      'icon': Icons.directions_car_filled_rounded,
      'limit': 400.00,
      'spent': 120.00,
      'days_left': 15,
    },
    {
      'id': '4',
      'title': 'E-Wallet (TNG)',
      'type': 'A',
      'icon': Icons.account_balance_wallet_rounded,
      'limit': 500.00,
      'spent': 550.00,
      'days_left': 15,
    },
     {
      'id': '5',
      'title': 'Shopping',
      'type': 'C',
      'icon': Icons.shopping_bag_rounded,
      'limit': 300.00,
      'spent': 50.00,
      'days_left': 15,
    },
  ];

  List<Map<String, dynamic>> get _filteredBudgets {
    if (_selectedFilter == 'All') return _allBudgets;
    if (_selectedFilter == 'Overall') return _allBudgets.where((b) => b['type'] == 'U').toList();
    if (_selectedFilter == 'Category') return _allBudgets.where((b) => b['type'] == 'C').toList();
    if (_selectedFilter == 'Account') return _allBudgets.where((b) => b['type'] == 'A').toList();
    return _allBudgets;
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return Colors.redAccent;
    if (percentage >= 0.75) return Colors.orangeAccent;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    const double pageMargin = 22.0;

    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BudgetPage()),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: pageMargin, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 👇 UPDATED: Added onPressed logic
                  AppBackButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "My Budgets",
                    style: AppTypography.headline3.copyWith(
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), 
                ],
              ),
            ),

            // --- Filter Pills ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: pageMargin),
              child: Row(
                children: ['All', 'Overall', 'Category', 'Account'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.greyLight,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: AppTypography.bodySmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // --- Budget List ---
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: pageMargin, vertical: 10),
                itemCount: _filteredBudgets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = _filteredBudgets[index];
                  final double limit = item['limit'];
                  final double spent = item['spent'];
                  final double percentage = (spent / limit).clamp(0.0, 1.0);
                  final double displayPercentage = (spent / limit) * 100;
                  final bool isOverBudget = spent > limit;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                      border: Border.all(color: AppColors.greyLight.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Icon, Title, Percentage Text
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getProgressColor(percentage).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'],
                                color: _getProgressColor(percentage),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                  Text(
                                    "${item['days_left']} days left",
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOverBudget ? Colors.redAccent : AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${displayPercentage.toStringAsFixed(0)}%",
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Row 2: Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            backgroundColor: AppColors.greyLight.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percentage)),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Row 3: Amount Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Spent: RM ${spent.toStringAsFixed(2)}",
                              style: AppTypography.bodySmall.copyWith(
                                color: isOverBudget ? Colors.redAccent : AppColors.getTextSecondary(context),
                                fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              "Limit: RM ${limit.toStringAsFixed(0)}",
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.getTextSecondary(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}