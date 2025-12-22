import 'package:cashlytics/domain/entities/ai_report.dart';

abstract class AiReportRepository {
  Future<AiReport> upsertAiReport(AiReport report);
}
