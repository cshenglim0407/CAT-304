import 'package:cashlytics/domain/entities/account_budget.dart';
import 'package:cashlytics/core/utils/math_formatter.dart';

/// Data model for account-specific budgets.
class AccountBudgetModel extends AccountBudget {
  const AccountBudgetModel({
    required super.budgetId,
    required super.accountId,
    required super.threshold,
  });

  factory AccountBudgetModel.fromEntity(AccountBudget entity) {
    return AccountBudgetModel(
      budgetId: entity.budgetId,
      accountId: entity.accountId,
      threshold: entity.threshold,
    );
  }

  factory AccountBudgetModel.fromMap(Map<String, dynamic> map) {
    return AccountBudgetModel(
      budgetId: map['budget_id'] as String? ?? '',
      accountId: map['account_id'] as String? ?? '',
      threshold: MathFormatter.parseDouble(map['threshold']) ?? 0.0,
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'budget_id': budgetId,
      'account_id': accountId,
      'threshold': threshold,
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();
}
