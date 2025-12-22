import 'package:cashlytics/domain/entities/transfer.dart';
import 'package:cashlytics/domain/repositories/transfer_repository.dart';

class UpsertTransfer {
  const UpsertTransfer(this._repository);

  final TransferRepository _repository;

  Future<Transfer> call(Transfer transfer) => _repository.upsertTransfer(transfer);
}
