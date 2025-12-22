import 'package:meta/meta.dart';

@immutable
class Budget {
  const Budget({
    this.id,
    required this.userId,
    required this.type,
    required this.dateFrom,
    required this.dateTo,
    this.createdAt,
  });

  final String? id;
  final String userId;
  final String type;
  final DateTime dateFrom;
  final DateTime dateTo;
  final DateTime? createdAt;

  Budget copyWith({
    String? id,
    String? userId,
    String? type,
    DateTime? dateFrom,
    DateTime? dateTo,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        type,
        dateFrom,
        dateTo,
        createdAt,
      );
}
