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
}
