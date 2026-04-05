import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../schedule/domain/entities/lesson_schedule_change.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/presentation/providers/unified_lesson_request_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';

/// Home dashboard section showing pending schedule change requests.
///
/// Uses the same card layout pattern as LessonRequestSection / RequestListItem:
/// Avatar + info lines + status chip + elapsed time.
class ScheduleChangeRequestSection extends ConsumerWidget {
  final String teacherId;

  const ScheduleChangeRequestSection({
    super.key,
    required this.teacherId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(
      pendingScheduleChangeRequestsProvider(teacherId),
    );
    final studentNames = ref.watch(studentNameMapProvider);

    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();

        final displayRequests = requests.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, requests.length),
            const SizedBox(height: AppSpacing.space1),
            _buildChangeStats(requests),
            const SizedBox(height: AppSpacing.space2),

            // Request list (same card container as LessonRequestSection)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < displayRequests.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: AppSpacing.space4),
                    _ScheduleChangeListItem(
                      event: displayRequests[i],
                      studentName: studentNames[displayRequests[i].actorId] ??
                          AppStrings.student,
                      onTap: displayRequests[i].subscriptionId != null
                          ? () => context.push(
                                AppRoutes.subscriptionDetail.replaceFirst(
                                    ':id',
                                    displayRequests[i].subscriptionId!),
                                extra: {'viewerRole': 'teacher'},
                              )
                          : null,
                    ),
                  ],
                ],
              ),
            ),

            if (requests.length > 3) ...[
              const SizedBox(height: AppSpacing.space2),
              Center(
                child: TextButton(
                  onPressed: () => context.push(
                    '${AppRoutes.scheduleChangeRequests}?teacherId=$teacherId',
                  ),
                  child: Text(
                    AppStrings.moreSubscriptions(requests.length - 3),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildChangeStats(List<RequestEvent> requests) {
    final changeCount = requests
        .where((r) =>
            r.eventType == RequestEventType.scheduleChanged ||
            r.eventType == RequestEventType.scheduleChangeProposed ||
            r.eventType == RequestEventType.scheduleChangeCountered)
        .length;
    final cancelCount = requests
        .where((r) => r.eventType == RequestEventType.lessonCancelled)
        .length;
    final completedCount = requests
        .where((r) => r.eventType == RequestEventType.scheduleChangeAccepted)
        .length;

    final parts = <String>[];
    if (changeCount > 0) {
      parts.add(AppStrings.phaseStatLabel(AppStrings.changeTypeLabel, changeCount));
    }
    if (cancelCount > 0) {
      parts.add(AppStrings.phaseStatLabel(AppStrings.cancelTypeLabel, cancelCount));
    }
    if (completedCount > 0) {
      parts.add(AppStrings.phaseStatLabel(AppStrings.tabCompleted, completedCount));
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.space2),
      child: Text(
        parts.join(' · '),
        style: AppTypography.caption.copyWith(
          color: AppColors.textTertiaryLight,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalCount) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: AppSpacing.iconSM,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                AppStrings.scheduleChangeRequests,
                style: AppTypography.headingMedium,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '($totalCount)',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        if (totalCount > 3)
          TextButton.icon(
            onPressed: () => context.push(
              '${AppRoutes.scheduleChangeRequests}?teacherId=$teacherId',
            ),
            icon: const Icon(Icons.list, size: AppSpacing.iconXS),
            label: Text(AppStrings.viewAll),
          ),
      ],
    );
  }
}

/// List item for schedule change requests — same layout as RequestListItem.
/// Avatar + info column + right column (status chip + elapsed time).
class _ScheduleChangeListItem extends StatelessWidget {
  final RequestEvent event;
  final String studentName;
  final VoidCallback? onTap;

  const _ScheduleChangeListItem({
    required this.event,
    required this.studentName,
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
            _buildRightColumn(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initial = studentName.isNotEmpty ? studentName[0] : '?';
    final isUrgent = DateTime.now().difference(event.createdAt).inHours >= 24;

    final avatar = CircleAvatar(
      radius: AppSpacing.avatarSmall / 2,
      backgroundColor: _statusColor.withValues(alpha: 0.08),
      child: Text(
        initial,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: _statusColor,
        ),
      ),
    );

    if (!isUrgent) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          top: -2,
          right: -2,
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
        // Line 1: student name
        Text(
          studentName,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // Line 2: session + type
        Text(
          _descriptionText,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Text(
            _statusLabel,
            style: AppTypography.caption.copyWith(
              color: _statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Elapsed time
        Text(
          formatRelativeTime(event.createdAt),
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }

  String get _descriptionText {
    final sessionText = event.sessionNumber != null
        ? AppStrings.sessionNumberLabel(event.sessionNumber!)
        : '';
    final isBulk = event.scheduleChangeType == ScheduleChangeType.bulkChange;

    switch (event.eventType) {
      case RequestEventType.scheduleChanged:
        return isBulk
            ? '$sessionText ${AppStrings.changeTypeBulkLabel}'
            : '$sessionText ${AppStrings.sessionChangeRequest}';
      case RequestEventType.lessonCancelled:
        return '$sessionText ${AppStrings.sessionCancelRequest}';
      case RequestEventType.scheduleChangeProposed:
        return '$sessionText ${AppStrings.rescheduleRequest}';
      case RequestEventType.scheduleChangeAccepted:
        return '$sessionText ${AppStrings.tabCompleted}';
      default:
        return '$sessionText ${AppStrings.sessionChangeRequest}';
    }
  }

  String get _statusLabel {
    switch (event.eventType) {
      case RequestEventType.scheduleChanged:
      case RequestEventType.lessonCancelled:
        return AppStrings.tabPending;
      case RequestEventType.scheduleChangeProposed:
      case RequestEventType.scheduleChangeCountered:
        return AppStrings.rescheduleRequest;
      case RequestEventType.scheduleChangeAccepted:
        return AppStrings.tabCompleted;
      default:
        return AppStrings.tabPending;
    }
  }

  Color get _statusColor {
    switch (event.eventType) {
      case RequestEventType.scheduleChanged:
        return AppColors.primary;
      case RequestEventType.lessonCancelled:
        return AppColors.error;
      case RequestEventType.scheduleChangeProposed:
      case RequestEventType.scheduleChangeCountered:
        return AppColors.warning;
      case RequestEventType.scheduleChangeAccepted:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}
