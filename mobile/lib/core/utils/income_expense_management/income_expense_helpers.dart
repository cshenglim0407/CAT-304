import 'package:cashlytics/core/utils/math_formatter.dart';

class IncomeExpenseHelpers {
  /// Formats a currency amount as a string with a sign prefix.
  /// Expenses are prefixed with '- ' and income with '+ '.
  static String formatCurrency(double amount, bool isExpense) {
    final sign = isExpense ? '- ' : '+ ';
    return '$sign${MathFormatter.formatCurrency(amount)}';
  }

  /// Formats a date for transaction display.
  /// Returns 'Today', 'Yesterday', or 'DD/MM' format.
  static String formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  /// Formats a date in DD/MM/YYYY format for display in input fields.
  static String formatDateForInput(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  /// Parses amount from various types and returns as double.
  static double parseAmount(dynamic value) {
    return MathFormatter.parseDouble(value) ?? 0.0;
  }

  /// Extracts initial data field with type coercion.
  static T? getInitialValue<T>(
    Map<String, dynamic>? initialData,
    String key, {
    T? defaultValue,
  }) {
    if (initialData == null || !initialData.containsKey(key)) {
      return defaultValue;
    }
    return initialData[key] as T?;
  }

  /// Safely extracts and parses a string value from initial data.
  static String? getInitialString(
    Map<String, dynamic>? initialData,
    String key,
  ) {
    final value = initialData?[key];
    if (value == null) return null;
    return value.toString().trim();
  }

  /// Safely extracts and parses a double value from initial data.
  /// Supports 'rawAmount' or 'amount' fields.
  static double getInitialAmount(Map<String, dynamic>? initialData) {
    if (initialData == null) return 0.0;
    final rawAmt = initialData['rawAmount'] ?? initialData['amount'];
    return parseAmount(rawAmt);
  }

  /// Safely extracts a DateTime from initial data.
  static DateTime? getInitialDate(Map<String, dynamic>? initialData) {
    final dateDyn = initialData?['date'];
    if (dateDyn is DateTime) return dateDyn;
    return null;
  }

  /// Safely extracts and matches a category against a list (case-insensitive).
  static String? getInitialCategory(
    Map<String, dynamic>? initialData,
    List<String> availableCategories,
    String defaultCategory,
  ) {
    final cat = getInitialString(initialData, 'category');
    if (cat != null && cat.isNotEmpty) {
      return availableCategories.firstWhere(
        (c) => c.toUpperCase() == cat.toUpperCase(),
        orElse: () => defaultCategory,
      );
    }
    return defaultCategory;
  }

  /// Safely extracts account name from initial data.
  static String? getInitialAccount(Map<String, dynamic>? initialData) {
    return getInitialString(initialData, 'fromAccount') ??
        getInitialString(initialData, 'accountName') ??
        getInitialString(initialData, 'toAccount');
  }

  /// Validates amount is positive and non-zero.
  static bool isValidAmount(double amount) {
    return amount > 0;
  }

  /// Validates that at least one item exists (for expenses).
  static bool hasItems(List<dynamic>? items) {
    return items != null && items.isNotEmpty;
  }
}
