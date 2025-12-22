import 'package:cashlytics/domain/entities/budget.dart';
import 'package:cashlytics/domain/repositories/budget_repository.dart';

class UpsertBudget {
  const UpsertBudget(this._repository);

  final BudgetRepository _repository;

  Future<Budget> call(Budget budget) => _repository.upsertBudget(budget);
}
