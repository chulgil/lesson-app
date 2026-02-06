import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Common widget for selecting bonus lesson count with preset chips and custom input.
///
/// Usage:
/// ```dart
/// BonusCountSelector(
///   selectedCount: _bonusLessons,
///   isCustom: _isCustomBonus,
///   customController: _customBonusController,
///   onCountChanged: (count, isCustom) {
///     setState(() {
///       _bonusLessons = count;
///       _isCustomBonus = isCustom;
///     });
///   },
/// )
/// ```
class BonusCountSelector extends StatelessWidget {
  /// Currently selected bonus count.
  final int selectedCount;

  /// Whether custom input mode is active.
  final bool isCustom;

  /// Controller for custom input field.
  final TextEditingController? customController;

  /// Callback when count changes. Returns (count, isCustom).
  final void Function(int count, bool isCustom) onCountChanged;

  /// Preset options for quick selection.
  final List<int> presets;

  /// Label text shown above the selector.
  final String? label;

  /// Accent color for selected state.
  final Color? accentColor;

  const BonusCountSelector({
    super.key,
    required this.selectedCount,
    required this.isCustom,
    this.customController,
    required this.onCountChanged,
    this.presets = const [0, 1, 2, 3],
    this.label,
    this.accentColor,
  });

  Color get _accentColor => accentColor ?? AppColors.primary;

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
            ...presets.map((count) {
              final isSelected = !isCustom && selectedCount == count;
              return ChoiceChip(
                label: Text(count == 0 ? '없음' : '+$count회'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onCountChanged(count, false);
                  }
                },
                backgroundColor: AppColors.surfaceLight,
                selectedColor: _accentColor.withValues(alpha: 0.15),
                checkmarkColor: _accentColor,
                side: BorderSide(
                  color: isSelected ? _accentColor : AppColors.borderLight,
                ),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: isSelected ? _accentColor : AppColors.textPrimaryLight,
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
                  onCountChanged(selectedCount, true);
                }
              },
              backgroundColor: AppColors.surfaceLight,
              selectedColor: _accentColor.withValues(alpha: 0.15),
              checkmarkColor: _accentColor,
              side: BorderSide(
                color: isCustom ? _accentColor : AppColors.borderLight,
              ),
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isCustom ? _accentColor : AppColors.textPrimaryLight,
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '횟수',
                suffixText: '회',
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
                  borderSide: BorderSide(color: _accentColor),
                ),
              ),
              onChanged: (value) {
                final count = int.tryParse(value) ?? 0;
                if (count >= 0) {
                  onCountChanged(count, true);
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}
