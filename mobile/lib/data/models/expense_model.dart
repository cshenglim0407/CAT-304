import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/domain/entities/expense.dart';

/// Data model for expenses.
class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.transactionId,
    required super.amount,
    super.expenseCategoryId,
  });

  factory ExpenseModel.fromEntity(Expense entity) {
    return ExpenseModel(
      transactionId: entity.transactionId,
      amount: entity.amount,
      expenseCategoryId: entity.expenseCategoryId,
    );
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      transactionId: map['transaction_id'] as String? ?? '',
      amount: MathFormatter.parseDouble(map['amount']) ?? 0.0,
      expenseCategoryId: map['expense_cat_id'] as String?,
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'transaction_id': transactionId,
      'amount': amount,
      'expense_cat_id': expenseCategoryId,
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();
}
