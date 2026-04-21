import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../features/lessons/presentation/providers/booking_providers.dart';
import 'compact_trial_booking_card.dart';

/// Trial bookings section for student dashboard
class TrialBookingsSection extends ConsumerWidget {
  final String studentId;

  const TrialBookingsSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(studentBookingsProvider(studentId));

    return bookingsAsync.when(
      data: (bookings) {
        // Filter for active trial bookings
        final trialBookings =
            bookings
                .where((b) => b.lessonType == LessonType.trial)
                .where((b) => b.status.isActive || b.status.canRetry)
                .toList()
              ..sort((a, b) => a.lessonDate.compareTo(b.lessonDate));

        if (trialBookings.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('내 체험레슨', style: AppTypography.headingMedium),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.teacherSearch),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('신청'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            // Booking cards (show max 2)
            ...trialBookings
                .take(2)
                .map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                    child: CompactTrialBookingCard(booking: booking),
                  ),
                ),

            // View all button if more than 2
            if (trialBookings.length > 2)
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('모든 체험 레슨은 스케줄 탭에서 확인할 수 있습니다'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text('${trialBookings.length - 2}개 더보기'),
                ),
              ),
          ],
        );
      },
      loading:
          () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.inkQuaternary,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 40, color: AppColors.inkTertiary),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '새로운 선생님과 레슨을 시작해보세요',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.teacherSearch),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('체험레슨 신청'),
          ),
        ],
      ),
    );
  }
}
