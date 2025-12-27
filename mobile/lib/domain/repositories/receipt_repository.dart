import 'package:cashlytics/domain/entities/receipt.dart';

abstract class ReceiptRepository {
  Future<Receipt> upsertReceipt(Receipt receipt);

  Future<String> uploadReceiptImage({
    required Object imageSource,
    required String receiptId,
  });

  Future<Receipt?> getReceiptById(String receiptId);

  Future<String> getSignedReceiptUrl(String storagePath);

  Future<Receipt?> getReceiptByTransactionId(String transactionId);
}
