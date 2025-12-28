import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gemini API client for generating financial insights
class GeminiClient {
  late final String _apiKey;
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent';
  final Duration _timeout = const Duration(seconds: 45);

  GeminiClient() {
    _apiKey = dotenv.env['AI_INSIGHT_GEMINI_API'] ?? '';
    if (_apiKey.isEmpty) {
      throw Exception(
        'AI_INSIGHT_GEMINI_API not configured in environment variables',
      );
    }
  }

  String sanitizeForUtf8(String input) {
    final out = <int>[];

    for (final u in input.codeUnits) {
      if (u >= 0xD800 && u <= 0xDFFF) continue; // surrogates
      if (u == 0x0000) continue; // NULL
      if (u < 0x20 && u != 0x09 && u != 0x0A && u != 0x0D) continue;
      out.add(u);
    }

    return String.fromCharCodes(out)
        .replaceAll('\uFEFF', '')
        .replaceAll('\u200B', '')
        .replaceAll('\u200C', '')
        .replaceAll('\u200D', '')
        .replaceAll('•', '.');
  }

  /// Generate financial insights from a prompt
  ///
  /// Returns the parsed JSON response from Gemini API
  /// Throws an exception if the API call fails
  Future<Map<String, dynamic>> generateInsights(String prompt) async {
    HttpClient? httpClient;
    try {
      final safePrompt = sanitizeForUtf8(prompt);

      httpClient = HttpClient()..connectionTimeout = _timeout;

      final uri = Uri.parse('$_baseUrl?key=$_apiKey');
      final request = await httpClient.postUrl(uri);

      request.headers.set('Content-Type', 'application/json; charset=utf-8');

      final payload = {
        'contents': [
          {
            'parts': [
              {'text': safePrompt},
            ],
          },
        ],
      };

      request.write(jsonEncode(payload)); // ✅ SAFE NOW

      final response = await request.close().timeout(_timeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        debugPrint('Gemini API error status: ${response.statusCode}');
        debugPrint('Gemini API error body: $responseBody');
        throw Exception('Gemini API error: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      debugPrint('[GeminiClient] Response received successfully');
      return jsonResponse;
    } catch (e) {
      debugPrint('[GeminiClient] Error: $e');
      rethrow;
    } finally {
      httpClient?.close(force: true);
    }
  }

  /// Extract the text content from Gemini's response
  static String extractResponseText(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No candidates in Gemini response');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        throw Exception('No content in first candidate');
      }

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('No parts in content');
      }

      final text = parts[0]['text'] as String?;
      if (text == null) {
        throw Exception('No text in first part');
      }

      return text;
    } catch (e) {
      debugPrint('[GeminiClient] Error extracting response text: $e');
      rethrow;
    }
  }
}
