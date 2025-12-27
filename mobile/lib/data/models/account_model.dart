import 'package:cashlytics/domain/entities/account.dart';
import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/core/utils/date_formatter.dart';

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
      initialBalance: MathFormatter.parseDouble(map['initial_balance']) ?? 0.0,
      currentBalance: MathFormatter.parseDouble(map['current_balance']) ?? 0.0,
      description: map['description'] as String?,
      createdAt: DateFormatter.parseDateTime(map['created_at']),
      updatedAt: DateFormatter.parseDateTime(map['updated_at']),
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
}
