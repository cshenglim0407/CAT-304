import 'package:cashlytics/domain/entities/ai_report.dart';
import 'package:cashlytics/domain/repositories/ai_report_repository.dart';

class UpsertAiReport {
  const UpsertAiReport(this._repository);

  final AiReportRepository _repository;

  Future<AiReport> call(AiReport report) => _repository.upsertAiReport(report);
}
