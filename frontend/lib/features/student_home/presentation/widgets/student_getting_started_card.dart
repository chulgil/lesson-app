import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../lessons/presentation/providers/booking_providers.dart';
import '../../../../providers/invite/invite_provider.dart';

/// Getting Started checklist card for new students.
/// Shows actionable steps to help them get started with lessons.
class StudentGettingStartedCard extends ConsumerWidget {
  final String studentId;

  const StudentGettingStartedCard({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(myConnectionsProvider);
    final bookingsAsync = ref.watch(studentBookingsProvider(studentId));

    final hasConnections =
        connectionsAsync.valueOrNull?.isNotEmpty ?? false;
    final hasLessons = bookingsAsync.valueOrNull?.isNotEmpty ?? false;
    const hasProfile = true; // Already set during onboarding

    // Hide when all steps are completed
    if (hasConnections && hasProfile && hasLessons) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '시작 가이드',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '아래 단계를 따라 레슨을 시작하세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Step 1: Connect with teacher
          _StepItem(
            step: 1,
            title: '선생님 연결하기',
            subtitle: '선생님을 검색하거나 초대 코드를 입력하세요',
            isCompleted: hasConnections,
            onTap: hasConnections
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
            onTap: hasLessons
                ? null
                : () => context.push(AppRoutes.myBookings),
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
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            // Step number or check
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isEnabled
                        ? AppColors.primary
                        : AppColors.textTertiaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$step',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
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
                      color:
                          isCompleted ? AppColors.textTertiaryLight : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isEnabled && !isCompleted)
              Icon(
                Icons.chevron_right,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
