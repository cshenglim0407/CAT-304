import 'package:flutter/material.dart';
import 'package:cashlytics/core/config/icons.dart';
import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/repositories/account_budget_repository_impl.dart';
import 'package:cashlytics/data/repositories/account_repository_impl.dart';
import 'package:cashlytics/data/repositories/budget_repository_impl.dart';
import 'package:cashlytics/data/repositories/category_budget_repository_impl.dart';
import 'package:cashlytics/data/repositories/user_budget_repository_impl.dart';
import 'package:cashlytics/domain/entities/account_budget.dart';
import 'package:cashlytics/domain/entities/budget.dart';
import 'package:cashlytics/domain/entities/category_budget.dart';
import 'package:cashlytics/domain/entities/user_budget.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';
import 'package:cashlytics/domain/usecases/account_budgets/upsert_account_budget.dart';
import 'package:cashlytics/domain/usecases/accounts/get_accounts.dart';
import 'package:cashlytics/domain/usecases/budgets/upsert_budget.dart';
import 'package:cashlytics/domain/usecases/category_budgets/upsert_category_budget.dart';
import 'package:cashlytics/domain/usecases/user_budgets/upsert_user_budget.dart';
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
  final DatabaseService _databaseService = const DatabaseService();

  // State
  BudgetType _selectedType = BudgetType.user;
  final TextEditingController _amountController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  bool _isLoading = true;
  bool _isSaving = false;

  // Selection IDs
  String? _selectedCategoryId;
  String? _selectedAccountId;

  // --- Category Data ---
  List<Map<String, dynamic>> _categories = [];

  // --- Account Data ---
  List<Map<String, dynamic>> _accounts = [];

  late final AccountRepository _accountRepository;
  late final GetAccounts _getAccounts;
  late final UpsertBudget _upsertBudget;
  late final UpsertUserBudget _upsertUserBudget;
  late final UpsertCategoryBudget _upsertCategoryBudget;
  late final UpsertAccountBudget _upsertAccountBudget;

  @override
  void initState() {
    super.initState();
    _accountRepository = AccountRepositoryImpl();
    _getAccounts = GetAccounts(_accountRepository);
    _upsertBudget = UpsertBudget(BudgetRepositoryImpl());
    _upsertUserBudget = UpsertUserBudget(UserBudgetRepositoryImpl());
    _upsertCategoryBudget = UpsertCategoryBudget(
      CategoryBudgetRepositoryImpl(),
    );
    _upsertAccountBudget = UpsertAccountBudget(AccountBudgetRepositoryImpl());

    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    _loadLookups();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() => _isLoading = true);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final categoryRows = await _databaseService.fetchAll(
        'expense_category',
        orderBy: 'name',
        ascending: true,
      );
      final accountRows = await _getAccounts(userId);

      final categories = categoryRows
          .map((row) {
            final name = (row['name'] as String? ?? '').trim();
            return {
              'id': row['expense_cat_id'] as String?,
              'name': name,
              'icon': getExpenseIcon(name.toUpperCase()),
            };
          })
          .where((item) => item['id'] != null)
          .toList();

      final accounts = accountRows.where((acc) => acc.id != null).map((acc) {
        return {
          'id': acc.id,
          'name': acc.name,
          'type': acc.type,
          'icon': getAccountTypeIcon(acc.type),
        };
      }).toList();

      setState(() {
        _categories = categories;
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading budget lookups: $e');
      setState(() => _isLoading = false);
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _rangesOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return !aEnd.isBefore(bStart) && !bEnd.isBefore(aStart);
  }

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

  Future<double> _sumChildBudgetsForRange(
    List<Map<String, dynamic>> budgets,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final matching = budgets.where((b) {
      final type = b['type'] as String?;
      if (type != 'C' && type != 'A') return false;
      final start = _parseDate(b['date_from']);
      final end = _parseDate(b['date_to']);
      return _rangesOverlap(rangeStart, rangeEnd, start, end);
    }).toList();

    if (matching.isEmpty) return 0;

    final ids = matching.map((b) => b['budget_id']).toList();
    final categoryRows = await _databaseService.fetchAll(
      'category_budget',
      filters: {'budget_id': ids},
    );
    final accountRows = await _databaseService.fetchAll(
      'account_budget',
      filters: {'budget_id': ids},
    );

    double total = 0;
    for (final row in categoryRows) {
      total += _parseDouble(row['threshold']);
    }
    for (final row in accountRows) {
      total += _parseDouble(row['threshold']);
    }
    return total;
  }

  String _formatDate(DateTime date, {bool showYear = false}) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
    if (_isSaving) return;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid amount format")));
      return;
    }

    if (_selectedType == BudgetType.category && _selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a category")));
      return;
    }

    if (_selectedType == BudgetType.account && _selectedAccountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select an account")));
      return;
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not signed in")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final rangeStart = _dateOnly(_selectedDateRange!.start);
      final rangeEnd = _dateOnly(_selectedDateRange!.end);

      final budgets = await _databaseService.fetchAll(
        'budget',
        filters: {'user_id': userId},
      );

      final overlapping = budgets.where((b) {
        final start = _parseDate(b['date_from']);
        final end = _parseDate(b['date_to']);
        return _rangesOverlap(rangeStart, rangeEnd, start, end);
      }).toList();

      Map<String, dynamic>? overallBudget;
      double? overallThreshold;
      if (overlapping.isNotEmpty) {
        final overallBudgets = overlapping
            .where((b) => b['type'] == 'U')
            .toList();
        if (overallBudgets.isNotEmpty) {
          overallBudgets.sort((a, b) {
            final aDate = _parseDate(a['created_at']);
            final bDate = _parseDate(b['created_at']);
            return bDate.compareTo(aDate);
          });
          overallBudget = overallBudgets.first;

          final overallId = overallBudget['budget_id'];
          if (overallId != null) {
            final rows = await _databaseService.fetchAll(
              'user_budget',
              filters: {
                'budget_id': [overallId],
              },
            );
            if (rows.isNotEmpty) {
              overallThreshold = _parseDouble(rows.first['threshold']);
            }
          }
        }
      }

      if (_selectedType != BudgetType.user &&
          overallBudget != null &&
          overallThreshold != null) {
        final overallStart = _parseDate(overallBudget['date_from']);
        final overallEnd = _parseDate(overallBudget['date_to']);
        if (_rangesOverlap(rangeStart, rangeEnd, overallStart, overallEnd)) {
          final existingTotal = await _sumChildBudgetsForRange(
            budgets,
            overallStart,
            overallEnd,
          );
          if (existingTotal + threshold > overallThreshold) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Category/Account budgets exceed overall budget limit",
                ),
              ),
            );
            return;
          }
        }
      }

      if (_selectedType == BudgetType.user) {
        final existingTotal = await _sumChildBudgetsForRange(
          budgets,
          rangeStart,
          rangeEnd,
        );
        if (existingTotal > threshold) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Overall budget is lower than existing category/account limits",
              ),
            ),
          );
          return;
        }
      }

      final budget = Budget(
        userId: userId,
        type: _selectedType.code,
        dateFrom: rangeStart,
        dateTo: rangeEnd,
      );

      final savedBudget = await _upsertBudget(budget);
      final budgetId = savedBudget.id;
      if (budgetId == null) {
        throw Exception('Failed to save budget');
      }

      if (_selectedType == BudgetType.user) {
        await _upsertUserBudget(
          UserBudget(budgetId: budgetId, threshold: threshold),
        );
      } else if (_selectedType == BudgetType.category) {
        await _upsertCategoryBudget(
          CategoryBudget(
            budgetId: budgetId,
            expenseCategoryId: _selectedCategoryId!,
            threshold: threshold,
          ),
        );
      } else if (_selectedType == BudgetType.account) {
        await _upsertAccountBudget(
          AccountBudget(
            budgetId: budgetId,
            accountId: _selectedAccountId!,
            threshold: threshold,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Budget created for ${_selectedType.label}!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double pageMargin = 22.0;

    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: pageMargin,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppBackButton(onPressed: () => Navigator.pop(context)),

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
                                builder: (context) =>
                                    const BudgetOverviewPage(),
                              ),
                            );
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.getSurface(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.greyLight.withValues(
                                  alpha: 0.5,
                                ),
                              ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: pageMargin,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              "I want to control spending for...",
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Type Cards
                            SizedBox(
                              height: 100,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: BudgetType.values.map((type) {
                                  final isSelected = _selectedType == type;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedType = type),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: EdgeInsets.only(
                                          right: type == BudgetType.account
                                              ? 0
                                              : 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.getSurface(context),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.greyLight,
                                            width: 2,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              type.icon,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.grey,
                                              size: 28,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              type.label,
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : AppColors.grey,
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
                                  Text(
                                    "MY LIMIT IS",
                                    style: AppTypography.labelSmall.copyWith(
                                      letterSpacing: 1.5,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Fix: Use SizedBox instead of IntrinsicWidth to avoid layout crash
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
                                    child: TextFormField(
                                      controller: _amountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      textAlign: TextAlign.center,
                                      style: AppTypography.headline1.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 42,
                                      ),
                                      decoration: InputDecoration(
                                        prefixText: "RM ",
                                        prefixStyle: AppTypography.headline1
                                            .copyWith(
                                              color: AppColors.grey,
                                              fontSize: 42,
                                            ),
                                        border: InputBorder.none,
                                        hintText: "0.00",
                                        hintStyle: TextStyle(
                                          color: AppColors.greyLight.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        // Optional: Custom underline if desired
                                        // enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.greyLight)),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.isEmpty) {
                                          return 'Enter amount';
                                        }
                                        if (double.tryParse(val) == null) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  // Decorative underline
                                  Container(
                                    height: 2,
                                    width: 150,
                                    color: AppColors.greyLight.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Dynamic Dropdowns with Unique Keys
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _selectedType == BudgetType.category
                                  ? _buildDropdownField(
                                      const ValueKey(
                                        'category_dropdown',
                                      ), // UNIQUE KEY for logic fix
                                      "Select Category",
                                      "Category", // Placeholder Text
                                      _categories,
                                      _selectedCategoryId,
                                      (val) => setState(
                                        () => _selectedCategoryId = val,
                                      ),
                                    )
                                  : _selectedType == BudgetType.account
                                  ? _buildDropdownField(
                                      const ValueKey(
                                        'account_dropdown',
                                      ), // UNIQUE KEY for logic fix
                                      "Select Account",
                                      "Account", // Placeholder Text
                                      _accounts,
                                      _selectedAccountId,
                                      (val) => setState(
                                        () => _selectedAccountId = val,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            if (_selectedType != BudgetType.user)
                              const SizedBox(height: 24),

                            // Date Range Picker
                            Text("Duration", style: AppTypography.labelLarge),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _pickDateRange,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.getSurface(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.greyLight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedDateRange == null
                                              ? "Select Dates"
                                              : "${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end, showYear: true)}",
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (_selectedDateRange != null)
                                          Text(
                                            "${_selectedDateRange!.duration.inDays} Days",
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: AppColors.grey,
                                                  fontSize: 10,
                                                ),
                                          ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: AppColors.grey,
                                    ),
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
                        onPressed: _isSaving ? null : _saveBudget,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                "Set Limit",
                                style: AppTypography.headline1.copyWith(
                                  color: Colors.white,
                                ),
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
          initialValue: currentValue,
          // --- Placeholder Logic ---
          hint: Text(
            hintText,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.grey, // Placeholder put grey color
            ),
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
                  Text(item['name'] as String, style: AppTypography.bodyMedium),
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
