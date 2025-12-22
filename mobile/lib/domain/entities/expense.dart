import 'package:meta/meta.dart';

@immutable
class Expense {
  const Expense({
    required this.transactionId,
    required this.amount,
    this.expenseCategoryId,
  });

  final String transactionId;
  final double amount;
  final String? expenseCategoryId;

  Expense copyWith({
    String? transactionId,
    double? amount,
    String? expenseCategoryId,
  }) {
    return Expense(
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      expenseCategoryId: expenseCategoryId ?? this.expenseCategoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.transactionId == transactionId &&
        other.amount == amount &&
        other.expenseCategoryId == expenseCategoryId;
  }

  @override
  int get hashCode => Object.hash(transactionId, amount, expenseCategoryId);
}
