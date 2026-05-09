import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../schedule/schedule_ui_facade.dart';

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
    final requestsAsync =
        viewerRole == 'teacher'
            ? ref.watch(todayRequestsProvider(userId))
            : ref.watch(studentTodayRequestsProvider(userId));
    final studentNames = ref.watch(studentNameMapProvider);
    final teacherNames = ref.watch(teacherNameMapProvider);
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
            const SizedBox(height: AppSpacing.space1),

            // Phase mini stats
            _buildPhaseStats(requests),
            const SizedBox(height: AppSpacing.space2),

            // Notebook × Score: 종이 위의 목록. 1px 잉크 구분선만, 카드 배경 없음.
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.inkQuaternary),
                  bottom: BorderSide(color: AppColors.inkQuaternary),
                ),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < displayRequests.length; i++) ...[
                    if (i > 0)
                      const ThinRule(),
                    RequestListItem(
                      request: displayRequests[i],
                      studentName:
                          studentNames[displayRequests[i].studentId] ??
                          AppStrings.student,
                      teacherName: teacherNames[displayRequests[i].teacherId],
                      academyName: academyNames[displayRequests[i].academyId],
                      viewerRole: viewerRole,
                      onTap:
                          () => context.push(
                            AppRoutes.requestDetail.replaceFirst(
                              ':id',
                              displayRequests[i].id,
                            ),
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
                  onPressed:
                      () => context.push(
                        viewerRole == 'student'
                            ? '${AppRoutes.myLessonRequests}?studentId=$userId'
                            : '${AppRoutes.lessonRequests}?teacherId=$userId',
                      ),
                  child: Text(
                    AppStrings.moreRequests(requests.length - 3),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
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

  Widget _buildPhaseStats(List<UnifiedLessonRequest> requests) {
    final counts = <RequestPhase, int>{};
    for (final r in requests) {
      final phase = r.currentPhase;
      if (phase != RequestPhase.terminal) {
        counts[phase] = (counts[phase] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return const SizedBox.shrink();

    final entries = <String>[];
    const phaseLabels = {
      RequestPhase.request: AppStrings.phaseFilterRequest,
      RequestPhase.subscription: AppStrings.phaseFilterSubscription,
      RequestPhase.lessons: AppStrings.phaseFilterInProgress,
      RequestPhase.completed: AppStrings.phaseFilterCompleted,
    };

    for (final phase in [
      RequestPhase.request,
      RequestPhase.subscription,
      RequestPhase.lessons,
      RequestPhase.completed,
    ]) {
      final count = counts[phase];
      if (count != null && count > 0) {
        entries.add(AppStrings.phaseStatLabel(phaseLabels[phase]!, count));
      }
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.space2),
      child: Text(
        entries.join(' · '),
        style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalCount) {
    return NotebookSectionHeader(
      label: '${AppStrings.lessonRequest} · $totalCount',
      trailing:
          totalCount > 3
              ? TextButton.icon(
                onPressed:
                    () => context.push(
                      viewerRole == 'student'
                          ? '${AppRoutes.myLessonRequests}?studentId=$userId'
                          : '${AppRoutes.lessonRequests}?teacherId=$userId',
                    ),
                icon: const Icon(
                  Icons.list,
                  size: AppSpacing.iconXS,
                  color: AppColors.ink,
                ),
                label: Text(
                  AppStrings.viewAll,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
              : null,
    );
  }
}
