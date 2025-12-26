import 'package:flutter/material.dart';

import 'package:cashlytics/core/config/icons.dart';
import 'package:cashlytics/core/utils/math_formatter.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class AccountCard extends StatelessWidget {
  final String accountName;
  final String accountType;
  final double currentBalance;
  final double initialBalance;
  final String description;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap; // <--- NEW CALLBACK

  const AccountCard({
    super.key,
    required this.accountName,
    required this.accountType,
    required this.currentBalance,
    required this.initialBalance,
    this.description = '',
    this.onTap,
    this.onEditTap, // <--- Add to constructor
  });

  // Type icon mapping moved to config/icons.dart

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    final subTextColor = Colors.white.withValues(alpha: 0.8);
    const iconTint = Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.85),
              AppColors.primary.withValues(alpha: 0.55),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- TOP ROW: Icon & Name ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    getAccountTypeIcon(accountType),
                    color: iconTint,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountName,
                        style: AppTypography.labelLarge.copyWith(
                          fontSize: 16,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          accountType.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- UPDATED: Clickable Three Dots ---
                GestureDetector(
                  onTap: onEditTap, // Trigger the callback
                  behavior: HitTestBehavior.opaque, // Ensures the tap is caught
                  child: Container(
                    padding: const EdgeInsets.all(8), // Make hit area bigger
                    child: Icon(Icons.more_vert, color: subTextColor, size: 20),
                  ),
                ),
              ],
            ),

            // --- DESCRIPTION ---
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: subTextColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: subTextColor,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),

            // --- BOTTOM ROW: Balances ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentBalance == 0 && initialBalance == 0
                      ? '\$0.00'
                      : MathFormatter.formatCurrency(currentBalance),
                  style: AppTypography.headline2.copyWith(
                    fontSize: 24,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    initialBalance == 0
                        ? "Initial: \$0.00"
                        : "Initial: ${MathFormatter.formatCurrency(initialBalance)}",
                    style: AppTypography.caption.copyWith(
                      color: subTextColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
