import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/unified_lesson_request.dart';

/// List item for lesson requests — triage card layout.
///
/// Layout optimized for teacher's decision priority:
/// [Academy badge + Avatar] [academy/type+elapsed | name·instrument·level | 1st slot + N more] [Status chip]
class RequestListItem extends StatelessWidget {
  final UnifiedLessonRequest request;
  final String studentName;
  final String? academyName;
  final VoidCallback? onTap;

  const RequestListItem({
    super.key,
    required this.request,
    required this.studentName,
    this.academyName,
    this.onTap,
  });

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
            _buildStatusChip(),
          ],
        ),
      ),
    );
  }

  /// Student avatar with academy badge overlay.
  Widget _buildAvatar() {
    final avatar = CircleAvatar(
      radius: AppSpacing.avatarSmall / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      child: Text(
        studentName.isNotEmpty ? studentName[0] : '?',
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );

    if (!request.isAcademy) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            child: const Center(
              child: Text('🏫', style: TextStyle(fontSize: 10)),
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
          '$studentName · ${request.instrument} · ${request.experience.label}',
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

  /// Line 1: [학원명/개인레슨] [체험/정규] [3일 전]
  Widget _buildLine1() {
    final source =
        request.isAcademy ? (academyName ?? AppStrings.academy) : AppStrings.individualLesson;
    final urgent = isRequestUrgent(request.createdAt);

    return Row(
      children: [
        Flexible(
          child: Text(
            '$source ${request.typeDisplayLabel}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
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

  Widget _buildStatusChip() {
    final (label, color) = _statusStyle;

    return Container(
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
    );
  }

  (String, Color) get _statusStyle {
    return switch (request.status) {
      UnifiedRequestStatus.completed =>
        (AppStrings.statusCompleted, AppColors.success),
      UnifiedRequestStatus.paymentNotified =>
        (AppStrings.statusPaymentDone, AppColors.error),
      UnifiedRequestStatus.cancelled =>
        (AppStrings.cancel, AppColors.warning),
      UnifiedRequestStatus.expired =>
        (AppStrings.statusExpired, AppColors.warning),
      UnifiedRequestStatus.rejected =>
        (request.statusChipLabel, AppColors.warning),
      _ => (request.statusChipLabel, AppColors.textPrimaryLight),
    };
  }
}
