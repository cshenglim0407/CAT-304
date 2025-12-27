import 'package:flutter/material.dart';

import 'package:cashlytics/core/config/icons.dart';
import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/services/supabase/database/database_service.dart';

import 'package:cashlytics/data/repositories/account_repository_impl.dart';
import 'package:cashlytics/data/repositories/budget_repository_impl.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';
import 'package:cashlytics/domain/usecases/accounts/get_account_transactions.dart';
import 'package:cashlytics/domain/usecases/accounts/get_accounts.dart';
import 'package:cashlytics/domain/usecases/budgets/delete_budget.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/widgets/index.dart';
import 'package:cashlytics/presentation/widgets/confirm_delete_dialog.dart';

import 'package:cashlytics/presentation/pages/budget_threshold/budget.dart';


class BudgetOverviewPage extends StatefulWidget {
  const BudgetOverviewPage({super.key});

  @override
  State<BudgetOverviewPage> createState() => _BudgetOverviewPageState();
}

class _BudgetOverviewPageState extends State<BudgetOverviewPage> {
  String _selectedFilter = 'All';

  // SAME MARGIN AS BUDGET.DART
  static const double pageMargin = 22.0;

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

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return _dateOnly(raw);
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return _dateOnly(parsed);
    }
    return _dateOnly(DateTime.now());
  }

  double _parseDouble(dynamic raw) {
    if (raw == null) return 0;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String && raw.isNotEmpty) {
      return double.tryParse(raw) ?? 0;
    }
    return 0;
  }

  int _daysLeft(DateTime endDate) {
    final today = _dateOnly(DateTime.now());
    final end = _dateOnly(endDate);
    final diff = end.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
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
          userBudgetMap[id] = _parseDouble(row['threshold']);
        }
      }

      final categoryBudgetMap = <String, Map<String, dynamic>>{};
      for (final row in categoryBudgetRows) {
        final id = row['budget_id'] as String?;
        if (id != null) {
          categoryBudgetMap[id] = {
            'expense_cat_id': row['expense_cat_id'] as String?,
            'threshold': _parseDouble(row['threshold']),
          };
        }
      }

      final accountBudgetMap = <String, Map<String, dynamic>>{};
      for (final row in accountBudgetRows) {
        final id = row['budget_id'] as String?;
        if (id != null) {
          accountBudgetMap[id] = {
            'account_id': row['account_id'] as String?,
            'threshold': _parseDouble(row['threshold']),
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
            'date': _dateOnly(tx.date),
          });
        }
      }

      final items = <Map<String, dynamic>>[];
      for (final row in budgetRows) {
        final budgetId = row['budget_id'] as String?;
        final type = row['type'] as String?;
        if (budgetId == null || type == null) continue;

        final start = _parseDate(row['date_from']);
        final end = _parseDate(row['date_to']);
        final daysLeft = _daysLeft(end);

        if (type == 'U') {
          final limit = userBudgetMap[budgetId];
          if (limit == null) continue;
          final spent = _sumSpent(txList, start, end);
          items.add({
            'id': budgetId,
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
            'type': 'A',
            'title': name,
            'icon': getAccountTypeIcon(accountType),
            'limit': limit,
            'spent': spent,
            'days_left': daysLeft,
          });
        }
      }

      setState(() {
        _budgets = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading budgets: $e');
      setState(() => _isLoading = false);
    }
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
    if (_selectedFilter == 'All') return _budgets;
    if (_selectedFilter == 'Overall') {
      return _budgets.where((b) => b['type'] == 'U').toList();
    }
    if (_selectedFilter == 'Category') {
      return _budgets.where((b) => b['type'] == 'C').toList();
    }
    if (_selectedFilter == 'Account') {
      return _budgets.where((b) => b['type'] == 'A').toList();
    }
    return _budgets;
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.getSurface(context);
    final Color primaryColor = AppColors.primary;
    const Color warningColor = Color(0xFFF5A623);
    const Color errorColor = Color(0xFFE02020);
    const Color greyText = Color(0xFF757575);

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
                            return _buildBudgetCard(
                              budget,
                              index,
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
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BudgetPage()),
            );
            if (mounted) {
              _loadBudgets();
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
