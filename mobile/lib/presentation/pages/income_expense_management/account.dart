import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/core/utils/string_case_formatter.dart';
import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/services/supabase/auth/auth_state_listener.dart';
import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/core/services/cache/cache_service.dart';

import 'package:cashlytics/domain/repositories/account_repository.dart';
import 'package:cashlytics/data/repositories/account_repository_impl.dart';
import 'package:cashlytics/domain/usecases/accounts/get_accounts.dart';
import 'package:cashlytics/domain/usecases/accounts/get_account_transactions.dart';
import 'package:cashlytics/domain/usecases/accounts/upsert_account.dart';
import 'package:cashlytics/domain/usecases/accounts/delete_account.dart';
import 'package:cashlytics/domain/entities/account.dart';
import 'package:cashlytics/domain/repositories/transaction_repository.dart';
import 'package:cashlytics/data/repositories/transaction_repository_impl.dart';
import 'package:cashlytics/domain/usecases/transactions/delete_transaction.dart';
import 'package:cashlytics/domain/usecases/transactions/upsert_transaction.dart';
import 'package:cashlytics/domain/entities/transaction_record.dart';
import 'package:cashlytics/domain/entities/income.dart';
import 'package:cashlytics/domain/entities/expense.dart';
import 'package:cashlytics/domain/entities/transfer.dart';
import 'package:cashlytics/domain/entities/expense_item.dart';
import 'package:cashlytics/domain/repositories/income_repository.dart';
import 'package:cashlytics/domain/repositories/expense_repository.dart';
import 'package:cashlytics/domain/repositories/transfer_repository.dart';
import 'package:cashlytics/domain/repositories/expense_item_repository.dart';
import 'package:cashlytics/data/repositories/income_repository_impl.dart';
import 'package:cashlytics/data/repositories/expense_repository_impl.dart';
import 'package:cashlytics/data/repositories/transfer_repository_impl.dart';
import 'package:cashlytics/data/repositories/expense_item_repository_impl.dart';
import 'package:cashlytics/domain/usecases/income/upsert_income.dart';
import 'package:cashlytics/domain/usecases/expenses/upsert_expense.dart';
import 'package:cashlytics/domain/usecases/transfers/upsert_transfer.dart';
import 'package:cashlytics/domain/usecases/expense_items/upsert_expense_item.dart';
import 'package:cashlytics/core/config/icons.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';
import 'package:cashlytics/presentation/widgets/account_card.dart';

import 'package:cashlytics/presentation/pages/user_management/login.dart';
import 'package:cashlytics/presentation/pages/expense_entry_ocr/add_income.dart';
import 'package:cashlytics/presentation/pages/expense_entry_ocr/add_transfer.dart';
import 'package:cashlytics/presentation/pages/expense_entry_ocr/add_expense.dart';
import 'package:cashlytics/presentation/pages/income_expense_management/transaction_history.dart';
import 'package:cashlytics/presentation/pages/income_expense_management/edit_transaction.dart';

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
  bool _redirecting = false;

  late final StreamSubscription<AuthState> _authStateSubscription;
  static const String _userProfileCacheKey = 'user_profile_cache';

  // Database service
  final DatabaseService _databaseService = const DatabaseService();

  // Repository and use cases
  late final AccountRepository _accountRepository;
  late final GetAccounts _getAccounts;
  late final GetAccountTransactions _getAccountTransactions;
  late final UpsertAccount _upsertAccount;
  late final DeleteAccount _deleteAccountUseCase;
  late final TransactionRepository _transactionRepository;
  late final DeleteTransaction _deleteTransactionUseCase;
  late final UpsertTransaction _upsertTransaction;
  late final IncomeRepository _incomeRepository;
  late final ExpenseRepository _expenseRepository;
  late final TransferRepository _transferRepository;
  late final ExpenseItemRepository _expenseItemRepository;
  late final UpsertIncome _upsertIncome;
  late final UpsertExpense _upsertExpense;
  late final UpsertTransfer _upsertTransfer;
  late final UpsertExpenseItem _upsertExpenseItem;

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

    // Check if user is signed in at startup
    final user = supabase.auth.currentUser;
    if (user == null) {
      // User not signed in, redirect immediately
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
      return;
    }

    _initializeRepositories();
    _loadData();

    _authStateSubscription = listenForSignedOutRedirect(
      shouldRedirect: () => !_redirecting,
      onRedirect: () {
        if (!mounted) return;
        setState(() => _redirecting = true);
        CacheService.remove(_userProfileCacheKey);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      onError: (error) {
        debugPrint('Auth State Listener Error: $error');
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  /// Ensure account map has valid UUIDs for id and user_id.
  Future<Map<String, dynamic>> _resolveAccountIdentifiers({
    required Map<String, dynamic> account,
    String? fallbackName,
  }) async {
    String? id = account['id'] ?? account['account_id'];
    String? userId = account['user_id'];

    // If both present and non-empty, return early
    if (id != null && id.isNotEmpty && userId != null && userId.isNotEmpty) {
      return {'id': id, 'user_id': userId};
    }

    // Try to resolve from backend using current user
    final authUserId = supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      userId = authUserId;
    }

    if (id == null || id.isEmpty) {
      // Fetch accounts for current user and match by name if possible
      if (authUserId != null) {
        try {
          final accounts = await _getAccounts(authUserId);
          final match = accounts.firstWhere(
            (acc) => acc.name == (fallbackName ?? account['name']),
            orElse: () => accounts.first,
          );
          id = match.id;
          userId = match.userId;
        } catch (e) {
          debugPrint('Failed to resolve account ID from backend: $e');
        }
      }
    }

    if (id == null || id.isEmpty) {
      throw Exception('Missing account id for balance update');
    }
    if (userId == null || userId.isEmpty) {
      throw Exception('Missing user_id for balance update');
    }

    // Persist resolved values back into map to avoid future lookups
    account['id'] = id;
    account['account_id'] = id;
    account['user_id'] = userId;

    return {'id': id, 'user_id': userId};
  }

  void _initializeRepositories() {
    _pageController = PageController(viewportFraction: 0.85);
    _accountRepository = AccountRepositoryImpl();
    _getAccounts = GetAccounts(_accountRepository);
    _getAccountTransactions = GetAccountTransactions(_accountRepository);
    _upsertAccount = UpsertAccount(_accountRepository);
    _deleteAccountUseCase = DeleteAccount(_accountRepository);
    _transactionRepository = TransactionRepositoryImpl();
    _deleteTransactionUseCase = DeleteTransaction(_transactionRepository);
    _upsertTransaction = UpsertTransaction(_transactionRepository);
    _incomeRepository = IncomeRepositoryImpl();
    _expenseRepository = ExpenseRepositoryImpl();
    _transferRepository = TransferRepositoryImpl();
    _expenseItemRepository = ExpenseItemRepositoryImpl();
    _upsertIncome = UpsertIncome(_incomeRepository);
    _upsertExpense = UpsertExpense(_expenseRepository);
    _upsertTransfer = UpsertTransfer(_transferRepository);
    _upsertExpenseItem = UpsertExpenseItem(_expenseItemRepository);
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

      // Sort by createdAt, earliest first
      accounts.sort(
        (a, b) => (a.createdAt ?? DateTime(1970)).compareTo(
          b.createdAt ?? DateTime(1970),
        ),
      );

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
          'user_id': account.userId,
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
            final bool isTransfer =
                (tx.category ?? '').toString().toUpperCase() == 'TRANSFER';

            final String? toAccountName =
                isTransfer && (tx.title.toLowerCase().startsWith('to '))
                ? tx.title.substring(3).trim()
                : null;

            final String? fromAccountName =
                isTransfer && (tx.title.toLowerCase().startsWith('from '))
                ? tx.title.substring(5).trim()
                : null;

            txList.add({
              'transactionId': tx.transactionId,
              'type': isTransfer
                  ? 'transfer'
                  : (isExpense ? 'expense' : 'income'),
              'title': tx.title,
              'date': _formatDate(tx.date),
              'amount': displayAmount,
              'rawAmount': amount,
              'isExpense': isExpense,
              'icon': tx.icon ?? _getTransactionIcon(isExpense, tx.category),
              'isRecurrent': false,
              'category': tx.category,
              'toAccount': toAccountName,
              'fromAccount': fromAccountName,
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
      return getExpenseIcon(category ?? '');
    } else {
      return getIncomeIcon(category ?? '');
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
  Future<void> _deleteTransaction(
    Map<String, dynamic> tx,
    int accountIndex,
  ) async {
    String? transactionId = tx['transactionId']?.toString();
    String? accountId = _myAccounts[accountIndex]['id']?.toString();
    final double amount = _parseAmount(tx);
    final bool isTransfer =
        (tx['type'] == 'transfer') ||
        ((tx['category'] ?? '').toString().toUpperCase() == 'TRANSFER');

    String? extractName(String? title, String prefix) {
      if (title == null) return null;
      if (title.toLowerCase().startsWith(prefix.toLowerCase()) &&
          title.length > prefix.length) {
        return title.substring(prefix.length).trim();
      }
      return null;
    }

    int? senderIndex;
    int? receiverIndex;

    if (isTransfer) {
      if (tx['isExpense'] == true) {
        senderIndex = accountIndex;
        final String? receiverName =
            tx['toAccount'] ?? extractName(tx['title']?.toString(), 'To ');
        if (receiverName != null) {
          final idx = _myAccounts.indexWhere(
            (acc) => acc['name'] == receiverName,
          );
          receiverIndex = idx >= 0 ? idx : null;
        }
      } else {
        receiverIndex = accountIndex;
        final String? senderName =
            tx['fromAccount'] ?? extractName(tx['title']?.toString(), 'From ');
        if (senderName != null) {
          final idx = _myAccounts.indexWhere(
            (acc) => acc['name'] == senderName,
          );
          senderIndex = idx >= 0 ? idx : null;
          if (senderIndex != null) {
            accountId = _myAccounts[senderIndex]['id']?.toString();
          }
        }
      }
    }

    bool matchesTx(Map<String, dynamic> item) {
      final String? itemId = item['transactionId']?.toString();
      if (transactionId != null && itemId != null) {
        return itemId == transactionId;
      }
      final bool sameTitle = (item['title'] ?? '') == (tx['title'] ?? '');
      final bool sameDate = (item['date'] ?? '') == (tx['date'] ?? '');
      final double itemAmount = _parseAmount(item);
      final bool sameAmount = (itemAmount - amount).abs() < 0.01;
      return sameTitle && sameDate && sameAmount;
    }

    try {
      // If transactionId is missing, try to resolve it from backend
      if ((transactionId == null || transactionId.isEmpty) &&
          accountId != null) {
        final resolvedId = await _resolveTransactionIdFromBackend(
          tx,
          accountId,
        );
        if (resolvedId != null) {
          transactionId = resolvedId;
          tx['transactionId'] = resolvedId;
        }
      }

      if (transactionId != null && transactionId.isNotEmpty) {
        // Persist delete in backend
        await _deleteTransactionUseCase(transactionId);
      }

      // Reload accounts from DB to pick up trigger-updated balances
      List<Account> refreshedAccounts = [];
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        refreshedAccounts = await _getAccounts(userId);
      }
      final Map<String?, Account> accountLookup = {
        for (final acc in refreshedAccounts) acc.id: acc,
      };

      if (!mounted) return;
      setState(() {
        if (isTransfer) {
          // Find any accounts that contain this transfer (by id or fallback match)
          final Set<int> affectedIndexes = {};

          for (int i = 0; i < _allTransactions.length; i++) {
            final hasMatch = _allTransactions[i].any(
              (item) => matchesTx(item),
            );
            if (hasMatch) affectedIndexes.add(i);
          }

          // Ensure sender/receiver indexes are also included (for cached legacy data)
          if (senderIndex != null) affectedIndexes.add(senderIndex);
          if (receiverIndex != null) affectedIndexes.add(receiverIndex);

          for (final idx in affectedIndexes) {
            if (idx < 0 || idx >= _allTransactions.length) continue;

            // Capture one matched item to infer direction when DB data is missing
            Map<String, dynamic>? matchedItem = _allTransactions[idx]
                .cast<Map<String, dynamic>?>()
                .firstWhere(
                  (item) => item != null && matchesTx(item),
                  orElse: () => null,
                );

            _allTransactions[idx].removeWhere((item) => matchesTx(item));

            final accId = _myAccounts[idx]['id'];
            final updated = accountLookup[accId];
            if (updated != null) {
              _myAccounts[idx]['current'] = updated.currentBalance;
            } else if (matchedItem != null) {
              // Fallback adjust when DB did not return balances
              final bool wasExpense = matchedItem['isExpense'] == true;
              if (wasExpense) {
                _myAccounts[idx]['current'] =
                    (_myAccounts[idx]['current'] ?? 0.0) + amount;
              } else {
                _myAccounts[idx]['current'] =
                    (_myAccounts[idx]['current'] ?? 0.0) - amount;
              }
            }
          }
        } else {
          _allTransactions[accountIndex].removeWhere(
            (item) => matchesTx(item),
          );

          final updated = accountLookup[accountId];
          if (updated != null) {
            _myAccounts[accountIndex]['current'] = updated.currentBalance;
          } else {
            if (tx['isExpense'] == true) {
              _myAccounts[accountIndex]['current'] += amount;
            } else {
              _myAccounts[accountIndex]['current'] -= amount;
            }
          }
        }
      });

      // Update caches to persist changes
      CacheService.save('accounts', _myAccounts);
      CacheService.save('transactions', _allTransactions);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Transaction deleted and balance updated"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  Future<String?> _resolveTransactionIdFromBackend(
    Map<String, dynamic> tx,
    String accountId,
  ) async {
    try {
      final backend = await _getAccountTransactions(accountId);
      final String title = (tx['title'] ?? '').toString();
      final double amt = _parseAmount(tx).abs();
      final String dateStr = (tx['date'] ?? '').toString();

      for (final b in backend) {
        final sameTitle = b.title == title;
        final sameAmt = (b.amount.abs() - amt).abs() < 0.01;
        final sameDay = _formatDate(b.date) == dateStr;
        if (sameTitle && sameAmt && sameDay) {
          return b.transactionId;
        }
      }
    } catch (_) {}
    return null;
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
            result['icon'] = getExpenseIcon(result['category']);
          } else if (result['type'] == 'income' && result['category'] != null) {
            result['icon'] = getIncomeIcon(result['category']);
          } else if (result['type'] == 'transfer') {
            result['icon'] = Icons.north_east_rounded;
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
    final List<String> allAccountNames = _myAccounts
        .map((acc) => acc['name'] as String)
        .toList();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddIncomePage(
          accountName: account['name']?.toString() ?? 'Account',
          availableAccounts: allAccountNames,
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      await _addTransactionToState(result, isExpense: false);
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
      await _addTransactionToState(result, isExpense: true, isTransfer: true);
    }
  }

  Future<void> _navigateToAddExpense(
    Map<String, dynamic> account,
    String category,
  ) async {
    final List<String> allAccountNames = _myAccounts
        .map((acc) => acc['name'] as String)
        .toList();

    const List<String> expenseCategories = [
      'FOOD',
      'TRANSPORT',
      'ENTERTAINMENT',
      'SHOPPING',
      'UTILITIES',
      'HEALTHCARE',
      'EDUCATION',
      'TRAVEL',
    ];

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpensePage(
          accountName: account['name']?.toString() ?? 'Account',
          availableAccounts: allAccountNames,
          category: category,
          availableCategories: expenseCategories,
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      await _addTransactionToState(result, isExpense: true);
    }
  }

  Future<void> _addTransactionToState(
    Map<String, dynamic> result, {
    required bool isExpense,
    bool isTransfer = false,
  }) async {
    // Get account ID for current account
    final currentAccount = _myAccounts[_currentCardIndex];
    final String? accountId =
        currentAccount['id'] ?? currentAccount['account_id'];
    final String accountName = currentAccount['name'];

    // Validate account ID
    if (accountId == null || accountId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid account ID")));
      }
      return;
    }

    try {
      // 1. Save to database first
      final String transactionName =
          result['itemName'] ??
          result['title'] ??
          (isTransfer
              ? 'Transfer'
              : isExpense
              ? 'Expense'
              : 'Income');

      // Create and save main transaction record (without ID for new transactions)
      final transactionRecord = TransactionRecord(
        accountId: accountId,
        name: transactionName,
        type: isTransfer ? 'T' : (isExpense ? 'E' : 'I'),
        description: result['description'],
        currency: 'MYR',
      );

      debugPrint(
        'Saving transaction: accountId=$accountId, name=$transactionName, type=${transactionRecord.type}',
      );
      final savedTransaction = await _upsertTransaction(transactionRecord);
      final String? transactionId = savedTransaction.id;

      if (transactionId == null || transactionId.isEmpty) {
        throw Exception('Transaction saved but ID is null or empty');
      }

      debugPrint('Transaction saved with ID: $transactionId');

      // Validate amount
      final amount = result['amount'];
      if (amount == null) {
        throw Exception('Amount is required');
      }

      debugPrint('Amount validated: $amount');

      // Save type-specific details
      if (isTransfer) {
        // Get account IDs
        final fromAccountName = result['fromAccount'] ?? accountName;
        final toAccountName = result['toAccount'];

        final fromAccount = _myAccounts.firstWhere(
          (acc) => acc['name'] == fromAccountName,
          orElse: () => currentAccount,
        );
        final toAccount = _myAccounts.firstWhere(
          (acc) => acc['name'] == toAccountName,
          orElse: () => {},
        );

        if (toAccount.isNotEmpty) {
          final String? fromAccountId =
              fromAccount['id'] ?? fromAccount['account_id'];
          final String? toAccountId =
              toAccount['id'] ?? toAccount['account_id'];

          if (fromAccountId != null &&
              fromAccountId.isNotEmpty &&
              toAccountId != null &&
              toAccountId.isNotEmpty) {
            final transfer = Transfer(
              transactionId: transactionId,
              amount: amount as double,
              fromAccountId: fromAccountId,
              toAccountId: toAccountId,
            );
            debugPrint(
              'Saving transfer with transactionId: $transactionId, from: $fromAccountId, to: $toAccountId',
            );
            await _upsertTransfer(transfer);
          } else {
            debugPrint(
              'Invalid account IDs for transfer: from=$fromAccountId, to=$toAccountId',
            );
          }
        }
      } else if (isExpense) {
        // Fetch expense category ID from category name
        String? categoryId;
        final categoryName = result['category'] as String?;
        if (categoryName != null && categoryName.isNotEmpty) {
          try {
            final categoryData = await _databaseService.fetchSingle(
              'expense_category',
              matchColumn: 'name',
              matchValue: categoryName.toUpperCase(),
            );
            categoryId = categoryData?['expense_cat_id'] as String?;
            debugPrint(
              'Fetched category ID: $categoryId for category: $categoryName',
            );
          } catch (e) {
            debugPrint('Error fetching expense category ID: $e');
          }
        }

        debugPrint(
          'Creating expense with transactionId: $transactionId, amount: $amount, categoryId: $categoryId',
        );

        final expense = Expense(
          transactionId: transactionId,
          amount: amount as double,
          expenseCategoryId: categoryId,
        );
        debugPrint('Expense object created, calling _upsertExpense()');
        await _upsertExpense(expense);
        debugPrint('Expense saved successfully');

        // Save expense items if present
        final items = result['items'] as List<Map<String, dynamic>>?;
        if (items != null && items.isNotEmpty) {
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            final qty = int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
            final unitPrice =
                double.tryParse(item['unitPrice']?.toString() ?? '0') ?? 0.0;

            final expenseItem = ExpenseItem(
              transactionId: transactionId,
              itemId: i + 1,
              itemName: item['name'] ?? '',
              quantity: qty,
              unitPrice: unitPrice,
              price: qty * unitPrice,
            );
            await _upsertExpenseItem(expenseItem);
          }
        }
      } else {
        // Income
        final String? category = result['category'];
        debugPrint(
          'Creating Income: transactionId=$transactionId, amount=$amount, category=$category',
        );

        final income = Income(
          transactionId: transactionId,
          amount: amount as double,
          category: category
              ?.toUpperCase(), // Ensure uppercase for database constraint
          isRecurrent: result['isRecurrent'] ?? false,
        );
        debugPrint('Income object created, calling _upsertIncome()');
        await _upsertIncome(income);
        debugPrint('Income saved successfully');
      }

      // 2. Update local state after successful database save
      setState(() {
        final double rawAmount = result['amount'];
        final String displayAmount =
            (isExpense ? '- \$' : '+ \$') + rawAmount.toStringAsFixed(2);

        // --- 1. SENDER LOGIC (Current Account) ---
        IconData icon;
        String title = result['itemName'] ?? result['title'] ?? 'Transaction';

        if (isTransfer) {
          icon = Icons.north_east_rounded;
          // FIX: Display "To [Receiver Name]" for the sender
          if (result['toAccount'] != null) {
            title = "To ${result['toAccount']}";
          }
        } else if (isExpense) {
          icon = getExpenseIcon(result['category'] ?? '');
        } else {
          icon = getIncomeIcon(result['category'] ?? '');
        }

        final newTxSender = {
          'type': isTransfer ? 'transfer' : (isExpense ? 'expense' : 'income'),
          'title': title,
          'date': "${result['date'].day}/${result['date'].month}",
          'amount': displayAmount,
          'rawAmount': rawAmount,
          'isExpense': isExpense,
          'icon': icon,
          'isRecurrent': result['isRecurrent'] ?? false,
          'category': result['category'],
          'transactionId': transactionId,
          'fromAccount': currentAccount['name'],
          'toAccount': result['toAccount'],
          'qty': result['quantity'],
          'unitPrice': result['unitPrice'],
          'items': result['items'],
          'description': result['description'],
        };

        // Add to Sender (Current Card)
        if (_currentCardIndex < _allTransactions.length) {
          _allTransactions[_currentCardIndex].insert(0, newTxSender);
          if (isExpense) {
            _myAccounts[_currentCardIndex]['current'] -= rawAmount;
          } else {
            _myAccounts[_currentCardIndex]['current'] += rawAmount;
          }
        }

        // --- 2. RECEIVER LOGIC (The Other Account) ---
        // This part finds the receiver account and adds the "Incoming" transaction
        if (isTransfer && result['toAccount'] != null) {
          final String targetName = result['toAccount'];
          final String senderName = _myAccounts[_currentCardIndex]['name'];

          // Find the index of the receiver account in your list
          final int targetIndex = _myAccounts.indexWhere(
            (acc) => acc['name'] == targetName,
          );

          if (targetIndex != -1 && targetIndex < _allTransactions.length) {
            // Create the "Incoming" version of the transaction
            final String displayAmountReceiver =
                '+ ${MathFormatter.formatCurrency(rawAmount)}';

            final newTxReceiver = {
              'type': 'transfer',
              'title': "From $senderName", // FIX: Display "From [Sender Name]"
              'date': "${result['date'].day}/${result['date'].month}",
              'amount': displayAmountReceiver,
              'rawAmount': rawAmount,
              'isExpense': false, // It's income for the receiver
              'icon': Icons
                  .arrow_downward_rounded, // Icon pointing down for received money
              'isRecurrent': false,
              'category': 'Transfer',
              'transactionId': transactionId,
              'fromAccount': senderName,
              'toAccount': targetName,
            };

            // Add to Receiver
            _allTransactions[targetIndex].insert(0, newTxReceiver);
            // Update Receiver Balance
            _myAccounts[targetIndex]['current'] += rawAmount;
          }
        }
      });

      // 3. Update account balances in database
      final resolvedSender = await _resolveAccountIdentifiers(
        account: currentAccount,
      );

      final updatedSenderAccount = Account(
        id: resolvedSender['id'],
        userId: resolvedSender['user_id'],
        name: currentAccount['name'],
        type: currentAccount['type'],
        initialBalance: (currentAccount['initial'] ?? 0.0).toDouble(),
        currentBalance: _myAccounts[_currentCardIndex]['current'].toDouble(),
        description: currentAccount['description'] ?? currentAccount['desc'],
      );
      await _upsertAccount(updatedSenderAccount);

      // Update receiver account balance if transfer
      if (isTransfer && result['toAccount'] != null) {
        final targetIndex = _myAccounts.indexWhere(
          (acc) => acc['name'] == result['toAccount'],
        );
        if (targetIndex != -1) {
          final receiverAccount = _myAccounts[targetIndex];
          final resolvedReceiver = await _resolveAccountIdentifiers(
            account: receiverAccount,
            fallbackName: receiverAccount['name'],
          );

          final updatedReceiverAccount = Account(
            id: resolvedReceiver['id'],
            userId: resolvedReceiver['user_id'],
            name: receiverAccount['name'],
            type: receiverAccount['type'],
            initialBalance: (receiverAccount['initial'] ?? 0.0).toDouble(),
            currentBalance: _myAccounts[targetIndex]['current'].toDouble(),
            description:
                receiverAccount['description'] ?? receiverAccount['desc'],
          );
          await _upsertAccount(updatedReceiverAccount);
        }
      }

      // Save changes to cache
      CacheService.save('transactions', _allTransactions);
      CacheService.save('accounts', _myAccounts);

      // Rebuild UI with new transactions
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction saved successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save transaction: $e")),
        );
      }
    }
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
                            getExpenseIcon(cat),
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          StringCaseFormatter.toTitleCase(cat),
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
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'CASH';

    final List<String> accountTypes = [
      'CASH',
      'BANK',
      'E-WALLET',
      'CREDIT CARD',
      'INVESTMENT',
      'LOAN',
      'OTHER',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Handle Bar ---
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Title ---
                    Text(
                      "Add New Account",
                      style: AppTypography.headline3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // --- Name Input ---
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Account Name',
                        // --- CHANGE HERE: Label color ---
                        labelStyle: const TextStyle(color: Colors.grey),
                        hintText: 'e.g. Main Bank',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Type Selector ---
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        // Keeping 'Type' consistent with the others,
                        // though you didn't explicitly ask for it, it looks better matching:
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: accountTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Balance Input ---
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Initial Balance',
                        // --- CHANGE HERE: Label color ---
                        labelStyle: const TextStyle(color: Colors.grey),
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Description Input ---
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        // --- CHANGE HERE: Label color ---
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Create Button ---
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;

                        final userId = supabase.auth.currentUser?.id;
                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You must be logged in'),
                            ),
                          );
                          return;
                        }

                        try {
                          final newAccount = Account(
                            id: null,
                            userId: userId,
                            name: nameController.text.trim(),
                            type: selectedType,
                            initialBalance:
                                double.tryParse(balanceController.text) ?? 0.0,
                            currentBalance:
                                double.tryParse(balanceController.text) ?? 0.0,
                            description: descController.text.trim(),
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          final savedAccount = await _upsertAccount(newAccount);

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          setState(() {
                            _myAccounts.add({
                              'id': savedAccount.id,
                              'name': savedAccount.name,
                              'type': savedAccount.type,
                              'initial': savedAccount.initialBalance,
                              'current': savedAccount.currentBalance,
                              'desc': savedAccount.description ?? '',
                            });
                            _allTransactions.add([]);
                            _currentCardIndex = _myAccounts.length - 1;

                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                if (_pageController.hasClients) {
                                  _pageController.animateToPage(
                                    _currentCardIndex,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                            );
                          });

                          CacheService.save('accounts', _myAccounts);
                          CacheService.save('transactions', _allTransactions);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account created successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error creating account: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editAccount(BuildContext context, Map<String, dynamic> account) {
    final nameController = TextEditingController(
      text: account['name']?.toString() ?? '',
    );
    final descController = TextEditingController(
      text: account['desc']?.toString() ?? '',
    );
    final initialController = TextEditingController(
      text: (account['initial'] ?? 0).toString(),
    );
    final currentController = TextEditingController(
      text: (account['current'] ?? 0).toString(),
    );

    // Enforce DB-allowed TYPE values
    String type = (account['type']?.toString() ?? 'CASH').toUpperCase();
    final types = <String>[
      'CASH',
      'BANK',
      'E-WALLET',
      'CREDIT CARD',
      'INVESTMENT',
      'LOAN',
      'OTHER',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                // Handle keyboard covering inputs
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Handle Bar ---
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Title ---
                    Text(
                      "Edit Account",
                      style: AppTypography.headline3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // --- Name Input ---
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Type Selector ---
                    DropdownButtonFormField<String>(
                      initialValue: types.contains(type) ? type : types.first,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: types
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setSheetState(() => type = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Initial Balance Input ---
                    TextField(
                      controller: initialController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Initial Balance',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Current Balance (Read-Only) ---
                    TextField(
                      controller: currentController,
                      readOnly: true,
                      enabled: false,
                      style: const TextStyle(color: Colors.grey),
                      decoration: InputDecoration(
                        labelText: 'Current Balance (Read-only)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixText: '\$ ',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Description Input ---
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Save Button ---
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final userId = supabase.auth.currentUser?.id;
                              if (userId == null) {
                                Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Not signed in'),
                                    ),
                                  );
                                }
                                return;
                              }

                              // Show loading state
                              setSheetState(() => _isLoading = true);

                              final updated = Account(
                                id: account['id']?.toString(),
                                userId: userId,
                                name: nameController.text.trim(),
                                type: type,
                                initialBalance:
                                    double.tryParse(
                                      initialController.text.trim(),
                                    ) ??
                                    0,
                                // Preserve current balance logic
                                currentBalance: (account['current'] is num)
                                    ? (account['current'] as num).toDouble()
                                    : double.tryParse(
                                            account['current']?.toString() ??
                                                '',
                                          ) ??
                                          0,
                                description: descController.text.trim().isEmpty
                                    ? null
                                    : descController.text.trim(),
                              );

                              try {
                                final saved = await _upsertAccount(updated);
                                if (!mounted) return;

                                setState(() {
                                  account['name'] = saved.name;
                                  account['type'] = saved.type;
                                  account['initial'] = saved.initialBalance;
                                  account['current'] = saved.currentBalance;
                                  account['desc'] = saved.description ?? '';
                                });

                                CacheService.save('accounts', _myAccounts);
                                CacheService.save(
                                  'transactions',
                                  _allTransactions,
                                );

                                if (ctx.mounted) {
                                  Navigator.pop(ctx); // Close bottom sheet only
                                }

                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Account updated'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Update failed: $e'),
                                    ),
                                  );
                                }
                              } finally {
                                // Hide loading state
                                setSheetState(() => _isLoading = false);
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditOptions(BuildContext context, Map<String, dynamic> account) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Account'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editAccount(context, account);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Account'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteAccount(context, account);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(
    BuildContext context,
    Map<String, dynamic> account,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will remove the account and its transactions. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount(context, account);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(
    BuildContext context,
    Map<String, dynamic> account,
  ) async {
    final String? accountId = account['id']?.toString();
    try {
      if (accountId != null && accountId.isNotEmpty) {
        await _deleteAccountUseCase(accountId);
      }

      final removeIndex = _myAccounts.indexOf(account);
      if (removeIndex != -1) {
        setState(() {
          _myAccounts.removeAt(removeIndex);
          if (removeIndex < _allTransactions.length) {
            _allTransactions.removeAt(removeIndex);
          }
          if (_currentCardIndex >= _myAccounts.length) {
            _currentCardIndex = _myAccounts.isEmpty
                ? 0
                : _myAccounts.length - 1;
          }
        });
        CacheService.save('accounts', _myAccounts);
        CacheService.save('transactions', _allTransactions);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Account deleted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
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
