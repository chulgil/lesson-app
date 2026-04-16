import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../../features/home/presentation/widgets/lesson_request_section.dart';
import '../../../../features/home/presentation/widgets/time_context_banner.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../../../lessons/presentation/providers/booking_providers.dart';
import '../../../practice/presentation/providers/practice_crud_provider.dart';
import '../../../gamification/presentation/widgets/gamification_header.dart';
import '../../../schedule/presentation/providers/schedule_confirmation_card_providers.dart';
import '../../../schedule/presentation/widgets/schedule_confirmation_card_widget.dart';
import '../widgets/dashboard/dashboard_widgets.dart';
import '../widgets/student_getting_started_card.dart';
import '../widgets/student_subscription_summary.dart';
import '../widgets/trial_bookings_section.dart';

/// Student Dashboard Tab - main home tab showing overview
class StudentDashboardTab extends ConsumerWidget {
  const StudentDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');
    final currentStudentId = ref.watch(currentUserIdProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(now),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text('오늘도 화이팅!', style: AppTypography.headingLarge),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.push(AppRoutes.invite),
                    icon: const Icon(Icons.person_add_outlined),
                    tooltip: '선생님 연결',
                  ),
                  IconButton(
                    onPressed: () => context.push(AppRoutes.notifications),
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // ── 0순위: 시간대 인식 배너 (student_home_master.md §2.2) ──
          _StudentTimeBanner(studentId: currentStudentId),

          // Gamification header
          GamificationHeader(
            studentId: currentStudentId,
            onTap:
                () => context.push(
                  '${AppRoutes.badgeCollection}?studentId=$currentStudentId',
                ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Getting started guide (조건부 자동 숨김)
          StudentGettingStartedCard(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

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

          // ── 3순위: 이벤트 그룹 (대응 필요, 4개 배너 통합) ──
          _StudentEventsGroup(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // ── 4순위: 선생님 피드백 (학생 관심사, 상단 이동) ──
          TeacherFeedbackSection(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // ── 5순위: 연습 요약 ──
          PracticeSummarySection(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // ── 6순위: 체험 레슨 (하단 이동) ──
          TrialBookingsSection(studentId: currentStudentId),
        ],
      ),
    );
  }
}

/// Shows pending schedule confirmation cards if any exist.
class _ScheduleConfirmationSection extends ConsumerWidget {
  final String studentId;

  const _ScheduleConfirmationSection({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(
      pendingScheduleConfirmationCardsProvider(studentId),
    );

    return cardsAsync.when(
      data: (cards) {
        if (cards.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            for (final card in cards) ...[
              ScheduleConfirmationCardWidget(card: card),
              const SizedBox(height: AppSpacing.space3),
            ],
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
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
    final bookingsAsync = ref.watch(studentBookingsProvider(studentId));
    final practiceLogsAsync = ref.watch(practiceLogsProvider(studentId));

    // 오늘 레슨 필터 (booking → Lesson처럼 사용 불가. 임시로 빈 리스트)
    // TODO: 학생 booking → Lesson 변환 필요. 현재는 빈 리스트로도 streak 기반 메시지 동작
    final todayLessons =
        bookingsAsync.valueOrNull != null
            ? _filterTodayBookings(bookingsAsync.value!)
            : <Lesson>[];

    // 연속 연습일 계산
    final streakDays =
        practiceLogsAsync.valueOrNull != null
            ? _calculateStreak(practiceLogsAsync.value!)
            : 0;

    return TimeContextBanner(
      todayLessons: todayLessons,
      role: TimeBannerRole.student,
      streakDays: streakDays,
    );
  }

  /// studentBookings를 Lesson 리스트로 변환 (오늘만).
  /// Booking 엔티티는 Lesson과 다르므로, 빈 리스트 반환.
  /// 학생 시간대 배너는 streak + 일반 메시지 중심.
  List<Lesson> _filterTodayBookings(List<dynamic> bookings) {
    // 현재 Lesson 엔티티로 매핑 불가 — streak 중심 메시지로 대체
    return const [];
  }

  int _calculateStreak(List<dynamic> logs) {
    if (logs.isEmpty) return 0;
    final now = DateTime.now();
    final practicedDates = <String>{};
    for (final log in logs) {
      final totalMinutes = log.totalMinutes as int? ?? 0;
      if (totalMinutes > 0) {
        final d = log.date as DateTime;
        practicedDates.add('${d.year}-${d.month}-${d.day}');
      }
    }
    var streak = 0;
    var checkDate = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 100; i++) {
      final key = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (practicedDates.contains(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}

/// 학생용 이벤트 그룹 (4개 배너 시각 통합).
///
/// 레슨 요청 + 갱신 + 제안 + 확인 카드를 하나의 그룹으로.
/// 데이터 통합 X, 시각적 묶음만.
class _StudentEventsGroup extends StatelessWidget {
  final String studentId;

  const _StudentEventsGroup({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonRequestSection(userId: studentId, viewerRole: 'student'),
        SubscriptionRenewalBanner(studentId: studentId),
        PendingProposalsBanner(studentId: studentId),
        _ScheduleConfirmationSection(studentId: studentId),
      ],
    );
  }
}
