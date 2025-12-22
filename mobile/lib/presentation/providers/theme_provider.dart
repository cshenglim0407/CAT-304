import 'package:flutter/material.dart';
import 'package:cashlytics/domain/entities/app_user.dart';

/// Example theme provider for managing app theme state
/// 
/// To use this properly:
/// 1. Add provider package to pubspec.yaml
/// 2. Wrap MaterialApp with ChangeNotifierProvider of ThemeProvider
/// 3. Use Provider.of ThemeProvider in MaterialApp
/// 4. Call setThemeFromPreference() after updating user profile
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Set theme from user preference string
  void setThemeFromPreference(String preference) {
    final newMode = _parseThemeMode(preference);
    if (newMode != _themeMode) {
      _themeMode = newMode;
      notifyListeners();
    }
  }

  /// Set theme from AppUser entity
  void setThemeFromUser(AppUser user) {
    setThemeFromPreference(user.themePreference);
  }

  ThemeMode _parseThemeMode(String preference) {
    switch (preference.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
