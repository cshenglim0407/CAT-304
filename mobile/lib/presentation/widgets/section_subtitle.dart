import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class SectionSubtitle extends StatelessWidget {
  final String subtitle;
  final TextAlign alignment;

  const SectionSubtitle({
    super.key,
    required this.subtitle,
    this.alignment = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle,
      textAlign: alignment,
      style: AppTypography.subtitle.copyWith(
        color: AppColors.getTextSecondary(context),
      ),
    );
  }
}
