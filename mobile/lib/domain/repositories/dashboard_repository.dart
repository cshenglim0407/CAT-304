import 'package:cashlytics/domain/entities/weekly_balance.dart';

abstract class DashboardRepository {
  Future<List<WeeklyBalance>> getMonthlyWeeklyBalances(String userId, DateTime month);
}
