import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/ocr_result.dart';

class OCRService {
  static const String ocrUrl = 'http://10.0.2.2:8000/ocr';

  static Future<OcrResult> scanReceipt(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(ocrUrl));

    request.files.add(
      await http.MultipartFile.fromPath('receipt', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('OCR failed: ${response.body}');
    }

    final Map<String, dynamic> jsonBody = json.decode(response.body);
    return OcrResult.fromJson(jsonBody);
  }
}
