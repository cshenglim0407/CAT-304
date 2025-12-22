import 'package:cashlytics/domain/repositories/budget_repository.dart';

class DeleteBudget {
  const DeleteBudget(this._repository);

  final BudgetRepository _repository;

  Future<void> call(String budgetId) => _repository.deleteBudget(budgetId);
}
