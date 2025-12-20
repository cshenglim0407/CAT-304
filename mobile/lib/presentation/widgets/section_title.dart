import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final TextAlign alignment;

  const SectionTitle({
    super.key,
    required this.title,
    this.alignment = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: alignment,
      style: AppTypography.headline2.copyWith(
        color: AppColors.primary,
      ),
    );
  }
}
