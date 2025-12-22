import 'package:cashlytics/domain/entities/income.dart';
import 'package:cashlytics/domain/repositories/income_repository.dart';

class UpsertIncome {
  const UpsertIncome(this._repository);

  final IncomeRepository _repository;

  Future<Income> call(Income income) => _repository.upsertIncome(income);
}
