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
      amount: _parseDouble(map['amount']),
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
