import 'package:cashlytics/domain/entities/weekly_balance.dart';
import 'package:cashlytics/domain/entities/quarterly_balance.dart';

abstract class DashboardRepository {
  Future<List<WeeklyBalance>> getMonthlyWeeklyBalances(String userId, DateTime month);
  Future<List<QuarterlyBalance>> getYearlyQuarterlyBalances(String userId, int year);
}
