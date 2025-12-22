import 'package:meta/meta.dart';

@immutable
class Transfer {
  const Transfer({
    required this.transactionId,
    required this.amount,
    required this.fromAccountId,
    required this.toAccountId,
  });

  final String transactionId;
  final double amount;
  final String fromAccountId;
  final String toAccountId;

  Transfer copyWith({
    String? transactionId,
    double? amount,
    String? fromAccountId,
    String? toAccountId,
  }) {
    return Transfer(
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transfer &&
        other.transactionId == transactionId &&
        other.amount == amount &&
        other.fromAccountId == fromAccountId &&
        other.toAccountId == toAccountId;
  }

  @override
  int get hashCode => Object.hash(
        transactionId,
        amount,
        fromAccountId,
        toAccountId,
      );
}
