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

          // Gamification header
          GamificationHeader(
            studentId: currentStudentId,
            onTap:
                () => context.push(
                  '${AppRoutes.badgeCollection}?studentId=$currentStudentId',
                ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Getting started guide
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

          // ── 3순위: 이벤트 (대응 필요, 있을 때만 표시) ──
          LessonRequestSection(userId: currentStudentId, viewerRole: 'student'),

          const SizedBox(height: AppSpacing.space4),

          // Action banners
          SubscriptionRenewalBanner(studentId: currentStudentId),
          PendingProposalsBanner(studentId: currentStudentId),

          // Schedule confirmation cards
          _ScheduleConfirmationSection(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // Trial bookings
          TrialBookingsSection(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // Practice summary
          PracticeSummarySection(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // Teacher feedback
          TeacherFeedbackSection(studentId: currentStudentId),
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
