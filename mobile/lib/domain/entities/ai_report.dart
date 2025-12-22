import 'package:meta/meta.dart';

@immutable
class AiReport {
  const AiReport({
    this.id,
    required this.userId,
    this.title,
    this.description,
    this.body,
    this.month,
    this.healthScore,
    this.createdAt,
  });

  final String? id;
  final String userId;
  final String? title;
  final String? description;
  final String? body;
  final String? month;
  final int? healthScore;
  final DateTime? createdAt;

  AiReport copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? body,
    String? month,
    int? healthScore,
    DateTime? createdAt,
  }) {
    return AiReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      body: body ?? this.body,
      month: month ?? this.month,
      healthScore: healthScore ?? this.healthScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiReport &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.body == body &&
        other.month == month &&
        other.healthScore == healthScore &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        title,
        description,
        body,
        month,
        healthScore,
        createdAt,
      );
}
