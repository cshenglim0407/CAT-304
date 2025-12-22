import 'package:cashlytics/domain/repositories/detailed_repository.dart';

class DeleteDetailed {
  const DeleteDetailed(this._repository);

  final DetailedRepository _repository;

  Future<void> call(String detailedId) => _repository.deleteDetailed(detailedId);
}
