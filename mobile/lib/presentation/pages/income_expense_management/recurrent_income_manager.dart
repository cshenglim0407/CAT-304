import 'package:flutter/material.dart';

import 'package:cashlytics/core/services/cache/cache_service.dart';
import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/core/utils/income_expense_management/income_expense_helpers.dart';
import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/data/repositories/account_repository_impl.dart';
import 'package:cashlytics/data/repositories/income_repository_impl.dart';
import 'package:cashlytics/data/repositories/transaction_repository_impl.dart';
import 'package:cashlytics/domain/entities/income.dart';
import 'package:cashlytics/domain/entities/transaction_record.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';
import 'package:cashlytics/domain/repositories/income_repository.dart';
import 'package:cashlytics/domain/repositories/transaction_repository.dart';
import 'package:cashlytics/domain/usecases/accounts/get_accounts.dart';
import 'package:cashlytics/domain/usecases/income/upsert_income.dart';
import 'package:cashlytics/domain/usecases/transactions/upsert_transaction.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class RecurrentIncomeManagerPage extends StatefulWidget {
  const RecurrentIncomeManagerPage({super.key});

  @override
  State<RecurrentIncomeManagerPage> createState() =>
      _RecurrentIncomeManagerPageState();
}

class _RecurrentIncomeManagerPageState
    extends State<RecurrentIncomeManagerPage> {
  final DatabaseService _databaseService = const DatabaseService();

  late final AccountRepository _accountRepository;
  late final GetAccounts _getAccounts;
  late final TransactionRepository _transactionRepository;
  late final UpsertTransaction _upsertTransaction;
  late final IncomeRepository _incomeRepository;
  late final UpsertIncome _upsertIncome;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<_RecurrentIncomeItem> _incomes = [];
  Map<String, bool> _initialStates = {};
  final Map<String, bool> _pendingChanges = {};

  @override
  void initState() {
    super.initState();
    _accountRepository = AccountRepositoryImpl(
      databaseService: _databaseService,
    );
    _getAccounts = GetAccounts(_accountRepository);

    _transactionRepository = TransactionRepositoryImpl(
      databaseService: _databaseService,
    );
    _upsertTransaction = UpsertTransaction(_transactionRepository);

    _incomeRepository = IncomeRepositoryImpl(databaseService: _databaseService);
    _upsertIncome = UpsertIncome(_incomeRepository);

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Please sign in to manage recurrent income.';
          _incomes = [];
          _initialStates = {};
          _pendingChanges.clear();
          _isLoading = false;
        });
        return;
      }

      final accounts = await _getAccounts(userId);
      final Map<String, String> accountNames = {
        for (final acc in accounts)
          if (acc.id != null) acc.id!: acc.name,
      };

      final List<_RecurrentIncomeItem> incomeRows = [];

      for (final account in accounts) {
        if (account.id == null) continue;
        final transactions = await _databaseService.fetchAll(
          'transaction',
          filters: {'account_id': account.id, 'type': 'I'},
          orderBy: 'created_at',
          ascending: false,
        );

        for (final tx in transactions) {
          final String transactionId = (tx['transaction_id'] as String?) ?? '';
          if (transactionId.isEmpty) continue;

          final incomeData = await _databaseService.fetchSingle(
            'income',
            matchColumn: 'transaction_id',
            matchValue: transactionId,
          );
          if (incomeData == null) continue;

          final double amount = IncomeExpenseHelpers.parseAmount(
            incomeData['amount'],
          );
          final bool isRecurrent = incomeData['is_recurrent'] as bool? ?? false;
          final DateTime createdAt =
              DateTime.tryParse(tx['created_at']?.toString() ?? '') ??
              DateTime.now();
          final String? description =
              (tx['description'] as String?) ??
              (incomeData['description'] as String?);

          incomeRows.add(
            _RecurrentIncomeItem(
              transactionId: transactionId,
              accountId: account.id!,
              accountName: accountNames[account.id] ?? 'Account',
              title: (tx['name'] as String?)?.trim().isNotEmpty == true
                  ? tx['name'] as String
                  : 'Income',
              description: description,
              amount: amount,
              category: incomeData['category'] as String?,
              isRecurrent: isRecurrent,
              createdAt: createdAt,
            ),
          );
        }
      }

      incomeRows.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _incomes = incomeRows;
        _initialStates = {
          for (final item in incomeRows) item.transactionId: item.isRecurrent,
        };
        _pendingChanges.clear();
        _isLoading = false;
      });

      await _maybePromptMonthlyAdditions();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load recurrent incomes. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _maybePromptMonthlyAdditions() async {
    if (!mounted) return;
    final now = DateTime.now();
    if (now.day != 1) return;

    final active = _incomes.where((i) => i.isRecurrent).toList();
    if (active.isEmpty) return;

    final cacheKey = 'recurrent_income_prompt_${now.year}_${now.month}';
    if (CacheService.load<bool>(cacheKey) == true) return;

    await Future.delayed(const Duration(milliseconds: 250));

    final bool? accept = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                Text(
                  'Monthly reminder',
                  style: AppTypography.headline3.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'It\'s the first day of the month. Do you want to add your recurrent incomes now?',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.greyLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: active.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = active[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.repeat,
                          color: AppColors.primary,
                        ),
                        title: Text(item.title, style: AppTypography.bodyLarge),
                        subtitle: Text(
                          '${item.accountName} • ${MathFormatter.formatCurrency(item.amount)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Maybe later'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Add now'),
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    await CacheService.save(cacheKey, true);

    if (accept == true) {
      await _addRecurringIncomes(active);
    }
  }

  Future<void> _addRecurringIncomes(List<_RecurrentIncomeItem> items) async {
    if (items.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      for (final item in items) {
        final txRecord = TransactionRecord(
          id: null,
          accountId: item.accountId,
          name: item.title,
          type: 'I',
          description: item.description,
          currency: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final savedTx = await _upsertTransaction(txRecord);

        final txId = savedTx.id ?? '';
        if (txId.isEmpty) continue;

        final income = Income(
          transactionId: txId,
          amount: item.amount,
          category: item.category?.toUpperCase(),
          isRecurrent: true,
        );
        await _upsertIncome(income);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recurrent incomes added for this month')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add recurrent incomes: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _persistToggleChanges() async {
    if (_pendingChanges.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      for (final entry in _pendingChanges.entries) {
        await _databaseService.updateById(
          'income',
          matchColumn: 'transaction_id',
          matchValue: entry.key,
          values: {'is_recurrent': entry.value},
        );
      }
      // Update initialStates to reflect newly saved values
      for (final entry in _pendingChanges.entries) {
        _initialStates[entry.key] = entry.value;
      }
      _pendingChanges.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recurring settings saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleRecurrent(String transactionId, bool value) {
    setState(() {
      final idx = _incomes.indexWhere(
        (element) => element.transactionId == transactionId,
      );
      if (idx != -1) {
        final item = _incomes[idx];
        _incomes[idx] = item.copyWith(isRecurrent: value);
      }

      final initial = _initialStates[transactionId];
      if (initial == null || initial == value) {
        _pendingChanges.remove(transactionId);
      } else {
        _pendingChanges[transactionId] = value;
      }
    });
  }

  String _formatAmount(double amount) {
    return '+ ${MathFormatter.formatCurrency(amount)}';
  }

  Future<bool> _onWillPop() async {
    await _persistToggleChanges();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recurrent Income'),
          actions: [
            if (_pendingChanges.isNotEmpty)
              TextButton(
                onPressed: _isSaving ? null : _persistToggleChanges,
                child: const Text('Save'),
              ),
          ],
        ),
        backgroundColor: AppColors.getSurface(context),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: _errorMessage != null
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _incomes.isEmpty
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No incomes found',
                                  style: AppTypography.headline3.copyWith(
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create or mark an income as recurrent to see it here.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: _incomes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _incomes[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: AppTypography.labelLarge
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppColors.getTextPrimary(
                                                        context,
                                                      ),
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.accountName} • ${_formatAmount(item.amount)}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color:
                                                      AppColors.getTextSecondary(
                                                        context,
                                                      ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Switch(
                                          value: item.isRecurrent,
                                          onChanged: (val) => _toggleRecurrent(
                                            item.transactionId,
                                            val,
                                          ),
                                          activeColor: AppColors.primary,
                                        ),
                                        Text(
                                          item.isRecurrent ? 'On' : 'Off',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: item.isRecurrent
                                                    ? AppColors.primary
                                                    : AppColors.getTextSecondary(
                                                        context,
                                                      ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (item.description != null &&
                                    item.description!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    item.description!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.getTextSecondary(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.category?.toUpperCase() ?? 'INCOME',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.getTextSecondary(
                                          context,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Created on ${IncomeExpenseHelpers.formatTransactionDate(item.createdAt)}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.getTextSecondary(
                                          context,
                                        ),
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
        bottomNavigationBar: _isSaving
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
    );
  }
}

class _RecurrentIncomeItem {
  const _RecurrentIncomeItem({
    required this.transactionId,
    required this.accountId,
    required this.accountName,
    required this.title,
    required this.amount,
    required this.isRecurrent,
    required this.createdAt,
    this.category,
    this.description,
  });

  final String transactionId;
  final String accountId;
  final String accountName;
  final String title;
  final double amount;
  final bool isRecurrent;
  final DateTime createdAt;
  final String? category;
  final String? description;

  _RecurrentIncomeItem copyWith({bool? isRecurrent}) {
    return _RecurrentIncomeItem(
      transactionId: transactionId,
      accountId: accountId,
      accountName: accountName,
      title: title,
      amount: amount,
      isRecurrent: isRecurrent ?? this.isRecurrent,
      createdAt: createdAt,
      category: category,
      description: description,
    );
  }
}
