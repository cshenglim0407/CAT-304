import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';
import 'package:cashlytics/presentation/widgets/account_card.dart';

import 'package:cashlytics/presentation/pages/expense_entry_ocr/add_income.dart';
import 'package:cashlytics/presentation/pages/expense_entry_ocr/add_transfer.dart';
import 'package:cashlytics/presentation/pages/expense_entry_ocr/add_expense.dart';
import 'package:cashlytics/presentation/pages/income_expense_management/transaction_history.dart';
import 'package:cashlytics/presentation/pages/income_expense_management/edit_transaction.dart';

import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/services/cache/cache_service.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';
import 'package:cashlytics/data/repositories/account_repository_impl.dart';
import 'package:cashlytics/domain/usecases/accounts/get_accounts.dart';
import 'package:cashlytics/domain/usecases/accounts/get_account_transactions.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _selectedIndex = 1;
  int _currentCardIndex = 0;
  late PageController _pageController;
  bool _isLoading = true;

  // Repository and use cases
  late final AccountRepository _accountRepository;
  late final GetAccounts _getAccounts;
  late final GetAccountTransactions _getAccountTransactions;

  // Data loaded from database
  List<Map<String, dynamic>> _myAccounts = [];
  List<List<Map<String, dynamic>>> _allTransactions = [];

  final List<String> _expenseCategories = [
    'FOOD',
    'TRANSPORT',
    'ENTERTAINMENT',
    'UTILITIES',
    'HEALTHCARE',
    'SHOPPING',
    'TRAVEL',
    'EDUCATION',
    'RENT',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _accountRepository = AccountRepositoryImpl();
    _getAccounts = GetAccounts(_accountRepository);
    _getAccountTransactions = GetAccountTransactions(_accountRepository);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Try loading from cache first
      final cachedAccounts = CacheService.load<List>('accounts');
      final cachedTransactions = CacheService.load<List>('transactions');

      if (cachedAccounts != null && cachedTransactions != null) {
        setState(() {
          _myAccounts = List<Map<String, dynamic>>.from(
            cachedAccounts.map((e) => Map<String, dynamic>.from(e)),
          );
          _allTransactions = List<List<Map<String, dynamic>>>.from(
            cachedTransactions.map(
              (list) => List<Map<String, dynamic>>.from(
                list.map((e) => Map<String, dynamic>.from(e)),
              ),
            ),
          );
          _isLoading = false;
        });
        return;
      }

      // If cache is empty, load from database progressively
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final accounts = await _getAccounts(userId);

      // Stop showing loading indicator, start showing accounts progressively
      setState(() => _isLoading = false);

      // Load each account and its transactions one by one
      for (final account in accounts) {
        final accountMap = {
          'id': account.id,
          'name': account.name,
          'type': account.type,
          'initial': account.initialBalance,
          'current': account.currentBalance,
          'desc': account.description ?? '',
        };

        final txList = <Map<String, dynamic>>[];

        // Load transactions for this account
        if (account.id != null) {
          final transactions = await _getAccountTransactions(account.id!);

          for (final tx in transactions) {
            final isExpense = tx.isExpense;
            final amount = tx.amount.abs();
            final displayAmount =
                (isExpense ? '- \$' : '+ \$') + amount.toStringAsFixed(2);

            txList.add({
              'type': isExpense ? 'expense' : 'income',
              'title': tx.title,
              'date': _formatDate(tx.date),
              'amount': displayAmount,
              'rawAmount': amount,
              'isExpense': isExpense,
              'icon': tx.icon ?? _getTransactionIcon(isExpense, tx.category),
              'isRecurrent': false,
              'category': tx.category,
            });
          }
        }

        // Add this account and its transactions immediately to UI
        setState(() {
          _myAccounts.add(accountMap);
          _allTransactions.add(txList);
        });
      }

      // Save everything to cache for next time
      CacheService.save('accounts', _myAccounts);
      CacheService.save('transactions', _allTransactions);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (txDate == today) {
      return 'Today';
    } else if (txDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '\${dateTime.day}/\${dateTime.month}';
    }
  }

  IconData _getTransactionIcon(bool isExpense, String? category) {
    if (isExpense) {
      return _getExpenseIcon(category ?? '');
    } else {
      return _getCategoryIcon(category ?? '');
    }
  }

  // --- HELPERS ---
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

  IconData _getExpenseIcon(String category) {
    switch (category) {
      case 'FOOD':
        return Icons.fastfood;
      case 'TRANSPORT':
        return Icons.directions_car;
      case 'ENTERTAINMENT':
        return Icons.movie;
      case 'UTILITIES':
        return Icons.lightbulb;
      case 'HEALTHCARE':
        return Icons.medical_services;
      case 'SHOPPING':
        return Icons.shopping_bag;
      case 'TRAVEL':
        return Icons.flight;
      case 'EDUCATION':
        return Icons.school;
      case 'RENT':
        return Icons.home;
      default:
        return Icons.money_off;
    }
  }

  double _parseAmount(Map<String, dynamic> tx) {
    if (tx['rawAmount'] != null) {
      return (tx['rawAmount'] as num).toDouble();
    }
    String amtString = tx['amount'].toString();
    String cleanString = amtString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanString) ?? 0.0;
  }

  // --- LOGIC: DELETE ---
  void _deleteTransaction(Map<String, dynamic> tx, int accountIndex) {
    setState(() {
      _allTransactions[accountIndex].removeWhere((element) => element == tx);
      double amount = _parseAmount(tx);

      if (tx['isExpense'] == true) {
        _myAccounts[accountIndex]['current'] += amount;
      } else {
        _myAccounts[accountIndex]['current'] -= amount;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transaction deleted and balance updated")),
    );
  }

  // --- LOGIC: EDIT (FIXED ICON ISSUE HERE) ---
  Future<void> _editTransaction(Map<String, dynamic> oldTx) async {
    final List<String> allAccountNames = _myAccounts
        .map((acc) => acc['name'] as String)
        .toList();
    final String currentAccountName = _myAccounts[_currentCardIndex]['name'];

    if (oldTx['rawAmount'] == null) {
      oldTx['rawAmount'] = _parseAmount(oldTx);
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionPage(
          transaction: oldTx,
          availableAccounts: allAccountNames,
          currentAccountName: currentAccountName,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        // 1. Update List
        final index = _allTransactions[_currentCardIndex].indexOf(oldTx);
        if (index != -1) {
          // --- FIX: Force Icon Refresh based on new Category ---
          if (result['type'] == 'expense' && result['category'] != null) {
            result['icon'] = _getExpenseIcon(result['category']);
          } else if (result['type'] == 'income' && result['category'] != null) {
            result['icon'] = _getCategoryIcon(result['category']);
          } else if (result['type'] == 'transfer') {
            result['icon'] = Icons.arrow_outward_rounded;
          }

          _allTransactions[_currentCardIndex][index] = result;
        }

        // 2. Adjust Balance
        double oldRaw = _parseAmount(oldTx);
        double newRaw = _parseAmount(result);
        bool isExpense = oldTx['isExpense'];

        if (isExpense) {
          _myAccounts[_currentCardIndex]['current'] += oldRaw;
          _myAccounts[_currentCardIndex]['current'] -= newRaw;
        } else {
          _myAccounts[_currentCardIndex]['current'] -= oldRaw;
          _myAccounts[_currentCardIndex]['current'] += newRaw;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction updated successfully")),
        );
      }
    }
  }

  // --- NAVIGATION HELPERS (ADD) ---
  Future<void> _navigateToAddIncome(Map<String, dynamic> account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddIncomePage(
          accountName: account['name']?.toString() ?? 'Account',
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      _addTransactionToState(result, isExpense: false);
    }
  }

  Future<void> _navigateToAddTransfer(
    Map<String, dynamic> sourceAccount,
  ) async {
    final List<String> allAccountNames = _myAccounts
        .map((acc) => acc['name'] as String)
        .toList();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransferPage(
          fromAccountName: sourceAccount['name'],
          availableAccounts: allAccountNames,
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      _addTransactionToState(result, isExpense: true, isTransfer: true);
    }
  }

  Future<void> _navigateToAddExpense(
    Map<String, dynamic> account,
    String category,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpensePage(
          accountName: account['name']?.toString() ?? 'Account',
          category: category,
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      _addTransactionToState(result, isExpense: true);
    }
  }

  void _addTransactionToState(
    Map<String, dynamic> result, {
    required bool isExpense,
    bool isTransfer = false,
  }) {
    setState(() {
      final double rawAmount = result['amount'];
      final String displayAmount =
          (isExpense ? '- \$' : '+ \$') + rawAmount.toStringAsFixed(2);

      // Determine Icon correctly on ADD
      IconData icon;
      if (isTransfer) {
        icon = Icons.arrow_outward_rounded;
      } else if (isExpense) {
        icon = _getExpenseIcon(result['category'] ?? '');
      } else {
        icon = _getCategoryIcon(result['category'] ?? '');
      }

      final newTx = {
        'type': isTransfer ? 'transfer' : (isExpense ? 'expense' : 'income'),
        'title':
            result['itemName'] ??
            result['title'] ??
            result['category'] ??
            'Transaction',
        'date': "${result['date'].day}/${result['date'].month}",
        'amount': displayAmount,
        'rawAmount': rawAmount,
        'isExpense': isExpense,
        'icon': icon,
        'isRecurrent': result['isRecurrent'] ?? false,
        'category': result['category'],
        'toAccount': result['toAccount'],
        'qty': result['quantity'],
        'unitPrice': result['unitPrice'],
      };

      if (_currentCardIndex < _allTransactions.length) {
        _allTransactions[_currentCardIndex].insert(0, newTx);
        if (isExpense) {
          _myAccounts[_currentCardIndex]['current'] -= rawAmount;
        } else {
          _myAccounts[_currentCardIndex]['current'] += rawAmount;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transaction saved successfully!")),
    );
  }

  // --- UI COMPONENTS ---
  void _showExpenseCategorySelector(
    BuildContext context,
    Map<String, dynamic> account,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text("Select Category", style: AppTypography.headline3),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _expenseCategories.length,
                  itemBuilder: (context, index) {
                    final cat = _expenseCategories[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _navigateToAddExpense(account, cat);
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getExpenseIcon(cat),
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          cat,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionHistoryPage(
          accountName: _myAccounts[_currentCardIndex]['name'],
          transactions: _allTransactions[_currentCardIndex],
          onDelete: (tx) => _deleteTransaction(tx, _currentCardIndex),
          onEdit: (tx) => _editTransaction(tx),
        ),
      ),
    );
  }

  void _showTransactionActionSheet(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Edit Transaction"),
                onTap: () {
                  Navigator.pop(ctx);
                  _editTransaction(tx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Transaction"),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteTransaction(tx, _currentCardIndex);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showTransactionOptions(
    BuildContext context,
    Map<String, dynamic> account,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text("Add Transaction", style: AppTypography.headline3),
              const SizedBox(height: 8),
              Text(
                "For ${account['name']}",
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.greyText,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOptionButton(
                    context,
                    icon: Icons.arrow_downward_rounded,
                    label: "Income",
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigateToAddIncome(account);
                    },
                  ),
                  _buildOptionButton(
                    context,
                    icon: Icons.arrow_upward_rounded,
                    label: "Expense",
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showExpenseCategorySelector(context, account);
                    },
                  ),
                  _buildOptionButton(
                    context,
                    icon: Icons.swap_horiz_rounded,
                    label: "Transfer",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigateToAddTransfer(account);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _addAccount(BuildContext context) {
    // Add Account Logic (retained from previous steps)
    // ...
  }
  void _editAccount(BuildContext context, Map<String, dynamic> account) {}
  void _showEditOptions(BuildContext context, Map<String, dynamic> account) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("Edit Account"),
              onTap: () => _editAccount(context, account),
            ),
            ListTile(title: Text("Delete Account"), onTap: () {}),
          ],
        ),
      ),
    );
  }

  void _onNavBarTap(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullTransactions =
        _myAccounts.isNotEmpty && _currentCardIndex < _allTransactions.length
        ? _allTransactions[_currentCardIndex]
        : <Map<String, dynamic>>[];
    final displayTransactions = fullTransactions.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "My Accounts",
                                  style: AppTypography.headline2.copyWith(
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _addAccount(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_myAccounts.isEmpty)
                            Container(
                              height: 220,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "No accounts found",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 220,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _myAccounts.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentCardIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final acc = _myAccounts[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: AccountCard(
                                      accountName: acc['name'],
                                      accountType: acc['type'],
                                      initialBalance: acc['initial'],
                                      currentBalance: acc['current'],
                                      description: acc['desc'],
                                      onTap: () =>
                                          _showTransactionOptions(context, acc),
                                      onEditTap: () =>
                                          _showEditOptions(context, acc),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 10),
                          if (_myAccounts.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_myAccounts.length, (
                                index,
                              ) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentCardIndex == index
                                        ? AppColors.primary
                                        : AppColors.greyLight,
                                  ),
                                );
                              }),
                            ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Recent Transactions",
                                  style: AppTypography.headline2.copyWith(
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                                if (fullTransactions.length > 5)
                                  GestureDetector(
                                    onTap: _navigateToHistory,
                                    child: Text(
                                      "View All",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_myAccounts.isEmpty ||
                              displayTransactions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(22),
                              child: Center(
                                child: Text("No transactions available."),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              itemCount: displayTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = displayTransactions[index];
                                // HITTEST BEHAVIOR OPAQUE is key for clickable whitespace
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _showTransactionActionSheet(tx),
                                  child: _TransactionTile(
                                    title: tx['title'],
                                    subtitle: tx['date'],
                                    amount: tx['amount'],
                                    icon: tx['icon'] ?? Icons.error,
                                    isExpense: tx['isExpense'] ?? false,
                                    isRecurrent: tx['isRecurrent'] ?? false,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final bool isExpense;
  final bool isRecurrent;

  const _TransactionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.isExpense,
    this.isRecurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: isExpense
                  ? Colors.black.withValues(alpha: 0.05)
                  : AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isExpense ? Colors.black : AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.getTextPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isRecurrent) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.repeat, size: 14, color: AppColors.greyText),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTypography.labelLarge.copyWith(
              color: isExpense ? Colors.black : AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
