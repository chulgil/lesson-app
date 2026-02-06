import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../providers/booking/booking_providers.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../schedule/domain/entities/lesson_request.dart';
import '../../../schedule/presentation/providers/lesson_request_providers.dart';
import '../../../schedule/presentation/providers/schedule_confirmation_card_providers.dart';
import '../../../schedule/presentation/widgets/schedule_confirmation_card_widget.dart';
import '../../../subscription/presentation/providers/subscription_proposal_providers.dart';
import '../widgets/student_subscription_summary.dart';
import '../widgets/trial_bookings_section.dart';

/// Student Dashboard Tab - main home tab showing overview
class StudentDashboardTab extends ConsumerWidget {
  const StudentDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');

    // Get current student ID from auth provider
    final currentStudentId = ref.watch(currentUserIdProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════
          // 섹션 1: 헤더 (간소화)
          // ═══════════════════════════════════════════════════════════
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
                  Text(
                    '오늘도 화이팅!',
                    style: AppTypography.headingLarge,
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.push(AppRoutes.invite),
                    icon: const Icon(Icons.person_add_outlined),
                    tooltip: '선생님 초대',
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

          // ═══════════════════════════════════════════════════════════
          // 섹션 2: 🔴 액션 필요 (최우선 - 스케줄 확인, 수강권 제안)
          // ═══════════════════════════════════════════════════════════
          _buildScheduleConfirmationCards(context, ref, currentStudentId),
          _buildPendingProposalsBanner(context, ref, currentStudentId),
          _buildLessonRequestsBanner(context, ref, currentStudentId),

          // ═══════════════════════════════════════════════════════════
          // 섹션 3: 다음 레슨 (가장 중요한 정보)
          // ═══════════════════════════════════════════════════════════
          _buildNextLessonCard(context, ref, currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // ═══════════════════════════════════════════════════════════
          // 섹션 4: 수강권 요약 (잔여 횟수)
          // ═══════════════════════════════════════════════════════════
          StudentSubscriptionSummary(
            studentId: currentStudentId,
            onViewAll: () {
              context.push('${AppRoutes.subscriptions}?studentId=$currentStudentId');
            },
          ),

          const SizedBox(height: AppSpacing.space4),

          // ═══════════════════════════════════════════════════════════
          // 섹션 5: 체험 레슨 (있을 경우만)
          // ═══════════════════════════════════════════════════════════
          TrialBookingsSection(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // ═══════════════════════════════════════════════════════════
          // 섹션 6: 연습 요약 (통합 - 스트릭 + 목표 + 주간)
          // ═══════════════════════════════════════════════════════════
          _buildPracticeSummarySection(context, ref, currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // ═══════════════════════════════════════════════════════════
          // 섹션 7: 선생님 피드백 (최근 1개만)
          // ═══════════════════════════════════════════════════════════
          _buildTeacherFeedbackSection(context),
        ],
      ),
    );
  }

  /// 통합 연습 요약 섹션 (스트릭 + 주간 현황)
  Widget _buildPracticeSummarySection(
    BuildContext context,
    WidgetRef ref,
    String studentId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('이번 주 연습', style: AppTypography.headingMedium),
            TextButton(
              onPressed: () {
                context.push('${AppRoutes.practiceStats}?studentId=$studentId');
              },
              child: const Text('상세 보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // 컴팩트한 연습 스트릭 + 목표
        Row(
          children: [
            Expanded(
              child: _buildCompactStatCard(
                icon: Icons.local_fire_department,
                iconColor: AppColors.warning,
                value: '7일',
                label: '연속 연습',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildCompactStatCard(
                icon: Icons.timer_outlined,
                iconColor: AppColors.info,
                value: '4시간 30분',
                label: '이번 주 총',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildCompactStatCard(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
                value: '75%',
                label: '목표 달성',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.space3),

        // 주간 바 차트 (간소화)
        _buildCompactWeeklyChart(studentId),
      ],
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: AppSpacing.space1),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactWeeklyChart(String studentId) {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final progress = [1.0, 0.8, 0.6, 0.4, 0.0, 0.0, 0.0];
    final today = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final isToday = index == today;
          final isFuture = index > today;
          final value = progress[index];

          return Column(
            children: [
              // 미니 바
              Container(
                width: 24,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 24,
                  height: 40 * value,
                  decoration: BoxDecoration(
                    color: isFuture
                        ? AppColors.borderLight
                        : value >= 0.8
                            ? AppColors.practiceGood
                            : value >= 0.5
                                ? AppColors.practiceNormal
                                : value > 0
                                    ? AppColors.practicePoor
                                    : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                days[index],
                style: AppTypography.caption.copyWith(
                  color: isToday ? AppColors.primary : AppColors.textTertiaryLight,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTeacherFeedbackSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 피드백', style: AppTypography.headingMedium),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all feedback
              },
              child: const Text('더보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        _buildTeacherFeedback(),
      ],
    );
  }

  Widget _buildNextLessonCard(
      BuildContext context, WidgetRef ref, String studentId) {
    final bookingsAsync = ref.watch(studentBookingsProvider(studentId));

    return bookingsAsync.when(
      loading: () => _buildNextLessonLoadingState(),
      error: (_, __) => _buildNextLessonEmptyState(context),
      data: (bookings) {
        // Find next upcoming lesson
        final now = DateTime.now();
        final upcomingBookings = bookings
            .where((b) => b.status.isActive && b.lessonDate.isAfter(now))
            .toList()
          ..sort((a, b) => a.lessonDate.compareTo(b.lessonDate));

        if (upcomingBookings.isEmpty) {
          return _buildNextLessonEmptyState(context);
        }

        final nextLesson = upcomingBookings.first;
        return _buildNextLessonContent(context, nextLesson);
      },
    );
  }

  Widget _buildNextLessonLoadingState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildNextLessonEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available,
            color: AppColors.textTertiaryLight,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '예정된 레슨이 없습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '선생님을 찾아 레슨을 예약해보세요',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.teacherSearch),
            child: const Text('선생님 찾기'),
          ),
        ],
      ),
    );
  }

  Widget _buildNextLessonContent(BuildContext context, LessonBooking booking) {
    final now = DateTime.now();
    final daysUntil = booking.lessonDate.difference(now).inDays;
    final isToday = daysUntil == 0;
    final isTomorrow = daysUntil == 1;

    String dDayText;
    if (isToday) {
      dDayText = '오늘';
    } else if (isTomorrow) {
      dDayText = '내일';
    } else {
      dDayText = 'D-$daysUntil';
    }

    final dayOfWeek = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayText = dayOfWeek[booking.lessonDate.weekday - 1];
    final typeText = booking.lessonType == LessonType.regular ? '정기' : '체험';

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to lesson detail
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            // 날짜 박스
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Column(
                children: [
                  Text(
                    dDayText,
                    style: AppTypography.headingSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    weekdayText,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space3),

            // 레슨 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '다음 레슨',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeText,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${booking.teacherName} · ${booking.instrument}',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${booking.lessonDate.month}월 ${booking.lessonDate.day}일 ($weekdayText) '
                    '${booking.startTime.hour.toString().padLeft(2, '0')}:${booking.startTime.minute.toString().padLeft(2, '0')} · '
                    '${booking.durationMinutes}분',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherFeedback() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  '김',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '김선생님',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '12월 18일',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          Text(
            '이번 주 바흐 파르티타 연습 잘 하고 있어요! '
            'Allemande 부분에서 보잉이 많이 좋아졌습니다. '
            '다음 레슨까지 Sarabande 첫 페이지 천천히 읽어오세요.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Tags
          Wrap(
            spacing: AppSpacing.space2,
            children: [
              _buildTag('보잉 개선', AppColors.practiceGood),
              _buildTag('Sarabande 예습', AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Lesson requests banner - shows active lesson requests status
  Widget _buildLessonRequestsBanner(
    BuildContext context,
    WidgetRef ref,
    String studentId,
  ) {
    final requestsAsync = ref.watch(studentLessonRequestsProvider(studentId));

    return requestsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (requests) {
        // Filter active requests (pending or proposal received)
        final activeRequests = requests.where((r) =>
            (r.status == LessonRequestStatus.pending && !r.isExpired) ||
            r.status == LessonRequestStatus.proposalSent).toList();

        if (activeRequests.isEmpty) {
          return const SizedBox.shrink();
        }

        // Count by status
        final proposalCount = activeRequests
            .where((r) => r.status == LessonRequestStatus.proposalSent)
            .length;
        final pendingCount = activeRequests
            .where((r) => r.status == LessonRequestStatus.pending && !r.isExpired)
            .length;

        // Determine display based on status
        Color bannerColor;
        IconData bannerIcon;
        String title;
        String subtitle;

        if (proposalCount > 0) {
          bannerColor = AppColors.success;
          bannerIcon = Icons.card_giftcard;
          title = '수강권 제안 도착!';
          subtitle = proposalCount == 1
              ? '선생님이 수강권을 제안했습니다'
              : '$proposalCount건의 수강권 제안이 있습니다';
        } else {
          bannerColor = AppColors.info;
          bannerIcon = Icons.hourglass_empty;
          title = '레슨 요청 대기 중';
          subtitle = pendingCount == 1
              ? '선생님 응답을 기다리고 있습니다'
              : '$pendingCount건의 요청이 대기 중입니다';
        }

        return GestureDetector(
          onTap: () {
            context.push(
              '${AppRoutes.myLessonRequests}?studentId=$studentId',
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    bannerIcon,
                    color: bannerColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Schedule confirmation cards - shows pending schedule confirmations (Issue #62)
  Widget _buildScheduleConfirmationCards(
    BuildContext context,
    WidgetRef ref,
    String studentId,
  ) {
    final cardsAsync =
        ref.watch(pendingScheduleConfirmationCardsProvider(studentId));

    return cardsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (cards) {
        if (cards.isEmpty) {
          return const SizedBox.shrink();
        }

        // Display all pending cards
        return Column(
          children: cards.map((card) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space4),
              child: ScheduleConfirmationCardWidget(
                card: card,
                onConfirmed: () {
                  // Refresh the cards list
                  ref.invalidate(
                      pendingScheduleConfirmationCardsProvider(studentId));
                },
                onSelectDifferentTime: () {
                  // Refresh the cards list
                  ref.invalidate(
                      pendingScheduleConfirmationCardsProvider(studentId));
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Pending proposals banner - shows if there are pending proposals
  Widget _buildPendingProposalsBanner(
    BuildContext context,
    WidgetRef ref,
    String studentId,
  ) {
    final pendingProposalsAsync =
        ref.watch(pendingStudentProposalsProvider(studentId));

    return pendingProposalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (proposals) {
        if (proposals.isEmpty) {
          return const SizedBox.shrink();
        }

        final proposal = proposals.first;
        final count = proposals.length;

        return GestureDetector(
          onTap: () {
            if (count == 1) {
              // 1개: 해당 제안 상세로 바로 이동
              context.push(
                  AppRoutes.proposalDetail.replaceFirst(':id', proposal.id));
            } else {
              // 2개 이상: 알림 화면으로 이동 (모든 제안 알림 표시)
              context.push(AppRoutes.notifications);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '수강권 제안이 도착했어요!',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        // 시스템 자동 제안: 할인 혜택 강조
                        // 선생님 수동 제안: 선생님 메시지 표시
                        proposal.isAutoProposal
                            ? (proposal.discountReason ?? '지금 확인하고 혜택 받으세요')
                            : (proposal.message ?? '선생님이 수강권을 제안했습니다'),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
