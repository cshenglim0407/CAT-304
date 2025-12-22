import 'package:cashlytics/domain/entities/budget.dart';

abstract class BudgetRepository {
  Future<Budget> upsertBudget(Budget budget);
  Future<void> deleteBudget(String budgetId);
}
