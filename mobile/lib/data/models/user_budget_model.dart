import 'package:cashlytics/domain/entities/user_budget.dart';

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
      threshold: _parseDouble(map['threshold']),
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
