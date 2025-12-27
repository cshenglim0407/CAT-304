class StringCaseFormatter {
  /// Converts a given string to Title Case.
  /// Example: "hello world" -> "Hello World"
  static String toTitleCase(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}