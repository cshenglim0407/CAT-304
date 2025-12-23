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
}
