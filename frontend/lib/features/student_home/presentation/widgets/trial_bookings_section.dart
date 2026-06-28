import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../providers/student_home_booking_provider.dart';
import 'compact_trial_booking_card.dart';

/// Trial bookings section for student dashboard
class TrialBookingsSection extends ConsumerWidget {
  final String studentId;

  const TrialBookingsSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(
      studentHomeTrialBookingsProvider(studentId),
    );

    return bookingsAsync.when(
      data: (trialBookings) {
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
                // Notebook × Score: 섹션 헤더는 Playfair sectionTitle (§7.87-f).
                Text(
                  AppStrings.studentHomeMyTrialLessons,
                  style: NotebookTypography.sectionTitle,
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.teacherSearch),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(AppStrings.studentHomeApply),
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
                        content: Text(
                          AppStrings.studentHomeAllTrialInScheduleTab,
                        ),
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
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      // C7 — primary 섹션: 에러도 빈 상태로 graceful degrade (가시성 일치).
      error: (_, __) => _buildEmptyState(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      // #636 — 빈 카드 배경을 subscription 빈 카드와 통일(paper).
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(
          color: AppColors.inkQuaternary,
          style: BorderStyle.solid,
        ),
      ),
      child: SizedBox(
        height: 190,
        child: EmptyStateWidget(
          icon: Icons.school_outlined,
          title: AppStrings.studentHomeStartNewLesson,
          actionLabel: AppStrings.studentHomeTrialBooking,
          actionIcon: Icons.add,
          onAction: () => context.push(AppRoutes.teacherSearch),
        ),
      ),
    );
  }
}
