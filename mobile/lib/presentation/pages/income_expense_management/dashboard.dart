import 'dart:async';

import 'package:cashlytics/core/services/supabase/auth/auth_state_listener.dart';
import 'package:cashlytics/presentation/pages/user_management/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/services/supabase/auth/auth_service.dart';

import 'package:cashlytics/domain/repositories/dashboard_repository.dart';
import 'package:cashlytics/data/repositories/dashboard_repository_impl.dart';
import 'package:cashlytics/domain/usecases/dashboard/get_monthly_weekly_balances.dart';
import 'package:cashlytics/domain/usecases/dashboard/get_yearly_quarterly_balances.dart';
import 'package:cashlytics/domain/entities/weekly_balance.dart';
import 'package:cashlytics/domain/entities/quarterly_balance.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0; // Home is always 0

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

  // --- AI Suggestions Modal ---
  void _showAISuggestions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 28,
                    ),
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

              // Health Score
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                            value: 0.85,
                            strokeWidth: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          "85",
                          style: AppTypography.headline3.copyWith(
                            color: AppColors.primary,
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
                            "Excellent Health",
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "You are in the top 15% of savers this month! Keep it up.",
                            style: AppTypography.caption.copyWith(
                              color: AppColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 30),

              // Suggestions
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    _SuggestionTile(
                      title: "Unusual Spending Detected",
                      body:
                          "Your spending on 'Food & Dining' is 15% higher than your average for this week.",
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    _SuggestionTile(
                      title: "Savings Opportunity",
                      body:
                          "Based on your cash flow, you could safely move \$300 to your savings account today.",
                      icon: Icons.savings_outlined,
                      color: Colors.green,
                    ),
                    _SuggestionTile(
                      title: "Subscription Alert",
                      body:
                          "You have a recurring payment for 'Streaming Service' coming up tomorrow.",
                      icon: Icons.calendar_today_rounded,
                      color: Colors.blue,
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

  late final DashboardRepository _dashboardRepository;
  late final GetMonthlyWeeklyBalances _getMonthlyWeeklyBalances;
  late final GetYearlyQuarterlyBalances _getYearlyQuarterlyBalances;
  late final AuthService _authService;

  bool _redirecting = false;
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _dashboardRepository = DashboardRepositoryImpl();
    _getMonthlyWeeklyBalances = GetMonthlyWeeklyBalances(_dashboardRepository);
    _getYearlyQuarterlyBalances = GetYearlyQuarterlyBalances(_dashboardRepository);
    _authService = AuthService();
    _loadData();

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
          final balances = await _getMonthlyWeeklyBalances(user.id, now);
          setState(() {
            _weeklyBalances = balances;
            _quarterlyBalances = [];
            _isLoading = false;
          });
          break;

        case 'Last month':
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          final balances = await _getMonthlyWeeklyBalances(user.id, lastMonth);
          setState(() {
            _weeklyBalances = balances;
            _quarterlyBalances = [];
            _isLoading = false;
          });
          break;

        case 'This year':
          final balances = await _getYearlyQuarterlyBalances(user.id, now.year);
          setState(() {
            _quarterlyBalances = balances;
            _weeklyBalances = [];
            _isLoading = false;
          });
          break;

        case 'Last year':
          final balances = await _getYearlyQuarterlyBalances(user.id, now.year - 1);
          setState(() {
            _quarterlyBalances = balances;
            _weeklyBalances = [];
            _isLoading = false;
          });
          break;

        default:
          setState(() {
            _isLoading = false;
            _weeklyBalances = [];
            _quarterlyBalances = [];
          });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _weeklyBalances = [];
        _quarterlyBalances = [];
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
      return _quarterlyBalances.fold(0.0, (sum, quarter) => sum + quarter.balance);
    }
    return 0.0;
  }

  String _calculatePercentageChange() {
    List<double> balances;
    
    if (_weeklyBalances.isNotEmpty) {
      balances = _weeklyBalances.map((w) => w.balance).toList();
    } else if (_quarterlyBalances.isNotEmpty) {
      balances = _quarterlyBalances.map((q) => q.balance).toList();
    } else {
      return '+0.0%';
    }

    if (balances.isEmpty) return '+0.0%';

    // Calculate change based on first vs last available period
    final first = balances.first;
    final last = balances.last;

    if (first == 0) return '+0.0%';

    final change = ((last - first) / first.abs()) * 100;
    return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
  }

  Color _getPercentageColor() {
    List<double> balances;
    
    if (_weeklyBalances.isNotEmpty) {
      balances = _weeklyBalances.map((w) => w.balance).toList();
    } else if (_quarterlyBalances.isNotEmpty) {
      balances = _quarterlyBalances.map((q) => q.balance).toList();
    } else {
      return AppColors.greyText;
    }

    if (balances.isEmpty) return AppColors.greyText;

    final first = balances.first;
    final last = balances.last;

    return last >= first ? AppColors.success : Colors.red;
  }

  List<double> _getChartData() {
    List<double> balances;
    
    if (_weeklyBalances.isNotEmpty) {
      balances = _weeklyBalances.map((w) => w.balance).toList();
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

    return balances
        .map((b) => (b.abs() / maxBalance).clamp(0.1, 1.0))
        .toList();
  }

  List<String> _getLabels() {
    if (_weeklyBalances.isNotEmpty) {
      return _weeklyBalances.map((w) => 'Week ${w.weekNumber}').toList();
    } else if (_quarterlyBalances.isNotEmpty) {
      return _quarterlyBalances.map((q) => 'Q${q.quarterNumber}').toList();
    }
    return ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
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
    final bool useRealData = !_isLoading &&
        (_weeklyBalances.isNotEmpty || _quarterlyBalances.isNotEmpty);

    final currentData = useRealData ? null : _data[_selectedFilter];

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
                    painter: _DynamicLineChartPainter(dataPoints: chartData),
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
    final currentData = _data[_selectedFilter];
    final List<String> labels = currentData['labels'];

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
                onSelected: (value) => setState(() => _selectedFilter = value),
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
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 150,
            width: double.infinity,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "\$8,000",
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.greyText,
                      ),
                    ),
                    Text(
                      "\$6,000",
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.greyText,
                      ),
                    ),
                    Text(
                      "\$4,000",
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.greyText,
                      ),
                    ),
                    Text(
                      "\$2,000",
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.greyText,
                      ),
                    ),
                    Text(
                      "\$0",
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _DynamicBarChartPainter(
                      incomeData: currentData['incomeData'],
                      expenseData: currentData['expenseData'],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.only(left: 45.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Initialize with stripped times
    _selectedRange = DateTimeRange(
      start: _stripTime(now.subtract(const Duration(days: 30))),
      end: _stripTime(now),
    );
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
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _DonutChartPainter()),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Expense Breakdown",
                          style: AppTypography.caption.copyWith(
                            color: AppColors.greyText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "By department",
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
          const _LegendItem(
            color: AppColors.primary,
            label: "Operations",
            pct: "35%",
            amt: "(\$54,600)",
          ),
          const SizedBox(height: 12),
          _LegendItem(
            color: AppColors.primary.withValues(alpha: 0.8),
            label: "Marketing",
            pct: "25%",
            amt: "(\$39,000)",
          ),
          const SizedBox(height: 12),
          _LegendItem(
            color: AppColors.primary.withValues(alpha: 0.6),
            label: "Payroll",
            pct: "20%",
            amt: "(\$31,200)",
          ),
          const SizedBox(height: 12),
          _LegendItem(
            color: AppColors.primary.withValues(alpha: 0.4),
            label: "IT & Tools",
            pct: "12%",
            amt: "(\$18,700)",
          ),
          const SizedBox(height: 12),
          _LegendItem(
            color: AppColors.primary.withValues(alpha: 0.2),
            label: "Others",
            pct: "8%",
            amt: "(\$12,500)",
          ),
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

// --- CUSTOM PAINTERS ---

class _DynamicLineChartPainter extends CustomPainter {
  final List<double> dataPoints;

  _DynamicLineChartPainter({required this.dataPoints});

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
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 16.0;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    void drawSegment(double startAngle, double sweepAngle, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      final gap = 0.05;
      canvas.drawArc(rect, startAngle + gap, sweepAngle - gap, false, paint);
    }

    const fullCircle = 3.14159 * 2;
    double start = -3.14159 / 2;

    double sweep1 = 0.35 * fullCircle;
    drawSegment(start, sweep1, AppColors.primary);
    start += sweep1;

    double sweep2 = 0.25 * fullCircle;
    drawSegment(start, sweep2, AppColors.primary.withValues(alpha: 0.8));
    start += sweep2;

    double sweep3 = 0.20 * fullCircle;
    drawSegment(start, sweep3, AppColors.primary.withValues(alpha: 0.6));
    start += sweep3;

    double sweep4 = 0.12 * fullCircle;
    drawSegment(start, sweep4, AppColors.primary.withValues(alpha: 0.4));
    start += sweep4;

    double sweep5 = 0.08 * fullCircle;
    drawSegment(start, sweep5, AppColors.primary.withValues(alpha: 0.2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
