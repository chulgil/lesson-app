import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../widgets/dashboard/dashboard_widgets.dart';
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

          // Action banners
          PendingProposalsBanner(studentId: currentStudentId),
          LessonRequestsBanner(studentId: currentStudentId),

          // Next lesson
          NextLessonCard(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // Subscription summary
          StudentSubscriptionSummary(
            studentId: currentStudentId,
            onViewAll: () {
              context.push(
                '${AppRoutes.subscriptions}?studentId=$currentStudentId',
              );
            },
          ),

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
