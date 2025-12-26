import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:cashlytics/data/models/ocr_result.dart';
import 'package:cashlytics/config/app_config.dart';

class OCRService {
  Future<OcrResult> scanReceipt(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConfig.ocrEndpoint),
    );

    request.files.add(
      await http.MultipartFile.fromPath('receipt', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('OCR failed: ${response.body}');
    }

    return OcrResult.fromJson(json.decode(response.body));
  }
}
