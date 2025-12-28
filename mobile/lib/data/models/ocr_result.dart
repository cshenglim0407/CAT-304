class OcrResult {
  final String? merchant;
  final double? total;
  final DateTime? date;
  final double? confidence;
  final String? rawText;

  OcrResult({
    this.merchant,
    this.total,
    this.date,
    this.confidence,
    this.rawText,
  });

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    return OcrResult(
      merchant: json['merchant_name'],
      total: json['total_amount'] != null
          ? (json['total_amount'] as num).toDouble()
          : null,
      date: json['expense_date'] != null
          ? DateTime.tryParse(json['expense_date'])
          : null,
      confidence: (json['confidence_score'] as num?)?.toDouble(),
      rawText: json['ocr_raw_text'],
    );
  }
}
