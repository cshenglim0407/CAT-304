import 'package:flutter/services.dart';

/// Custom formatter to automatically add decimal point to currency input
/// Examples: 2 -> 0.02, 200 -> 2.00, 12345 -> 123.45
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extract only digits from the new value
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Remove leading zeros but keep at least one digit
    digitsOnly = digitsOnly.replaceFirst(RegExp(r'^0+'), '');
    if (digitsOnly.isEmpty) {
      digitsOnly = '0';
    }

    // Pad with zeros on the left if less than 3 digits
    while (digitsOnly.length < 3) {
      digitsOnly = '0$digitsOnly';
    }

    // Insert decimal point: "123" -> "1.23", "012" -> "0.12", "001" -> "0.01"
    String withDecimal =
        '${digitsOnly.substring(0, digitsOnly.length - 2)}.${digitsOnly.substring(digitsOnly.length - 2)}';

    // Set cursor to end of text
    return newValue.copyWith(
      text: withDecimal,
      selection: TextSelection.collapsed(offset: withDecimal.length),
    );
  }
}

