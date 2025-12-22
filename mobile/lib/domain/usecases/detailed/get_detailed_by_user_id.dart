import 'package:cashlytics/domain/entities/detailed.dart';
import 'package:cashlytics/domain/repositories/detailed_repository.dart';

class GetDetailedByUserId {
  const GetDetailedByUserId(this._repository);

  final DetailedRepository _repository;

  Future<Detailed?> call(String userId) => _repository.getDetailedByUserId(userId);
}
