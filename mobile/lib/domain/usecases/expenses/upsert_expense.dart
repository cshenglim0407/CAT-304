import 'package:cashlytics/domain/entities/expense.dart';
import 'package:cashlytics/domain/repositories/expense_repository.dart';

class UpsertExpense {
  const UpsertExpense(this._repository);

  final ExpenseRepository _repository;

  Future<Expense> call(Expense expense) => _repository.upsertExpense(expense);
}
