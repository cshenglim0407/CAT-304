import 'package:flutter/material.dart';

import 'package:cashlytics/core/config/icons.dart';
import 'package:cashlytics/core/services/cache/cache_service.dart';
import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/core/utils/date_formatter.dart';
import 'package:cashlytics/core/utils/math_formatter.dart';

import 'package:cashlytics/data/repositories/account_repository_impl.dart';
import 'package:cashlytics/data/repositories/budget_repository_impl.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';
import 'package:cashlytics/domain/usecases/accounts/get_account_transactions.dart';
import 'package:cashlytics/domain/usecases/accounts/get_accounts.dart';
import 'package:cashlytics/domain/usecases/budgets/delete_budget.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/widgets/index.dart';
import 'package:cashlytics/presentation/widgets/confirm_delete_dialog.dart';

import 'package:cashlytics/presentation/pages/budget_threshold/add_budget.dart';

class BudgetOverviewPage extends StatefulWidget {
  const BudgetOverviewPage({super.key});

  @override
  State<BudgetOverviewPage> createState() => _BudgetOverviewPageState();
}

class _BudgetOverviewPageState extends State<BudgetOverviewPage> {
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';

  // SAME MARGIN AS BUDGET.DART
  static const double pageMargin = 22.0;
  static const String _budgetsCacheKey = 'budgets_cache';

  final DatabaseService _databaseService = const DatabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _budgets = [];

  late final AccountRepository _accountRepository;
  late final GetAccounts _getAccounts;
  late final GetAccountTransactions _getAccountTransactions;
  late final DeleteBudget _deleteBudget;

  @override
  void initState() {
    super.initState();
    _accountRepository = AccountRepositoryImpl();
    _getAccounts = GetAccounts(_accountRepository);
    _getAccountTransactions = GetAccountTransactions(_accountRepository);
    _deleteBudget = DeleteBudget(BudgetRepositoryImpl());
    _loadBudgets();
  }

  Future<void> _loadBudgets({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    if (!forceRefresh) {
      final cachedBudgets = CacheService.load<List>(_budgetsCacheKey);
      if (cachedBudgets != null) {
        setState(() {
          _budgets = List<Map<String, dynamic>>.from(
            cachedBudgets.map((e) {
              final budget = Map<String, dynamic>.from(e);
              budget['icon'] = _getIconFromBudget(budget);
              return budget;
            }),
          );
          _isLoading = false;
        });
        return;
      }
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final accounts = await _getAccounts(userId);
      final accountMap = <String, Map<String, dynamic>>{};
      for (final acc in accounts) {
        if (acc.id == null) continue;
        accountMap[acc.id!] = {'name': acc.name, 'type': acc.type};
      }

      final categoryRows = await _databaseService.fetchAll('expense_category');
      final categoryMap = <String, String>{};
      for (final row in categoryRows) {
        final id = row['expense_cat_id'] as String?;
        final name = row['name'] as String?;
        if (id != null && name != null) {
          categoryMap[id] = name;
        }
      }

      final budgetRows = await _databaseService.fetchAll(
        'budget',
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );

      final budgetIds = budgetRows
          .map((row) => row['budget_id'])
          .whereType<String>()
          .toList();

      final userBudgetRows = budgetIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _databaseService.fetchAll(
              'user_budget',
              filters: {'budget_id': budgetIds},
            );
      final categoryBudgetRows = budgetIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _databaseService.fetchAll(
              'category_budget',
              filters: {'budget_id': budgetIds},
            );
      final accountBudgetRows = budgetIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _databaseService.fetchAll(
              'account_budget',
              filters: {'budget_id': budgetIds},
            );

      final userBudgetMap = <String, double>{};
      for (final row in userBudgetRows) {
        final id = row['budget_id'] as String?;
        if (id != null) {
          userBudgetMap[id] =
              MathFormatter.parseDouble(row['threshold']) ?? 0.0;
        }
      }

      final categoryBudgetMap = <String, Map<String, dynamic>>{};
      for (final row in categoryBudgetRows) {
        final id = row['budget_id'] as String?;
        if (id != null) {
          categoryBudgetMap[id] = {
            'expense_cat_id': row['expense_cat_id'] as String?,
            'threshold': MathFormatter.parseDouble(row['threshold']) ?? 0.0,
          };
        }
      }

      final accountBudgetMap = <String, Map<String, dynamic>>{};
      for (final row in accountBudgetRows) {
        final id = row['budget_id'] as String?;
        if (id != null) {
          accountBudgetMap[id] = {
            'account_id': row['account_id'] as String?,
            'threshold': MathFormatter.parseDouble(row['threshold']) ?? 0.0,
          };
        }
      }

      final txList = <Map<String, dynamic>>[];
      for (final acc in accounts) {
        if (acc.id == null) continue;
        final txns = await _getAccountTransactions(acc.id!);
        for (final tx in txns) {
          if (!tx.isExpense) continue;
          final category = (tx.category ?? '').trim();
          if (category.toLowerCase() == 'transfer') continue;
          txList.add({
            'accountId': acc.id,
            'category': category,
            'amount': tx.amount,
            'date': DateFormatter.dateOnly(tx.date),
          });
        }
      }

      final items = <Map<String, dynamic>>[];
      final now = DateFormatter.dateOnly(DateTime.now());
      for (final row in budgetRows) {
        final budgetId = row['budget_id'] as String?;
        final type = row['type'] as String?;
        if (budgetId == null || type == null) continue;

        final start = DateFormatter.parseDate(row['date_from']);
        final end = DateFormatter.parseDate(row['date_to']);
        final daysLeft = end.isBefore(now) ? 0 : DateFormatter.daysLeft(end);

        if (type == 'U') {
          final limit = userBudgetMap[budgetId];
          if (limit == null) continue;
          final spent = _sumSpent(txList, start, end);
          items.add({
            'id': budgetId,
            'created_at': row['created_at'],
            'type': 'U',
            'title': 'Monthly Limit',
            'icon': Icons.account_balance_wallet_rounded,
            'limit': limit,
            'spent': spent,
            'days_left': daysLeft,
          });
        } else if (type == 'C') {
          final catBudget = categoryBudgetMap[budgetId];
          if (catBudget == null) continue;
          final catId = catBudget['expense_cat_id'] as String?;
          final limit = catBudget['threshold'] as double?;
          if (catId == null || limit == null) continue;
          final name = categoryMap[catId] ?? 'Category';
          final spent = _sumSpent(txList, start, end, category: name);
          items.add({
            'id': budgetId,
            'created_at': row['created_at'],
            'type': 'C',
            'title': name,
            'icon': getExpenseIcon(name.toUpperCase()),
            'limit': limit,
            'spent': spent,
            'days_left': daysLeft,
          });
        } else if (type == 'A') {
          final accBudget = accountBudgetMap[budgetId];
          if (accBudget == null) continue;
          final accountId = accBudget['account_id'] as String?;
          final limit = accBudget['threshold'] as double?;
          if (accountId == null || limit == null) continue;
          final accountInfo = accountMap[accountId];
          final name = accountInfo?['name'] as String? ?? 'Account';
          final accountType = accountInfo?['type'] as String? ?? '';
          final spent = _sumSpent(txList, start, end, accountId: accountId);
          items.add({
            'id': budgetId,
            'created_at': row['created_at'],
            'type': 'A',
            'title': name,
            'icon': getAccountTypeIcon(accountType),
            'limit': limit,
            'spent': spent,
            'days_left': daysLeft,
            'accountType': accountType,
          });
        }
      }

      CacheService.save(_budgetsCacheKey, _getSanitizedBudgets(items));
      setState(() {
        _budgets = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading budgets: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getSanitizedBudgets(
    List<Map<String, dynamic>> budgets,
  ) {
    return budgets.map((budget) {
      final sanitized = Map<String, dynamic>.from(budget);
      sanitized.remove('icon'); // Remove IconData

      final type = sanitized['type'];
      if (type == 'U') {
        sanitized['iconName'] = 'account_balance_wallet_rounded';
      } else if (type == 'C') {
        sanitized['iconName'] = sanitized['title']; // The category name
      } else if (type == 'A') {
        sanitized['iconName'] = sanitized['accountType']; // The account type
      }
      return sanitized;
    }).toList();
  }

  IconData _getIconFromBudget(Map<String, dynamic> budget) {
    final type = budget['type'];
    final iconName = budget['iconName'] as String?;

    if (iconName == null) return Icons.error; // Fallback

    if (type == 'U') {
      return Icons.account_balance_wallet_rounded;
    } else if (type == 'C') {
      return getExpenseIcon(iconName.toUpperCase());
    } else if (type == 'A') {
      return getAccountTypeIcon(iconName); // iconName is accountType
    }
    return Icons.error; // Fallback
  }

  double _sumSpent(
    List<Map<String, dynamic>> txList,
    DateTime start,
    DateTime end, {
    String? category,
    String? accountId,
  }) {
    double total = 0;
    for (final tx in txList) {
      final date = tx['date'] as DateTime;
      if (date.isBefore(start) || date.isAfter(end)) continue;
      if (category != null) {
        final txCategory = (tx['category'] as String).toLowerCase();
        if (txCategory != category.toLowerCase()) continue;
      }
      if (accountId != null && tx['accountId'] != accountId) continue;
      total += (tx['amount'] as num).toDouble();
    }
    return total;
  }

  Future<void> _confirmDelete(String budgetId) async {
    await showConfirmDeleteDialog(
      context: context,
      title: 'Delete Budget',
      content: 'This will remove the budget. Continue?',
      onConfirm: () async {
        await _deleteBudgetById(budgetId);
      },
    );
  }

  Future<void> _deleteBudgetById(String budgetId) async {
    try {
      await _deleteBudget(budgetId);
      setState(() {
        _budgets.removeWhere((b) => b['id'] == budgetId);
      });
      CacheService.save(_budgetsCacheKey, _getSanitizedBudgets(_budgets));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Budget deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredBudgets {
    List<Map<String, dynamic>> result;
    if (_selectedFilter == 'All') {
      result = List.from(_budgets);
    } else if (_selectedFilter == 'Overall') {
      result = _budgets.where((b) => b['type'] == 'U').toList();
    } else if (_selectedFilter == 'Category') {
      result = _budgets.where((b) => b['type'] == 'C').toList();
    } else if (_selectedFilter == 'Account') {
      result = _budgets.where((b) => b['type'] == 'A').toList();
    } else {
      result = List.from(_budgets);
    }

    switch (_selectedSort) {
      case 'Newest':
        result.sort(
          (a, b) => (b['created_at'] as String? ?? '').compareTo(
            a['created_at'] as String? ?? '',
          ),
        );
        break;
      case 'Oldest':
        result.sort(
          (a, b) => (a['created_at'] as String? ?? '').compareTo(
            b['created_at'] as String? ?? '',
          ),
        );
        break;
      case 'Limit: High':
        result.sort((a, b) => (b['limit'] as num).compareTo(a['limit'] as num));
        break;
      case 'Limit: Low':
        result.sort((a, b) => (a['limit'] as num).compareTo(b['limit'] as num));
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.getSurface(context);
    final Color primaryColor = AppColors.primary;
    const Color warningColor = Color(0xFFF5A623);
    const Color errorColor = Color(0xFFE02020);
    const Color greyText = Color(0xFF757575);

    final activeBudgets = _filteredBudgets
        .where((b) => (b['days_left'] as int) > 0)
        .toList();
    final expiredBudgets = _filteredBudgets
        .where((b) => (b['days_left'] as int) <= 0)
        .toList();

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                            child: _buildFilterChip(
                              filter,
                              primaryColor,
                              greyText,
                            ),
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
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            pageMargin,
                            16,
                            pageMargin,
                            100,
                          ),
                          children: [
                            if (activeBudgets.isNotEmpty) ...[
                              _buildSectionHeader("Active", showSort: true),
                              ...activeBudgets.map(
                                (budget) => _buildBudgetCard(
                                  budget,
                                  0,
                                  primaryColor,
                                  warningColor,
                                  errorColor,
                                  greyText,
                                ),
                              ),
                            ],
                            if (activeBudgets.isNotEmpty &&
                                expiredBudgets.isNotEmpty)
                              const SizedBox(height: 24),
                            if (expiredBudgets.isNotEmpty) ...[
                              _buildSectionHeader(
                                "Expired",
                                showSort: activeBudgets.isEmpty,
                              ),
                              ...expiredBudgets.map(
                                (budget) => _buildBudgetCard(
                                  budget,
                                  0,
                                  primaryColor,
                                  warningColor,
                                  errorColor,
                                  greyText,
                                ),
                              ),
                            ],
                          ],
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
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BudgetPage()),
            );
            if (mounted) {
              _loadBudgets(forceRefresh: true);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showSort = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showSort)
            DropdownButton<String>(
              value: _selectedSort,
              icon: const Icon(Icons.sort_rounded),
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                if (newValue != null) setState(() => _selectedSort = newValue);
              },
              items: ['Newest', 'Oldest', 'Limit: High', 'Limit: Low']
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  })
                  .toList(),
            ),
        ],
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
    double limit = (budget['limit'] ?? 0).toDouble();
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
                      budget['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if ((budget['days_left'] as int) <= 0)
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: error,
                          ), // Alert Icon
                          const SizedBox(width: 4),
                          Text(
                            'Expired',
                            style: TextStyle(
                              fontSize: 12,
                              color: error, // Red color for expired
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${budget['days_left']} days left',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    // --------------------------
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
                onPressed: () => _confirmDelete(budget['id'] as String),
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
                'Spent: ${MathFormatter.formatCurrency(spent)}',
                style: TextStyle(
                  color: percentage >= 1.0 ? error : greyText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Limit: ${MathFormatter.formatCurrency(limit)}',
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
