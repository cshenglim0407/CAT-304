import 'package:cashlytics/domain/entities/expense.dart';

abstract class ExpenseRepository {
  Future<Expense> upsertExpense(Expense expense);
}
