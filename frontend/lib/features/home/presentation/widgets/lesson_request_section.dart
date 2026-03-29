import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../schedule/presentation/providers/unified_lesson_request_providers.dart';
import '../../../schedule/presentation/widgets/request_list_item.dart';

/// Home dashboard section showing today's lesson requests.
///
/// Replaces UrgentActionsSection — shows active + today-completed requests.
/// Max 3 items + "더보기" button. Hidden when 0 items.
class LessonRequestSection extends ConsumerWidget {
  final String userId;
  final String viewerRole; // 'teacher' or 'student'

  const LessonRequestSection({
    super.key,
    required this.userId,
    this.viewerRole = 'teacher',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = viewerRole == 'teacher'
        ? ref.watch(todayRequestsProvider(userId))
        : ref.watch(studentTodayRequestsProvider(userId));
    final studentNames = ref.watch(studentNameMapProvider);
    final academyNames = ref.watch(academyNameMapProvider);

    return requestsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();

        final displayRequests = requests.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "레슨요청 (N)"
            _buildHeader(context, requests.length),
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
                    RequestListItem(
                      request: displayRequests[i],
                      studentName: studentNames[displayRequests[i].studentId] ?? AppStrings.student,
                      academyName: academyNames[displayRequests[i].academyId],
                      onTap: () => context.push(
                        AppRoutes.requestDetail
                            .replaceFirst(':id', displayRequests[i].id),
                        extra: {'viewerRole': viewerRole},
                      ),
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
                    '${AppRoutes.lessonRequests}?teacherId=$userId',
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

  Widget _buildHeader(BuildContext context, int totalCount) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.assignment,
                  size: AppSpacing.iconSM, color: AppColors.textSecondaryLight),
              const SizedBox(width: AppSpacing.space2),
              Text(AppStrings.lessonRequest, style: AppTypography.headingMedium),
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
              '${AppRoutes.lessonRequests}?teacherId=$userId',
            ),
            icon: const Icon(Icons.list, size: AppSpacing.iconXS),
            label: const Text('전체보기'),
          ),
      ],
    );
  }
}
