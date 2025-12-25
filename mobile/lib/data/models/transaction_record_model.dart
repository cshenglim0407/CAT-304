import 'package:cashlytics/domain/entities/transaction_record.dart';

/// Data model for transactions linked to accounts.
class TransactionRecordModel extends TransactionRecord {
  const TransactionRecordModel({
    super.id,
    required super.accountId,
    required super.name,
    required super.type,
    super.description,
    super.currency,
    super.createdAt,
    super.updatedAt,
  });

  factory TransactionRecordModel.fromEntity(TransactionRecord entity) {
    return TransactionRecordModel(
      id: entity.id,
      accountId: entity.accountId,
      name: entity.name,
      type: entity.type,
      description: entity.description,
      currency: entity.currency,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory TransactionRecordModel.fromMap(Map<String, dynamic> map) {
    return TransactionRecordModel(
      id: map['transaction_id'] as String?,
      accountId: map['account_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      description: map['description'] as String?,
      currency: map['currency'] as String?,
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'transaction_id': id, // Always include ID (it's generated before calling this)
      'account_id': accountId,
      'name': name,
      'type': type,
      'description': description,
      'currency': currency,
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}
