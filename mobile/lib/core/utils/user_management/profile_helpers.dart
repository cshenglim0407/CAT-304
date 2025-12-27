import 'package:cashlytics/core/config/profile_constants.dart';
import 'package:cashlytics/core/services/cache/cache_service.dart';
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

  /// Get current user currency preference from cached profile
  static String getUserCurrencyPref() {
    // Default currency symbol
    String currencyPref = '\$';

    // Attempt to load user's currency preference from cache
    Map<String, dynamic>? currentUserProfile =
        CacheService.load<Map<String, dynamic>>('user_profile_cache') ?? {};
    if (currentUserProfile.containsKey('currency_pref')) {
      currencyPref = currentUserProfile['currency_pref'] as String;
    }

    return currencyPref;
  }

  static String? mapOffsetToIana(String offset) {
    const Map<String, String> offsetToIana = {
      '-12:00': 'Etc/GMT+12',
      '-11:00': 'Etc/GMT+11',
      '-10:00': 'Pacific/Honolulu',
      '-09:00': 'America/Anchorage',
      '-08:00': 'America/Los_Angeles',
      '-07:00': 'America/Denver',
      '-06:00': 'America/Chicago',
      '-05:00': 'America/New_York',
      '-04:30': 'America/Caracas',
      '-04:00': 'America/La_Paz',
      '-03:30': 'America/St_Johns',
      '-03:00': 'America/Sao_Paulo',
      '-02:00': 'Etc/GMT+2',
      '-01:00': 'Atlantic/Azores',
      '+00:00': 'Europe/London',
      '+01:00': 'Europe/Berlin',
      '+02:00': 'Europe/Helsinki',
      '+03:00': 'Europe/Moscow',
      '+03:30': 'Asia/Tehran',
      '+04:00': 'Asia/Dubai',
      '+04:30': 'Asia/Kabul',
      '+05:00': 'Asia/Karachi',
      '+05:30': 'Asia/Kolkata',
      '+05:45': 'Asia/Kathmandu',
      '+06:00': 'Asia/Dhaka',
      '+06:30': 'Asia/Yangon',
      '+07:00': 'Asia/Bangkok',
      '+08:00': 'Asia/Kuala_Lumpur',
      '+09:00': 'Asia/Tokyo',
      '+09:30': 'Australia/Darwin',
      '+10:00': 'Australia/Sydney',
      '+11:00': 'Pacific/Noumea',
      '+12:00': 'Pacific/Auckland',
      '+13:00': 'Pacific/Fakaofo',
    };
    return offsetToIana[offset];
  }
}
