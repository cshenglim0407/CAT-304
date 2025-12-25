import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OCRService {
  static const String ocrUrl = 'http://10.0.2.2:8000/ocr';
  // ⚠️ Use LAN IP if testing on physical device

  static Future<Map<String, dynamic>> scanReceipt(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(ocrUrl));

    request.files.add(
      await http.MultipartFile.fromPath('receipt', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('OCR failed: ${response.body}');
    }

    return json.decode(response.body);
  }
}
