import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/presentation/providers/unified_lesson_request_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';

/// Home dashboard section showing pending schedule change requests.
///
/// Replaces TeacherSubscriptionSection — shows pending change/cancel requests.
/// Max 3 items + "더보기" button. Hidden when 0 items.
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
            // Header: "스케줄 변경요청 (N)"
            _buildHeader(context, requests.length),
            const SizedBox(height: AppSpacing.space1),

            // Mini stats: 변경 N · 취소 N
            _buildChangeStats(requests),
            const SizedBox(height: AppSpacing.space2),

            // Request list items
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
                    _buildRequestItem(
                      context,
                      displayRequests[i],
                      studentNames,
                    ),
                  ],
                ],
              ),
            ),

            // "더보기" button
            if (requests.length > 3) ...[
              const SizedBox(height: AppSpacing.space2),
              Center(
                child: TextButton(
                  onPressed: () => context.push(
                    '${AppRoutes.scheduleChangeRequests}?teacherId=$teacherId',
                  ),
                  child: Text(
                    AppStrings.moreRequests(requests.length - 3),
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
        .where((r) => r.eventType == RequestEventType.scheduleChangeProposed)
        .length;
    final cancelCount = requests
        .where((r) => r.eventType == RequestEventType.lessonCancelled)
        .length;

    final parts = <String>[];
    if (changeCount > 0) {
      parts.add(AppStrings.phaseStatLabel(AppStrings.changeTypeLabel, changeCount));
    }
    if (cancelCount > 0) {
      parts.add(AppStrings.phaseStatLabel(AppStrings.cancelTypeLabel, cancelCount));
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
              const Icon(
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

  Widget _buildRequestItem(
    BuildContext context,
    RequestEvent event,
    Map<String, String> studentNames,
  ) {
    final studentName = studentNames[event.actorId] ?? '';
    final sessionLabel = event.sessionNumber != null
        ? AppStrings.sessionNumberLabel(event.sessionNumber!)
        : '';
    final typeLabel =
        event.eventType == RequestEventType.scheduleChangeProposed
            ? AppStrings.sessionChangeRequest
            : AppStrings.sessionCancelRequest;
    final relativeTime = formatRelativeTime(event.createdAt);

    final isChange =
        event.eventType == RequestEventType.scheduleChangeProposed;

    return GestureDetector(
      onTap: event.subscriptionId != null
          ? () => context.push(
                AppRoutes.subscriptionDetail
                    .replaceFirst(':id', event.subscriptionId!),
                extra: {'viewerRole': 'teacher'},
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            // Type indicator dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isChange ? AppColors.primary : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            // Content
            Expanded(
              child: Text(
                '$studentName $sessionLabel $typeLabel',
                style: AppTypography.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Relative time
            Text(
              relativeTime,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
