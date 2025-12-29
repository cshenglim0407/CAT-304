import 'package:cashlytics/core/utils/date_formatter.dart';
import 'package:cashlytics/domain/entities/receipt.dart';

/// Data model for uploaded receipts.
class ReceiptModel extends Receipt {
  const ReceiptModel({
    super.id,
    required super.transactionId,
    required super.path,
    super.ocrRawText,
    super.scannedAt,
  });

  factory ReceiptModel.fromEntity(Receipt entity) {
    return ReceiptModel(
      id: entity.id,
      transactionId: entity.transactionId,
      path: entity.path,
      ocrRawText: entity.ocrRawText,
      scannedAt: entity.scannedAt,
    );
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['receipt_id'] as String?,
      transactionId: map['transaction_id'] as String? ?? '',
      path: map['path'] as String? ?? '',
      ocrRawText: map['ocr_raw_text'] as String?,
      scannedAt: DateFormatter.parseDateTime(map['scanned_at']),
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      if (id != null) 'receipt_id': id,
      'transaction_id': transactionId,
      'path': path,
      'ocr_raw_text': ocrRawText,
      'scanned_at': scannedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();
}
