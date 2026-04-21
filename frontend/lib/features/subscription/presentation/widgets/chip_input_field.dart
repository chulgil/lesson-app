import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A compact widget with quick selection chips and an input field in a single row.
///
/// Used for selecting values like lesson count, validity days, discount percent, etc.
class ChipInputField extends StatelessWidget {
  /// Title displayed above the row.
  final String title;

  /// Whether to show "(선택)" label after title.
  final bool isOptional;

  /// Preset options to display as chips (recommend 3 options for single row).
  final List<int> options;

  /// Currently selected value.
  final int currentValue;

  /// Callback when a value is selected.
  final ValueChanged<int> onChanged;

  /// Text editing controller for the input field.
  final TextEditingController controller;

  /// Suffix text for the input field (e.g., "회", "일", "%").
  final String suffix;

  /// Width of the input field.
  final double inputWidth;

  /// Color for selected chip (defaults to primary).
  final Color? selectedColor;

  /// Custom label formatter for chip display.
  final String Function(int value)? labelFormatter;

  /// Label for "no selection" option (e.g., "없음").
  final String? zeroLabel;

  /// Maximum allowed value (for validation).
  final int? maxValue;

  const ChipInputField({
    super.key,
    required this.title,
    required this.options,
    required this.currentValue,
    required this.onChanged,
    required this.controller,
    required this.suffix,
    this.isOptional = false,
    this.inputWidth = 70,
    this.selectedColor,
    this.labelFormatter,
    this.zeroLabel,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = selectedColor ?? AppColors.paperAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          children: [
            Text(title, style: AppTypography.headingSmall),
            if (isOptional) ...[
              const SizedBox(width: AppSpacing.space2),
              Text(
                '(선택)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Single row: chips + input field
        Row(
          children: [
            // Quick selection chips
            ...options.map((value) {
              final isSelected = currentValue == value;
              final label = _getLabel(value);
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.space2),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) {
                    onChanged(value);
                    controller.text = value > 0 ? value.toString() : '';
                  },
                  selectedColor: chipColor.withValues(alpha: 0.15),
                  checkmarkColor: chipColor,
                  backgroundColor: AppColors.paper,
                  side: BorderSide(
                    color: isSelected ? chipColor : AppColors.inkQuaternary,
                  ),
                  labelStyle: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? chipColor : AppColors.inkSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }),

            // Input field
            SizedBox(
              width: inputWidth,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: suffix,
                  filled: true,
                  fillColor: AppColors.paper,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space2,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: BorderSide(color: AppColors.inkQuaternary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: BorderSide(color: AppColors.inkQuaternary),
                  ),
                ),
                onChanged: (value) {
                  var parsedValue = int.tryParse(value) ?? 0;
                  if (maxValue != null && parsedValue > maxValue!) {
                    parsedValue = maxValue!;
                    controller.text = parsedValue.toString();
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  }
                  onChanged(parsedValue);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getLabel(int value) {
    if (labelFormatter != null) {
      return labelFormatter!(value);
    }
    if (value == 0 && zeroLabel != null) {
      return zeroLabel!;
    }
    return '$value$suffix';
  }
}
