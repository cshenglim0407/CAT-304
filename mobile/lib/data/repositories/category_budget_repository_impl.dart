import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/category_budget_model.dart';
import 'package:cashlytics/domain/entities/category_budget.dart';
import 'package:cashlytics/domain/repositories/category_budget_repository.dart';

class CategoryBudgetRepositoryImpl implements CategoryBudgetRepository {
  CategoryBudgetRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'category_budget';

  @override
  Future<CategoryBudget> upsertCategoryBudget(CategoryBudget categoryBudget) async {
    final model = CategoryBudgetModel.fromEntity(categoryBudget);

    final upsertData = await _databaseService.upsert(
      _table,
      [model.toInsert()],
      onConflict: 'budget_id',
    );

    if (upsertData.isEmpty) {
      throw Exception('Failed to upsert category budget');
    }

    return CategoryBudgetModel.fromMap(upsertData.first);
  }
}
