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

// ignore_for_file: use_build_context_synchronously

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
        // Use addPostFrameCallback to delay navigation until after frame is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Show loading dialog while initializing
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );
            // Delay navigation to allow UI to render
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.of(context).pop(); // Close loading dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            });
          }
        });
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
        // Use addPostFrameCallback to delay navigation until after frame is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Show loading dialog while initializing
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );
            // Delay navigation to allow UI to render
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.of(context).pop(); // Close loading dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            });
          }
        });
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
                list.map((e) {
                  final tx = Map<String, dynamic>.from(e);
                  // Regenerate icon from iconName if missing
                  if (tx['icon'] == null && tx['iconName'] != null) {
                    final iconName = tx['iconName'];
                    IconData iconData;
                    if (iconName == 'north_east_rounded') {
                      iconData = Icons.north_east_rounded;
                    } else if (iconName == 'south_east_rounded') {
                      iconData = Icons.south_east_rounded;
                    } else {
                      final isExpense = tx['isExpense'] == true;
                      iconData = _getTransactionIcon(isExpense, iconName);
                    }
                    tx['icon'] = iconData;
                  } else if (tx['icon'] == null) {
                    // Fallback: regenerate icon if no iconName
                    final isTransfer =
                        (tx['type'] == 'transfer') ||
                        ((tx['category'] ?? '').toString().toUpperCase() ==
                            'TRANSFER');
                    if (isTransfer) {
                      tx['icon'] = tx['isExpense'] == true
                          ? Icons.north_east_rounded
                          : Icons.south_east_rounded;
                    } else {
                      final isExpense = tx['isExpense'] == true;
                      tx['icon'] = _getTransactionIcon(
                        isExpense,
                        tx['category'],
                      );
                    }
                  }
                  return tx;
                }),
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

            String? toAccountName;
            String? fromAccountName;
            if (isTransfer) {
              final String title = tx.title ?? '';
              final String titleLower = title.toLowerCase().trim();

              // Support multiple title formats: "Transfer to X", "to X", "Transfer from Y", "from Y"
              const toPrefixes = ['transfer to ', 'to '];
              for (final prefix in toPrefixes) {
                if (titleLower.startsWith(prefix)) {
                  toAccountName = title.substring(prefix.length).trim();
                  break;
                }
              }

              const fromPrefixes = ['transfer from ', 'from '];
              for (final prefix in fromPrefixes) {
                if (titleLower.startsWith(prefix)) {
                  fromAccountName = title.substring(prefix.length).trim();
                  break;
                }
              }

              // If counterpart name cannot be derived and one side was deleted, show a sensible fallback
              if (toAccountName == null && fromAccountName == null) {
                final String fallbackName = 'Deleted account';
                if (isExpense) {
                  toAccountName =
                      fallbackName; // money moved out to a deleted account
                } else {
                  fromAccountName =
                      fallbackName; // money came from a deleted account
                }
              }
            }

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
              'iconName': _getIconName(isExpense, tx.category, isTransfer),
              'isRecurrent': false,
              'category': tx.category,
              'toAccount': toAccountName,
              'fromAccount': fromAccountName,
              'description': tx.description,
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
      CacheService.save('transactions', _getSanitizedTransactions());
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

  String _getIconName(bool isExpense, String? category, bool isTransfer) {
    if (isTransfer) {
      return isExpense ? 'north_east_rounded' : 'south_east_rounded';
    }
    // Return the category name as the icon identifier
    // This will be resolved to an actual IconData when rendering
    return category ?? (isExpense ? 'expense' : 'income');
  }

  double _parseAmount(Map<String, dynamic> tx) {
    if (tx['rawAmount'] != null) {
      return (tx['rawAmount'] as num).toDouble();
    }
    String amtString = tx['amount'].toString();
    String cleanString = amtString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanString) ?? 0.0;
  }

  /// Parse amount from various types (double, int, String, Map)
  double _parseAmountValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      String cleanString = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanString) ?? 0.0;
    }
    if (value is Map) {
      // If it's a map, extract the amount field
      return _parseAmount(value as Map<String, dynamic>);
    }
    return 0.0;
  }

  /// Remove non-serializable fields (like IconData) before caching
  List<List<Map<String, dynamic>>> _getSanitizedTransactions() {
    return _allTransactions.map((txList) {
      return txList.map((tx) {
        final sanitized = Map<String, dynamic>.from(tx);
        // Remove any non-serializable fields
        sanitized.remove('icon'); // Remove IconData which can't be serialized
        return sanitized;
      }).toList();
    }).toList();
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
            final hasMatch = _allTransactions[i].any((item) => matchesTx(item));
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
          _allTransactions[accountIndex].removeWhere((item) => matchesTx(item));

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
      CacheService.save('transactions', _getSanitizedTransactions());

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

  /// Fetch complete transaction details from database
  Future<Map<String, dynamic>?> _fetchCompleteTransactionDetails(
    String transactionId,
  ) async {
    try {
      // Fetch transaction record
      final txData = await _databaseService.fetchSingle(
        'transaction',
        matchColumn: 'transaction_id',
        matchValue: transactionId,
      );

      if (txData == null) return null;

      final type = txData['type'] as String;
      final name = txData['name'] as String;
      final description = txData['description'] as String?;
      final accountId = txData['account_id'] as String;
      final createdAt =
          DateTime.tryParse(txData['created_at'] as String? ?? '') ??
          DateTime.now();

      Map<String, dynamic> completeData = {
        'transactionId': transactionId,
        'title': name,
        'description': description,
        'date': _formatDate(createdAt),
        'rawDate': createdAt,
      };

      if (type == 'I') {
        // Income
        final incomeData = await _databaseService.fetchSingle(
          'income',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );

        if (incomeData != null) {
          final amount = _parseAmountValue(incomeData['amount']);
          completeData.addAll({
            'type': 'income',
            'rawAmount': amount,
            'amount': '+ \$${amount.toStringAsFixed(2)}',
            'isExpense': false,
            'category': incomeData['category'] as String?,
            'isRecurrent': incomeData['is_recurrent'] as bool? ?? false,
            'icon': getIncomeIcon(incomeData['category'] as String?),
          });
        }
      } else if (type == 'E') {
        // Expense
        final expenseData = await _databaseService.fetchSingle(
          'expenses',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );

        if (expenseData != null) {
          final categoryId = expenseData['expense_cat_id'] as String?;
          final categoryData = await _databaseService.fetchSingle(
            'expense_category',
            matchColumn: 'expense_cat_id',
            matchValue: categoryId,
          );
          final categoryName = categoryData?['name'] as String?;
          final amount = _parseAmountValue(expenseData['amount']);

          // Fetch expense items
          final expenseItems = await _databaseService.fetchAll(
            'expense_items',
            filters: {'transaction_id': transactionId},
          );

          // Format items for the edit page
          final List<Map<String, dynamic>> items = expenseItems.map((item) {
            return {
              'name': item['item_name'] as String?,
              'itemName': item['item_name'] as String?,
              'qty': item['qty'] as int?,
              'quantity': item['qty'] as int?,
              'unitPrice': _parseAmountValue(item['unit_price']),
              'unit_price': _parseAmountValue(item['unit_price']),
              'price': _parseAmountValue(item['price']),
            };
          }).toList();

          completeData.addAll({
            'type': 'expense',
            'rawAmount': amount,
            'amount': '- \$${amount.toStringAsFixed(2)}',
            'isExpense': true,
            'category': categoryName ?? 'OTHER',
            'icon': getExpenseIcon(categoryName),
            'items': items,
            'itemName': items.isNotEmpty ? items[0]['name'] : null,
          });
        }
      } else if (type == 'T') {
        // Transfer
        final transferData = await _databaseService.fetchSingle(
          'transfer',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );

        if (transferData != null) {
          final String? fromAccountId =
              transferData['from_account_id'] as String?;
          final String? toAccountId = transferData['to_account_id'] as String?;
          final amount = _parseAmountValue(transferData['amount']);

          // Fetch account names (only when IDs are present)
          String? fromAccountName;
          if (fromAccountId != null && fromAccountId.isNotEmpty) {
            final fromAccountData = await _databaseService.fetchSingle(
              'accounts',
              matchColumn: 'account_id',
              matchValue: fromAccountId,
              columns: 'name',
            );
            fromAccountName = fromAccountData?['name'] as String?;
          }

          String? toAccountName;
          if (toAccountId != null && toAccountId.isNotEmpty) {
            final toAccountData = await _databaseService.fetchSingle(
              'accounts',
              matchColumn: 'account_id',
              matchValue: toAccountId,
              columns: 'name',
            );
            toAccountName = toAccountData?['name'] as String?;
          }

          // Determine if it's expense or income for current account
          final bool isExpense =
              (fromAccountId != null && accountId == fromAccountId);

          completeData.addAll({
            'type': 'transfer',
            'rawAmount': amount,
            'amount': '${isExpense ? '-' : '+'} \$${amount.toStringAsFixed(2)}',
            'isExpense': isExpense,
            'category': 'TRANSFER',
            'fromAccount':
                fromAccountName ??
                (fromAccountId == null ? 'Deleted account' : null),
            'toAccount':
                toAccountName ??
                (toAccountId == null ? 'Deleted account' : null),
            'fromAccountId': fromAccountId,
            'toAccountId': toAccountId,
            'icon': isExpense
                ? Icons.north_east_rounded
                : Icons.south_east_rounded,
          });
        }
      }

      return completeData;
    } catch (e) {
      debugPrint('Error fetching complete transaction details: $e');
      return null;
    }
  }

  // --- LOGIC: EDIT (now routes to Add* pages with context) ---
  Future<void> _editTransaction(Map<String, dynamic> oldTx) async {
    // Prevent editing transfers where the counterpart account was deleted
    if (_isTransferCounterpartDeleted(oldTx)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot edit transfer: counterpart account was deleted.',
          ),
        ),
      );
      return;
    }

    final List<String> allAccountNames = _myAccounts
        .map((acc) => acc['name'] as String)
        .toList();
    final String currentAccountName = _myAccounts[_currentCardIndex]['name'];

    if (oldTx['rawAmount'] == null) {
      oldTx['rawAmount'] = _parseAmount(oldTx);
    }

    // Ensure we have a transactionId for backend updates
    if ((oldTx['transactionId'] == null ||
        (oldTx['transactionId'].toString().isEmpty))) {
      try {
        final resolvedSender = await _resolveAccountIdentifiers(
          account: _myAccounts[_currentCardIndex],
          fallbackName: currentAccountName,
        );
        final String? accountId = resolvedSender['id']?.toString();
        if (accountId != null) {
          final resolvedId = await _resolveTransactionIdFromBackend(
            oldTx,
            accountId,
          );
          if (resolvedId != null) {
            oldTx['transactionId'] = resolvedId;
          }
        }
      } catch (e) {
        debugPrint('Failed to resolve transactionId for edit: $e');
      }
    }

    // Fetch complete transaction details from database
    Map<String, dynamic> completeData = oldTx;
    if (oldTx['transactionId'] != null) {
      final fetchedData = await _fetchCompleteTransactionDetails(
        oldTx['transactionId'] as String,
      );
      if (fetchedData != null) {
        completeData = fetchedData;
      } else {
        debugPrint(
          'Failed to fetch complete transaction details, using cached data',
        );
      }
    }

    // Decide which page to open based on type
    Widget page;
    final String type = (completeData['type'] ?? '').toString();
    if (type == 'income') {
      page = AddIncomePage(
        accountName: currentAccountName,
        availableAccounts: allAccountNames,
        initialData: completeData,
      );
    } else if (type == 'expense') {
      // Use existing expense categories
      page = AddExpensePage(
        accountName: currentAccountName,
        availableAccounts: allAccountNames,
        category: (completeData['category'] ?? 'OTHER').toString(),
        availableCategories: _expenseCategories,
        initialData: completeData,
      );
    } else {
      // transfer - determine if current account is sender or receiver
      final bool isCurrentAccountSender = completeData['isExpense'] == true;
      final String actualFromAccount = isCurrentAccountSender
          ? currentAccountName
          : (completeData['fromAccount']?.toString() ?? currentAccountName);

      page = AddTransferPage(
        fromAccountName: actualFromAccount,
        availableAccounts: allAccountNames,
        initialData: completeData,
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      // Ensure type exists in result and sanitize for display
      final String resolvedType = (type.isNotEmpty)
          ? type
          : ((result['type'] ?? '').toString());

      final bool isExpenseForCurrent = completeData['isExpense'] == true;

      // Extract and format core fields
      final dynamic amtDyn = result['amount'];
      final double newRaw = (amtDyn is num)
          ? amtDyn.toDouble()
          : double.tryParse(amtDyn?.toString() ?? '0') ?? 0.0;
      final String displayAmount =
          (isExpenseForCurrent ? '- \$' : '+ \$') + newRaw.toStringAsFixed(2);

      final dynamic dateDyn = result['date'];
      final String displayDate = (dateDyn is DateTime)
          ? "${dateDyn.day}/${dateDyn.month}"
          : (dateDyn?.toString() ?? '');

      // Title prioritization
      String title =
          result['itemName']?.toString() ??
          result['title']?.toString() ??
          'Transaction';
      if (resolvedType == 'transfer' &&
          result['toAccount'] != null &&
          isExpenseForCurrent) {
        // Show direction for sender
        title = "To ${result['toAccount']}";
      }

      // Icon
      IconData icon;
      if (resolvedType == 'expense') {
        icon = getExpenseIcon(result['category']);
      } else if (resolvedType == 'income') {
        icon = getIncomeIcon(result['category']);
      } else {
        icon = Icons.north_east_rounded;
      }

      // Build sanitized display map
      final Map<String, dynamic> sanitized = {
        'type': resolvedType,
        'title': title,
        'date': displayDate,
        'amount': displayAmount,
        'rawAmount': newRaw,
        'isExpense': isExpenseForCurrent,
        'icon': icon,
        'isRecurrent': result['isRecurrent'] ?? false,
        'category': result['category'],
        'transactionId':
            result['transactionId'] ?? completeData['transactionId'],
        'fromAccount': result['fromAccount'] ?? completeData['fromAccount'],
        'toAccount': result['toAccount'] ?? completeData['toAccount'],
        'qty': result['quantity'] ?? completeData['qty'],
        'unitPrice': result['unitPrice'] ?? completeData['unitPrice'],
        'items': result['items'] ?? completeData['items'],
        'description': result['description'] ?? completeData['description'],
      };

      setState(() {
        // 2. Adjust Balance using numeric raw values
        double oldRaw = _parseAmount(completeData);

        // Handle transfer: recalculate balance effects
        if (resolvedType == 'transfer') {
          final String? oldFromAccount = completeData['fromAccount']
              ?.toString();
          final String? oldToAccount = completeData['toAccount']?.toString();
          final String? newFromAccount = result['fromAccount']?.toString();
          final String? newToAccount = result['toAccount']?.toString();

          // Determine if current account was sender or receiver in old transfer
          final bool isCurrentOldSender = completeData['isExpense'] == true;

          // Revert old transfer effects
          if (isCurrentOldSender) {
            // Current account was sender: add back the old amount (undo deduction)
            _myAccounts[_currentCardIndex]['current'] =
                (_myAccounts[_currentCardIndex]['current'] ?? 0.0) + oldRaw;
          } else {
            // Current account was receiver: subtract the old amount (undo addition)
            _myAccounts[_currentCardIndex]['current'] =
                (_myAccounts[_currentCardIndex]['current'] ?? 0.0) - oldRaw;
          }

          // Undo effects on the other account involved in old transfer
          if (isCurrentOldSender && oldToAccount != null) {
            // Was sender, so undo receiver's addition
            final oldReceiverIndex = _myAccounts.indexWhere(
              (acc) => acc['name'] == oldToAccount,
            );
            if (oldReceiverIndex != -1) {
              _myAccounts[oldReceiverIndex]['current'] =
                  (_myAccounts[oldReceiverIndex]['current'] ?? 0.0) - oldRaw;
            }
          } else if (!isCurrentOldSender && oldFromAccount != null) {
            // Was receiver, so undo sender's deduction
            final oldSenderIndex = _myAccounts.indexWhere(
              (acc) => acc['name'] == oldFromAccount,
            );
            if (oldSenderIndex != -1) {
              _myAccounts[oldSenderIndex]['current'] =
                  (_myAccounts[oldSenderIndex]['current'] ?? 0.0) + oldRaw;
            }
          }

          // Apply new transfer effects
          // Find sender and receiver accounts
          int? newSenderIndex;
          int? newReceiverIndex;

          if (newFromAccount != null) {
            newSenderIndex = _myAccounts.indexWhere(
              (acc) => acc['name'] == newFromAccount,
            );
          }

          if (newToAccount != null) {
            newReceiverIndex = _myAccounts.indexWhere(
              (acc) => acc['name'] == newToAccount,
            );
          }

          // Deduct from sender
          if (newSenderIndex != null && newSenderIndex != -1) {
            _myAccounts[newSenderIndex]['current'] =
                (_myAccounts[newSenderIndex]['current'] ?? 0.0) - newRaw;

            // Update or add new transfer to sender's transaction list (if sender is not current account)
            if (newSenderIndex != _currentCardIndex) {
              final senderTxIndex = _allTransactions[newSenderIndex].indexWhere(
                (tx) => tx['transactionId'] == sanitized['transactionId'],
              );
              final newSenderTx = {
                'transactionId': sanitized['transactionId'],
                'type': 'transfer',
                'title': 'To ${newToAccount ?? 'Unknown'}',
                'date': sanitized['date'],
                'amount': '- \$${newRaw.toStringAsFixed(2)}',
                'rawAmount': newRaw,
                'isExpense': true,
                'icon': Icons.north_west_rounded,
                'category': 'TRANSFER',
                'fromAccount': newFromAccount,
                'toAccount': newToAccount,
              };
              if (senderTxIndex != -1) {
                // Update existing transaction
                _allTransactions[newSenderIndex][senderTxIndex] = newSenderTx;
              } else {
                // Add new transaction if it doesn't exist
                _allTransactions[newSenderIndex].add(newSenderTx);
              }
            } else {
              // Current account is the sender: update transaction with sender perspective
              final index = _allTransactions[_currentCardIndex].indexWhere(
                (item) =>
                    item['transactionId'] == completeData['transactionId'],
              );
              if (index != -1) {
                _allTransactions[_currentCardIndex][index] = {
                  ...sanitized,
                  'title': 'To ${newToAccount ?? 'Unknown'}',
                  'amount': '- \$${newRaw.toStringAsFixed(2)}',
                  'rawAmount': newRaw,
                  'isExpense': true,
                };
              }
            }
          }

          // Add to receiver
          if (newReceiverIndex != null && newReceiverIndex != -1) {
            _myAccounts[newReceiverIndex]['current'] =
                (_myAccounts[newReceiverIndex]['current'] ?? 0.0) + newRaw;

            // Update or add new transfer to receiver's transaction list
            if (newReceiverIndex != _currentCardIndex) {
              final receiverTxIndex = _allTransactions[newReceiverIndex]
                  .indexWhere(
                    (tx) => tx['transactionId'] == sanitized['transactionId'],
                  );
              final newReceiverTx = {
                'transactionId': sanitized['transactionId'],
                'type': 'transfer',
                'title': 'From ${newFromAccount ?? 'Unknown'}',
                'date': sanitized['date'],
                'amount': '+ \$${newRaw.toStringAsFixed(2)}',
                'rawAmount': newRaw,
                'isExpense': false,
                'icon': Icons.south_east_rounded,
                'category': 'TRANSFER',
                'fromAccount': newFromAccount,
                'toAccount': newToAccount,
              };
              if (receiverTxIndex != -1) {
                // Update existing transaction
                _allTransactions[newReceiverIndex][receiverTxIndex] =
                    newReceiverTx;
              } else {
                // Add new transaction if it doesn't exist
                _allTransactions[newReceiverIndex].add(newReceiverTx);
              }
            } else {
              // Current account is the receiver: update transaction with receiver perspective
              final index = _allTransactions[_currentCardIndex].indexWhere(
                (item) =>
                    item['transactionId'] == completeData['transactionId'],
              );
              if (index != -1) {
                _allTransactions[_currentCardIndex][index] = {
                  ...sanitized,
                  'title': 'From ${newFromAccount ?? 'Unknown'}',
                  'amount': '+ \$${newRaw.toStringAsFixed(2)}',
                  'rawAmount': newRaw,
                  'isExpense': false,
                };
              }
            }
          }
        } else {
          // Non-transfer transactions
          if (isExpenseForCurrent) {
            _myAccounts[_currentCardIndex]['current'] += oldRaw;
            _myAccounts[_currentCardIndex]['current'] -= newRaw;
          } else {
            _myAccounts[_currentCardIndex]['current'] -= oldRaw;
            _myAccounts[_currentCardIndex]['current'] += newRaw;
          }
        }
      });

      // Update caches to persist changes
      CacheService.save('accounts', _myAccounts);
      CacheService.save('transactions', _getSanitizedTransactions());

      try {
        await _persistEditedTransaction(
          sanitized: sanitized,
          oldTx: completeData,
          isExpenseForCurrent: isExpenseForCurrent,
          isTransferType: resolvedType == 'transfer',
          newRawAmount: newRaw,
        );

        // Reload account balances from database for transfers to sync with trigger updates
        if (resolvedType == 'transfer') {
          List<Account> refreshedAccounts = [];
          final userId = supabase.auth.currentUser?.id;
          if (userId != null) {
            refreshedAccounts = await _getAccounts(userId);
          }
          final Map<String?, Account> accountLookup = {
            for (final acc in refreshedAccounts) acc.id: acc,
          };

          if (mounted) {
            setState(() {
              // Update all account balances from database
              for (int i = 0; i < _myAccounts.length; i++) {
                final accId = _myAccounts[i]['id'];
                final updated = accountLookup[accId];
                if (updated != null) {
                  _myAccounts[i]['current'] = updated.currentBalance;
                }
              }
            });

            // Update caches again with refreshed balances
            CacheService.save('accounts', _myAccounts);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transaction updated successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Backend update failed: $e")));
        }
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

      final savedTransaction = await _upsertTransaction(transactionRecord);
      final String? transactionId = savedTransaction.id;

      if (transactionId == null || transactionId.isEmpty) {
        throw Exception('Transaction saved but ID is null or empty');
      }

      // Validate amount
      final amount = result['amount'];
      if (amount == null) {
        throw Exception('Amount is required');
      }

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
          } catch (e) {
            debugPrint('Error fetching expense category ID: $e');
          }
        }

        final expense = Expense(
          transactionId: transactionId,
          amount: amount as double,
          expenseCategoryId: categoryId,
        );
        await _upsertExpense(expense);

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

        final income = Income(
          transactionId: transactionId,
          amount: amount as double,
          category: category
              ?.toUpperCase(), // Ensure uppercase for database constraint
          isRecurrent: result['isRecurrent'] ?? false,
        );
        await _upsertIncome(income);
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
      CacheService.save('transactions', _getSanitizedTransactions());
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

  Future<void> _persistEditedTransaction({
    required Map<String, dynamic> sanitized,
    required Map<String, dynamic> oldTx,
    required bool isExpenseForCurrent,
    required bool isTransferType,
    required double newRawAmount,
  }) async {
    final currentAccount = _myAccounts[_currentCardIndex];

    final String? transactionId =
        sanitized['transactionId']?.toString() ?? oldTx['transactionId'];
    if (transactionId == null || transactionId.isEmpty) {
      throw Exception('Missing transactionId for update');
    }

    // For transfers, determine the actual sender account
    String transactionAccountId;
    if (isTransferType) {
      final String? fromAccountName =
          sanitized['fromAccount']?.toString() ??
          oldTx['fromAccount']?.toString();
      if (fromAccountName != null) {
        final fromAccount = _myAccounts.firstWhere(
          (acc) => acc['name'] == fromAccountName,
          orElse: () => currentAccount,
        );
        final resolvedFrom = await _resolveAccountIdentifiers(
          account: fromAccount,
          fallbackName: fromAccountName,
        );
        transactionAccountId = resolvedFrom['id'];
      } else {
        final resolvedCurrent = await _resolveAccountIdentifiers(
          account: currentAccount,
        );
        transactionAccountId = resolvedCurrent['id'];
      }
    } else {
      final resolvedCurrent = await _resolveAccountIdentifiers(
        account: currentAccount,
      );
      transactionAccountId = resolvedCurrent['id'];
    }

    final transactionRecord = TransactionRecord(
      id: transactionId,
      accountId: transactionAccountId,
      name: sanitized['title']?.toString() ?? 'Transaction',
      type: isTransferType ? 'T' : (isExpenseForCurrent ? 'E' : 'I'),
      description: sanitized['description']?.toString(),
      currency: 'MYR',
    );

    await _upsertTransaction(transactionRecord);

    if (isTransferType) {
      final String? fromAccountName =
          sanitized['fromAccount']?.toString() ??
          oldTx['fromAccount']?.toString();
      final String? toAccountName =
          sanitized['toAccount']?.toString() ?? oldTx['toAccount']?.toString();

      if (fromAccountName != null && toAccountName != null) {
        final fromAccount = _myAccounts.firstWhere(
          (acc) => acc['name'] == fromAccountName,
          orElse: () => {},
        );
        final toAccount = _myAccounts.firstWhere(
          (acc) => acc['name'] == toAccountName,
          orElse: () => {},
        );

        if (fromAccount.isNotEmpty && toAccount.isNotEmpty) {
          final resolvedFrom = await _resolveAccountIdentifiers(
            account: fromAccount,
            fallbackName: fromAccountName,
          );
          final resolvedTo = await _resolveAccountIdentifiers(
            account: toAccount,
            fallbackName: toAccountName,
          );
          final transfer = Transfer(
            transactionId: transactionId,
            amount: newRawAmount,
            fromAccountId: resolvedFrom['id'],
            toAccountId: resolvedTo['id'],
          );
          await _upsertTransfer(transfer);
        }
      }
    } else if (isExpenseForCurrent) {
      String? categoryId;
      final String? categoryName = sanitized['category']?.toString();
      if (categoryName != null && categoryName.isNotEmpty) {
        try {
          final categoryData = await _databaseService.fetchSingle(
            'expense_category',
            matchColumn: 'name',
            matchValue: categoryName.toUpperCase(),
          );
          categoryId = categoryData?['expense_cat_id'] as String?;
        } catch (e) {
          debugPrint('Error fetching expense category ID during update: $e');
        }
      }

      final expense = Expense(
        transactionId: transactionId,
        amount: newRawAmount,
        expenseCategoryId: categoryId,
      );
      await _upsertExpense(expense);

      // Delete existing expense items before inserting new ones
      try {
        await _databaseService.deleteById(
          'expense_items',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );
      } catch (e) {
        debugPrint('Error deleting old expense items: $e');
      }

      final items = sanitized['items'];
      if (items is List) {
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final qty = int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
          final unitPrice =
              double.tryParse(item['unitPrice']?.toString() ?? '0') ?? 0.0;
          final expenseItem = ExpenseItem(
            transactionId: transactionId,
            itemId: i + 1,
            itemName: item['name']?.toString() ?? '',
            quantity: qty,
            unitPrice: unitPrice,
            price: qty * unitPrice,
          );
          await _upsertExpenseItem(expenseItem);
        }
      }
    } else {
      final income = Income(
        transactionId: transactionId,
        amount: newRawAmount,
        category: sanitized['category']?.toString().toUpperCase(),
        isRecurrent: sanitized['isRecurrent'] == true,
      );
      await _upsertIncome(income);
    }

    // For non-transfer transactions, persist updated balance for current account
    if (!isTransferType) {
      final resolvedCurrent = await _resolveAccountIdentifiers(
        account: currentAccount,
      );
      final updatedCurrentAccount = Account(
        id: resolvedCurrent['id'],
        userId: resolvedCurrent['user_id'],
        name: currentAccount['name'],
        type: currentAccount['type'],
        initialBalance: (currentAccount['initial'] ?? 0.0).toDouble(),
        currentBalance: _myAccounts[_currentCardIndex]['current'].toDouble(),
        description: currentAccount['description'] ?? currentAccount['desc'],
      );
      await _upsertAccount(updatedCurrentAccount);
    }
    // For transfer transactions, DON'T manually update account balances
    // The database triggers will handle all balance adjustments automatically
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

  bool _isTransferCounterpartDeleted(Map<String, dynamic> tx) {
    final String type = (tx['type'] ?? '').toString();
    if (type != 'transfer') return false;
    final String? toName = tx['toAccount']?.toString();
    final String? fromName = tx['fromAccount']?.toString();
    return toName == 'Deleted account' || fromName == 'Deleted account';
  }

  void _showTransactionActionSheet(Map<String, dynamic> tx) {
    // Determine transaction type for labels
    final String transactionType = StringCaseFormatter.toTitleCase(
      (tx['type'] ?? 'Transaction').toString(),
    );
    final bool disableEdit = _isTransferCounterpartDeleted(tx);

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
                title: Text("Edit $transactionType"),
                enabled: !disableEdit,
                onTap: disableEdit
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _editTransaction(tx);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text("Delete $transactionType"),
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
                          CacheService.save(
                            'transactions',
                            _getSanitizedTransactions(),
                          );

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

                              // Calculate the delta for initial balance change
                              final oldInitialBalance =
                                  (account['initial'] is num)
                                  ? (account['initial'] as num).toDouble()
                                  : double.tryParse(
                                          account['initial']?.toString() ?? '0',
                                        ) ??
                                        0;
                              final newInitialBalance =
                                  double.tryParse(
                                    initialController.text.trim(),
                                  ) ??
                                  0;
                              final initialBalanceDelta =
                                  newInitialBalance - oldInitialBalance;

                              // Calculate the current balance
                              final oldCurrentBalance =
                                  (account['current'] is num)
                                  ? (account['current'] as num).toDouble()
                                  : double.tryParse(
                                          account['current']?.toString() ?? '0',
                                        ) ??
                                        0;
                              final newCurrentBalance =
                                  oldCurrentBalance + initialBalanceDelta;

                              final updated = Account(
                                id: account['id']?.toString(),
                                userId: userId,
                                name: nameController.text.trim(),
                                type: type,
                                initialBalance: newInitialBalance,
                                currentBalance: newCurrentBalance,
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
        CacheService.save('transactions', _getSanitizedTransactions());
      }

      // After deleting the account, remove any orphan transfer transactions
      // where either FROM_ACCOUNT_ID or TO_ACCOUNT_ID is already NULL.
      await _cleanupOrphanTransfers();

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

  Future<void> _cleanupOrphanTransfers() async {
    try {
      final List<dynamic> orphanRows = await supabase
          .from('transfer')
          .select('transaction_id')
          .or('from_account_id.is.null,to_account_id.is.null');

      final List<String> orphanTxIds = orphanRows
          .map((e) => e['transaction_id']?.toString())
          .whereType<String>()
          .toList();

      if (orphanTxIds.isEmpty) return;

      // Delete each orphan transaction (TRANSFER will cascade by PK)
      for (final txId in orphanTxIds) {
        await _databaseService.deleteById(
          'transaction',
          matchColumn: 'transaction_id',
          matchValue: txId,
        );
      }

      // Remove from local state lists
      setState(() {
        for (final txList in _allTransactions) {
          txList.removeWhere(
            (tx) => orphanTxIds.contains(tx['transactionId']?.toString()),
          );
        }
      });
      CacheService.save('transactions', _getSanitizedTransactions());
    } catch (e) {
      debugPrint('Failed to cleanup orphan transfers: $e');
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
                            displayTransactions.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(22),
                                    child: Center(
                                      child: Text("No record found"),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                    ),
                                    itemCount: displayTransactions.length,
                                    itemBuilder: (context, index) {
                                      final tx = displayTransactions[index];
                                      // HITTEST BEHAVIOR OPAQUE is key for clickable whitespace
                                      return GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () =>
                                            _showTransactionActionSheet(tx),
                                        child: _TransactionTile(
                                          title: tx['title'] ?? 'N/A',
                                          subtitle: tx['date'] ?? 'N/A',
                                          amount: tx['amount'] ?? '\$0.00',
                                          icon: tx['icon'] ?? Icons.error,
                                          isExpense: tx['isExpense'] ?? false,
                                          isRecurrent:
                                              tx['isRecurrent'] ?? false,
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
