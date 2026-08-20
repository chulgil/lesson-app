import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../profile/profile_facade.dart';
import '../providers/student_home_booking_provider.dart';

/// Getting Started checklist card for new students.
/// Shows actionable steps to help them get started with lessons.
class StudentGettingStartedCard extends ConsumerWidget {
  final String studentId;

  const StudentGettingStartedCard({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(myConnectionsProvider);
    final sentRequestsAsync = ref.watch(mySentRequestsProvider);
    final hasAnyBookingAsync = ref.watch(
      studentHomeHasAnyBookingProvider(studentId),
    );

    // 로딩 중이면 숨김 (깜빡임 방지)
    if (connectionsAsync.isLoading ||
        sentRequestsAsync.isLoading ||
        hasAnyBookingAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final hasConnections = connectionsAsync.valueOrNull?.isNotEmpty ?? false;
    final hasPendingConnectionRequest =
        sentRequestsAsync.valueOrNull?.any((request) => request.isActionable) ??
        false;
    final hasLessons = hasAnyBookingAsync.valueOrNull ?? false;
    const hasProfile = true; // Already set during onboarding

    // Hide when all steps are completed
    if (hasConnections && hasProfile && hasLessons) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: AppColors.ink, size: 24),
              const SizedBox(width: AppSpacing.space2),
              // Notebook × Score: 카드 내부 섹션 제목도 Playfair sectionTitle 로 통일 (§7.17 패턴).
              Text(
                AppStrings.studentHomeGettingStartedTitle,
                style: NotebookTypography.sectionTitle.copyWith(
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.studentHomeGettingStartedSubtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Step 1: Connect with teacher
          _StepItem(
            step: 1,
            title:
                hasPendingConnectionRequest
                    ? AppStrings.studentHomeTeacherConnectionPending
                    : AppStrings.studentHomeConnectTeacher,
            subtitle:
                hasPendingConnectionRequest
                    ? AppStrings.studentHomeTeacherConnectionPendingHint
                    : AppStrings.studentHomeConnectTeacherHint,
            isCompleted: hasConnections,
            onTap:
                hasConnections || hasPendingConnectionRequest
                    ? null
                    : () => context.push(AppRoutes.teacherSearch),
          ),

          const SizedBox(height: AppSpacing.space2),

          // Step 2: Complete profile
          _StepItem(
            step: 2,
            title: AppStrings.studentHomeCompleteProfile,
            subtitle: AppStrings.studentHomeCompleteProfileHint,
            isCompleted: hasProfile,
            onTap: null,
          ),

          const SizedBox(height: AppSpacing.space2),

          // Step 3: Check first lesson
          _StepItem(
            step: 3,
            title: AppStrings.studentHomeCheckFirstLesson,
            subtitle: AppStrings.studentHomeCheckFirstLessonHint,
            isCompleted: hasLessons,
            // #521 — 실 studentId 를 extra 로 전달. 누락 시 라우트가 빈 id 로
            // 폴백해 remote 에서 빈 예약/404 가 났다.
            onTap:
                hasLessons
                    ? null
                    : () => context.push(
                      AppRoutes.myBookings,
                      extra: {'studentId': studentId},
                    ),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _StepItem({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Opacity(
      opacity: !isCompleted && !isEnabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.paperOkSoft : AppColors.paper,
            border: Border.all(
              color:
                  isCompleted
                      ? AppColors.paperOkSelected
                      : AppColors.inkQuaternary,
            ),
          ),
          child: Row(
            children: [
              // Step number or check
              // §7.132: round → 사각 step 인디케이터 (Notebook 번호 메타포).
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      isCompleted
                          ? AppColors.paperOk
                          : isEnabled
                          ? AppColors.ink
                          : AppColors.inkTertiary,
                ),
                child: Center(
                  child:
                      isCompleted
                          ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.paper,
                          )
                          : Text(
                            '$step',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.paper,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? AppColors.inkTertiary : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEnabled && !isCompleted)
                Icon(Icons.chevron_right, color: AppColors.ink, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
