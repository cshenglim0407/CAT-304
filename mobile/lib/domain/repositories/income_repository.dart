import 'package:cashlytics/domain/entities/income.dart';

abstract class IncomeRepository {
  Future<Income> upsertIncome(Income income);
}
