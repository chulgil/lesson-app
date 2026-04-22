import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Common widget for selecting discount percentage with preset chips and custom input.
///
/// Usage:
/// ```dart
/// DiscountPercentSelector(
///   selectedPercent: _discountPercent,
///   isCustom: _isCustomDiscount,
///   customController: _customDiscountController,
///   onPercentChanged: (percent, isCustom) {
///     setState(() {
///       _discountPercent = percent;
///       _isCustomDiscount = isCustom;
///     });
///   },
/// )
/// ```
class DiscountPercentSelector extends StatelessWidget {
  /// Currently selected discount percentage (0-100).
  final int selectedPercent;

  /// Whether custom input mode is active.
  final bool isCustom;

  /// Controller for custom input field.
  final TextEditingController? customController;

  /// Callback when percent changes. Returns (percent, isCustom).
  final void Function(int percent, bool isCustom) onPercentChanged;

  /// Preset options for quick selection.
  final List<int> presets;

  /// Label text shown above the selector.
  final String? label;

  /// Accent color for selected state.
  final Color? accentColor;

  const DiscountPercentSelector({
    super.key,
    required this.selectedPercent,
    required this.isCustom,
    this.customController,
    required this.onPercentChanged,
    this.presets = const [0, 5, 10, 15, 20],
    this.label,
    this.accentColor,
  });

  Color get _accentColor => accentColor ?? AppColors.secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
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
            ...presets.map((percent) {
              final isSelected = !isCustom && selectedPercent == percent;
              return ChoiceChip(
                label: Text(percent == 0 ? '없음' : '$percent%'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onPercentChanged(percent, false);
                  }
                },
                backgroundColor: AppColors.paper,
                selectedColor: _accentColor.withValues(alpha: 0.15),
                checkmarkColor: _accentColor,
                side: BorderSide(
                  color: isSelected ? _accentColor : AppColors.inkQuaternary,
                ),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: isSelected ? _accentColor : AppColors.ink,
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
                  onPercentChanged(selectedPercent, true);
                }
              },
              backgroundColor: AppColors.paper,
              selectedColor: _accentColor.withValues(alpha: 0.15),
              checkmarkColor: _accentColor,
              side: BorderSide(
                color: isCustom ? _accentColor : AppColors.inkQuaternary,
              ),
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isCustom ? _accentColor : AppColors.ink,
                fontWeight: isCustom ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        // Custom input field
        if (isCustom && customController != null) ...[
          const SizedBox(height: AppSpacing.space3),
          SizedBox(
            width: 120,
            child: TextFormField(
              controller: customController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _MaxValueInputFormatter(100),
              ],
              decoration: InputDecoration(
                hintText: '할인율',
                suffixText: '%',
                filled: true,
                fillColor: AppColors.paper,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: _accentColor),
                ),
              ),
              onChanged: (value) {
                final percent = int.tryParse(value) ?? 0;
                onPercentChanged(percent.clamp(0, 100), true);
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Input formatter to limit maximum value.
class _MaxValueInputFormatter extends TextInputFormatter {
  final int maxValue;

  _MaxValueInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final intValue = int.tryParse(newValue.text);
    if (intValue == null) return oldValue;
    if (intValue > maxValue) {
      return TextEditingValue(
        text: maxValue.toString(),
        selection: TextSelection.collapsed(offset: maxValue.toString().length),
      );
    }
    return newValue;
  }
}
