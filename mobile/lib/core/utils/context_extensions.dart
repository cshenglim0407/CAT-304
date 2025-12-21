import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';

extension ContextExtension on BuildContext {
  void showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : (isSuccess
                  ? AppColors.success
                  : Theme.of(this).snackBarTheme.backgroundColor),
      ),
    );
  }
}