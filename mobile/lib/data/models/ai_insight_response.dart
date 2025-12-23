import 'dart:convert';

/// Request payload for Gemini AI to generate financial insights
class AiInsightRequest {
  final String prompt;
  final String userId;
  final String month;

  const AiInsightRequest({
    required this.prompt,
    required this.userId,
    required this.month,
  });
}

/// Parsed response from Gemini containing financial insights
class AiInsightResponse {
  final int healthScore;
  final List<SuggestionItem> suggestions;
  final String insights;
  final List<String>? recommendations;
  final double? totalIncome;
  final double? totalExpense;
  final double? savingsRate;

  const AiInsightResponse({
    required this.healthScore,
    required this.suggestions,
    required this.insights,
    this.recommendations,
    this.totalIncome,
    this.totalExpense,
    this.savingsRate,
  });

  /// Parse from Gemini's JSON response text
  factory AiInsightResponse.fromJson(String jsonString) {
    try {
      final json = _parseJson(jsonString);

      return AiInsightResponse(
        healthScore: (json['healthScore'] as num?)?.toInt() ?? 0,
        suggestions: _parseSuggestions(json['suggestions']),
        insights: json['insights'] as String? ?? '',
        recommendations: _parseRecommendations(json['recommendations']),
        totalIncome: (json['totalIncome'] as num?)?.toDouble(),
        totalExpense: (json['totalExpense'] as num?)?.toDouble(),
        savingsRate: (json['savingsRate'] as num?)?.toDouble(),
      );
    } catch (e) {
      throw Exception('Failed to parse AiInsightResponse: $e');
    }
  }

  /// Safely parse JSON from response text (may be wrapped in markdown)
  static Map<String, dynamic> _parseJson(String text) {
    // Try direct parse first
    try {
      return _parseJsonString(text);
    } catch (_) {
      // Try extracting JSON from markdown code blocks
      final jsonMatch = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```').firstMatch(text);
      if (jsonMatch != null) {
        return _parseJsonString(jsonMatch.group(1)!);
      }

      // Try extracting raw JSON object
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (objectMatch != null) {
        return _parseJsonString(objectMatch.group(0)!);
      }

      throw Exception('Could not extract JSON from response');
    }
  }

  static Map<String, dynamic> _parseJsonString(String jsonString) {
    return Map<String, dynamic>.from(
      _decodeJson(jsonString.trim()) as Map,
    );
  }

  static dynamic _decodeJson(String json) {
    // Remove any control characters
    final cleaned = json.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    return Map.from(jsonDecode(cleaned) as Map<String, dynamic>);
  }

  static List<SuggestionItem> _parseSuggestions(dynamic raw) {
    if (raw is! List) return [];

    return (raw).whereType<Map<String, dynamic>>().map((item) {
      return SuggestionItem(
        title: item['title'] as String? ?? '',
        body: item['body'] as String? ?? '',
        category: item['category'] as String? ?? 'general',
      );
    }).toList();
  }

  static List<String>? _parseRecommendations(dynamic raw) {
    if (raw is! List) return null;
    return raw.whereType<String>().toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'healthScore': healthScore,
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
      'insights': insights,
      'recommendations': recommendations,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'savingsRate': savingsRate,
    };
  }
}

/// Individual suggestion item from AI
class SuggestionItem {
  final String title;
  final String body;
  final String category;

  const SuggestionItem({
    required this.title,
    required this.body,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'category': category,
    };
  }

  factory SuggestionItem.fromJson(Map<String, dynamic> json) {
    return SuggestionItem(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
    );
  }
}
