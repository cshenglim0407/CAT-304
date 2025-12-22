import 'package:meta/meta.dart';

@immutable
class Account {
  const Account({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.initialBalance = 0,
    this.currentBalance = 0,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String userId;
  final String name;
  final String type;
  final double initialBalance;
  final double currentBalance;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    double? initialBalance,
    double? currentBalance,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.type == type &&
        other.initialBalance == initialBalance &&
        other.currentBalance == currentBalance &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        name,
        type,
        initialBalance,
        currentBalance,
        description,
        createdAt,
        updatedAt,
      );
}
