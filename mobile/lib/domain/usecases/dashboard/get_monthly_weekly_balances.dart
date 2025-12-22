import 'package:cashlytics/domain/entities/weekly_balance.dart';
import 'package:cashlytics/domain/repositories/dashboard_repository.dart';

class GetMonthlyWeeklyBalances {
  const GetMonthlyWeeklyBalances(this._repository);

  final DashboardRepository _repository;

  Future<List<WeeklyBalance>> call(String userId, DateTime month) =>
      _repository.getMonthlyWeeklyBalances(userId, month);
}
