import 'package:cashlytics/domain/entities/detailed.dart';
import 'package:cashlytics/domain/repositories/detailed_repository.dart';

class UpsertDetailed {
  const UpsertDetailed(this._repository);

  final DetailedRepository _repository;

  Future<Detailed> call(Detailed detailed) => _repository.upsertDetailed(detailed);
}
