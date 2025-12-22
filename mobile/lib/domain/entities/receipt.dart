import 'package:meta/meta.dart';

@immutable
class Receipt {
  const Receipt({
    this.id,
    required this.transactionId,
    required this.path,
    this.merchantName,
    this.confidenceScore,
    this.ocrRawText,
    this.scannedAt,
  });

  final String? id;
  final String transactionId;
  final String path;
  final String? merchantName;
  final double? confidenceScore;
  final String? ocrRawText;
  final DateTime? scannedAt;

  Receipt copyWith({
    String? id,
    String? transactionId,
    String? path,
    String? merchantName,
    double? confidenceScore,
    String? ocrRawText,
    DateTime? scannedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      path: path ?? this.path,
      merchantName: merchantName ?? this.merchantName,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Receipt &&
        other.id == id &&
        other.transactionId == transactionId &&
        other.path == path &&
        other.merchantName == merchantName &&
        other.confidenceScore == confidenceScore &&
        other.ocrRawText == ocrRawText &&
        other.scannedAt == scannedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        transactionId,
        path,
        merchantName,
        confidenceScore,
        ocrRawText,
        scannedAt,
      );
}
