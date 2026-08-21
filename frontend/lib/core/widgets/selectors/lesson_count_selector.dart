import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/app_strings.dart';

/// Common widget for selecting lesson count with preset chips and custom input.
///
/// Usage:
/// ```dart
/// LessonCountSelector(
///   selectedCount: _totalLessons,
///   isCustom: _isCustomLessons,
///   customController: _customLessonsController,
///   onCountChanged: (count, isCustom) {
///     setState(() {
///       _totalLessons = count;
///       _isCustomLessons = isCustom;
///     });
///   },
/// )
/// ```
class LessonCountSelector extends StatelessWidget {
  /// Currently selected lesson count.
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

  /// Whether the field is required.
  final bool isRequired;

  const LessonCountSelector({
    super.key,
    required this.selectedCount,
    required this.isCustom,
    this.customController,
    required this.onCountChanged,
    this.presets = const [4, 8, 12, 16],
    this.label,
    this.isRequired = false,
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
            ...presets.map((count) {
              final isSelected = !isCustom && selectedCount == count;
              return ChoiceChip(
                label: Text(AppStrings.usageCountShort(count)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onCountChanged(count, false);
                  }
                },
                backgroundColor: AppColors.paper,
                selectedColor: AppColors.paperAccent.withValues(alpha: 0.15),
                checkmarkColor: AppColors.paperAccent,
                side: BorderSide(
                  color:
                      isSelected
                          ? AppColors.paperAccent
                          : AppColors.inkQuaternary,
                ),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: isSelected ? AppColors.paperAccent : AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
            // Custom input chip
            ChoiceChip(
              label: Text(AppLocalizations.of(context).selectorDirectInput),
              selected: isCustom,
              onSelected: (selected) {
                if (selected) {
                  onCountChanged(selectedCount, true);
                }
              },
              backgroundColor: AppColors.paper,
              selectedColor: AppColors.paperAccent.withValues(alpha: 0.15),
              checkmarkColor: AppColors.paperAccent,
              side: BorderSide(
                color:
                    isCustom ? AppColors.paperAccent : AppColors.inkQuaternary,
              ),
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isCustom ? AppColors.paperAccent : AppColors.ink,
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
                hintText: AppLocalizations.of(context).selectorCountInputHint,
                suffixText: '회',
                filled: true,
                fillColor: AppColors.paper,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.paperAccent),
                ),
              ),
              onChanged: (value) {
                final count = int.tryParse(value) ?? 0;
                if (count > 0) {
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
