import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../students/domain/entities/lesson_class.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../subscription/subscription_facade.dart';
import '../../../subscription/presentation/widgets/subscription_badge.dart';

/// A card displaying a single lesson with time, student info, and status.
class LessonCard extends ConsumerWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const LessonCard({super.key, required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border(left: BorderSide(color: _getStatusColor(), width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              // Time column (fixed width)
              SizedBox(
                width: 56,
                child: Text(
                  lesson.startTime,
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.space3),

              // Info section (flexible)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lesson.studentName} · ${lesson.instrument}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _buildBadgesRow(ref),
                    if (lesson.pieces.isNotEmpty)
                      Text(
                        lesson.pieces.first.displayName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Status (fixed width)
              SizedBox(
                width: 36,
                child: Text(
                  _getStatusLabel(),
                  style: AppTypography.caption.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),

              const SizedBox(width: AppSpacing.space1),

              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel() {
    switch (lesson.displayStatus) {
      case LessonStatus.scheduled:
      case LessonStatus.reschedulePending:
        return '예정';
      case LessonStatus.completed:
        return '완료';
      case LessonStatus.cancelled:
      case LessonStatus.cancelledByStudentAdvance:
      case LessonStatus.cancelledByTeacher:
      case LessonStatus.cancelledMutual:
        return '취소';
      case LessonStatus.noShow:
      case LessonStatus.cancelledByStudentLate:
      case LessonStatus.studentAbsent:
        return '결석';
    }
  }

  Color _getStatusColor() {
    switch (lesson.displayStatus) {
      case LessonStatus.scheduled:
      case LessonStatus.reschedulePending:
        return AppColors.primary;
      case LessonStatus.completed:
        return AppColors.success;
      case LessonStatus.cancelled:
      case LessonStatus.cancelledByStudentAdvance:
      case LessonStatus.cancelledByTeacher:
      case LessonStatus.cancelledMutual:
        return AppColors.textTertiaryLight;
      case LessonStatus.noShow:
      case LessonStatus.cancelledByStudentLate:
      case LessonStatus.studentAbsent:
        return AppColors.error;
    }
  }

  /// Build context badge and subscription badge row.
  Widget _buildBadgesRow(WidgetRef ref) {
    final memberships =
        ref
            .watch(activeStudentMembershipsProvider(lesson.studentId))
            .valueOrNull;
    final subscriptions =
        ref
            .watch(activeStudentSubscriptionsProvider(lesson.studentId))
            .valueOrNull;

    // Context badge from lesson class
    Widget? contextBadge;
    if (memberships != null && memberships.isNotEmpty) {
      final lessonClass =
          ref
              .watch(lessonClassProvider(memberships.first.lessonClassId))
              .valueOrNull;
      if (lessonClass != null) {
        final isAcademy = lessonClass.type == LessonClassType.academy;
        contextBadge = Text(
          isAcademy ? '🏫 ${lessonClass.name}' : '👤 개인레슨',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
    }

    final subscription =
        (subscriptions?.isNotEmpty == true) ? subscriptions!.first : null;

    if (contextBadge == null && subscription == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          if (contextBadge != null) Flexible(child: contextBadge),
          if (contextBadge != null && subscription != null)
            const SizedBox(width: 6),
          if (subscription != null)
            SubscriptionBadge(subscription: subscription, showIcon: false),
        ],
      ),
    );
  }
}
