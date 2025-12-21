import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static late SharedPreferences _prefs;

  /// Initialize the cache service (call once at app startup)
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save any data to cache with a key
  static Future<void> save<T>(String key, T value) async {
    try {
      if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is List<String>) {
        await _prefs.setStringList(key, value);
      } else if (value is Map<String, dynamic>) {
        final jsonString = jsonEncode(value);
        await _prefs.setString(key, jsonString);
      } else {
        debugPrint('Unsupported type for cache: ${T.toString()}');
      }
      debugPrint('Cache saved: $key');
    } catch (e) {
      debugPrint('Error saving cache [$key]: $e');
    }
  }

  /// Load data from cache
  static T? load<T>(String key) {
    try {
      final value = _prefs.get(key);
      if (value == null) return null;

      if (T == String) {
        return _prefs.getString(key) as T?;
      } else if (T == int) {
        return _prefs.getInt(key) as T?;
      } else if (T == double) {
        return _prefs.getDouble(key) as T?;
      } else if (T == bool) {
        return _prefs.getBool(key) as T?;
      } else if (T == List<String>) {
        return _prefs.getStringList(key) as T?;
      } else if (T == Map<String, dynamic>) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          return jsonDecode(jsonString) as T?;
        }
      } else {
        debugPrint('Unsupported type for cache load: ${T.toString()}');
      }
    } catch (e) {
      debugPrint('Error loading cache [$key]: $e');
    }
    return null;
  }

  /// Clear a specific cache key
  static Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
      debugPrint('Cache removed: $key');
    } catch (e) {
      debugPrint('Error removing cache [$key]: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    try {
      await _prefs.clear();
      debugPrint('All cache cleared');
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
    }
  }

  /// Check if key exists
  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
}
