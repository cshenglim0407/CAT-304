import 'package:cashlytics/domain/entities/budget.dart';

/// Data model for budgets.
class BudgetModel extends Budget {
  const BudgetModel({
    super.id,
    required super.userId,
    required super.type,
    required super.dateFrom,
    required super.dateTo,
    super.createdAt,
  });

  factory BudgetModel.fromEntity(Budget entity) {
    return BudgetModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      dateFrom: entity.dateFrom,
      dateTo: entity.dateTo,
      createdAt: entity.createdAt,
    );
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['budget_id'] as String?,
      userId: map['user_id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      dateFrom: _parseDate(map['date_from']) ?? DateTime.now(),
      dateTo: _parseDate(map['date_to']) ?? DateTime.now(),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      if (id != null) 'budget_id': id,
      'user_id': userId,
      'type': type,
      'date_from': _formatDate(dateFrom),
      'date_to': _formatDate(dateTo),
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  static String _formatDate(DateTime date) => date.toIso8601String().split('T').first;
}
