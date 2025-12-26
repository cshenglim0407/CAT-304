import 'package:cashlytics/core/utils/json_utils.dart';

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
    final map = JsonUtils.tryParseObject(text);
    if (map != null) return map;
    throw Exception('Could not extract JSON from response');
  }

  static List<SuggestionItem> _parseSuggestions(dynamic raw) {
    if (raw is! List) return [];

    return (raw).whereType<Map<String, dynamic>>().map((item) {
      return SuggestionItem(
        title: item['title'] as String? ?? '',
        body: item['body'] as String? ?? '',
        category: item['category'] as String? ?? 'general',
        icon: item['icon'] as String? ?? 'lightbulb_outline',
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
  final String icon;

  const SuggestionItem({
    required this.title,
    required this.body,
    required this.category,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {'title': title, 'body': body, 'category': category, 'icon': icon};
  }

  factory SuggestionItem.fromJson(Map<String, dynamic> json) {
    return SuggestionItem(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      icon: json['icon'] as String? ?? 'lightbulb_outline',
    );
  }
}
