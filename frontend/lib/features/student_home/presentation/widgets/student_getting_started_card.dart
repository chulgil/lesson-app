import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../lessons/presentation/providers/booking_providers.dart';
import '../../../../features/profile/presentation/providers/invite_provider.dart';

/// Getting Started checklist card for new students.
/// Shows actionable steps to help them get started with lessons.
class StudentGettingStartedCard extends ConsumerWidget {
  final String studentId;

  const StudentGettingStartedCard({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(myConnectionsProvider);
    final bookingsAsync = ref.watch(studentBookingsProvider(studentId));

    // 로딩 중이면 숨김 (깜빡임 방지)
    if (connectionsAsync.isLoading || bookingsAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final hasConnections = connectionsAsync.valueOrNull?.isNotEmpty ?? false;
    final hasLessons = bookingsAsync.valueOrNull?.isNotEmpty ?? false;
    const hasProfile = true; // Already set during onboarding

    // Hide when all steps are completed
    if (hasConnections && hasProfile && hasLessons) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: AppColors.ink, size: 24),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '시작 가이드',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '아래 단계를 따라 레슨을 시작하세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Step 1: Connect with teacher
          _StepItem(
            step: 1,
            title: '선생님 연결하기',
            subtitle: '선생님을 검색하거나 초대 코드를 입력하세요',
            isCompleted: hasConnections,
            onTap:
                hasConnections
                    ? null
                    : () => context.push(AppRoutes.selectTeacher),
          ),

          const SizedBox(height: AppSpacing.space2),

          // Step 2: Complete profile
          _StepItem(
            step: 2,
            title: '프로필 완성하기',
            subtitle: '온보딩에서 프로필이 설정되었습니다',
            isCompleted: hasProfile,
            onTap: null,
          ),

          const SizedBox(height: AppSpacing.space2),

          // Step 3: Check first lesson
          _StepItem(
            step: 3,
            title: '첫 레슨 확인하기',
            subtitle: '선생님과 첫 레슨을 예약하세요',
            isCompleted: hasLessons,
            onTap: hasLessons ? null : () => context.push(AppRoutes.myBookings),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color:
              isCompleted
                  ? AppColors.paperOk.withValues(alpha: 0.08)
                  : AppColors.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color:
                isCompleted
                    ? AppColors.paperOk.withValues(alpha: 0.3)
                    : AppColors.inkQuaternary,
          ),
        ),
        child: Row(
          children: [
            // Step number or check
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
                shape: BoxShape.circle,
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
    );
  }
}
