import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/unified_lesson_request.dart';

/// List item for lesson requests — used in home section and full list.
///
/// Layout: [Student avatar] [Info: 개인레슨 정규 | 이름·악기·목표 | message] [Status chip]
class RequestListItem extends StatelessWidget {
  final UnifiedLessonRequest request;
  final String studentName;
  final String? academyName;
  final String? lastMessage;
  final VoidCallback? onTap;

  const RequestListItem({
    super.key,
    required this.request,
    required this.studentName,
    this.academyName,
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
            // Left: student profile avatar
            _buildStudentAvatar(),
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

  /// Student profile photo or initial avatar (like assignment list).
  Widget _buildStudentAvatar() {
    return CircleAvatar(
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
  }

  /// "개인레슨 정규" or "서울음악학원 체험" format.
  String get _sourceAndType {
    final source = request.isAcademy
        ? (academyName ?? AppStrings.academy)
        : AppStrings.individualLesson;
    return '$source ${request.typeDisplayLabel}';
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line 1: source + type ("개인레슨 정규" or "서울음악학원 체험")
        Text(
          _sourceAndType,
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
