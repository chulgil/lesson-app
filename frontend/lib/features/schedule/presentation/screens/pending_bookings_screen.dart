import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../features/lessons/presentation/providers/booking_providers.dart';
import '../widgets/approval_bottom_sheet.dart';
import '../widgets/teacher_approval_card.dart';

/// Screen showing pending booking requests for teacher approval
/// Supports multi-option schedule selection
class PendingBookingsScreen extends ConsumerWidget {
  final String teacherId;

  const PendingBookingsScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingBookings = ref.watch(pendingBookingsProvider(teacherId));

    return Scaffold(
      appBar: AppBar(title: const Text('승인 대기')),
      body: pendingBookings.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pendingBookingsProvider(teacherId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space4),
                  child: TeacherApprovalListItem(
                    booking: booking,
                    onTap: () => _showApprovalSheet(context, ref, booking),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.space3),
                  Text('오류가 발생했습니다', style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.space2),
                  TextButton(
                    onPressed:
                        () =>
                            ref.invalidate(pendingBookingsProvider(teacherId)),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: AppColors.inkTertiary),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '대기 중인 신청이 없습니다',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '새로운 레슨 신청이 들어오면\n여기에 표시됩니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showApprovalSheet(
    BuildContext context,
    WidgetRef ref,
    LessonBooking booking,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => ApprovalBottomSheet(
                  booking: booking,
                  teacherId: teacherId,
                  scrollController: scrollController,
                  onApproved: () {
                    ref.invalidate(pendingBookingsProvider(teacherId));
                  },
                ),
          ),
    );
  }
}
