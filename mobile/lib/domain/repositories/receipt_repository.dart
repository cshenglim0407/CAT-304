import 'package:cashlytics/domain/entities/receipt.dart';

abstract class ReceiptRepository {
  Future<Receipt> upsertReceipt(Receipt receipt);
}
