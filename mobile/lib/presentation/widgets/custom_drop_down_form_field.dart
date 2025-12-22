import 'package:flutter/material.dart';
import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';

class CustomDropdownFormField extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onChanged;
  // NEW: Function to transform the display text when selected
  final String Function(String)? selectedItemTransformer;

  const CustomDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
    this.selectedItemTransformer,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true, // FIXED: Prevents overflow errors
      hint: Text(
        hint,
        style: AppTypography.hintText.copyWith(
          color: AppColors.getTextSecondary(context),
        ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.getTextSecondary(context),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.getSurface(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.getBorder(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.getBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      // NEW: Logic to show the transformed text (short version) when closed
      selectedItemBuilder: selectedItemTransformer != null
          ? (BuildContext context) {
              return items.map<Widget>((String item) {
                return Builder(
                  builder: (context) => Text(
                    selectedItemTransformer!(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.getTextPrimary(context)),
                  ),
                );
              }).toList();
            }
          : null,
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis, // Handles long text in the menu
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}