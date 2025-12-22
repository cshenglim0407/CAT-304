import 'package:cashlytics/domain/entities/category_budget.dart';
import 'package:cashlytics/domain/repositories/category_budget_repository.dart';

class UpsertCategoryBudget {
  const UpsertCategoryBudget(this._repository);

  final CategoryBudgetRepository _repository;

  Future<CategoryBudget> call(CategoryBudget categoryBudget) => 
      _repository.upsertCategoryBudget(categoryBudget);
}
