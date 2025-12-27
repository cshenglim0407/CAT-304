import 'package:cashlytics/core/utils/user_management/profile_helpers.dart';

class MathFormatter {
  static String formatCurrency(double amount, {String currencyPref = '\$'}) {
    // Attempt to load user's currency preference from cache
    currencyPref = ProfileHelpers.getUserCurrencyPref();
    
    return '$currencyPref${amount.toStringAsFixed(2)}';
  }

  /// Parse formatted amount strings (e.g., "RM45.00", "45.00 USD") by removing
  /// non-numeric characters except decimal points
  static double parseFormattedAmount(String value) {
    String cleanString = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanString) ?? 0.0;
  }

  /// Parse int from various types with null safety
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  /// Parse double from various types with null safety
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Parse bool from various types with null safety
  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }
}
