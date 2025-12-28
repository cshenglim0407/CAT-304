import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:cashlytics/core/config/env_config.dart';
import 'package:cashlytics/data/models/ocr_result.dart';

class OCRService {
  static late EnvConfigResult envConfig;
  static late OCRService _ocrService;

  static Future<void> initialize() async {
    envConfig = await EnvConfig.load();
    _ocrService = OCRService();
  }

  static OCRService get instance => _ocrService;

  Future<OcrResult> scanReceipt(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(envConfig.ocrEndpoint),
    );

    request.files.add(
      await http.MultipartFile.fromPath('receipt', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      debugPrint(
        'OCR Service Error: ${response.statusCode} - ${response.body}',
      );
      throw Exception('OCR failed: ${response.body}');
    }

    return OcrResult.fromJson(json.decode(response.body));
  }

  Future<OcrResult> scanReceiptFromBytes(
    List<int> imageBytes,
    String filename,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(envConfig.ocrEndpoint),
    );

    request.files.add(
      http.MultipartFile.fromBytes('receipt', imageBytes, filename: filename),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      debugPrint(
        'OCR Service Error: ${response.statusCode} - ${response.body}',
      );
      throw Exception('OCR failed: ${response.body}');
    }

    return OcrResult.fromJson(json.decode(response.body));
  }
}
