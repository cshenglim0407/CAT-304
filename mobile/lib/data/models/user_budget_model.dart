import 'package:cashlytics/domain/entities/user_budget.dart';
import 'package:cashlytics/core/utils/math_formatter.dart';

/// Data model for user-level budgets.
class UserBudgetModel extends UserBudget {
  const UserBudgetModel({
    required super.budgetId,
    required super.threshold,
  });

  factory UserBudgetModel.fromEntity(UserBudget entity) {
    return UserBudgetModel(
      budgetId: entity.budgetId,
      threshold: entity.threshold,
    );
  }

  factory UserBudgetModel.fromMap(Map<String, dynamic> map) {
    return UserBudgetModel(
      budgetId: map['budget_id'] as String? ?? '',
      threshold: MathFormatter.parseDouble(map['threshold']) ?? 0.0,
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'budget_id': budgetId,
      'threshold': threshold,
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();
}
