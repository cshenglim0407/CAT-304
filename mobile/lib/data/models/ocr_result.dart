class OcrResult {
  final double? total;
  final DateTime? date;
  final String? rawText;

  OcrResult({this.total, this.date, this.rawText});

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    return OcrResult(
      total: json['total_amount'] != null
          ? (json['total_amount'] as num).toDouble()
          : null,
      date: json['expense_date'] != null
          ? DateTime.tryParse(json['expense_date'])
          : null,
      rawText: json['ocr_raw_text'],
    );
  }
}
