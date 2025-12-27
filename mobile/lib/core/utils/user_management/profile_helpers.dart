import 'package:cashlytics/core/config/profile_constants.dart';
import 'package:cashlytics/core/utils/string_case_formatter.dart';

class ProfileHelpers {
  /// Finds a timezone item from the list using a UTC code
  /// Example: "+08:00" -> "(UTC+08:00) Kuala Lumpur, Singapore, Beijing, Perth"
  static String? findTimezoneFromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final needle = "(UTC$code)"; // "+08:00" -> "(UTC+08:00)"
    try {
      return ProfileConstants.timezones.firstWhere(
        (tz) => tz.startsWith(needle),
      );
    } catch (_) {
      return null;
    }
  }

  /// Finds a currency item from the list using a currency code
  /// Example: "myr" -> "MYR - Malaysian Ringgit"
  static String? findCurrencyFromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final upper = code.toUpperCase();
    try {
      return ProfileConstants.currencies.firstWhere(
        (c) => c.startsWith("$upper "),
      );
    } catch (_) {
      return null;
    }
  }

  /// Normalizes theme preference string to proper case
  /// Example: "light" -> "Light", "DARK" -> "Dark"
  static String? normalizeTheme(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final t = raw.toLowerCase();
    if (t == 'light' || t == 'dark' || t == 'system') {
      return StringCaseFormatter.toTitleCase(t);
    }
    return null;
  }

  /// Normalizes gender string to standard format
  /// Example: "m" -> "Male", "F" -> "Female"
  static String? normalizeGender(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final g = raw.toLowerCase();
    if (g == 'male' || g == 'm') return 'Male';
    if (g == 'female' || g == 'f') return 'Female';
    if (g == 'other') return 'Other';
    return null;
  }

  /// Extracts UTC code from timezone string
  /// Example: "(UTC+08:00) City" -> "+08:00"
  static String? extractTimezoneCode(String? timezone) {
    if (timezone == null || timezone.isEmpty) return null;
    if (timezone.contains(')')) {
      final code = timezone.split(')').first.replaceFirst('(UTC', '');
      return code;
    }
    return timezone;
  }

  /// Extracts currency code from currency string
  /// Example: "MYR - Malaysian Ringgit" -> "MYR"
  static String? extractCurrencyCode(String? currency) {
    if (currency == null || currency.isEmpty) return null;
    if (currency.contains(' - ')) {
      return currency.split(' - ').first;
    }
    return currency;
  }
}
