import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2E604B);
  static const Color primaryLight = Color(0xFF4A7D66);
  static const Color primaryDark = Color(0xFF1F4033);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Grey Colors
  static const Color greyLight = Color(0xFFEAEAEA);
  static const Color greyBorder = Color(0xFFEAEAEA);
  static const Color greyHint = Color(0xFFBDBDBD);
  static const Color greyText = Color(0xFF9E9E9E);

  // Text Colors
  static const Color textDark = Color(0xFF000000);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color textLightGrey = Color(0xFF9E9E9E);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);

  // Social Colors
  static const Color facebook = Color(0xFF1877F2);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFE1E1E1);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkBorder = Color(0xFF3A3A3A);

  static Color? get grey => null;

  // Get adaptive colors based on brightness
  static Color getBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : background;

  static Color getSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : white;

  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textDark;

  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textGrey;

  static Color getBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : greyBorder;
}
