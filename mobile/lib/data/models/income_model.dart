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
      amount: _parseDouble(map['amount']),
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
