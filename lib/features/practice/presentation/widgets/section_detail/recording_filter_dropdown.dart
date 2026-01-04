// Recording filter dropdown widget

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/recording_filter_type.dart';

/// Dropdown for filtering recordings by date range
class RecordingFilterDropdown extends StatelessWidget {
  final RecordingFilterType selectedFilter;
  final ValueChanged<RecordingFilterType> onFilterChanged;

  const RecordingFilterDropdown({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RecordingFilterType>(
          value: selectedFilter,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          iconEnabledColor: AppColors.textSecondaryLight,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          isDense: true,
          items: RecordingFilterType.values.map((type) {
            return DropdownMenuItem<RecordingFilterType>(
              value: type,
              child: Text(type.displayLabel),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onFilterChanged(value);
            }
          },
        ),
      ),
    );
  }
}
