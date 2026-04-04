import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/unified_lesson_request.dart';

/// List item for lesson requests — triage card layout.
///
/// Supports both teacher and student perspectives via [viewerRole].
/// Teacher view: shows student name, avatar, teacher action label.
/// Student view: shows teacher name, avatar, student action label.
class RequestListItem extends StatelessWidget {
  final UnifiedLessonRequest request;
  final String studentName;
  final String? teacherName;
  final String? academyName;
  final String viewerRole;
  final VoidCallback? onTap;

  const RequestListItem({
    super.key,
    required this.request,
    required this.studentName,
    this.teacherName,
    this.academyName,
    this.viewerRole = 'teacher',
    this.onTap,
  });

  bool get _isStudentView => viewerRole == 'student';

  /// Display name: teacher view shows student, student view shows teacher.
  String get _displayName =>
      _isStudentView
          ? AppStrings.teacherDisplayName(teacherName ?? AppStrings.teacher)
          : studentName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: AppSpacing.space3),
            Expanded(child: _buildInfo()),
            const SizedBox(width: AppSpacing.space3),
            _buildRightColumn(),
          ],
        ),
      ),
    );
  }

  /// Avatar with urgency dot overlay.
  Widget _buildAvatar() {
    final urgent = isRequestUrgent(request.createdAt);
    final initial = _displayName.isNotEmpty ? _displayName[0] : '?';
    final avatar = CircleAvatar(
      radius: AppSpacing.avatarSmall / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      child: Text(
        initial,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );

    if (!urgent) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceLight, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line 1: source badge + type + elapsed time
        _buildLine1(),
        const SizedBox(height: AppSpacing.space1),

        // Line 2: name · instrument · level
        Text(
          '$_displayName · ${request.instrument} · ${request.experience.label}',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.space1),

        // Line 3: 1st preferred time + "외 N건"
        _buildLine3(),
      ],
    );
  }

  /// Line 1: [학원명/개인레슨] · [체험/정규]
  Widget _buildLine1() {
    final source =
        request.isAcademy ? (academyName ?? AppStrings.academy) : AppStrings.individualLesson;

    return Text(
      '$source · ${request.typeDisplayLabel}',
      style: AppTypography.caption.copyWith(
        color: AppColors.textTertiaryLight,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Line 3: 1st preferred slot + "외 N건"
  Widget _buildLine3() {
    final slots = request.preferredSlots;
    if (slots.isEmpty) {
      return Text(
        AppStrings.noTimeSpecified,
        style: AppTypography.caption.copyWith(
          color: AppColors.textTertiaryLight,
        ),
      );
    }

    // Sort by priority, take the first
    final sorted = [...slots]..sort((a, b) => a.priority.compareTo(b.priority));
    final firstSlot = sorted.first;
    final remaining = slots.length - 1;

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: AppSpacing.iconXS,
          color: AppColors.textTertiaryLight,
        ),
        const SizedBox(width: AppSpacing.space1),
        Text(
          firstSlot.displayLabel,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        if (remaining > 0) ...[
          const SizedBox(width: AppSpacing.space1),
          Text(
            AppStrings.slotsRemaining(remaining),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ],
    );
  }

  /// Right column: status chip + elapsed time (vertically stacked).
  Widget _buildRightColumn() {
    final label = _isStudentView
        ? request.studentActionLabel
        : request.teacherActionLabel;
    final color = _actionColor;
    final urgent = isRequestUrgent(request.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          formatRelativeTime(request.createdAt),
          style: AppTypography.caption.copyWith(
            color: urgent ? AppColors.error : AppColors.textTertiaryLight,
            fontWeight: urgent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Color get _actionColor {
    final colorKey = _isStudentView
        ? request.studentActionColorKey
        : request.teacherActionColorKey;
    return switch (colorKey) {
      'action' => AppColors.primary,
      _ => AppColors.textTertiaryLight,
    };
  }
}
