import 'package:flutter/material.dart';
import 'package:cashlytics/core/utils/user_management/profile_helpers.dart';

class CustomInputDecoration {
  static InputDecoration simple(
    String hint,
    Color fillColor, {
    bool isCurrencyInput = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixText: isCurrencyInput
          ? '${ProfileHelpers.getUserCurrencyPref()} '
          : null,
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
