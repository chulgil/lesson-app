import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/student_lesson_progress_item.dart';

class StudentLessonProgressItemRow extends StatelessWidget {
  final StudentLessonProgressItem item;
  final VoidCallback? onTap;

  const StudentLessonProgressItemRow({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBox(kind: item.kind),
            const SizedBox(width: AppSpacing.space3),
            Expanded(child: _InfoColumn(item: item)),
            const SizedBox(width: AppSpacing.space2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 82),
              child: _RightColumn(item: item),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final StudentLessonProgressItem item;

  const _InfoColumn({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          item.subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  final StudentLessonProgressItem item;

  const _RightColumn({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(item.priority);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12)),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.statusLabel,
              maxLines: 1,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          formatRelativeTime(item.createdAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  final StudentLessonProgressKind kind;

  const _IconBox({required this.kind});

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(kind);
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.paperDark),
      child: Icon(icon, size: 18, color: AppColors.paperAccent),
    );
  }
}

IconData _iconFor(StudentLessonProgressKind kind) {
  return switch (kind) {
    StudentLessonProgressKind.request => Icons.edit_calendar_outlined,
    StudentLessonProgressKind.proposal => Icons.confirmation_number_outlined,
    StudentLessonProgressKind.payment => Icons.receipt_long_outlined,
    StudentLessonProgressKind.subscriptionReady =>
      Icons.card_membership_outlined,
    StudentLessonProgressKind.scheduleConfirmation =>
      Icons.event_available_outlined,
    StudentLessonProgressKind.renewal => Icons.autorenew,
  };
}

Color _priorityColor(StudentLessonProgressPriority priority) {
  return switch (priority) {
    StudentLessonProgressPriority.actionRequired => AppColors.paperAccent,
    StudentLessonProgressPriority.waiting => AppColors.ink,
    StudentLessonProgressPriority.completed => AppColors.paperOk,
  };
}
