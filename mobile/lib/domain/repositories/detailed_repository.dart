import 'package:cashlytics/domain/entities/detailed.dart';

abstract class DetailedRepository {
  Future<Detailed?> getDetailedByUserId(String userId);
  Future<Detailed> upsertDetailed(Detailed detailed);
  Future<void> deleteDetailed(String detailedId);
}
