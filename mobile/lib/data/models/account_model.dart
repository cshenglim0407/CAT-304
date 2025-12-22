import 'package:cashlytics/domain/entities/account.dart';

/// Data model for account rows.
class AccountModel extends Account {
  const AccountModel({
    super.id,
    required super.userId,
    required super.name,
    required super.type,
    super.initialBalance = 0,
    super.currentBalance = 0,
    super.description,
    super.createdAt,
    super.updatedAt,
  });

  factory AccountModel.fromEntity(Account entity) {
    return AccountModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      type: entity.type,
      initialBalance: entity.initialBalance,
      currentBalance: entity.currentBalance,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['account_id'] as String?,
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      initialBalance: _parseDouble(map['initial_balance']),
      currentBalance: _parseDouble(map['current_balance']),
      description: map['description'] as String?,
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      if (id != null) 'account_id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'description': description,
    };
  }

  Map<String, dynamic> toUpdate() {
    return {
      if (id != null) 'account_id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'description': description,
    };
  }

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

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}
