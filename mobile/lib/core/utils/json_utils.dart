import 'dart:convert';

/// Utility helpers for robust JSON parsing from text that may
/// include markdown code fences or stray control characters.
class JsonUtils {
  /// Remove control characters that can break JSON decoding.
  static String sanitize(String input) {
    return input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  }

  /// Decode sanitized JSON string to a dynamic object.
  /// Throws on invalid JSON.
  static dynamic decode(String jsonString) {
    final cleaned = sanitize(jsonString.trim());
    return jsonDecode(cleaned);
  }

  /// Try to parse a JSON object (Map) from a text blob.
  /// - Tries direct parse
  /// - Then tries fenced code blocks: ```json { ... } ``` or ``` { ... } ```
  /// - Then tries first JSON object occurrence in the text
  /// Returns null if no object can be parsed.
  static Map<String, dynamic>? tryParseObject(String text) {
    // Direct parse first
    final direct = _tryDecodeMap(text);
    if (direct != null) return direct;

    // Extract from fenced code blocks
    final fenced = RegExp(
      r"```(?:json)?\s*(\{[\s\S]*?\})\s*```",
    ).firstMatch(text);
    if (fenced != null) {
      final fromFence = _tryDecodeMap(fenced.group(1)!);
      if (fromFence != null) return fromFence;
    }

    // Extract first JSON object
    final objectMatch = RegExp(r'\{[\s\S]*?\}').firstMatch(text);
    if (objectMatch != null) {
      final fromObject = _tryDecodeMap(objectMatch.group(0)!);
      if (fromObject != null) return fromObject;
    }

    return null;
  }

  /// Try to parse a JSON array (List) from a text blob.
  static List<dynamic>? tryParseArray(String text) {
    // Direct parse first
    final direct = _tryDecodeList(text);
    if (direct != null) return direct;

    // Extract from fenced code blocks
    final fenced = RegExp(
      r"```(?:json)?\s*(\[[\s\S]*?\])\s*```",
    ).firstMatch(text);
    if (fenced != null) {
      final fromFence = _tryDecodeList(fenced.group(1)!);
      if (fromFence != null) return fromFence;
    }

    // Extract first JSON array
    final arrayMatch = RegExp(r'\[[\s\S]*?\]').firstMatch(text);
    if (arrayMatch != null) {
      final fromArray = _tryDecodeList(arrayMatch.group(0)!);
      if (fromArray != null) return fromArray;
    }

    return null;
  }

  /// Attempt to decode a Map from a JSON string; returns null on failure.
  static Map<String, dynamic>? _tryDecodeMap(String jsonString) {
    try {
      final decoded = decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Attempt to decode a List from a JSON string; returns null on failure.
  static List<dynamic>? _tryDecodeList(String jsonString) {
    try {
      final decoded = decode(jsonString);
      if (decoded is List<dynamic>) return decoded;
      if (decoded is List) return List<dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }
}
