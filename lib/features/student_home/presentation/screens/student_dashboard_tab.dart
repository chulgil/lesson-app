import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../practice/presentation/widgets/goal/goal_progress_widget.dart';
import '../../../practice/presentation/widgets/practice_streak_card.dart';
import '../../../schedule/domain/entities/lesson_request.dart';
import '../../../schedule/presentation/providers/lesson_request_providers.dart';
import '../../../subscription/presentation/providers/subscription_proposal_providers.dart';
import '../widgets/student_subscription_summary.dart';
import '../widgets/trial_bookings_section.dart';
import '../widgets/weekly_practice_widget.dart';

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요, 홍길동님 🎻',
                    style: AppTypography.headingLarge,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    dateFormat.format(now),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Invite button
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

          const SizedBox(height: AppSpacing.space6),

          // Practice Streak Card (NEW)
          PracticeStreakCard(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // Practice Goal Widget
          GoalProgressWidget(
            studentId: currentStudentId,
            onSettingsTap: () {
              context.push(
                '${AppRoutes.practiceGoalSettings}?studentId=$currentStudentId',
              );
            },
          ),

          const SizedBox(height: AppSpacing.space6),

          // Pending Proposals
          _buildPendingProposalsBanner(context, ref, currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // My Lesson Requests
          _buildLessonRequestsBanner(context, ref, currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // My Subscriptions (수강권 요약)
          StudentSubscriptionSummary(
            studentId: currentStudentId,
            onViewAll: () {
              context.push('${AppRoutes.subscriptions}?studentId=$currentStudentId');
            },
          ),

          const SizedBox(height: AppSpacing.space4),

          // Next Lesson Card
          _buildNextLessonCard(context),

          const SizedBox(height: AppSpacing.space6),

          // My Trial Lessons Section
          TrialBookingsSection(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space6),

          // This Week's Practice (from teacher assignments)
          WeeklyPracticeWidget(
            studentId: currentStudentId,
            showHeader: true,
            onViewAll: () {
              // TODO: Navigate to full practice list
            },
          ),

          const SizedBox(height: AppSpacing.space6),

          // Weekly Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('이번 주 연습 현황', style: AppTypography.headingMedium),
              TextButton(
                onPressed: () {
                  context.push(
                    '${AppRoutes.practiceStats}?studentId=$currentStudentId',
                  );
                },
                child: const Text('통계 보기'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          _buildWeeklyProgress(context, currentStudentId),

          const SizedBox(height: AppSpacing.space6),

          // Teacher Feedback
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('선생님 피드백', style: AppTypography.headingMedium),
              TextButton(
                onPressed: () {},
                child: const Text('더보기'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          _buildTeacherFeedback(),
        ],
      ),
    );
  }

  Widget _buildNextLessonCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to lesson detail or lessons tab
        // TODO: Connect to actual next lesson data
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '다음 레슨',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'D-2',
                  style: AppTypography.headingMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),

            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    '김',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '김선생님',
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '바이올린',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space3),

            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '12월 23일 (월) 14:00',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress(BuildContext context, String studentId) {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final progress = [1.0, 0.8, 0.6, 0.0, 0.0, 0.0, 0.0]; // 0-1 scale
    final today = DateTime.now().weekday - 1; // 0-indexed

    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.practiceStats}?studentId=$studentId');
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Stats row
            Row(
              children: [
                _buildStatItem('연습한 날', '3일'),
                const SizedBox(width: AppSpacing.space4),
                _buildStatItem('총 연습 시간', '4시간 30분'),
                const SizedBox(width: AppSpacing.space4),
                _buildStatItem('달성률', '75%'),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),
            const Divider(),
            const SizedBox(height: AppSpacing.space4),

            // Weekly bar chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isToday = index == today;
                final isFuture = index > today;
                final value = progress[index];

                return Column(
                  children: [
                    // Bar
                    Container(
                      width: 32,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 32,
                        height: 80 * value,
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
                    const SizedBox(height: AppSpacing.space2),

                    // Day label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        days[index],
                        style: AppTypography.caption.copyWith(
                          color: isToday
                              ? Colors.white
                              : AppColors.textSecondaryLight,
                          fontWeight: isToday ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
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
