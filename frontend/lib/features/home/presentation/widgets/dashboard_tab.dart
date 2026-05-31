import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/sync/sync_facade.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/paper_scaffold.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../profile/profile_facade.dart';
import '../providers/home_dashboard_provider.dart';
import 'assignment_summary_section.dart';
import 'demo_dashboard_overlay.dart';
import 'quest_board_card.dart';
import 'lesson_card.dart';
import 'lesson_request_section.dart';
import 'schedule_change_request_section.dart';
import 'time_context_banner.dart';
import 'urgent_alert_zone.dart';

/// Dashboard Tab - information hierarchy: urgent → today → trends → tools.
class DashboardTab extends ConsumerWidget {
  final VoidCallback onViewAllLessons;

  const DashboardTab({super.key, required this.onViewAllLessons});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);

    // Get today's lessons
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayLessons = dashboard.lessons.whenData((lessons) {
      return lessons.where((lesson) {
          final lessonDate = lesson.date;
          return lessonDate.year == today.year &&
              lessonDate.month == today.month &&
              lessonDate.day == today.day;
        }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    return PaperScaffold(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(homeDashboardRefreshProvider)
              .refresh(dashboard.teacherId);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space2,
            AppSpacing.screenPadding,
            AppSpacing.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Masthead: Playfair eyebrow + IBM Plex Mono 메타 ──
              _buildMasthead(context),

              // ── Programme Title: 페이지 타이틀 ──
              _buildProgrammeTitle(context, todayLessons),

              const SizedBox(height: AppSpacing.space5),

              const DemoDashboardOverlay(),

              const SizedBox(height: AppSpacing.space4),

              // ── Sync failure banner ────
              _buildSyncFailureBanner(ref),

              // ── 0순위: 선생님이 즉시 처리해야 하는 학생 연결 요청 ────
              _buildPendingConnectionRequests(context, ref),

              const SizedBox(height: AppSpacing.space4),

              // ── 0순위: 시간대 인식 컨텍스트 배너 (다음 레슨) ────
              // (home_master.md §3.5)
              todayLessons.maybeWhen(
                data: (lessons) => TimeContextBanner(todayLessons: lessons),
                orElse: () => const SizedBox.shrink(),
              ),

              // ── Today's Lessons Section (다음 레슨 바로 아래) ──
              _buildTodayLessonsHeader(context, todayLessons),
              const SizedBox(height: AppSpacing.space3),

              todayLessons.when(
                data: (lessons) => _buildLessonsList(context, lessons),
                loading:
                    () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.space4),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                error:
                    (error, _) =>
                        _buildErrorCard(AppStrings.dashboardLessonsLoadError),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Quest Board — profile completion gamification
              const QuestBoardCard(),

              // ── 통계: 오늘 N회 / 이번달 N회 ─────────────────
              _buildStatsRow(context, todayLessons, dashboard.lessonStats),

              const SizedBox(height: AppSpacing.space3),

              // ── 긴급 알림 존 (입금대기 등 — 통계 바로 아래) ────
              UrgentAlertZone(
                teacherId: dashboard.teacherId,
                unpaidSummary: dashboard.unpaidSummary,
                needsConfirmation: dashboard.needsConfirmation,
              ),

              const SizedBox(height: AppSpacing.space6),

              // ── 이벤트: 대응 필요 ──────────────────────────
              _buildEventsGroup(context, ref, dashboard.teacherId),

              const SizedBox(height: AppSpacing.space6),

              const AssignmentSummarySection(),

              const SizedBox(height: AppSpacing.space6),

              // ── Fine. 통계 링크 ──
              _buildAnalyticsLink(context),

              const SizedBox(height: AppSpacing.space8),
            ],
          ),
        ),
      ),
    );
  }

  /// Masthead — Notebook × Score 상단 헤더.
  /// 좌측: "LESSONAZA" (Playfair eyebrow)
  /// 우측: 알림 아이콘
  Widget _buildMasthead(BuildContext context) {
    return NotebookMasthead(
      eyebrow: 'LESSONAZA',
      meta: _volumeIssueString(DateTime.now()),
      trailing: IconButton(
        onPressed: () => context.push(AppRoutes.notifications),
        icon: const Icon(
          Icons.notifications_outlined,
          color: AppColors.ink,
          size: 22,
        ),
        tooltip: AppStrings.notifications,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  /// Programme Title — 페이지 타이틀.
  /// "Programme for Thursday" + "오늘의 레슨" + 날짜·레슨 수.
  Widget _buildProgrammeTitle(
    BuildContext context,
    AsyncValue<List<Lesson>> todayLessons,
  ) {
    final now = DateTime.now();
    final lessonCount = todayLessons.valueOrNull?.length ?? 0;
    final dayLabel = _englishWeekday(now.weekday);

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Programme for $dayLabel',
            style: NotebookTypography.mastheadLabel,
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.dashboardProgrammeTitle,
            style: NotebookTypography.masthead,
          ),
          const SizedBox(height: 6),
          Text(
            '${now.month}月 ${now.day}日  ·  ${AppStrings.dashboardLessonCountFormat(lessonCount)}',
            style: NotebookTypography.mastheadDate,
          ),
          const SizedBox(height: AppSpacing.space3),
          const ThinRule(),
        ],
      ),
    );
  }

  static const _englishWeekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _englishWeekday(int weekday) {
    final idx = (weekday - 1).clamp(0, 6);
    return _englishWeekdays[idx];
  }

  /// "VOL. IV · NO. 18 · APR MMXXVI" 형식 메타 생성.
  /// 알림 아이콘이 자리를 차지하므로 실제 렌더에는 사용되지 않지만,
  /// NotebookMasthead 의 ``meta`` 요구사항을 만족시키기 위해 유지.
  String _volumeIssueString(DateTime now) {
    return 'VOL. ${romanOf(now.month - 1)} · NO. ${now.day}';
  }

  Widget _buildStatsRow(
    BuildContext context,
    AsyncValue<List<Lesson>> todayLessons,
    AsyncValue<Map<String, int>> lessonStatsAsync,
  ) {
    final todayCard = todayLessons.when(
      data:
          (lessons) => StatCard(
            title: AppStrings.todayLessons,
            value: AppStrings.usageCountShort(lessons.length),
            color: AppColors.ink,
            icon: Icons.today,
            onTap: onViewAllLessons,
          ),
      loading:
          () => StatCard(
            title: AppStrings.todayLessons,
            value: '-',
            color: AppColors.ink,
            icon: Icons.today,
          ),
      error:
          (_, __) => StatCard(
            title: AppStrings.todayLessons,
            value: '-',
            color: AppColors.ink,
          ),
    );

    final monthCard = lessonStatsAsync.when(
      data:
          (stats) => StatCard(
            title: AppStrings.dashboardThisMonth,
            value: AppStrings.usageCountShort(stats['completed'] ?? 0),
            color: AppColors.ink,
            icon: Icons.check_circle_outline,
            onTap: () => context.push(AppRoutes.analytics),
          ),
      loading:
          () => StatCard(
            title: AppStrings.dashboardThisMonth,
            value: '-',
            color: AppColors.ink,
            icon: Icons.check_circle_outline,
          ),
      error:
          (_, __) => StatCard(
            title: AppStrings.dashboardThisMonth,
            value: '-',
            color: AppColors.ink,
          ),
    );

    return StatCardRow(cards: [todayCard, monthCard]);
  }

  /// 이벤트 그룹: 레슨 요청 + 스케줄 변경을 시각적으로 묶음.
  /// 두 섹션 모두 빈 경우 자식이 SizedBox.shrink → 그룹 헤더도 자연 숨김.
  Widget _buildEventsGroup(
    BuildContext context,
    WidgetRef ref,
    String teacherId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonRequestSection(userId: teacherId),
        const SizedBox(height: AppSpacing.space4),
        ScheduleChangeRequestSection(teacherId: teacherId),
      ],
    );
  }

  Widget _buildPendingConnectionRequests(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(pendingRequestCountProvider);

    return countAsync.maybeWhen(
      data: (count) {
        if (count <= 0) return const SizedBox.shrink();

        return InkWell(
          onTap: () => context.push(AppRoutes.pendingRequests),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.paperAccentSoft,
              border: Border.all(color: AppColors.paperAccent),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_add_alt_1_outlined,
                  color: AppColors.paperAccent,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.teacherHomeConnectionRequestsTitle(count),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        AppStrings.teacherHomeConnectionRequestsSubtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.paperAccent),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildTodayLessonsHeader(
    BuildContext context,
    AsyncValue<List<Lesson>> todayLessons,
  ) {
    final lessonCount = todayLessons.valueOrNull?.length ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // 로마숫자 카운트 — Notebook × Score 4대 시그니처 (Roman numerals)
        Text(
          lessonCount > 0 ? romanOf(lessonCount - 1) : '—',
          style: NotebookTypography.roman,
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            'Today\'s Programme',
            style: NotebookTypography.sectionTitle,
          ),
        ),
        if (lessonCount > 0)
          TextButton(
            onPressed: () => context.push(AppRoutes.bulkFeedback),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppStrings.bulkFeedbackTitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (lessonCount > 5)
          TextButton.icon(
            onPressed: onViewAllLessons,
            icon: const Icon(
              Icons.calendar_today,
              size: 14,
              color: AppColors.ink,
            ),
            label: Text(
              AppStrings.viewAll,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  Widget _buildLessonsList(BuildContext context, List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_available,
        title: AppStrings.dashboardEmptyTitle,
        subtitle: AppStrings.dashboardEmptySubtitle,
        actionLabel: AppStrings.lessonAddTitle,
        actionIcon: Icons.add,
        onAction: () => context.push(AppRoutes.addLesson),
      );
    }

    // Progressive Disclosure (ux_guidelines §2.6): 5건 + 전체보기
    final hasMore = lessons.length > 5;
    final displayLessons = hasMore ? lessons.take(5).toList() : lessons;

    return Column(
      children: [
        ...displayLessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 로마숫자 인덱스 — Notebook × Score 시그니처
                Padding(
                  padding: const EdgeInsets.only(top: 14, right: 10),
                  child: SizedBox(
                    width: 24,
                    child: Text(
                      '${romanOf(index)}.',
                      style: NotebookTypography.roman,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                Expanded(
                  child: LessonCard(
                    lesson: lesson,
                    onTap:
                        () => context.push(
                          AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
                        ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space1),
            child: OutlinedButton(
              onPressed: onViewAllLessons,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                side: const BorderSide(color: AppColors.inkQuaternary),
                foregroundColor: AppColors.ink,
              ),
              child: Text(
                AppStrings.dashboardMoreLessonsFormat(lessons.length - 5),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// "Fine." 푸터 — 악보 마지막 종지부 인용.
  /// Playfair Display italic "Fine." + 통계 더보기 링크.
  Widget _buildAnalyticsLink(BuildContext context) {
    return Column(
      children: [
        const ThinRule(),
        const SizedBox(height: AppSpacing.space3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Fine.', style: NotebookTypography.fine),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.analytics),
              icon: const Icon(Icons.bar_chart, size: 16, color: AppColors.ink),
              label: Text(
                AppStrings.dashboardAnalyticsMoreLink,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.paperAccent, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space3),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.paperAccent,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sync failure notification banner.
  /// Watches syncServiceStatsStream and displays warning when failed > 0.
  /// Uses angular Notebook × Score design (no rounded corners, inkQuaternary border).
  Widget _buildSyncFailureBanner(WidgetRef ref) {
    return ref
        .watch(syncServiceStatsStreamProvider)
        .when(
          data: (stats) {
            if (stats.failed == 0) {
              return const SizedBox.shrink();
            }

            return DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.inkQuaternary, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: AppColors.paperAccent,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        AppStrings.syncFailedBanner(stats.failed),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    TextButton(
                      onPressed: () {
                        ref.read(syncServiceProvider).retryFailedEntries();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppStrings.syncRetryAction,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
  }
}
