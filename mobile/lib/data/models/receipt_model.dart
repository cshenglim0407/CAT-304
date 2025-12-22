import 'package:cashlytics/domain/entities/receipt.dart';

/// Data model for uploaded receipts.
class ReceiptModel extends Receipt {
  const ReceiptModel({
    super.id,
    required super.transactionId,
    required super.path,
    super.merchantName,
    super.confidenceScore,
    super.ocrRawText,
    super.scannedAt,
  });

  factory ReceiptModel.fromEntity(Receipt entity) {
    return ReceiptModel(
      id: entity.id,
      transactionId: entity.transactionId,
      path: entity.path,
      merchantName: entity.merchantName,
      confidenceScore: entity.confidenceScore,
      ocrRawText: entity.ocrRawText,
      scannedAt: entity.scannedAt,
    );
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['receipt_id'] as String?,
      transactionId: map['transaction_id'] as String? ?? '',
      path: map['path'] as String? ?? '',
      merchantName: map['merchant_name'] as String?,
      confidenceScore: _parseDouble(map['confidence_score']),
      ocrRawText: map['ocr_raw_text'] as String?,
      scannedAt: _parseDateTime(map['scanned_at']),
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      if (id != null) 'receipt_id': id,
      'transaction_id': transactionId,
      'path': path,
      'merchant_name': merchantName,
      'confidence_score': confidenceScore,
      'ocr_raw_text': ocrRawText,
      'scanned_at': scannedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();

  static double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String && raw.isNotEmpty) {
      return double.tryParse(raw);
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}
