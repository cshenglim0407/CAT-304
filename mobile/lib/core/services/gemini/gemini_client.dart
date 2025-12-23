import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gemini API client for generating financial insights
class GeminiClient {
  late final String _apiKey;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent';
  final Duration _timeout = const Duration(seconds: 45);

  GeminiClient() {
    _apiKey = dotenv.env['AI_INSIGHT_GEMINI_API'] ?? '';
    if (_apiKey.isEmpty) {
      throw Exception('AI_INSIGHT_GEMINI_API not configured in environment variables');
    }
  }

  /// Generate financial insights from a prompt
  /// 
  /// Returns the parsed JSON response from Gemini API
  /// Throws an exception if the API call fails
  Future<Map<String, dynamic>> generateInsights(String prompt) async {
    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = _timeout;

      final uri = Uri.parse('$_baseUrl?key=$_apiKey');
      final request = await httpClient.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');

      final payload = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      };

      request.write(jsonEncode(payload));
      final response = await request.close().timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('Gemini API error status: ${response.statusCode}');
        throw Exception('Gemini API error: ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final jsonResponse = jsonDecode(body) as Map<String, dynamic>;

      httpClient.close();

      debugPrint('[GeminiClient] Response received successfully');
      return jsonResponse;
    } catch (e) {
      debugPrint('[GeminiClient] Error: $e');
      rethrow;
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
