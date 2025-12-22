import 'package:cashlytics/domain/entities/quarterly_balance.dart';
import 'package:cashlytics/domain/repositories/dashboard_repository.dart';

class GetYearlyQuarterlyBalances {
  const GetYearlyQuarterlyBalances(this._repository);

  final DashboardRepository _repository;

  Future<List<QuarterlyBalance>> call(String userId, int year) =>
      _repository.getYearlyQuarterlyBalances(userId, year);
}
