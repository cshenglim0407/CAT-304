class DateFormatter {
  /// Formats a date string with age calculation
  /// Returns the date with age in parentheses (e.g., "1990-01-15 (34)")
  /// If dateStr is empty or 'N/A', returns it as-is
  static String formatDateWithAge(String dateStr) {
    if (dateStr == 'N/A' || dateStr.isEmpty) return dateStr;

    try {
      DateTime birthDate = DateTime.parse(dateStr);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return "$dateStr ($age)";
    } catch (e) {
      return dateStr;
    }
  }

  /// Formats a DateTime into a readable date string.
  /// Returns 'Today' for today's date, 'Yesterday' for yesterday,
  /// or 'DD MMM' format for other dates.
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day} ${_monthName(date.month)}';
    }
  }

  /// Formats a DateTime into 'DD MMM' or 'DD MMM YYYY'
  static String formatDateSimple(DateTime date, {bool showYear = false}) {
    final day = date.day;
    final month = _monthName(date.month);
    if (showYear) {
      return '$day $month ${date.year}';
    }
    return '$day $month';
  }

  /// Returns the abbreviated month name (e.g., 'Jan', 'Feb', etc.)
  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Returns only the date part of a DateTime
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Calculates the number of days left until endDate
  static int daysLeft(DateTime endDate) {
    final today = dateOnly(DateTime.now());
    final end = dateOnly(endDate);
    final diff = end.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Checks if two date ranges overlap
  static bool rangesOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return !aEnd.isBefore(bStart) && !bEnd.isBefore(aStart);
  }

  /// Parses a date from dynamic type, returns today if parsing fails
  static DateTime parseDate(dynamic raw) {
    if (raw is DateTime) return dateOnly(raw);
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return dateOnly(parsed);
    }
    return dateOnly(DateTime.now());
  }

  /// Parse DateTime from various types with null safety
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
