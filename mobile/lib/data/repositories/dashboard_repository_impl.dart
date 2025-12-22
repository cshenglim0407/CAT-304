import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/weekly_balance_model.dart';
import 'package:cashlytics/data/models/quarterly_balance_model.dart';
import 'package:cashlytics/domain/entities/weekly_balance.dart';
import 'package:cashlytics/domain/entities/quarterly_balance.dart';
import 'package:cashlytics/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Future<List<WeeklyBalance>> getMonthlyWeeklyBalances(
    String userId,
    DateTime month,
  ) async {
    // Get first and last day of the month
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final now = DateTime.now();

    // Calculate which week we're currently in (if we're in this month)
    final isCurrentMonth = now.year == month.year && now.month == month.month;
    final currentDay = isCurrentMonth ? now.day : lastDayOfMonth.day;

    // Execute RPC function to get weekly balances
    final response = await _databaseService.rpc(
      'get_monthly_weekly_balances',
      params: {
        'p_user_id': userId,
        'p_year': month.year,
        'p_month': month.month,
        'p_current_day': currentDay,
      },
    );

    if (response == null || response is! List) {
      throw Exception('Failed to fetch weekly balances');
    }

    final weeklyBalances = (response)
        .map((item) => WeeklyBalanceModel.fromMap(item as Map<String, dynamic>))
        .toList();

    // If we're in the current month and haven't completed all 4 weeks yet,
    // fill remaining weeks with empty data
    if (isCurrentMonth && weeklyBalances.length < 4) {
      final existingWeeks = weeklyBalances.map((w) => w.weekNumber).toSet();

      for (int week = 1; week <= 4; week++) {
        if (!existingWeeks.contains(week)) {
          // Calculate week start and end dates
          final weekStart = firstDayOfMonth.add(Duration(days: (week - 1) * 7));
          final weekEnd = DateTime(month.year, month.month, weekStart.day + 6);

          // Only add if week hasn't started yet
          if (weekStart.isAfter(now)) {
            weeklyBalances.add(
              WeeklyBalanceModel(
                weekNumber: week,
                startDate: weekStart,
                endDate: weekEnd.isAfter(lastDayOfMonth)
                    ? lastDayOfMonth
                    : weekEnd,
                totalIncome: 0.0,
                totalExpense: 0.0,
                balance: 0.0,
                isCurrentWeek: false,
              ),
            );
          }
        }
      }

      // Sort by week number
      weeklyBalances.sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
    }

    return weeklyBalances;
  }

  @override
  Future<List<QuarterlyBalance>> getYearlyQuarterlyBalances(
    String userId,
    int year,
  ) async {
    final now = DateTime.now();

    // Calculate which quarter we're currently in (if we're in this year)
    final isCurrentYear = now.year == year;
    final currentQuarter = isCurrentYear ? ((now.month - 1) ~/ 3) + 1 : 4;

    // Execute RPC function to get quarterly balances
    final response = await _databaseService.rpc(
      'get_yearly_quarterly_balances',
      params: {
        'p_user_id': userId,
        'p_year': year,
        'p_current_quarter': currentQuarter,
      },
    );

    if (response == null || response is! List) {
      throw Exception('Failed to fetch quarterly balances');
    }

    final quarterlyBalances = (response)
        .map((item) => QuarterlyBalanceModel.fromMap(item as Map<String, dynamic>))
        .toList();

    // If we're in the current year and haven't completed all 4 quarters yet,
    // fill remaining quarters with empty data
    if (isCurrentYear && quarterlyBalances.length < 4) {
      final existingQuarters = quarterlyBalances.map((q) => q.quarterNumber).toSet();

      for (int quarter = 1; quarter <= 4; quarter++) {
        if (!existingQuarters.contains(quarter)) {
          // Calculate quarter start and end dates
          final quarterStartMonth = (quarter - 1) * 3 + 1;
          final quarterStart = DateTime(year, quarterStartMonth, 1);
          final quarterEnd = DateTime(year, quarterStartMonth + 2 + 1, 0);

          // Only add if quarter hasn't started yet
          if (quarter > currentQuarter) {
            quarterlyBalances.add(
              QuarterlyBalanceModel(
                quarterNumber: quarter,
                startDate: quarterStart,
                endDate: quarterEnd,
                totalIncome: 0.0,
                totalExpense: 0.0,
                balance: 0.0,
                isCurrentQuarter: false,
              ),
            );
          }
        }
      }

      // Sort by quarter number
      quarterlyBalances.sort((a, b) => a.quarterNumber.compareTo(b.quarterNumber));
    }

    return quarterlyBalances;
  }
}
