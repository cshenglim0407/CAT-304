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

  // Computed property for the header summary
  double get _totalRecurrentAmount {
    return _incomes
        .where((item) => item.isRecurrent)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

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

  // Re-inserting the prompt logic for context:
  Future<void> _maybePromptMonthlyAdditions() async {
    if (!mounted) return;
    final now = DateTime.now();

    // --- DO NOT DELETE: DISABLE LINE BELOW TO TEST PROMPT EVERY TIME
    if (now.day != 1) return;
    // --- END DO NOT DELETE

    final active = _incomes.where((i) => i.isRecurrent).toList();
    if (active.isEmpty) return;

    // --- DO NOT DELETE: ENABLE LINE BELOW TO TEST PROMPT EVERY TIME
    // final cacheKey =
    //     'recurrent_income_prompt_${now.year}_${now.month}_${now.day}_${now.hour}_${now.minute}';
    // --- END DO NOT DELETE
    // --- DISABLE LINE BELOW TO TEST PROMPT EVERY TIME
    final cacheKey = 'recurrent_income_prompt_${now.year}_${now.month}';
    // --- END DISABLE

    if (CacheService.load<bool>(cacheKey) == true) return;

    final addedThisMonthKey =
        'recurrent_incomes_added_${now.year}_${now.month}';
    final addedIds = CacheService.load<List<dynamic>>(addedThisMonthKey) ?? [];
    final addedIdSet = addedIds.cast<String>().toSet();
    final toAdd = active
        .where((i) => !addedIdSet.contains(i.transactionId))
        .toList();
    if (toAdd.isEmpty) return;

    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    final bool? accept = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Transparent for custom styling
      builder: (ctx) => _MonthlyPromptSheet(toAdd: toAdd),
    );

    await CacheService.save(cacheKey, true);

    if (accept == true) {
      await _addRecurringIncomes(toAdd);
    }
  }

  Future<void> _addRecurringIncomes(List<_RecurrentIncomeItem> items) async {
    // ... [Same implementation as original code] ...
    if (items.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final addedThisMonthKey =
          'recurrent_incomes_added_${now.year}_${now.month}';
      final addedIds =
          CacheService.load<List<dynamic>>(addedThisMonthKey) ?? [];
      final addedIdList = addedIds.cast<String>().toList();

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

        await _databaseService.updateById(
          'income',
          matchColumn: 'transaction_id',
          matchValue: item.transactionId,
          values: {'is_recurrent': false},
        );

        addedIdList.add(item.transactionId);
      }

      await CacheService.save(addedThisMonthKey, addedIdList);

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
      for (final entry in _pendingChanges.entries) {
        _initialStates[entry.key] = entry.value;
      }
      _pendingChanges.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recurring settings saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _persistToggleChanges();
      },
      child: Scaffold(
        backgroundColor: AppColors.getSurface(context),
        appBar: AppBar(
          title: const Text('Recurrent Income'),
          centerTitle: true,
          backgroundColor: AppColors.getSurface(context),
          elevation: 0,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (!_isLoading && _incomes.isNotEmpty)
                  _SummaryHeader(totalAmount: _totalRecurrentAmount),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: _errorMessage != null
                              ? _ErrorView(message: _errorMessage!)
                              : _incomes.isEmpty
                              ? const _EmptyStateView()
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    10,
                                    20,
                                    100,
                                  ), // Bottom padding for FAB
                                  itemCount: _incomes.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = _incomes[index];
                                    return _RecurrentIncomeCard(
                                      item: item,
                                      onToggle: (val) => _toggleRecurrent(
                                        item.transactionId,
                                        val,
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),

            // Floating Save Button
            if (_pendingChanges.isNotEmpty)
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: _SaveChangesButton(
                    count: _pendingChanges.length,
                    isSaving: _isSaving,
                    onPressed: _persistToggleChanges,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class _SummaryHeader extends StatelessWidget {
  final double totalAmount;

  const _SummaryHeader({required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        border: Border(
          bottom: BorderSide(color: AppColors.greyLight.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Total Monthly Recurring',
            style: AppTypography.bodyLarge.copyWith(
              // Changed from bodySmall
              color: AppColors.getTextPrimary(
                context,
              ), // Changed from Secondary to Primary (Darker)
              fontWeight: FontWeight.w600, // Added weight
            ),
          ),
          const SizedBox(height: 8), // Increased spacing
          Text(
            MathFormatter.formatCurrency(totalAmount),
            style: AppTypography.headline1.copyWith(
              color: AppColors.primary,
              fontSize: 32, // Forced larger size
              fontWeight: FontWeight.w800, // Extra bold
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurrentIncomeCard extends StatelessWidget {
  final _RecurrentIncomeItem item;
  final ValueChanged<bool> onToggle;

  const _RecurrentIncomeCard({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: item.isRecurrent
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ), // More padding
          leading: Container(
            padding: const EdgeInsets.all(12), // Larger icon area
            decoration: BoxDecoration(
              color: item.isRecurrent
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.greyLight.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(item.category),
              // Use standard grey if AppColors.grey is missing
              color: item.isRecurrent ? AppColors.primary : Colors.grey[700],
              size: 24, // Larger icon
            ),
          ),
          title: Text(
            item.title,
            style: AppTypography.headline3.copyWith(
              // Much larger title
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(context), // Darkest black
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                item.accountName,
                style: AppTypography.bodyMedium.copyWith(
                  // Larger subtitle
                  color: Colors.black87, // Darker grey
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MathFormatter.formatCurrency(item.amount),
                style: AppTypography.bodyLarge.copyWith(
                  // Larger amount
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: item.isRecurrent
                      ? const Color(0xFF2E7D32)
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 24,
                width: 40,
                child: Switch(
                  value: item.isRecurrent,
                  onChanged: onToggle,
                  activeThumbColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey[300]), // Visible divider
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Category',
                    value: item.category?.toUpperCase() ?? 'INCOME',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Date Added',
                    value: IncomeExpenseHelpers.formatTransactionDate(
                      item.createdAt,
                    ),
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Note', value: item.description!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'salary':
        return Icons.work_outline;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      case 'rental':
        return Icons.home_work_outlined;
      case 'business':
        return Icons.storefront;
      default:
        return Icons.attach_money;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.getTextSecondary(context),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SaveChangesButton extends StatelessWidget {
  final int count;
  final bool isSaving;
  final VoidCallback onPressed;

  const _SaveChangesButton({
    required this.count,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: AppColors.primary,
      child: InkWell(
        onTap: isSaving ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count change${count > 1 ? 's' : ''} pending',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                Row(
                  children: [
                    Text(
                      'Apply',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.check, color: Colors.white, size: 20),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.update, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'No Recurring Incomes',
            style: AppTypography.headline3.copyWith(
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Incomes marked as recurrent will appear here to help you track monthly cash flow.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyPromptSheet extends StatelessWidget {
  final List<_RecurrentIncomeItem> toAdd;

  const _MonthlyPromptSheet({required this.toAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
              Icon(
                Icons.calendar_month,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'New Month, New Income',
                style: AppTypography.headline3.copyWith(
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Would you like to add these recurring incomes to your transactions for this month?',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greyLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: toAdd.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = toAdd[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        item.title,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Text(
                        MathFormatter.formatCurrency(item.amount),
                        style: AppTypography.bodyMedium,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: AppColors.getTextSecondary(context),
                      ),
                      child: const Text('Maybe Later'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add All'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MODELS
// -----------------------------------------------------------------------------

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
