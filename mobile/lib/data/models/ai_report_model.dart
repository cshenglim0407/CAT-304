import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/domain/entities/ai_report.dart';

/// Data model for AI financial health reports.
class AiReportModel extends AiReport {
  const AiReportModel({
    super.id,
    required super.userId,
    super.title,
    super.insights,
    super.body,
    super.month,
    super.healthScore,
    super.createdAt,
  });

  factory AiReportModel.fromEntity(AiReport entity) {
    return AiReportModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      insights: entity.insights,
      body: entity.body,
      month: entity.month,
      healthScore: entity.healthScore,
      createdAt: entity.createdAt,
    );
  }

  factory AiReportModel.fromMap(Map<String, dynamic> map) {
    return AiReportModel(
      id: map['report_id'] as String?,
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String?,
      insights: (map['insights'] as String?),
      body: map['body'] as String?,
      month: map['month'] as String?,
      healthScore: map['health_score'] as int?,
      createdAt: MathFormatter.parseDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      if (id != null) 'report_id': id,
      'user_id': userId,
      'title': title,
      'insights': insights,
      'body': body,
      'month': month,
      'health_score': healthScore,
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();

  
}
