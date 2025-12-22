import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class SocialAuthButton extends StatelessWidget {
  final String? label; // Changed to nullable (optional)
  final Widget icon;
  final VoidCallback onPressed;

  const SocialAuthButton({
    super.key,
    this.label, // No longer required
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16), // Consistent padding
          side: BorderSide(color: AppColors.getBorder(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // Logic: If label exists, show Row. If null, just show Icon centered.
        child: label != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(
                    label!,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                ],
              )
            : icon, // Icon is centered by default in OutlinedButton
      ),
    );
  }
}