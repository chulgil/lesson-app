import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';

/// Display mode for schedule option card
///
/// **DEPRECATED**: Part of the old multi-option scheduling system.
/// Use [AvailabilityChipSelector] for the new single-selection UI.
@Deprecated('Use AvailabilityChipSelector. Will be removed in v2.0.')
enum ScheduleOptionCardMode {
  /// Student view - editable with change/delete buttons
  student,

  /// Teacher view - selectable for approval
  teacher,

  /// Read-only view - shows selected status
  readonly,
}

/// A card widget displaying a schedule option with priority
///
/// **DEPRECATED**: Part of the old multi-option scheduling system.
/// Use [AvailabilityChipSelector] for the new single-selection UI.
@Deprecated('Use AvailabilityChipSelector. Will be removed in v2.0.')
class ScheduleOptionCard extends StatelessWidget {
  final ScheduleOption option;
  final ScheduleOptionCardMode mode;
  final bool isSelected;
  final bool isDisabled;
  final bool showDragHandle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ScheduleOptionCard({
    super.key,
    required this.option,
    this.mode = ScheduleOptionCardMode.readonly,
    this.isSelected = false,
    this.isDisabled = false,
    this.showDragHandle = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = option.priority == 1;
    final borderColor = isSelected
        ? AppColors.primary
        : isDisabled
            ? AppColors.borderLight
            : AppColors.borderLight;
    final backgroundColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.05)
        : isDisabled
            ? AppColors.textSecondaryLight.withValues(alpha: 0.05)
            : AppColors.backgroundLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle (left side)
                if (showDragHandle)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: AppSpacing.space3,
                      top: AppSpacing.space1,
                    ),
                    child: ReorderableDragStartListener(
                      index: option.priority - 1,
                      child: Icon(
                        Icons.drag_handle,
                        color: AppColors.textTertiaryLight,
                        size: 24,
                      ),
                    ),
                  ),
                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Priority badge + Actions
                      Row(
                        children: [
                          _buildPriorityBadge(isPrimary),
                          const Spacer(),
                          if (mode == ScheduleOptionCardMode.student) ...[
                            if (onEdit != null)
                              _buildActionButton(
                                icon: Icons.edit_outlined,
                                onTap: onEdit!,
                              ),
                            if (onDelete != null) ...[
                              const SizedBox(width: AppSpacing.space1),
                              _buildActionButton(
                                icon: Icons.close,
                                onTap: onDelete!,
                              ),
                            ],
                          ] else if (mode == ScheduleOptionCardMode.teacher) ...[
                            _buildSelectionIndicator(),
                          ],
                        ],
                      ),

                      const SizedBox(height: AppSpacing.space3),

                      // Schedule content
                      if (option.isSingleLesson)
                        _buildSingleLessonContent()
                      else if (option.isRegularLesson)
                        _buildRegularLessonContent(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.textSecondaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPrimary) ...[
            Icon(
              Icons.star,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.space1),
          ],
          Text(
            option.priorityLabel,
            style: AppTypography.caption.copyWith(
              color: isPrimary ? AppColors.primary : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space1),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderLight,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _buildSingleLessonContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.textPrimaryLight,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              option.fullFormattedDate,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: isDisabled
                    ? AppColors.textSecondaryLight
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.space2),

        // Time
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 18,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              option.timeRange,
              style: AppTypography.bodyMedium.copyWith(
                color: isDisabled
                    ? AppColors.textSecondaryLight
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegularLessonContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary day
        Row(
          children: [
            Icon(
              Icons.repeat,
              size: 18,
              color: AppColors.textPrimaryLight,
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                option.isWeekly2x
                    ? '${option.shortDayName} ${option.timeRange}'
                    : '매주 ${option.dayName}',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? AppColors.textSecondaryLight
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),

        // Secondary day for weekly 2x
        if (option.isWeekly2x) ...[
          const SizedBox(height: AppSpacing.space1),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              '+ ${option.secondShortDayName} ${option.secondTimeRange}',
              style: AppTypography.bodyMedium.copyWith(
                color: isDisabled
                    ? AppColors.textSecondaryLight
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],

        if (!option.isWeekly2x) ...[
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 18,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                option.timeRange,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDisabled
                      ? AppColors.textSecondaryLight
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ],

        // Start date
        if (option.startDate != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Icon(
                Icons.event,
                size: 18,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '시작일: ${option.startDate!.month}월 ${option.startDate!.day}일',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A button for adding a new schedule option
class AddScheduleOptionButton extends StatelessWidget {
  final int optionNumber;
  final VoidCallback onTap;

  const AddScheduleOptionButton({
    super.key,
    required this.optionNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: AppColors.borderLight,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '$optionNumber순위 추가 (선택)',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
