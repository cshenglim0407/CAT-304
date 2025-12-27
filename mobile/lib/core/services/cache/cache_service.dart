import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static SharedPreferences? _prefs;

  /// Initialize the cache service (call once at app startup)
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if the cache service is initialized
  static bool get isInitialized => _prefs != null;

  /// Save any data to cache with a key
  static Future<void> save<T>(String key, T value) async {
    if (!isInitialized) {
      debugPrint('Cache service not initialized, cannot save [$key]');
      return;
    }

    try {
      if (value is String) {
        await _prefs!.setString(key, value);
      } else if (value is int) {
        await _prefs!.setInt(key, value);
      } else if (value is double) {
        await _prefs!.setDouble(key, value);
      } else if (value is bool) {
        await _prefs!.setBool(key, value);
      } else if (value is List<String>) {
        await _prefs!.setStringList(key, value);
      } else if (value is List || value is Map) {
        // Handle any List or Map by JSON encoding
        final jsonString = jsonEncode(value);
        await _prefs!.setString(key, jsonString);
      } else {
        debugPrint('Unsupported type for cache: ${value.runtimeType}');
        return;
      }
      debugPrint('Cache saved: $key');
    } catch (e) {
      debugPrint('Error saving cache [$key]: $e');
    }
  }

  /// Load data from cache
  static T? load<T>(String key) {
    if (!isInitialized) {
      debugPrint('Cache service not initialized, cannot load [$key]');
      return null;
    }

    try {
      if (!containsKey(key)) return null;

      final value = _prefs!.get(key);
      if (value == null) return null;

      if (T == String) {
        return _prefs!.getString(key) as T?;
      } else if (T == int) {
        return _prefs!.getInt(key) as T?;
      } else if (T == double) {
        return _prefs!.getDouble(key) as T?;
      } else if (T == bool) {
        return _prefs!.getBool(key) as T?;
      } else if (T.toString().contains('List<String>')) {
        return _prefs!.getStringList(key) as T?;
      } else {
        // Try to decode as JSON for List or Map types
        final jsonString = _prefs!.getString(key);
        if (jsonString != null) {
          final decoded = jsonDecode(jsonString);
          return decoded as T?;
        }
      }
    } catch (e) {
      debugPrint('Error loading cache [$key]: $e');
    }
    return null;
  }

  /// Clear a specific cache key
  static Future<void> remove(String key) async {
    if (!isInitialized) {
      debugPrint('Cache service not initialized, cannot remove [$key]');
      return;
    }

    try {
      if (!containsKey(key)) return;

      await _prefs!.remove(key);
      debugPrint('Cache removed: $key');
    } catch (e) {
      debugPrint('Error removing cache [$key]: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    if (!isInitialized) {
      debugPrint('Cache service not initialized, cannot clear all');
      return;
    }

    try {
      await _prefs!.clear();
      debugPrint('All cache cleared');
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
    }
  }

  /// Check if key exists
  static bool containsKey(String key) {
    if (!isInitialized) return false;
    return _prefs!.containsKey(key);
  }
}
