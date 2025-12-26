import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/domain/entities/transfer.dart';

/// Data model for transfer transactions.
class TransferModel extends Transfer {
  const TransferModel({
    required super.transactionId,
    required super.amount,
    required super.fromAccountId,
    required super.toAccountId,
  });

  factory TransferModel.fromEntity(Transfer entity) {
    return TransferModel(
      transactionId: entity.transactionId,
      amount: entity.amount,
      fromAccountId: entity.fromAccountId,
      toAccountId: entity.toAccountId,
    );
  }

  factory TransferModel.fromMap(Map<String, dynamic> map) {
    return TransferModel(
      transactionId: map['transaction_id'] as String? ?? '',
      amount: MathFormatter.parseDouble(map['amount']) ?? 0.0,
      fromAccountId: map['from_account_id'] as String? ?? '',
      toAccountId: map['to_account_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'transaction_id': transactionId,
      'amount': amount,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();
}
