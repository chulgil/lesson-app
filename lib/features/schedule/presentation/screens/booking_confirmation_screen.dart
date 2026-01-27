import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Booking confirmation result passed from LessonBookingScreen
class BookingConfirmationData {
  final String teacherName;
  final String instrument;
  final DateTime lessonDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int fee;
  final String? studentName;
  final bool isPending;

  const BookingConfirmationData({
    required this.teacherName,
    required this.instrument,
    required this.lessonDate,
    required this.startTime,
    required this.endTime,
    required this.fee,
    this.studentName,
    this.isPending = true,
  });

  String get formattedDate {
    return DateFormat('M월 d일 (E)', 'ko').format(lessonDate);
  }

  String get formattedTime {
    final startStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr ~ $endStr';
  }

  String get formattedFee {
    if (fee >= 10000) {
      final man = fee ~/ 10000;
      final remainder = fee % 10000;
      if (remainder == 0) {
        return '$man만원';
      }
      return '$man만 ${remainder}원';
    }
    return '$fee원';
  }

  int get durationMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }
}

/// Screen displayed after successful lesson booking
class BookingConfirmationScreen extends ConsumerWidget {
  final BookingConfirmationData bookingData;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.space8),

                    // Success icon
                    _buildSuccessIcon(),

                    const SizedBox(height: AppSpacing.space6),

                    // Title
                    Text(
                      bookingData.isPending ? '예약 신청 완료!' : '예약 완료!',
                      style: AppTypography.headingLarge,
                    ),

                    const SizedBox(height: AppSpacing.space2),

                    // Subtitle
                    Text(
                      bookingData.isPending
                          ? '선생님 확인 후 레슨이 확정됩니다'
                          : '레슨이 확정되었습니다',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.space8),

                    // Booking details card
                    _buildBookingDetailsCard(),

                    const SizedBox(height: AppSpacing.space6),

                    // Info tips
                    if (bookingData.isPending) _buildPendingInfoTip(),

                    const SizedBox(height: AppSpacing.space4),

                    // Calendar add suggestion
                    _buildCalendarTip(context),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.practiceGood.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle,
        size: 48,
        color: AppColors.practiceGood,
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher info row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                child: Text(
                  bookingData.teacherName.isNotEmpty
                      ? bookingData.teacherName[0]
                      : 'T',
                  style: AppTypography.headingSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookingData.teacherName,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      bookingData.instrument,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),

          // Date
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: '날짜',
            value: bookingData.formattedDate,
          ),

          const SizedBox(height: AppSpacing.space3),

          // Time
          _buildDetailRow(
            icon: Icons.access_time,
            label: '시간',
            value: '${bookingData.formattedTime} (${bookingData.durationMinutes}분)',
          ),

          const SizedBox(height: AppSpacing.space3),

          // Fee
          _buildDetailRow(
            icon: Icons.payment_outlined,
            label: '수강료',
            value: bookingData.formattedFee,
          ),

          if (bookingData.studentName != null) ...[
            const SizedBox(height: AppSpacing.space3),
            _buildDetailRow(
              icon: Icons.person_outline,
              label: '학생',
              value: bookingData.studentName!,
            ),
          ],

          // Status badge
          const SizedBox(height: AppSpacing.space4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: bookingData.isPending
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.practiceGood.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  bookingData.isPending
                      ? Icons.schedule
                      : Icons.check_circle_outline,
                  size: 16,
                  color: bookingData.isPending
                      ? AppColors.warning
                      : AppColors.practiceGood,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  bookingData.isPending ? '선생님 확인 대기중' : '예약 확정',
                  style: AppTypography.caption.copyWith(
                    color: bookingData.isPending
                        ? AppColors.warning
                        : AppColors.practiceGood,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondaryLight,
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingInfoTip() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.info,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알림을 확인해주세요',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '선생님이 예약을 확정하면 알림으로 안내해드립니다.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTip(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Add to device calendar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('캘린더 연동 기능은 준비 중입니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 24,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '캘린더에 추가하기',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '기기 캘린더에 레슨 일정을 추가해보세요',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 24,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.space4,
        top: AppSpacing.space3,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary button - Go to home
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeight,
            child: FilledButton(
              onPressed: () {
                // Go to home, clearing the navigation stack
                context.go('/');
              },
              child: const Text('홈으로 돌아가기'),
            ),
          ),

          const SizedBox(height: AppSpacing.space2),

          // Secondary button - View lesson detail
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeight,
            child: OutlinedButton(
              onPressed: () {
                // Go back to previous screen
                context.pop();
              },
              child: const Text('다른 레슨 예약하기'),
            ),
          ),
        ],
      ),
    );
  }
}
