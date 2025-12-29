import 'package:meta/meta.dart';

@immutable
class TransactionRecord {
  const TransactionRecord({
    this.id,
    required this.accountId,
    required this.name,
    required this.type,
    this.description,
    this.currency,
    this.createdAt,
    this.updatedAt,
    this.spentAt
  });

  final String? id;
  final String accountId;
  final String name;
  final String type;
  final String? description;
  final String? currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? spentAt;

  TransactionRecord copyWith({
    String? id,
    String? accountId,
    String? name,
    String? type,
    String? description,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? spentAt,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      spentAt: spentAt ?? this.spentAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionRecord &&
        other.id == id &&
        other.accountId == accountId &&
        other.name == name &&
        other.type == type &&
        other.description == description &&
        other.currency == currency &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.spentAt == spentAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        accountId,
        name,
        type,
        description,
        currency,
        createdAt,
        updatedAt,
        spentAt,
      );
}
