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
      amount: _parseDouble(map['amount']),
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
