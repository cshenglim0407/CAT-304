import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/widgets/index.dart'; // Import your AppBackButton
import 'package:cashlytics/presentation/pages/budget_threshold/budget.dart';

class BudgetOverviewPage extends StatefulWidget {
  // Add this optional parameter to accept a new budget
  final Map<String, dynamic>? newBudget;

  const BudgetOverviewPage({super.key, this.newBudget});

  @override
  State<BudgetOverviewPage> createState() => _BudgetOverviewPageState();
}

class _BudgetOverviewPageState extends State<BudgetOverviewPage> {
  String _selectedFilter = 'All';

  // SAME MARGIN AS BUDGET.DART
  static const double pageMargin = 22.0;

  final List<Map<String, dynamic>> _allBudgets = [
    {
      'id': '1',
      'name': 'Monthly Limit',
      'type': 'Overall',
      'icon': Icons.account_balance_wallet_rounded,
      'spent': 1250.0,
      'amount': 3000.0,
      'days_left': 15,
    },
    {
      'id': '2',
      'name': 'Food & Dining',
      'type': 'Category',
      'icon': Icons.restaurant_rounded,
      'spent': 650.0,
      'amount': 800.0,
      'days_left': 15,
    },
    {
      'id': '3',
      'name': 'Transport',
      'type': 'Category',
      'icon': Icons.directions_car_rounded,
      'spent': 120.0,
      'amount': 400.0,
      'days_left': 15,
    },
    {
      'id': '4',
      'name': 'E-Wallet (TNG)',
      'type': 'Account',
      'icon': Icons.credit_card_rounded,
      'spent': 550.0,
      'amount': 500.0,
      'days_left': 15,
    },
    {
      'id': '5',
      'name': 'Shopping',
      'type': 'Category',
      'icon': Icons.shopping_bag_rounded,
      'spent': 50.0,
      'amount': 300.0,
      'days_left': 15,
    },
  ];

  @override
  void initState() {
    super.initState();
    // CHECK: If a new budget was passed in, add it to the top of the list
    if (widget.newBudget != null) {
      _allBudgets.insert(0, widget.newBudget!);
    }
  }

  List<Map<String, dynamic>> get _filteredBudgets {
    if (_selectedFilter == 'All') return _allBudgets;
    return _allBudgets.where((b) => b['type'] == _selectedFilter).toList();
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Budget?'),
          content: const Text('Are you sure you want to delete this budget?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  _allBudgets.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.getSurface(context);
    final primaryColor = AppColors.primary;
    const warningColor = Color(0xFFF5A623);
    const errorColor = Color(0xFFE02020);
    const greyText = Color(0xFF757575);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // --- UPDATED BACK BUTTON SECTION ---
        // We use Container + padding to perfectly align with the page margin
        leading: Container(
          margin: const EdgeInsets.only(left: pageMargin),
          alignment: Alignment.centerLeft, // Ensures button doesn't stretch
          child: AppBackButton(onPressed: () => Navigator.pop(context)),
        ),
        leadingWidth: 70, // Give enough width for margin + button
        title: Text(
          'My Budgets',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- 1. FILTER BAR ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: pageMargin,
              vertical: 10,
            ),
            child: Row(
              children: ['All', 'Overall', 'Category', 'Account']
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildFilterChip(filter, primaryColor, greyText),
                    ),
                  )
                  .toList(),
            ),
          ),

          // --- 2. BUDGET LIST ---
          Expanded(
            child: _filteredBudgets.isEmpty
                ? Center(
                    child: Text(
                      "No budgets found.",
                      style: TextStyle(color: greyText),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      pageMargin,
                      16,
                      pageMargin,
                      100,
                    ),
                    itemCount: _filteredBudgets.length,
                    itemBuilder: (context, index) {
                      final budget = _filteredBudgets[index];
                      final originalIndex = _allBudgets.indexOf(budget);

                      return _buildBudgetCard(
                        budget,
                        originalIndex,
                        primaryColor,
                        warningColor,
                        errorColor,
                        greyText,
                      );
                    },
                  ),
          ),
        ],
      ),

      // --- 3. CREATE NEW BUTTON ---
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 15),
        child: FloatingActionButton(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),

          // UPDATED LOGIC HERE
          onPressed: () async {
            // 1. Wait for data from BudgetPage
            final newBudget = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BudgetPage()),
            );

            // 2. If data was returned, add it to the list
            if (newBudget != null) {
              setState(() {
                _allBudgets.add(newBudget);
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, Color primary, Color greyText) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : greyText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard(
    Map<String, dynamic> budget,
    int index,
    Color primary,
    Color warning,
    Color error,
    Color greyText,
  ) {
    double spent = (budget['spent'] ?? 0).toDouble();
    double limit = (budget['amount'] ?? 0).toDouble();
    double percentage = (limit == 0) ? 0 : (spent / limit);
    int percentageInt = (percentage * 100).toInt();

    Color statusColor = primary;
    if (percentage >= 1.0) {
      statusColor = error;
    } else if (percentage >= 0.8) {
      statusColor = warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(budget['icon'], color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${budget['days_left']} days left',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentageInt%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                onPressed: () => _confirmDelete(index),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage > 1 ? 1 : percentage,
              backgroundColor: Colors.grey.shade200,
              color: statusColor,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: RM ${spent.toStringAsFixed(2)}',
                style: TextStyle(
                  color: percentage >= 1.0 ? error : greyText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Limit: RM ${limit.toStringAsFixed(0)}',
                style: TextStyle(
                  color: greyText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
