import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/domain/entities/income.dart';

/// Data model for income transactions.
class IncomeModel extends Income {
  const IncomeModel({
    required super.transactionId,
    required super.amount,
    super.category,
    super.isRecurrent = false,
  });

  factory IncomeModel.fromEntity(Income entity) {
    return IncomeModel(
      transactionId: entity.transactionId,
      amount: entity.amount,
      category: entity.category,
      isRecurrent: entity.isRecurrent,
    );
  }

  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      transactionId: map['transaction_id'] as String? ?? '',
      amount: MathFormatter.parseDouble(map['amount']) ?? 0.0,
      category: map['category'] as String?,
      isRecurrent: map['is_recurrent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'transaction_id': transactionId,
      'amount': amount,
      'category': category,
      'is_recurrent': isRecurrent,
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();
}
