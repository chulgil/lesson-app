import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/paper_scaffold.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../billing/billing_facade.dart';
import '../../../notifications/notifications_facade.dart';
import '../../../practice/domain/entities/practice_loop_stats.dart';
import '../../../practice/practice_facade.dart';
import '../../../practice/practice_ui_facade.dart';
import '../../../profile/profile_facade.dart';
import '../providers/home_dashboard_provider.dart';
import 'assignment_summary_section.dart';
import 'demo_dashboard_overlay.dart';
import '../../../profile/profile_ui_facade.dart';
import '../../../subscription/subscription_ui_facade.dart';
import 'quest_board_card.dart';
import 'lesson_card.dart';
import 'lesson_request_section.dart';
import 'next_mission_spotlight.dart';
import 'pending_actions_summary.dart';
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

    return Stack(
      children: [
        PaperScaffold(
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
                  _buildMasthead(context, ref),

                  // ── Programme Title: 페이지 타이틀 ──
                  _buildProgrammeTitle(context, todayLessons),

                  const SizedBox(height: AppSpacing.space5),

                  const DemoDashboardOverlay(),

                  const SizedBox(height: AppSpacing.space4),

                  // #1120: sync failure surface is now the app-wide
                  // SyncStatusBanner (all roles), so the teacher-only
                  // banner here was removed to avoid a duplicate.

                  // ── 최상위: 4개 "확인 필요" 표면(연결·예약승인·레슨요청·
                  // 일정변경) 통합 카운터. 각 표면은 아래에 개별로 그대로 유지.
                  PendingActionsSummary(teacherId: dashboard.teacherId),

                  const SizedBox(height: AppSpacing.space4),

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
                    // 로드 실패는 빨간 에러가 아니라 부드러운 재시도 상태로 표시.
                    // (빈 데이터는 data 경로의 EmptyStateWidget 이 담당)
                    error:
                        (error, _) => EmptyStateWidget(
                          icon: Icons.cloud_off_outlined,
                          title: AppStrings.dashboardLessonsLoadErrorTitle,
                          subtitle: AppStrings.dashboardLessonsLoadErrorHint,
                          actionLabel: AppStrings.retry,
                          actionIcon: Icons.refresh,
                          onAction:
                              () => ref
                                  .read(homeDashboardRefreshProvider)
                                  .refresh(dashboard.teacherId),
                        ),
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Payment-pending dashboard card — #424. Hides itself when count=0.
                  const PaymentPendingCard(),
                  const SizedBox(height: AppSpacing.space3),

                  // Refund-pending dashboard card — #1271. Hides when count=0.
                  const RefundPendingCard(),
                  const SizedBox(height: AppSpacing.space3),

                  // Invite-pending dashboard card — #5 D-G3 Phase 2. Hides when count=0.
                  const InvitePendingCard(),
                  const SizedBox(height: AppSpacing.space3),

                  // Quest Board — profile completion gamification
                  const QuestBoardCard(),

                  // ── 통계: 오늘 N회 / 이번달 N회 ─────────────────
                  _buildStatsRow(context, ref, dashboard.lessonStats),

                  const SizedBox(height: AppSpacing.space3),

                  // ── 긴급 알림 존 (미수금 등 — 통계 바로 아래) ────
                  UrgentAlertZone(
                    teacherId: dashboard.teacherId,
                    unpaidSummary: dashboard.unpaidSummary,
                    needsConfirmation: dashboard.needsConfirmation,
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // ── 이벤트: 대응 필요 ──────────────────────────
                  _buildEventsGroup(context, ref, dashboard.teacherId),

                  const SizedBox(height: AppSpacing.space6),

                  // 피드백 대기 배지 (껍데기 감사 #415 / #1128) — 0건이면 숨김.
                  const AwaitingFeedbackCard(),

                  const AssignmentSummarySection(),

                  const SizedBox(height: AppSpacing.space6),

                  // ── Loop Stats Entry (#512) — 영상 반복 통계 진입점 ──
                  _LoopStatsEntryCard(),

                  const SizedBox(height: AppSpacing.space6),

                  // ── Fine. 종지부 ──
                  _buildFineFooter(),

                  const SizedBox(height: AppSpacing.space8),
                ],
              ),
            ),
          ),
        ),
        // W4 Task 4.4 — 가입 후 메인 첫 진입 1회 spotlight.
        // questFirstShownProvider 재사용 (architect P1 #4).
        NextMissionSpotlight(
          onStart: () => context.push(AppRoutes.teacherFirstAvailability),
        ),
      ],
    );
  }

  /// Masthead — Notebook × Score 상단 헤더.
  /// 좌측: "LESSONAZA" (Playfair eyebrow)
  /// 우측: 알림 아이콘 + 미읽음 배지
  Widget _buildMasthead(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    return NotebookMasthead(
      eyebrow: 'LESSONAZA',
      // H2 — 로고는 배경으로 물러나고 본문 글자가 먼저 읽히게 한다.
      eyebrowStyle: NotebookTypography.wordmark,
      meta: _volumeIssueString(DateTime.now()),
      trailing: IconButton(
        onPressed: () => context.push(AppRoutes.notifications),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: AppColors.ink,
              size: 22,
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(color: AppColors.paperAccent),
                  child: Text(
                    AppStrings.unreadBadgeCount(unreadCount),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paper,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          ],
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

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // H3 — 날짜는 위 한 줄에서만. 제목·부제와 중복되지 않게 '레슨' 제거.
          Text(
            formatDateMDKorean(now),
            style: NotebookTypography.mastheadLabel,
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.dashboardProgrammeTitle,
            style: NotebookTypography.masthead,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.dashboardLessonCountFormat(lessonCount),
            style: NotebookTypography.mastheadDate,
          ),
          const SizedBox(height: AppSpacing.space3),
          const ThinRule(),
        ],
      ),
    );
  }

  /// "VOL. IV · NO. 18 · APR MMXXVI" 형식 메타 생성.
  /// 알림 아이콘이 자리를 차지하므로 실제 렌더에는 사용되지 않지만,
  /// NotebookMasthead 의 ``meta`` 요구사항을 만족시키기 위해 유지.
  String _volumeIssueString(DateTime now) {
    return 'VOL. ${romanOf(now.month - 1)} · NO. ${now.day}';
  }

  Widget _buildStatsRow(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, int>> lessonStatsAsync,
  ) {
    final monthCard = lessonStatsAsync.when(
      data:
          (stats) => StatCard(
            title: AppStrings.dashboardThisMonth,
            value: AppStrings.usageCountShort(stats['completed'] ?? 0),
            color: AppColors.ink,
            icon: Icons.check_circle_outline,
            // #749: sole entry point to analytics — the duplicate "통계 더보기"
            // footer link was removed (same destination + same Pro paywall guard).
            onTap:
                () => guardProFeatureNavigation(
                  context: context,
                  ref: ref,
                  required: TierRequirement.pro,
                  featureName: AppStrings.featureLockedMonthlyStats,
                  onPass: () => context.push(AppRoutes.analytics),
                ),
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

    return StatCardRow(cards: [monthCard]);
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
        Expanded(
          child: Text(
            AppStrings.dashboardTodayLessonsSection,
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
              // H6 — 버튼처럼 눌리는 텍스트 액션은 밑줄로 affordance 를 준다.
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.paperAccent,
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
  ///
  /// #749 (UI 복잡도 감사) — 통계 진입은 위 "이번 달" StatCard 하나로 통합.
  /// 여기 있던 "통계 더보기" 링크는 동일 목적지(AppRoutes.analytics) +
  /// 동일 Pro 가드의 중복 CTA였기 때문에 제거 (UX 규칙: 같은 행동 → 하나의 CTA).
  Widget _buildFineFooter() {
    return Column(
      children: [
        const ThinRule(),
        const SizedBox(height: AppSpacing.space3),
        Center(child: Text('Fine.', style: NotebookTypography.fine)),
      ],
    );
  }
}

/// Entry-point card linking to the per-student YouTube loop stats screen.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4 / #512.
///
/// Hides itself when the summary returns 0 students — the card should only
/// surface once at least one student has reported repeat data.
// ignore: widget-smoke-test — small dashboard card composed of existing primitives
class _LoopStatsEntryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(
      practiceLoopStatsSummaryProvider(window: PracticeLoopStatsWindow.weekly),
    );
    return summaryAsync.when(
      data: (students) {
        if (students.isEmpty) return const SizedBox.shrink();
        return InkWell(
          onTap: () => context.push(AppRoutes.practiceLoopStats),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.teacherStatsEntryTitle,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        AppStrings.teacherStatsEntrySubtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
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
