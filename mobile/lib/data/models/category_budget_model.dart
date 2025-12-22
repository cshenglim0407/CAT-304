import 'package:cashlytics/domain/entities/category_budget.dart';

/// Data model for category-specific budgets.
class CategoryBudgetModel extends CategoryBudget {
  const CategoryBudgetModel({
    required super.budgetId,
    required super.expenseCategoryId,
    required super.threshold,
  });

  factory CategoryBudgetModel.fromEntity(CategoryBudget entity) {
    return CategoryBudgetModel(
      budgetId: entity.budgetId,
      expenseCategoryId: entity.expenseCategoryId,
      threshold: entity.threshold,
    );
  }

  factory CategoryBudgetModel.fromMap(Map<String, dynamic> map) {
    return CategoryBudgetModel(
      budgetId: map['budget_id'] as String? ?? '',
      expenseCategoryId: map['expense_cat_id'] as String? ?? '',
      threshold: _parseDouble(map['threshold']),
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'budget_id': budgetId,
      'expense_cat_id': expenseCategoryId,
      'threshold': threshold,
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();

  static double _parseDouble(dynamic raw) {
    if (raw == null) return 0;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String && raw.isNotEmpty) {
      return double.tryParse(raw) ?? 0;
    }
    return 0;
  }
}
