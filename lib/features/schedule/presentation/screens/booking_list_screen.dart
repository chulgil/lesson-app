import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../providers/booking/booking_providers.dart';
import '../widgets/booking_card.dart';

/// Screen showing all bookings for a user
class BookingListScreen extends ConsumerWidget {
  final String? teacherId;
  final String? studentId;
  final BookingStatus? filterStatus;

  const BookingListScreen({
    super.key,
    this.teacherId,
    this.studentId,
    this.filterStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = teacherId != null
        ? ref.watch(teacherBookingsProvider(teacherId!))
        : studentId != null
            ? ref.watch(studentBookingsProvider(studentId!))
            : ref.watch(allBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          // Apply filter if specified
          var filteredBookings = bookings;
          if (filterStatus != null) {
            filteredBookings =
                bookings.where((b) => b.status == filterStatus).toList();
          }

          if (filteredBookings.isEmpty) {
            return _buildEmptyState();
          }

          // Group by status
          final pending =
              filteredBookings.where((b) => b.isPending).toList();
          final upcoming = filteredBookings
              .where((b) => b.isUpcoming && !b.isPending)
              .toList();
          final past = filteredBookings
              .where((b) => !b.isUpcoming && !b.isPending)
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              if (teacherId != null) {
                ref.invalidate(teacherBookingsProvider(teacherId!));
              } else if (studentId != null) {
                ref.invalidate(studentBookingsProvider(studentId!));
              } else {
                ref.invalidate(allBookingsProvider);
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                if (pending.isNotEmpty) ...[
                  _buildSectionHeader('승인 대기', pending.length),
                  ...pending.map((b) => _buildBookingCard(context, b)),
                  const SizedBox(height: AppSpacing.space4),
                ],
                if (upcoming.isNotEmpty) ...[
                  _buildSectionHeader('예정된 레슨', upcoming.length),
                  ...upcoming.map((b) => _buildBookingCard(context, b)),
                  const SizedBox(height: AppSpacing.space4),
                ],
                if (past.isNotEmpty) ...[
                  _buildSectionHeader('지난 레슨', past.length),
                  ...past.map((b) => _buildBookingCard(context, b)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space3),
              Text('오류가 발생했습니다', style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () {
                  if (teacherId != null) {
                    ref.invalidate(teacherBookingsProvider(teacherId!));
                  } else if (studentId != null) {
                    ref.invalidate(studentBookingsProvider(studentId!));
                  } else {
                    ref.invalidate(allBookingsProvider);
                  }
                },
                child: const Text('다시 시도'),
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
          Icon(
            Icons.event_note,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '예약이 없습니다',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.headingSmall,
          ),
          const SizedBox(width: AppSpacing.space2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              '$count',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, LessonBooking booking) {
    return BookingCardCompact(
      booking: booking,
      onTap: () {
        context.push('/schedule/booking/${booking.id}');
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('필터', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.space4),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('전체'),
              onTap: () {
                Navigator.pop(context);
                // Apply filter
              },
            ),
            ListTile(
              leading: Icon(BookingStatus.pending.icon),
              title: Text(BookingStatus.pending.label),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(BookingStatus.confirmed.icon),
              title: Text(BookingStatus.confirmed.label),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(BookingStatus.completed.icon),
              title: Text(BookingStatus.completed.label),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
