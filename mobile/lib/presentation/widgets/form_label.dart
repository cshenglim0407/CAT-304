import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class FormLabel extends StatelessWidget {
  final String label;
  final bool required;
  final bool useGreyStyle;

  const FormLabel({
    super.key,
    required this.label,
    this.required = false,
    this.useGreyStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: useGreyStyle
          ? Text(
              label,
              style: AppTypography.labelLarge.copyWith(color: AppColors.greyText),
            )
          : RichText(
              text: TextSpan(
                style: AppTypography.labelMedium.copyWith(
                    color: AppColors.getTextPrimary(context)),
                children: [
                  TextSpan(text: label),
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.error),
                    ),
                ],
              ),
            ),
    );
  }
}
