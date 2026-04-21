import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/entities/availability_slot.dart';
import '../providers/teacher_availability_providers.dart';
import 'booking_cancel_screen.dart';
import 'booking_reschedule_screen.dart';

/// My bookings screen
///
/// Shows list of student's bookings with options to reschedule or cancel.
class MyBookingsScreen extends ConsumerWidget {
  final String studentId;
  final String studentName;
  final String teacherId;
  final String teacherName;
  final int remainingReschedules;
  final int totalReschedules;
  final String? instrument;
  final String? subscriptionId; // 🆕 For reschedule count deduction

  const MyBookingsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.teacherName,
    required this.remainingReschedules,
    required this.totalReschedules,
    this.instrument,
    this.subscriptionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get upcoming bookings (next 60 days)
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 60));

    final slotsAsync = ref.watch(
      availableSlotsForDateRangeProvider(
        teacherId: teacherId,
        startDate: now,
        endDate: endDate,
        currentStudentId: studentId,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 레슨 예약'),
        backgroundColor: AppColors.paperDark,
        elevation: 0,
      ),
      backgroundColor: AppColors.paperDark,
      body: SafeArea(
        child: Column(
          children: [
            // Subscription info header
            _buildSubscriptionHeader(context),

            // Booking list
            Expanded(
              child: slotsAsync.when(
                data: (slots) {
                  final myBookings =
                      slots
                          .where(
                            (s) => s.status == AvailabilitySlotStatus.myBooking,
                          )
                          .toList();

                  if (myBookings.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildBookingList(context, ref, myBookings);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.paperAccent,
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          Text(
                            '데이터를 불러올 수 없습니다',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionHeader(BuildContext context) {
    final canReschedule = remainingReschedules > 0;
    final isLastChance = remainingReschedules == 1;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.paperAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: const Icon(
              Icons.music_note,
              color: AppColors.paperAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$teacherName${instrument != null ? ' · $instrument' : ''}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Row(
                  children: [
                    Icon(
                      canReschedule
                          ? (isLastChance
                              ? Icons.warning_amber
                              : Icons.swap_horiz)
                          : Icons.block,
                      size: 14,
                      color:
                          canReschedule
                              ? (isLastChance
                                  ? AppColors.paperAccent
                                  : AppColors.ink)
                              : AppColors.paperAccent,
                    ),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      '변경/취소: $remainingReschedules/$totalReschedules회',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            canReschedule
                                ? (isLastChance
                                    ? AppColors.paperAccent
                                    : AppColors.inkSecondary)
                                : AppColors.paperAccent,
                        fontWeight:
                            isLastChance ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.event_available,
      title: '예약된 레슨이 없습니다',
      subtitle: '새로운 레슨을 예약해보세요',
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    WidgetRef ref,
    List<AvailabilitySlot> bookings,
  ) {
    // Sort by date
    final sortedBookings = List<AvailabilitySlot>.from(bookings)
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      itemCount: sortedBookings.length,
      itemBuilder: (context, index) {
        final booking = sortedBookings[index];
        return _buildBookingCard(context, ref, booking);
      },
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    WidgetRef ref,
    AvailabilitySlot booking,
  ) {
    final canReschedule = remainingReschedules > 0;
    final isPast = booking.startDateTime.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color:
              isPast
                  ? AppColors.inkQuaternary
                  : AppColors.paperAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color:
                      isPast
                          ? AppColors.paper
                          : AppColors.paperAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  booking.formattedDate,
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        isPast
                            ? AppColors.inkSecondary
                            : AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${booking.formattedStartTime} - ${booking.formattedEndTime}',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isPast
                          ? AppColors.inkSecondary
                          : AppColors.ink,
                ),
              ),
              const Spacer(),
              if (isPast)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paperOk.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    '완료',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperOk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          if (!isPast) ...[
            const SizedBox(height: AppSpacing.space3),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.space3),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        canReschedule
                            ? () => _navigateToReschedule(context, booking)
                            : null,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('변경'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.paperAccent,
                      side: BorderSide(
                        color:
                            canReschedule
                                ? AppColors.paperAccent
                                : AppColors.inkQuaternary,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        canReschedule
                            ? () => _navigateToCancel(context, booking)
                            : null,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text(AppStrings.cancel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.paperAccent,
                      side: BorderSide(
                        color:
                            canReschedule
                                ? AppColors.paperAccent
                                : AppColors.inkQuaternary,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space2,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (!canReschedule) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                '변경/취소 횟수를 모두 사용했습니다',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _navigateToReschedule(BuildContext context, AvailabilitySlot booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookingRescheduleScreen(
              teacherId: teacherId,
              teacherName: teacherName,
              studentId: studentId,
              studentName: studentName,
              currentBookingId: booking.id,
              currentDate: booking.date,
              currentStartTime: booking.startTime,
              remainingReschedules: remainingReschedules,
              totalReschedules: totalReschedules,
              instrument: instrument,
              subscriptionId:
                  subscriptionId, // 🆕 For reschedule count deduction
            ),
      ),
    );
  }

  void _navigateToCancel(BuildContext context, AvailabilitySlot booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookingCancelScreen(
              bookingId: booking.id,
              teacherName: teacherName,
              teacherId: teacherId,
              bookingDate: booking.date,
              startTime: booking.startTime,
              remainingReschedules: remainingReschedules,
              totalReschedules: totalReschedules,
              instrument: instrument,
              subscriptionId: subscriptionId,
              studentId: studentId,
            ),
      ),
    );
  }
}
