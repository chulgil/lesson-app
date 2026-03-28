import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/unified_lesson_request.dart';

/// List item for lesson requests — used in home section and full list.
///
/// Layout: [Type badge] [Info: academy/name·instrument·goal | message] [Status chip]
class RequestListItem extends StatelessWidget {
  final UnifiedLessonRequest request;
  final String studentName;
  final String? lastMessage;
  final VoidCallback? onTap;

  const RequestListItem({
    super.key,
    required this.request,
    required this.studentName,
    this.lastMessage,
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
            // Left: type badge
            _buildTypeBadge(),
            const SizedBox(width: AppSpacing.space3),

            // Center: info
            Expanded(child: _buildInfo()),

            const SizedBox(width: AppSpacing.space3),

            // Right: status chip
            _buildStatusChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      width: AppSpacing.avatarSmall,
      height: AppSpacing.avatarSmall,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Center(
        child: Text(
          _typeAbbrev,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  String get _typeAbbrev {
    if (request.isReturningStudent && request.type == LessonRequestType.regular) {
      return '재';
    }
    return switch (request.type) {
      LessonRequestType.trial => '체험',
      LessonRequestType.regular => '정규',
      LessonRequestType.package => '회차',
    };
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line 1: academy or "개인"
        Text(
          request.isAcademy ? AppStrings.academy : AppStrings.individual,
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),

        // Line 2: student name + instrument + goal + level
        Text(
          '$studentName · ${request.instrument} · ${request.goal.label} · ${request.experience.label}',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // Line 3: last message (if any)
        if (lastMessage != null && lastMessage!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            lastMessage!,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
      UnifiedRequestStatus.completed => ('완료', AppColors.success),
      UnifiedRequestStatus.paymentNotified => ('입금완료', AppColors.error),
      UnifiedRequestStatus.cancelled => ('취소', AppColors.warning),
      UnifiedRequestStatus.expired => ('만료', AppColors.warning),
      UnifiedRequestStatus.rejected => ('거절', AppColors.warning),
      _ => (request.statusChipLabel, AppColors.textPrimaryLight),
    };
  }
}
