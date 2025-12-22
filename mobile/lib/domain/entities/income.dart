import 'package:meta/meta.dart';

@immutable
class Income {
  const Income({
    required this.transactionId,
    required this.amount,
    this.category,
    this.isRecurrent = false,
  });

  final String transactionId;
  final double amount;
  final String? category;
  final bool isRecurrent;

  Income copyWith({
    String? transactionId,
    double? amount,
    String? category,
    bool? isRecurrent,
  }) {
    return Income(
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isRecurrent: isRecurrent ?? this.isRecurrent,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Income &&
        other.transactionId == transactionId &&
        other.amount == amount &&
        other.category == category &&
        other.isRecurrent == isRecurrent;
  }

  @override
  int get hashCode => Object.hash(
        transactionId,
        amount,
        category,
        isRecurrent,
      );
}
