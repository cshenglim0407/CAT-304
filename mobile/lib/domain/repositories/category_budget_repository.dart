import 'package:cashlytics/domain/entities/category_budget.dart';

abstract class CategoryBudgetRepository {
  Future<CategoryBudget> upsertCategoryBudget(CategoryBudget categoryBudget);
}
