import 'package:cashlytics/domain/entities/transfer.dart';

abstract class TransferRepository {
  Future<Transfer> upsertTransfer(Transfer transfer);
}
