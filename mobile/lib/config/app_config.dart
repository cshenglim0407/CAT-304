class AppConfig {
  static const String ocrBaseUrl = String.fromEnvironment(
    'OCR_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static String get ocrEndpoint => '$ocrBaseUrl/ocr';
}
