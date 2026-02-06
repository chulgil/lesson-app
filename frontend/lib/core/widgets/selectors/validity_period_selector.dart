import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Common widget for selecting validity period with preset chips and custom input.
///
/// Usage:
/// ```dart
/// ValidityPeriodSelector(
///   selectedDays: _validityDays,
///   isCustom: _isCustomValidity,
///   customController: _customValidityController,
///   onPeriodChanged: (days, isCustom) {
///     setState(() {
///       _validityDays = days;
///       _isCustomValidity = isCustom;
///     });
///   },
/// )
/// ```
class ValidityPeriodSelector extends StatelessWidget {
  /// Currently selected validity period in days.
  final int selectedDays;

  /// Whether custom input mode is active.
  final bool isCustom;

  /// Controller for custom input field.
  final TextEditingController? customController;

  /// Callback when period changes. Returns (days, isCustom).
  final void Function(int days, bool isCustom) onPeriodChanged;

  /// Preset options for quick selection. List of (days, label) tuples.
  final List<(int, String)> presets;

  /// Label text shown above the selector.
  final String? label;

  /// Whether the field is required.
  final bool isRequired;

  /// Unit for custom input: 'days' or 'months'.
  final ValidityInputUnit inputUnit;

  const ValidityPeriodSelector({
    super.key,
    required this.selectedDays,
    required this.isCustom,
    this.customController,
    required this.onPeriodChanged,
    this.presets = const [
      (30, '1개월'),
      (60, '2개월'),
      (90, '3개월'),
      (120, '4개월'),
      (150, '5개월'),
    ],
    this.label,
    this.isRequired = false,
    this.inputUnit = ValidityInputUnit.days,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            isRequired ? '$label *' : label!,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            // Preset chips
            ...presets.map((preset) {
              final (days, displayLabel) = preset;
              final isSelected = !isCustom && selectedDays == days;
              return ChoiceChip(
                label: Text(displayLabel),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onPeriodChanged(days, false);
                  }
                },
                backgroundColor: AppColors.surfaceLight,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                ),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textPrimaryLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
            // Custom input chip
            ChoiceChip(
              label: const Text('직접 입력'),
              selected: isCustom,
              onSelected: (selected) {
                if (selected) {
                  onPeriodChanged(selectedDays, true);
                }
              },
              backgroundColor: AppColors.surfaceLight,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              side: BorderSide(
                color: isCustom ? AppColors.primary : AppColors.borderLight,
              ),
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isCustom ? AppColors.primary : AppColors.textPrimaryLight,
                fontWeight: isCustom ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        // Custom input field
        if (isCustom && customController != null) ...[
          const SizedBox(height: AppSpacing.space3),
          SizedBox(
            width: 150,
            child: TextFormField(
              controller: customController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: inputUnit == ValidityInputUnit.days
                    ? '유효기간 입력'
                    : '개월 입력',
                suffixText: inputUnit == ValidityInputUnit.days ? '일' : '개월',
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (value) {
                final input = int.tryParse(value) ?? 0;
                if (input > 0) {
                  final days = inputUnit == ValidityInputUnit.months
                      ? input * 30
                      : input;
                  onPeriodChanged(days, true);
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Unit for validity period custom input.
enum ValidityInputUnit {
  /// Input as days (e.g., 30, 60, 90).
  days,

  /// Input as months (e.g., 1, 2, 3) - converted to days (* 30).
  months,
}
