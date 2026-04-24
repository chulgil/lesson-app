import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Common widget for selecting lesson duration with preset chips and optional custom input.
///
/// Usage:
/// ```dart
/// LessonDurationSelector(
///   selectedDuration: _lessonDuration,
///   isCustom: _isCustomDuration,
///   customController: _customDurationController,
///   onDurationChanged: (duration, isCustom) {
///     setState(() {
///       _lessonDuration = duration;
///       _isCustomDuration = isCustom;
///     });
///   },
/// )
/// ```
class LessonDurationSelector extends StatelessWidget {
  /// Currently selected duration in minutes.
  final int selectedDuration;

  /// Whether custom input mode is active.
  final bool isCustom;

  /// Controller for custom input field. If null, custom input is disabled.
  final TextEditingController? customController;

  /// Callback when duration changes. Returns (duration, isCustom).
  final void Function(int duration, bool isCustom) onDurationChanged;

  /// Preset options for quick selection. List of (minutes, label) tuples.
  final List<(int, String)> presets;

  /// Label text shown above the selector.
  final String? label;

  /// Whether the field is required.
  final bool isRequired;

  /// Whether to show custom input option.
  final bool allowCustomInput;

  const LessonDurationSelector({
    super.key,
    required this.selectedDuration,
    this.isCustom = false,
    this.customController,
    required this.onDurationChanged,
    this.presets = const [
      (30, '30분'),
      (45, '45분'),
      (50, '50분'),
      (60, '1시간'),
      (90, '1시간 30분'),
    ],
    this.label,
    this.isRequired = false,
    this.allowCustomInput = true,
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
              final (minutes, displayLabel) = preset;
              final isSelected = !isCustom && selectedDuration == minutes;
              return ChoiceChip(
                label: Text(displayLabel),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onDurationChanged(minutes, false);
                  }
                },
                backgroundColor: AppColors.paper,
                selectedColor: AppColors.paperAccent.withValues(alpha: 0.15),
                checkmarkColor: AppColors.paperAccent,
                side: BorderSide(
                  color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
                ),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.paperAccent
                      : AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
            // Custom input chip
            if (allowCustomInput)
              ChoiceChip(
                label: const Text('직접 입력'),
                selected: isCustom,
                onSelected: (selected) {
                  if (selected) {
                    onDurationChanged(selectedDuration, true);
                  }
                },
                backgroundColor: AppColors.paper,
                selectedColor: AppColors.paperAccent.withValues(alpha: 0.15),
                checkmarkColor: AppColors.paperAccent,
                side: BorderSide(
                  color: isCustom ? AppColors.paperAccent : AppColors.inkQuaternary,
                ),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color:
                      isCustom ? AppColors.paperAccent : AppColors.ink,
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
                hintText: '시간 입력',
                suffixText: '분',
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
                final duration = int.tryParse(value) ?? 0;
                if (duration > 0) {
                  onDurationChanged(duration, true);
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}
