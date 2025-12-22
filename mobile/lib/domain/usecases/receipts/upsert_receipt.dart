import 'package:cashlytics/domain/entities/receipt.dart';
import 'package:cashlytics/domain/repositories/receipt_repository.dart';

class UpsertReceipt {
  const UpsertReceipt(this._repository);

  final ReceiptRepository _repository;

  Future<Receipt> call(Receipt receipt) => _repository.upsertReceipt(receipt);
}
