import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/services/supabase/auth/auth_service.dart';
import 'package:cashlytics/core/services/supabase/auth/auth_state_listener.dart';
import 'package:cashlytics/core/services/cache/cache_service.dart';
import 'package:cashlytics/core/utils/ai_insights/ai_insights_service.dart';

import 'package:cashlytics/domain/repositories/dashboard_repository.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';
import 'package:cashlytics/data/repositories/dashboard_repository_impl.dart';
import 'package:cashlytics/data/repositories/account_repository_impl.dart';
import 'package:cashlytics/domain/usecases/dashboard/get_monthly_weekly_balances.dart';
import 'package:cashlytics/domain/usecases/dashboard/get_yearly_quarterly_balances.dart';
import 'package:cashlytics/domain/usecases/accounts/get_accounts.dart';
import 'package:cashlytics/domain/entities/weekly_balance.dart';
import 'package:cashlytics/domain/entities/quarterly_balance.dart';
import 'package:cashlytics/domain/entities/account.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

import 'package:cashlytics/presentation/pages/user_management/login.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0; // Home is always 0

  // Cache keys
  final String _accountsCacheKey = 'dashboard_accounts_cache';
  final String _balancesCacheKey = 'dashboard_balances_cache';

  // Cached data
  List<Account> cachedAccounts = [];
  Map<String, dynamic>? cachedBalances;

  late final AuthService _authService;
  late final GetAccounts _getAccounts;
  late final AccountRepository _accountRepository;

  bool _redirecting = false;
  late final StreamSubscription<AuthState> _authStateSubscription;

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      // Index 1 is now ACCOUNT
      Navigator.pushReplacementNamed(context, '/account');
    } else if (index == 2) {
      // Index 2 is now PROFILE
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _accountRepository = AccountRepositoryImpl();
    _getAccounts = GetAccounts(_accountRepository);
    _fetchAndCacheAccounts();
    _fetchAndCacheBalances();

    _authStateSubscription = listenForSignedOutRedirect(
      shouldRedirect: () => !_redirecting,
      onRedirect: () {
        if (!mounted) return;
        setState(() => _redirecting = true);
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
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchAndCacheAccounts() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final accounts = await _getAccounts(user.id);
      if (accounts.isNotEmpty) {
        cachedAccounts = accounts;
        final accountsData = accounts
            .map(
              (acc) => {
                'account_id': acc.id,
                'user_id': acc.userId,
                'name': acc.name,
                'type': acc.type,
                'initial_balance': acc.initialBalance,
                'current_balance': acc.currentBalance,
                'description': acc.description,
                'created_at': acc.createdAt?.toIso8601String(),
                'updated_at': acc.updatedAt?.toIso8601String(),
              },
            )
            .toList();
        await CacheService.save(_accountsCacheKey, accountsData);
      }
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
      final cached = CacheService.load<List<dynamic>>(_accountsCacheKey);
      if (cached != null) {
        cachedAccounts = cached
            .where((item) {
              // Filter out invalid accounts
              final userId = item['user_id'];
              return userId != null && userId.toString().isNotEmpty;
            })
            .map(
              (item) => Account(
                id: item['account_id'],
                userId: item['user_id'], // Safe because we filtered above
                name: item['name'],
                type: item['type'],
                initialBalance: item['initial_balance'] ?? 0,
                currentBalance: item['current_balance'] ?? 0,
                description: item['description'],
              ),
            )
            .toList();

        if (cachedAccounts.isEmpty) {
          debugPrint('No valid cached accounts found');
        }
      }
    } finally {
      if (_authService.currentUser == null) {
        // Only redirect if cache is also empty
        if (cachedAccounts.isEmpty) {
          cachedAccounts = [];
          await CacheService.remove(_accountsCacheKey);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        } else {
          debugPrint('User logged out but cached accounts available');
        }
      }
    }
  }

  Future<void> _fetchAndCacheBalances() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch monthly/weekly and yearly/quarterly balances
      final now = DateTime.now();
      final dashboardRepository = DashboardRepositoryImpl();
      final getMonthlyWeeklyBalances = GetMonthlyWeeklyBalances(
        dashboardRepository,
      );
      final getYearlyQuarterlyBalances = GetYearlyQuarterlyBalances(
        dashboardRepository,
      );

      final monthlyWeekly = await getMonthlyWeeklyBalances(user.id, now);
      final yearlyQuarterly = await getYearlyQuarterlyBalances(
        user.id,
        now.year,
      );

      if (monthlyWeekly.isNotEmpty || yearlyQuarterly.isNotEmpty) {
        cachedBalances = {
          'monthly_weekly': monthlyWeekly
              .map(
                (b) => {
                  'week_number': b.weekNumber,
                  'balance': b.balance,
                  'start_date': b.startDate.toIso8601String(),
                  'end_date': b.endDate.toIso8601String(),
                  'total_income': b.totalIncome,
                  'total_expense': b.totalExpense,
                  'is_current_week': b.isCurrentWeek,
                },
              )
              .toList(),
          'yearly_quarterly': yearlyQuarterly
              .map(
                (b) => {
                  'quarter_number': b.quarterNumber,
                  'balance': b.balance,
                  'start_date': b.startDate.toIso8601String(),
                  'end_date': b.endDate.toIso8601String(),
                  'total_income': b.totalIncome,
                  'total_expense': b.totalExpense,
                  'is_current_quarter': b.isCurrentQuarter,
                },
              )
              .toList(),
        };
        await CacheService.save(_balancesCacheKey, cachedBalances!);
      }
    } catch (e) {
      debugPrint('Error fetching balances: $e');
      final cached = CacheService.load<Map<String, dynamic>>(_balancesCacheKey);
      if (cached != null) {
        // Validate cache has required data
        if (((cached['monthly_weekly'] as List?)?.isNotEmpty ?? false) ||
            ((cached['yearly_quarterly'] as List?)?.isNotEmpty ?? false)) {
          cachedBalances = cached;
        } else {
          debugPrint('Cached balances are empty');
        }
      }
    } finally {
      if (_authService.currentUser == null) {
        // Only redirect if cache is also empty
        if (cachedBalances == null ||
            (((cachedBalances!['monthly_weekly'] as List?)?.isEmpty ?? true) &&
                ((cachedBalances!['yearly_quarterly'] as List?)?.isEmpty ??
                    true))) {
          cachedBalances = null;
          await CacheService.remove(_balancesCacheKey);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        } else {
          debugPrint('User logged out but cached balances available');
        }
      }
    }
  }

  // --- AI Suggestions Modal ---
  void _showAISuggestions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      isScrollControlled: true,
      builder: (context) {
        return _AISuggestionsModalContent();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Center(
                child: Image.asset(
                  'assets/logo/logo.webp',
                  height: 70,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Financial Overview",
                    style: AppTypography.headline2.copyWith(
                      color: Colors.black87,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      _showAISuggestions(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- 1. Total Balance Card ---
              const _TotalBalanceCard(),

              const SizedBox(height: 20),

              // --- 2. Cash Flow Card ---
              const _CashFlowCard(),

              const SizedBox(height: 20),

              // --- 3. Expense Distribution (No Future Dates) ---
              const _ExpenseDistributionCard(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}

// --- Helper Widgets & Painters ---

class _AISuggestionsModalContent extends StatefulWidget {
  const _AISuggestionsModalContent();

  @override
  State<_AISuggestionsModalContent> createState() =>
      _AISuggestionsModalContentState();
}

class _AISuggestionsModalContentState
    extends State<_AISuggestionsModalContent> {
  bool _isLoading = true;
  int? _healthScore;
  String? _insights;
  List<dynamic> _suggestions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAIInsights();
  }

  Future<void> _loadAIInsights() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Import the service
      final aiInsightsService = AiInsightsService();
      final report = await aiInsightsService.generateInsights();

      if (!mounted) return;

      // Parse suggestions from the body (JSON string)
      if (report.body != null) {
        try {
          final json = _parseJsonFromBody(report.body!);
          setState(() {
            _healthScore = report.healthScore;
            _insights = json['insights'] as String?;
            _suggestions = json['suggestions'] as List? ?? [];
            _isLoading = false;
          });
        } catch (e) {
          debugPrint('Error parsing AI response: $e');
          _setError('Failed to parse AI insights');
        }
      }
    } catch (e) {
      debugPrint('Error loading AI insights: $e');
      _setError('Failed to load insights');
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _parseJsonFromBody(String body) {
    try {
      // Try direct parse
      return Map<String, dynamic>.from(jsonDecode(body));
    } catch (_) {
      // Try extracting from markdown
      final jsonMatch = RegExp(
        r'```(?:json)?\s*(\{[\s\S]*?\})\s*```',
      ).firstMatch(body);
      if (jsonMatch != null) {
        return Map<String, dynamic>.from(jsonDecode(jsonMatch.group(1)!));
      }
      // Try extracting raw JSON
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(body);
      if (objectMatch != null) {
        return Map<String, dynamic>.from(jsonDecode(objectMatch.group(0)!));
      }
      throw Exception('Could not parse JSON from body');
    }
  }

  IconData _getIconData(String iconName) {
    final iconMap = <String, IconData>{
      'savings': Icons.savings,
      'trending_up': Icons.trending_up,
      'trending_down': Icons.trending_down,
      'account_balance_wallet': Icons.account_balance_wallet,
      'restaurant': Icons.restaurant,
      'home': Icons.home,
      'shopping_cart': Icons.shopping_cart,
      'attach_money': Icons.attach_money,
      'credit_card': Icons.credit_card,
      'receipt': Icons.receipt,
      'local_gas_station': Icons.local_gas_station,
      'lightbulb_outline': Icons.lightbulb_outline,
      'warning': Icons.warning,
      'check_circle': Icons.check_circle,
      'info': Icons.info,
      'star': Icons.star,
      'workspace_premium': Icons.workspace_premium,
    };

    return iconMap[iconName] ?? Icons.lightbulb_outline;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'spending':
        return Colors.orange;
      case 'savings':
        return Colors.green;
      case 'budgeting':
        return Colors.blue;
      case 'income':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  Color _getHealthColor() {
    if (_healthScore == null) return Colors.grey;
    if (_healthScore! >= 80) return AppColors.success;
    if (_healthScore! >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getHealthStatus() {
    if (_healthScore == null) return 'Unknown';
    if (_healthScore! >= 80) return 'Excellent';
    if (_healthScore! >= 60) return 'Good';
    return 'Needs Improvement';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  "AI Financial Insights",
                  style: AppTypography.headline3.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'For more accurate insights, fill in your details in Profile > Edit AI Analysis Profile.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Health Score
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _getHealthColor().withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getHealthColor().withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: (_healthScore ?? 0) / 100,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getHealthColor(),
                                ),
                              ),
                            ),
                            Text(
                              _healthScore?.toString() ?? '?',
                              style: AppTypography.headline3.copyWith(
                                color: _getHealthColor(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getHealthStatus(),
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _insights ?? 'Analyzing your finances...',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.greyText,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 30),
                  // Suggestions
                  if (_suggestions.isNotEmpty)
                    ..._suggestions.whereType<Map<String, dynamic>>().map(
                      (suggestion) => _SuggestionTile(
                        title: suggestion['title'] as String? ?? '',
                        body: suggestion['body'] as String? ?? '',
                        icon: _getIconData(
                          suggestion['icon'] as String? ?? 'lightbulb_outline',
                        ),
                        color: _getCategoryColor(
                          suggestion['category'] as String? ?? 'general',
                        ),
                      ),
                    )
                  else
                    _SuggestionTile(
                      title: 'No Suggestions',
                      body: 'Your finances are looking good!',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                ],
              ),
            ),
          // Close Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Close"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  const _SuggestionTile({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.getTextSecondary(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBalanceCard extends StatefulWidget {
  const _TotalBalanceCard();

  @override
  State<_TotalBalanceCard> createState() => _TotalBalanceCardState();
}

class _TotalBalanceCardState extends State<_TotalBalanceCard> {
  String _selectedFilter = 'This month';
  bool _isLoading = true;
  List<WeeklyBalance> _weeklyBalances = [];
  List<QuarterlyBalance> _quarterlyBalances = [];
  List<WeeklyBalance> _previousWeeklyBalances = [];
  List<QuarterlyBalance> _previousQuarterlyBalances = [];

  late final DashboardRepository _dashboardRepository;
  late final GetMonthlyWeeklyBalances _getMonthlyWeeklyBalances;
  late final GetYearlyQuarterlyBalances _getYearlyQuarterlyBalances;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _dashboardRepository = DashboardRepositoryImpl();
    _getMonthlyWeeklyBalances = GetMonthlyWeeklyBalances(_dashboardRepository);
    _getYearlyQuarterlyBalances = GetYearlyQuarterlyBalances(
      _dashboardRepository,
    );
    _authService = AuthService();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();

      // Determine what data to load based on selected filter
      switch (_selectedFilter) {
        case 'This month':
          final currentBalances = await _getMonthlyWeeklyBalances(user.id, now);
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          final previousBalances = await _getMonthlyWeeklyBalances(
            user.id,
            lastMonth,
          );
          setState(() {
            _weeklyBalances = currentBalances;
            _previousWeeklyBalances = previousBalances;
            _quarterlyBalances = [];
            _previousQuarterlyBalances = [];
            _isLoading = false;
          });
          break;

        case 'Last month':
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          final currentBalances = await _getMonthlyWeeklyBalances(
            user.id,
            lastMonth,
          );
          final prevMonth = DateTime(now.year, now.month - 2, 1);
          final previousBalances = await _getMonthlyWeeklyBalances(
            user.id,
            prevMonth,
          );
          setState(() {
            _weeklyBalances = currentBalances;
            _previousWeeklyBalances = previousBalances;
            _quarterlyBalances = [];
            _previousQuarterlyBalances = [];
            _isLoading = false;
          });
          break;

        case 'This year':
          final currentBalances = await _getYearlyQuarterlyBalances(
            user.id,
            now.year,
          );
          final previousBalances = await _getYearlyQuarterlyBalances(
            user.id,
            now.year - 1,
          );
          setState(() {
            _quarterlyBalances = currentBalances;
            _previousQuarterlyBalances = previousBalances;
            _weeklyBalances = [];
            _previousWeeklyBalances = [];
            _isLoading = false;
          });
          break;

        case 'Last year':
          final currentBalances = await _getYearlyQuarterlyBalances(
            user.id,
            now.year - 1,
          );
          final previousBalances = await _getYearlyQuarterlyBalances(
            user.id,
            now.year - 2,
          );
          setState(() {
            _quarterlyBalances = currentBalances;
            _previousQuarterlyBalances = previousBalances;
            _weeklyBalances = [];
            _previousWeeklyBalances = [];
            _isLoading = false;
          });
          break;

        default:
          setState(() {
            _isLoading = false;
            _weeklyBalances = [];
            _quarterlyBalances = [];
            _previousWeeklyBalances = [];
            _previousQuarterlyBalances = [];
          });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _weeklyBalances = [];
        _quarterlyBalances = [];
        _previousWeeklyBalances = [];
        _previousQuarterlyBalances = [];
      });
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _getCompareText() {
    switch (_selectedFilter) {
      case 'This month':
        return 'vs last month';
      case 'Last month':
        return 'vs prev month';
      case 'This year':
        return 'vs last year';
      case 'Last year':
        return 'vs prev year';
      default:
        return '';
    }
  }

  double _calculateTotalBalance() {
    if (_weeklyBalances.isNotEmpty) {
      return _weeklyBalances.fold(0.0, (sum, week) => sum + week.balance);
    } else if (_quarterlyBalances.isNotEmpty) {
      return _quarterlyBalances.fold(
        0.0,
        (sum, quarter) => sum + quarter.balance,
      );
    }
    return 0.0;
  }

  String _calculatePercentageChange() {
    double currentTotal = 0.0;
    double previousTotal = 0.0;

    if (_weeklyBalances.isNotEmpty) {
      currentTotal = _weeklyBalances.fold(
        0.0,
        (sum, week) => sum + week.balance,
      );
      previousTotal = _previousWeeklyBalances.fold(
        0.0,
        (sum, week) => sum + week.balance,
      );
    } else if (_quarterlyBalances.isNotEmpty) {
      currentTotal = _quarterlyBalances.fold(
        0.0,
        (sum, quarter) => sum + quarter.balance,
      );
      previousTotal = _previousQuarterlyBalances.fold(
        0.0,
        (sum, quarter) => sum + quarter.balance,
      );
    } else {
      return '+0.0%';
    }

    if (previousTotal == 0) {
      // If previous period had no balance, show current as 100% increase if positive
      if (currentTotal > 0) return '+100.0%';
      if (currentTotal < 0) return '-100.0%';
      return '+0.0%';
    }

    final change = ((currentTotal - previousTotal) / previousTotal.abs()) * 100;
    return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
  }

  Color _getPercentageColor() {
    double currentTotal = 0.0;
    double previousTotal = 0.0;

    if (_weeklyBalances.isNotEmpty) {
      currentTotal = _weeklyBalances.fold(
        0.0,
        (sum, week) => sum + week.balance,
      );
      previousTotal = _previousWeeklyBalances.fold(
        0.0,
        (sum, week) => sum + week.balance,
      );
    } else if (_quarterlyBalances.isNotEmpty) {
      currentTotal = _quarterlyBalances.fold(
        0.0,
        (sum, quarter) => sum + quarter.balance,
      );
      previousTotal = _previousQuarterlyBalances.fold(
        0.0,
        (sum, quarter) => sum + quarter.balance,
      );
    } else {
      return AppColors.greyText;
    }

    return currentTotal >= previousTotal ? AppColors.success : Colors.red;
  }

  List<double> _getChartData() {
    List<double> balances;

    if (_weeklyBalances.isNotEmpty) {
      // Sort by start_date to ensure chronological order
      final sortedBalances = List<WeeklyBalance>.from(_weeklyBalances)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      balances = sortedBalances.map((w) => w.balance).toList();
    } else if (_quarterlyBalances.isNotEmpty) {
      balances = _quarterlyBalances.map((q) => q.balance).toList();
    } else {
      return [0.2, 0.5, 0.4, 0.7, 0.6, 0.9, 0.8]; // Default placeholder
    }

    // Normalize balance values to 0-1 range for chart
    final maxBalance = balances
        .map((b) => b.abs())
        .reduce((a, b) => a > b ? a : b);

    if (maxBalance == 0) {
      return List.filled(balances.length, 0.5);
    }

    return balances.map((b) => (b.abs() / maxBalance).clamp(0.1, 1.0)).toList();
  }

  List<String> _getLabels() {
    if (_weeklyBalances.isNotEmpty) {
      // Sort by start_date to ensure chronological order
      final sortedBalances = List<WeeklyBalance>.from(_weeklyBalances)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      return sortedBalances.map((w) {
        // Add year suffix for Week 1 when it appears with higher week numbers
        if (w.weekNumber == 1 && sortedBalances.any((b) => b.weekNumber > 10)) {
          // Extract last 2 digits of year from start_date
          final nextYear = (w.startDate.year + 1) % 100;
          return "Week 1'$nextYear";
        }
        return 'Week ${w.weekNumber}';
      }).toList();
    } else if (_quarterlyBalances.isNotEmpty) {
      return _quarterlyBalances.map((q) => 'Q${q.quarterNumber}').toList();
    }
    return ['Week 1', 'Week 2', 'Week 3', 'Week 4']; // Default placeholder
  }

  final Map<String, dynamic> _data = {
    'This month': {
      'amount': '\$12,450.75',
      'pct': '+2.4%',
      'pctColor': AppColors.success,
      'compare': 'vs last month',
      'labels': ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
      'chart': [0.2, 0.5, 0.4, 0.7, 0.6, 0.9, 0.8],
    },
    'Last month': {
      'amount': '\$11,230.00',
      'pct': '-1.2%',
      'pctColor': Colors.red,
      'compare': 'vs prev month',
      'labels': ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
      'chart': [0.6, 0.5, 0.6, 0.4, 0.3, 0.4, 0.2],
    },
    'This year': {
      'amount': '\$145,200.50',
      'pct': '+15.3%',
      'pctColor': AppColors.success,
      'compare': 'vs last year',
      'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
      'chart': [0.3, 0.4, 0.6, 0.8, 0.7, 0.9, 0.95],
    },
    'Last year': {
      'amount': '\$128,900.00',
      'pct': '+8.5%',
      'pctColor': AppColors.success,
      'compare': 'vs prev year',
      'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
      'chart': [0.2, 0.3, 0.4, 0.5, 0.5, 0.6, 0.7],
    },
  };

  @override
  Widget build(BuildContext context) {
    // Use real data if available for any filter
    final bool useRealData =
        !_isLoading &&
        (_weeklyBalances.isNotEmpty || _quarterlyBalances.isNotEmpty);

    // Fallback to default placeholder data if the selected filter has no mock entry yet
    final currentData = useRealData
        ? null
        : (_data[_selectedFilter] ?? _data['This month']);

    final displayAmount = useRealData
        ? _formatCurrency(_calculateTotalBalance())
        : currentData['amount'];

    final displayPct = useRealData
        ? _calculatePercentageChange()
        : currentData['pct'];

    final displayPctColor = useRealData
        ? _getPercentageColor()
        : currentData['pctColor'];

    final displayCompare = useRealData
        ? _getCompareText()
        : currentData['compare'];

    final chartData = useRealData ? _getChartData() : currentData['chart'];
    final labels = useRealData ? _getLabels() : currentData['labels'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Balance", style: AppTypography.bodyLarge),

              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() => _selectedFilter = value);
                  _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyBorder),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(_selectedFilter, style: AppTypography.caption),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.greyText,
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'This month',
                    child: Text('This month'),
                  ),
                  const PopupMenuItem(
                    value: 'Last month',
                    child: Text('Last month'),
                  ),
                  const PopupMenuItem(
                    value: 'This year',
                    child: Text('This year'),
                  ),
                  const PopupMenuItem(
                    value: 'Last year',
                    child: Text('Last year'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      displayAmount,
                      style: AppTypography.headline1.copyWith(fontSize: 28),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          displayPct,
                          style: AppTypography.labelLarge.copyWith(
                            color: displayPctColor,
                          ),
                        ),
                        Text(
                          displayCompare,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          const SizedBox(height: 20),

          SizedBox(
            height: 100,
            width: double.infinity,
            child: _isLoading
                ? Container()
                : CustomPaint(
                    painter: _DynamicLineChartPainter(
                      dataPoints: chartData,
                      weeklyBalances: _weeklyBalances.isNotEmpty
                          ? _weeklyBalances
                          : null,
                    ),
                  ),
          ),

          const SizedBox(height: 10),

          if (!_isLoading)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: (labels as List<String>)
                  .map(
                    (label) => Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _CashFlowCard extends StatefulWidget {
  const _CashFlowCard();

  @override
  State<_CashFlowCard> createState() => _CashFlowCardState();
}

class _CashFlowCardState extends State<_CashFlowCard> {
  String _selectedFilter = 'This month';
  bool _isLoading = true;
  List<WeeklyBalance> _weeklyBalances = [];
  List<QuarterlyBalance> _quarterlyBalances = [];

  late final DashboardRepository _dashboardRepository;
  late final GetMonthlyWeeklyBalances _getMonthlyWeeklyBalances;
  late final GetYearlyQuarterlyBalances _getYearlyQuarterlyBalances;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _dashboardRepository = DashboardRepositoryImpl();
    _getMonthlyWeeklyBalances = GetMonthlyWeeklyBalances(_dashboardRepository);
    _getYearlyQuarterlyBalances = GetYearlyQuarterlyBalances(
      _dashboardRepository,
    );
    _authService = AuthService();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _weeklyBalances = [];
            _quarterlyBalances = [];
          });
        }
        return;
      }

      final now = DateTime.now();

      // Load data based on selected filter
      switch (_selectedFilter) {
        case 'This month':
          final balances = await _getMonthlyWeeklyBalances(user.id, now);
          if (mounted) {
            setState(() {
              _weeklyBalances = balances;
              _quarterlyBalances = [];
              _isLoading = false;
            });
          }
          break;

        case 'Last month':
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          final balances = await _getMonthlyWeeklyBalances(user.id, lastMonth);
          if (mounted) {
            setState(() {
              _weeklyBalances = balances;
              _quarterlyBalances = [];
              _isLoading = false;
            });
          }
          break;

        case 'This year':
          final balances = await _getYearlyQuarterlyBalances(user.id, now.year);
          if (mounted) {
            setState(() {
              _quarterlyBalances = balances;
              _weeklyBalances = [];
              _isLoading = false;
            });
          }
          break;

        case 'Last year':
          final balances = await _getYearlyQuarterlyBalances(
            user.id,
            now.year - 1,
          );
          if (mounted) {
            setState(() {
              _quarterlyBalances = balances;
              _weeklyBalances = [];
              _isLoading = false;
            });
          }
          break;

        default:
          if (mounted) {
            setState(() {
              _isLoading = false;
              _weeklyBalances = [];
              _quarterlyBalances = [];
            });
          }
      }
    } catch (e) {
      debugPrint('Error loading cash flow data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _weeklyBalances = [];
          _quarterlyBalances = [];
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  List<double> _getIncomeData() {
    List<double> incomes;

    if (_weeklyBalances.isNotEmpty) {
      // Sort by start_date
      final sortedBalances = List<WeeklyBalance>.from(_weeklyBalances)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      incomes = sortedBalances.map((w) => w.totalIncome).toList();
    } else if (_quarterlyBalances.isNotEmpty) {
      incomes = _quarterlyBalances.map((q) => q.totalIncome).toList();
    } else {
      return [0.6, 0.4, 0.8, 0.45]; // Default placeholder
    }

    // Normalize to 0-1 range
    final maxValue = _getMaxValue();
    if (maxValue <= 0) return List.filled(incomes.length, 0.0);

    return incomes.map((v) => (v / maxValue).clamp(0.0, 1.0)).toList();
  }

  List<double> _getExpenseData() {
    List<double> expenses;

    if (_weeklyBalances.isNotEmpty) {
      // Sort by start_date
      final sortedBalances = List<WeeklyBalance>.from(_weeklyBalances)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      expenses = sortedBalances.map((w) => w.totalExpense).toList();
    } else if (_quarterlyBalances.isNotEmpty) {
      expenses = _quarterlyBalances.map((q) => q.totalExpense).toList();
    } else {
      return [0.35, 0.38, 0.65, 0.48]; // Default placeholder
    }

    // Normalize to 0-1 range
    final maxValue = _getMaxValue();
    if (maxValue <= 0) return List.filled(expenses.length, 0.0);

    return expenses.map((v) => (v / maxValue).clamp(0.0, 1.0)).toList();
  }

  double _getMaxValue() {
    List<double> allValues = [];

    if (_weeklyBalances.isNotEmpty) {
      final sortedBalances = List<WeeklyBalance>.from(_weeklyBalances)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      for (var week in sortedBalances) {
        allValues.add(week.totalIncome);
        allValues.add(week.totalExpense);
      }
    } else if (_quarterlyBalances.isNotEmpty) {
      for (var quarter in _quarterlyBalances) {
        allValues.add(quarter.totalIncome);
        allValues.add(quarter.totalExpense);
      }
    }

    if (allValues.isEmpty) return 8000.0;
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return 8000.0;
    return maxValue;
  }

  List<String> _getYAxisLabels() {
    final maxValue = _getMaxValue();
    final step = maxValue / 4;

    return [
      _formatCurrency(maxValue),
      _formatCurrency(maxValue - step),
      _formatCurrency(maxValue - step * 2),
      _formatCurrency(maxValue - step * 3),
      '\$0',
    ];
  }

  List<String> _getLabels() {
    if (_weeklyBalances.isNotEmpty) {
      final sortedBalances = List<WeeklyBalance>.from(_weeklyBalances)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      return sortedBalances.map((w) {
        if (w.weekNumber == 1 && sortedBalances.any((b) => b.weekNumber > 10)) {
          final nextYear = (w.startDate.year + 1) % 100;
          return "Wk 1'$nextYear";
        }
        return 'Wk ${w.weekNumber}';
      }).toList();
    } else if (_quarterlyBalances.isNotEmpty) {
      return _quarterlyBalances.map((q) => 'Q${q.quarterNumber}').toList();
    }
    return ['Week 1', 'Week 2', 'Week 3', 'Week 4']; // Default placeholder
  }

  final Map<String, dynamic> _data = {
    'This month': {
      'incomeData': [0.6, 0.4, 0.8, 0.45],
      'expenseData': [0.35, 0.38, 0.65, 0.48],
      'labels': ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
    },
    'Last month': {
      'incomeData': [0.5, 0.6, 0.5, 0.4],
      'expenseData': [0.4, 0.55, 0.6, 0.3],
      'labels': ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
    },
  };

  @override
  Widget build(BuildContext context) {
    // Use real data if available
    final bool useRealData =
        !_isLoading &&
        (_weeklyBalances.isNotEmpty || _quarterlyBalances.isNotEmpty);

    final currentData = useRealData
        ? null
        : (_data[_selectedFilter] ?? _data['This month']);
    final incomeData = useRealData
        ? _getIncomeData()
        : currentData!['incomeData'];
    final expenseData = useRealData
        ? _getExpenseData()
        : currentData!['expenseData'];
    final labels = useRealData ? _getLabels() : currentData!['labels'];
    final yAxisLabels = useRealData
        ? _getYAxisLabels()
        : ['\$8,000', '\$6,000', '\$4,000', '\$2,000', '\$0'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cash Flow", style: AppTypography.bodyLarge),

              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() => _selectedFilter = value);
                  _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyBorder),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(_selectedFilter, style: AppTypography.caption),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.greyText,
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'This month',
                    child: Text('This month'),
                  ),
                  const PopupMenuItem(
                    value: 'Last month',
                    child: Text('Last month'),
                  ),
                  const PopupMenuItem(
                    value: 'This year',
                    child: Text('This year'),
                  ),
                  const PopupMenuItem(
                    value: 'Last year',
                    child: Text('Last year'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: yAxisLabels
                            .map(
                              (label) => Text(
                                label,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  color: AppColors.greyText,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _DynamicBarChartPainter(
                            incomeData: incomeData,
                            expenseData: expenseData,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

          const SizedBox(height: 10),

          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 45.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: (labels as List<String>)
                    .map(
                      (label) => Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.greyText,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Income",
                style: TextStyle(color: AppColors.greyText, fontSize: 12),
              ),
              const SizedBox(width: 20),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Expenses",
                style: TextStyle(color: AppColors.greyText, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- UPDATED: Expense Distribution with NO Future Dates ---
class _ExpenseDistributionCard extends StatefulWidget {
  const _ExpenseDistributionCard();

  @override
  State<_ExpenseDistributionCard> createState() =>
      _ExpenseDistributionCardState();
}

class _ExpenseDistributionCardState extends State<_ExpenseDistributionCard> {
  // Helper to remove time components (Hours/Minutes) so dates compare correctly
  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  late DateTimeRange _selectedRange;
  bool _isLoading = true;
  double _totalExpense = 0;
  final List<_ExpenseSlice> _slices = [];
  late final AuthService _authService;
  final List<Color> _palette = [
    AppColors.primary,
    AppColors.primary.withValues(alpha: 0.85),
    AppColors.primary.withValues(alpha: 0.7),
    AppColors.primary.withValues(alpha: 0.55),
    AppColors.primary.withValues(alpha: 0.4),
    AppColors.primary.withValues(alpha: 0.25),
    Colors.grey.shade400,
  ];

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    final now = DateTime.now();
    // Initialize with stripped times
    _selectedRange = DateTimeRange(
      start: _stripTime(now.subtract(const Duration(days: 30))),
      end: _stripTime(now),
    );

    _loadDistribution();
  }

  Future<void> _loadDistribution() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _slices.clear();
          _totalExpense = 0;
          _isLoading = false;
        });
        return;
      }

      final start = _stripTime(_selectedRange.start);
      final end = DateTime(
        _selectedRange.end.year,
        _selectedRange.end.month,
        _selectedRange.end.day,
        23,
        59,
        59,
      );

      // Fetch expenses with transaction and category details
      final expenseResponse = await supabase
          .from('expenses')
          .select(
            'amount, expense_cat_id, expense_category:expense_cat_id(name), transaction!expenses_transaction_id_fkey(created_at, account:account_id(user_id))',
          );

      debugPrint('[ExpenseDistribution] Raw response: $expenseResponse');

      // Filter in Dart for date range and user_id due to potential RLS constraints
      final Map<String, double> totalsByCategory = {};

      for (final row in expenseResponse as List<dynamic>) {
        final map = row as Map<String, dynamic>;

        // Check user match
        final transaction = map['transaction'] as Map<String, dynamic>?;
        if (transaction == null) continue;

        final account = transaction['account'] as Map<String, dynamic>?;
        final accountUserId = account?['user_id'] as String?;
        if (accountUserId != user.id) continue;

        // Check date range
        final createdAtStr = transaction['created_at'] as String?;
        if (createdAtStr == null) continue;

        final createdAt = DateTime.tryParse(createdAtStr);
        if (createdAt == null ||
            createdAt.isBefore(start) ||
            createdAt.isAfter(end)) {
          continue;
        }

        // Parse amount
        final rawAmount = map['amount'];
        final amount = rawAmount is num
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '0') ?? 0;

        if (amount <= 0) continue;

        // Get category name
        final catName =
            (map['expense_category']?['name'] as String?) ?? 'Uncategorized';
        totalsByCategory[catName] = (totalsByCategory[catName] ?? 0) + amount;
      }

      debugPrint('[ExpenseDistribution] Totals by category: $totalsByCategory');

      final sorted = totalsByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final slices = <_ExpenseSlice>[];
      for (int i = 0; i < sorted.length; i++) {
        final color = i < _palette.length ? _palette[i] : _palette.last;
        slices.add(
          _ExpenseSlice(
            label: sorted[i].key,
            amount: sorted[i].value,
            color: color,
          ),
        );
      }

      final total = slices.fold<double>(0, (sum, s) => sum + s.amount);

      if (!mounted) return;
      setState(() {
        _slices
          ..clear()
          ..addAll(slices);
        _totalExpense = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading expense distribution: $e');
      if (!mounted) return;
      setState(() {
        _slices.clear();
        _totalExpense = 0;
        _isLoading = false;
      });
    }
  }

  String get _formattedRange {
    final start = "${_selectedRange.start.day}/${_selectedRange.start.month}";
    final end = "${_selectedRange.end.day}/${_selectedRange.end.month}";

    if (_selectedRange.start.year == _selectedRange.end.year &&
        _selectedRange.start.month == _selectedRange.end.month &&
        _selectedRange.start.day == _selectedRange.end.day) {
      return start;
    }

    return "$start - $end";
  }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final today = _stripTime(now); // Strip time for the limit as well

    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate:
          today, // FIX: Use 'today' (midnight), matching the initial range end
      initialDateRange: _selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      setState(() {
        _selectedRange = newRange;
      });
      await _loadDistribution();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Expense Distribution", style: AppTypography.bodyLarge),

              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyBorder),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(_formattedRange, style: AppTypography.caption),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.greyText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_totalExpense <= 0 || _slices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No expenses recorded in this range',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.greyText,
                  ),
                ),
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                height: 180,
                width: 180,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DonutChartPainter(
                          slices: _slices,
                          total: _totalExpense,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.greyText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(_totalExpense),
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ..._slices.map((slice) {
              final pct = _totalExpense == 0
                  ? 0
                  : (slice.amount / _totalExpense * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LegendItem(
                  color: slice.color,
                  label: slice.label,
                  pct: '${pct.toStringAsFixed(1)}%',
                  amt: '(${_formatCurrency(slice.amount)})',
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String pct;
  final String amt;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.pct,
    required this.amt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.bodyMedium),
        const Spacer(),
        Text(
          pct,
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Text(
          amt,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.greyText),
        ),
      ],
    );
  }
}

class _ExpenseSlice {
  final String label;
  final double amount;
  final Color color;

  const _ExpenseSlice({
    required this.label,
    required this.amount,
    required this.color,
  });
}

// --- CUSTOM PAINTERS ---

class _DynamicLineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<WeeklyBalance>? weeklyBalances;

  _DynamicLineChartPainter({required this.dataPoints, this.weeklyBalances});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    double stepX = size.width / (dataPoints.length - 1);
    double firstY = size.height * (1 - dataPoints[0]);
    path.moveTo(0, firstY);

    for (int i = 1; i < dataPoints.length; i++) {
      double x = i * stepX;
      double y = size.height * (1 - dataPoints[i]);
      double prevX = (i - 1) * stepX;
      double prevY = size.height * (1 - dataPoints[i - 1]);

      path.cubicTo((prevX + x) / 2, prevY, (prevX + x) / 2, y, x, y);
    }

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw "current week" line if we have weekly balance data
    if (weeklyBalances != null && weeklyBalances!.isNotEmpty) {
      final sortedBalances = List<WeeklyBalance>.from(weeklyBalances!)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      // Find the current week using isCurrentWeek flag
      int? currentWeekIndex;
      for (int i = 0; i < sortedBalances.length; i++) {
        if (sortedBalances[i].isCurrentWeek) {
          currentWeekIndex = i;
          break;
        }
      }

      if (currentWeekIndex != null) {
        // Draw line at the center of the current week
        final currentWeekX = currentWeekIndex * stepX;

        // Draw dotted vertical line
        final dottedPaint = Paint()
          ..color = AppColors.greyText.withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        const dashHeight = 4.0;
        const dashSpace = 4.0;
        double startY = 0;

        while (startY < size.height) {
          canvas.drawLine(
            Offset(currentWeekX, startY),
            Offset(currentWeekX, startY + dashHeight),
            dottedPaint,
          );
          startY += dashHeight + dashSpace;
        }

        // Draw a small circle at the top
        final circlePaint = Paint()
          ..color = AppColors.greyText
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(currentWeekX, 0), 3, circlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DynamicBarChartPainter extends CustomPainter {
  final List<double> incomeData;
  final List<double> expenseData;

  _DynamicBarChartPainter({
    required this.incomeData,
    required this.expenseData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBlue = Paint()..color = AppColors.primary;
    final paintGrey = Paint()..color = Colors.grey.shade300;

    int count = incomeData.length;
    if (count == 0) return;

    final groupWidth = size.width / count;
    double padding = 8.0;
    if (count > 5) padding = 4.0;

    final barWidth = (groupWidth - (padding * 3)) / 2;
    final spacing = (groupWidth - (barWidth * 2)) / 2;

    for (int i = 0; i < count; i++) {
      double startX = (i * groupWidth) + spacing;

      double h1 = size.height * incomeData[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, size.height - h1, barWidth, h1),
          const Radius.circular(4),
        ),
        paintBlue,
      );

      double h2 = size.height * expenseData[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX + barWidth + 4, size.height - h2, barWidth, h2),
          const Radius.circular(4),
        ),
        paintGrey,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutChartPainter extends CustomPainter {
  final List<_ExpenseSlice> slices;
  final double total;

  _DonutChartPainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    // Draw neutral ring when there is no data
    if (total <= 0 || slices.isEmpty) {
      final bgPaint = Paint()
        ..color = AppColors.greyBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, 0, math.pi * 2, false, bgPaint);
      return;
    }

    double startAngle = -math.pi / 2;
    for (final slice in slices) {
      if (slice.amount <= 0) continue;
      final sweep = (slice.amount / total) * math.pi * 2;
      if (sweep <= 0) {
        startAngle += sweep;
        continue;
      }
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      // Small gap between slices for readability
      const gap = 0.02;
      final adjustedSweep = sweep > gap ? sweep - gap : sweep;
      canvas.drawArc(rect, startAngle + (gap / 2), adjustedSweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}
