import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/ai_report_model.dart';
import 'package:cashlytics/domain/entities/ai_report.dart';
import 'package:cashlytics/domain/repositories/ai_report_repository.dart';
import 'package:flutter/foundation.dart';

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

  @override
  Future<AiReport?> getLatestReport(String userId) async {
    try {
      final results = await _databaseService.fetchAll(
        _table,
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      return AiReportModel.fromMap(results.first);
    } catch (e) {
      debugPrint('Error fetching latest AI report: $e');
      return null;
    }
  }

  @override
  Future<AiReport?> getReportByMonth(String userId, String month) async {
    try {
      final results = await _databaseService.fetchAll(
        _table,
        filters: {'user_id': userId, 'month': month},
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      return AiReportModel.fromMap(results.first);
    } catch (e) {
      debugPrint('Error fetching AI report for month $month: $e');
      return null;
    }
  }
}
