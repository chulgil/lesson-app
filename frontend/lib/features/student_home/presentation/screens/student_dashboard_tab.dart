import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../features/home/home_ui_facade.dart';
import '../../../gamification/gamification_facade.dart'
    show effectiveStreakProvider;
import '../../../gamification/gamification_ui_facade.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../../../practice/practice_ui_facade.dart';
import '../../../practice_journal/practice_journal.dart';
import '../../../students/students_facade.dart';
import '../widgets/dashboard/next_lesson_card.dart';
import '../widgets/learning_record_group.dart';
import '../widgets/student_getting_started_card.dart';
import '../widgets/weekly_assignments_section.dart';
import '../widgets/student_lesson_progress_section.dart';
import '../widgets/student_subscription_summary.dart';

/// Student Dashboard Tab - main home tab showing overview
class StudentDashboardTab extends ConsumerWidget {
  const StudentDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    // Resolve the real Student.id (GET /students/me/profile). Passing the auth
    // userId as a student id 404s on remote (mock matched by coincidence).
    return ref
        .watch(currentStudentProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(AppStrings.cannotLoadData)),
          data: (student) {
            final currentStudentId = student.id;

            // O7: StudentQuest 0개 시 자동 onboarding (Job 6 Task 6.2).
            //
            // 2026-06-12 회귀 수정 — trigger 는 반드시 스크롤 **밖** (tab 전체 wrap).
            // onboarding 화면은 Scaffold 기반 full-screen 이므로
            // SingleChildScrollView 내부 슬롯에 두면 unbounded height 크래시
            // (RenderCustomMultiChildLayoutBox infinite size). W6
            // TeacherMigrationOverlayGate 와 동일한 게이트 패턴.
            return StudentGamificationOnboardingTrigger(
              studentId: currentStudentId,
              child: _buildDashboardBody(context, now, currentStudentId),
            );
          },
        );
  }

  Widget _buildDashboardBody(
    BuildContext context,
    DateTime now,
    String currentStudentId,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space2,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Masthead: Playfair eyebrow + 친구초대/알림 아이콘 ──
          _buildMasthead(context),

          // ── Programme Title: 오늘의 연습 + 인사 ──
          _buildProgrammeTitle(context, now),

          const SizedBox(height: AppSpacing.space5),

          // ── 0순위: 시간대 인식 배너 (student_home_master.md §2.2) ──
          _StudentTimeBanner(studentId: currentStudentId),

          // ── G21/#402: 노트 일시 접근 동의 활성 배너 (조건부) ──
          const NoteAccessActiveBanner(),

          // ── 1순위: 다음 레슨 (가장 궁금한 것) ──────────
          NextLessonCard(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // ── 2순위: 수강권 (잔여 횟수) ─────────────────
          StudentSubscriptionSummary(
            studentId: currentStudentId,
            onViewAll: () {
              context.push(
                '${AppRoutes.subscriptions}?studentId=$currentStudentId',
              );
            },
          ),

          const SizedBox(height: AppSpacing.space4),

          // ── Student gamification P2: 오늘의 연습 목표 + 잔디 연동 (doc 46 §4) ──
          DailyGoalCard(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // ── Student gamification P1: [연습 시작] 단일 진입점 (스펙 §4.1) ──
          PracticeStartSection(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space3),

          // ── 연습장 카드: 이달 연습 도장 미리보기 ──
          PracticeJournalCard(
            childProfileId: currentStudentId,
            role: JournalRole.student,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PracticeJournalScreen(
                    childProfileId: currentStudentId,
                    role: JournalRole.student,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.space4),

          // Gamification header (선생님 quest / badge — P1 무변)
          GamificationHeader(
            studentId: currentStudentId,
            onTap: () => context.push(
              '${AppRoutes.badgeCollection}?studentId=$currentStudentId',
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // ── 이번 주 과제 (미완료 항목 최대 3개 미리보기) ──
          WeeklyAssignmentsSection(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // Getting started guide (조건부 자동 숨김)
          StudentGettingStartedCard(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // ── 3순위: 이벤트 그룹 (대응 필요, 4개 배너 통합) ──
          _StudentEventsGroup(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // ── 4순위: 학습 기록 그룹 (피드백 + 연습요약 + 체험) ──
          LearningRecordGroup(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space5),

          // ── Fine. 페이지 종지부 ──
          _buildFineFooter(context),

          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    );
  }

  /// Masthead — Notebook × Score 상단 헤더.
  /// 좌측: "LESSONAZA" (Playfair eyebrow)
  /// 우측: 친구초대 + 알림 아이콘
  Widget _buildMasthead(BuildContext context) {
    return NotebookMasthead(
      eyebrow: 'LESSONAZA',
      meta: volNoLabel(DateTime.now()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => context.push(AppRoutes.invite),
            icon: const Icon(
              Icons.person_add_outlined,
              color: AppColors.ink,
              size: 22,
            ),
            tooltip: AppStrings.inviteTeacher,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          IconButton(
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
        ],
      ),
    );
  }

  /// Programme Title — "Programme for Thursday" + "오늘의 연습" + 날짜·인사.
  Widget _buildProgrammeTitle(BuildContext context, DateTime now) {
    final dayLabel = _englishWeekday(now.weekday);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppStrings.studentHomeProgrammeFor(dayLabel),
            style: NotebookTypography.mastheadLabel,
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.studentHomeTodayPractice,
            style: NotebookTypography.masthead,
          ),
          const SizedBox(height: 6),
          Text(
            '${AppStrings.studentHomeMastheadHanjaDate(now.month, now.day)}'
            '  ·  ${AppStrings.studentHomeGreeting}',
            style: NotebookTypography.mastheadDate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space3),
          const ThinRule(),
        ],
      ),
    );
  }

  /// "Fine." 푸터 — 악보 종지부 인용 + 연습 기록 링크.
  Widget _buildFineFooter(BuildContext context) {
    return Column(
      children: [
        const ThinRule(),
        const SizedBox(height: AppSpacing.space3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Fine.', style: NotebookTypography.fine),
            const Spacer(),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.push(AppRoutes.practiceStats),
                  icon: const Icon(
                    Icons.bar_chart,
                    size: 16,
                    color: AppColors.ink,
                  ),
                  label: Text(
                    AppStrings.studentPracticeRecordMore,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
}

/// 학생용 시간대 인식 배너 (TimeContextBanner 래퍼).
///
/// 오늘 레슨(studentBookings) + 연습 스트릭을 기반으로 메시지 생성.
class _StudentTimeBanner extends ConsumerWidget {
  final String studentId;

  const _StudentTimeBanner({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Streak from the single source of truth (effectiveStreakProvider) — never
    // recomputed here. Freeze bridges a covered gap so one missed day does not
    // reset to 0. See docs/specs/practice/streak_ssot.md §1 Phase 3.
    final streakDays = ref
        .watch(effectiveStreakProvider(studentId))
        .maybeWhen(
          data: (streak) => streak.effectiveCurrentStreak,
          orElse: () => 0,
        );

    return TimeContextBanner(
      todayLessons: const <Lesson>[],
      role: TimeBannerRole.student,
      streakDays: streakDays,
    );
  }
}

/// 학생용 이벤트 그룹.
///
/// 레슨 신청부터 수강권 준비, 첫 스케줄 확인까지 하나의 진행함으로 묶는다.
class _StudentEventsGroup extends StatelessWidget {
  final String studentId;

  const _StudentEventsGroup({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StudentLessonProgressSection(studentId: studentId);
  }
}
