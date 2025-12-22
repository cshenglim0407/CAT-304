import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/ai_report_model.dart';
import 'package:cashlytics/domain/entities/ai_report.dart';
import 'package:cashlytics/domain/repositories/ai_report_repository.dart';

class AiReportRepositoryImpl implements AiReportRepository {
  AiReportRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'ai_report';

  @override
  Future<AiReport> upsertAiReport(AiReport report) async {
    final model = AiReportModel.fromEntity(report);
    final bool isInsert = report.id == null;

    if (isInsert) {
      final insertData = await _databaseService.insert(
        _table,
        model.toInsert(),
      );

      if (insertData == null) {
        throw Exception('Failed to insert AI report');
      }

      return AiReportModel.fromMap(insertData);
    } else {
      final updateData = await _databaseService.updateById(
        _table,
        matchColumn: 'report_id',
        matchValue: report.id!,
        values: model.toUpdate(),
      );

      if (updateData == null) {
        throw Exception('Failed to update AI report');
      }

      return AiReportModel.fromMap(updateData);
    }
  }
}
