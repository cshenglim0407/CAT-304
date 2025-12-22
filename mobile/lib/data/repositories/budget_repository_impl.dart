import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/budget_model.dart';
import 'package:cashlytics/domain/entities/budget.dart';
import 'package:cashlytics/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'budget';

  @override
  Future<Budget> upsertBudget(Budget budget) async {
    final model = BudgetModel.fromEntity(budget);
    final bool isInsert = budget.id == null;

    if (isInsert) {
      final insertData = await _databaseService.insert(
        _table,
        model.toInsert(),
      );

      if (insertData == null) {
        throw Exception('Failed to insert budget');
      }

      return BudgetModel.fromMap(insertData);
    } else {
      final updateData = await _databaseService.updateById(
        _table,
        matchColumn: 'budget_id',
        matchValue: budget.id!,
        values: model.toUpdate(),
      );

      if (updateData == null) {
        throw Exception('Failed to update budget');
      }

      return BudgetModel.fromMap(updateData);
    }
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    await _databaseService.deleteById(
      _table,
      matchColumn: 'budget_id',
      matchValue: budgetId,
    );
  }
}
