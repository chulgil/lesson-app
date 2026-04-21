import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
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
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../lessons/presentation/providers/booking_providers.dart';
import '../../../lessons/presentation/providers/lesson_confirmation_provider.dart';
import '../../../lessons/presentation/providers/lesson_crud_provider.dart';
import '../../../lessons/presentation/providers/lesson_stats_provider.dart';
import '../../../schedule/presentation/providers/unified_lesson_request_providers.dart';
import '../../../subscription/subscription_facade.dart';
import 'assignment_summary_section.dart';
import 'getting_started_card.dart';
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
    final lessonsAsync = ref.watch(lessonsProvider);
    final lessonStatsAsync = ref.watch(lessonStatsProvider);
    final teacherId = ref.watch(currentUserIdProvider);
    final unpaidSummaryAsync = ref.watch(unpaidSummaryProvider(teacherId));
    final needsConfirmationAsync = ref.watch(
      lessonsNeedingConfirmationProvider,
    );

    // Get today's lessons
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayLessons = lessonsAsync.whenData((lessons) {
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
          ref.invalidate(lessonsProvider);
          ref.invalidate(lessonStatsProvider);
          ref.invalidate(unpaidSummaryProvider(teacherId));
          ref.invalidate(pendingBookingsCountProvider(teacherId));
          ref.invalidate(todayRequestsProvider(teacherId));
          ref.invalidate(expiringSoonSubscriptionsProvider);
          ref.invalidate(expiredSubscriptionsProvider);
          ref.invalidate(lessonsNeedingConfirmationProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space4,
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

              // ── 0순위: 시간대 인식 컨텍스트 배너 ─────────────
              // (home_master.md §3.5)
              todayLessons.maybeWhen(
                data: (lessons) => TimeContextBanner(todayLessons: lessons),
                orElse: () => const SizedBox.shrink(),
              ),

              // Getting Started Guide (shown when 0 students)
              const GettingStartedCard(),

              // ── 1순위: 긴급 알림 존 ──────────────────────────
              UrgentAlertZone(
                teacherId: teacherId,
                unpaidSummary: unpaidSummaryAsync,
                needsConfirmation: needsConfirmationAsync,
              ),

              // ── 2순위: 오늘 ─────────────────────────────────
              _buildStatsRow(context, todayLessons, lessonStatsAsync),

              const SizedBox(height: AppSpacing.space6),

              // Today's Lessons Section
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
                error: (error, _) => _buildErrorCard('레슨을 불러올 수 없습니다'),
              ),

              const SizedBox(height: AppSpacing.space6),

              // ── 이벤트: 대응 필요 (오늘 레슨 바로 아래) ──────────
              _buildEventsGroup(context, teacherId),

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
        tooltip: '알림',
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
          Text('오늘의 레슨', style: NotebookTypography.masthead),
          const SizedBox(height: 6),
          Text(
            '${now.month}月 ${now.day}日  ·  ${_koreanLessonCount(lessonCount)}',
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

  String _koreanLessonCount(int count) {
    if (count == 0) return '예정된 레슨 없음';
    const korean = ['한', '두', '세', '네', '다섯', '여섯', '일곱', '여덟', '아홉', '열'];
    final label = count <= korean.length ? korean[count - 1] : '$count';
    return '$label 편의 수업';
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
            title: '오늘 레슨',
            value: '${lessons.length}회',
            color: AppColors.ink,
            icon: Icons.today,
            onTap: onViewAllLessons,
          ),
      loading:
          () => StatCard(
            title: '오늘 레슨',
            value: '-',
            color: AppColors.ink,
            icon: Icons.today,
          ),
      error:
          (_, __) => StatCard(title: '오늘 레슨', value: '-', color: AppColors.ink),
    );

    final monthCard = lessonStatsAsync.when(
      data:
          (stats) => StatCard(
            title: '이번 달',
            value: '${stats['completed'] ?? 0}회',
            color: AppColors.ink,
            icon: Icons.check_circle_outline,
            onTap: () => context.push(AppRoutes.analytics),
          ),
      loading:
          () => StatCard(
            title: '이번 달',
            value: '-',
            color: AppColors.ink,
            icon: Icons.check_circle_outline,
          ),
      error:
          (_, __) => StatCard(title: '이번 달', value: '-', color: AppColors.ink),
    );

    return StatCardRow(cards: [todayCard, monthCard]);
  }

  /// 이벤트 그룹: 레슨 요청 + 스케줄 변경을 시각적으로 묶음.
  /// 두 섹션 모두 빈 경우 자식이 SizedBox.shrink → 그룹 헤더도 자연 숨김.
  Widget _buildEventsGroup(BuildContext context, String teacherId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonRequestSection(userId: teacherId),
        const SizedBox(height: AppSpacing.space4),
        ScheduleChangeRequestSection(teacherId: teacherId),
      ],
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
          style: NotebookTypography.roman.copyWith(fontSize: 16),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            'Today\'s Programme',
            style: NotebookTypography.mastheadLabel.copyWith(fontSize: 13),
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
              '일괄 피드백',
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
              '전체보기',
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
        title: '오늘 예정된 레슨이 없습니다',
        subtitle: '비어 있는 프로그램 — 새 레슨을 추가해 보세요.',
        actionLabel: '레슨 추가',
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
                '${lessons.length - 5}개 레슨 더보기',
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
                '통계 더보기',
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
}
