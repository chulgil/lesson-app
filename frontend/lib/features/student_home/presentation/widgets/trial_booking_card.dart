import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../features/lessons/presentation/providers/booking_providers.dart';

/// Trial Booking Card - displays a single trial lesson booking with status and actions
class TrialBookingCard extends ConsumerWidget {
  final LessonBooking booking;

  const TrialBookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher info & status
          Row(
            children: [
              // Teacher avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.ink,
                child: Text(
                  booking.teacherName.isNotEmpty ? booking.teacherName[0] : 'T',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),

              // Teacher name & instrument
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paperAccentSoft,
                          ),
                          child: Text(
                            '체험레슨',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.paperAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      booking.teacherName,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: booking.status.color.withValues(alpha: 0.15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      booking.status.icon,
                      size: 14,
                      color: booking.status.color,
                    ),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      booking.status.label,
                      style: AppTypography.caption.copyWith(
                        color: booking.status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Lesson time
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(color: AppColors.paperDark),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.inkSecondary,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(booking.timeRange, style: AppTypography.bodyMedium),
                if (booking.instrument != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(color: AppColors.paper),
                    child: Text(
                      booking.instrument!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Change request info (if any)
          if (booking.hasChangeRequest) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.paperHighlight.withValues(alpha: 0.3),
                border: Border.all(color: AppColors.inkQuaternary),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 16, color: AppColors.ink),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '변경 요청: ${booking.formattedRequestedDate} ${booking.requestedTimeRange}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Unavailable message (for unavailable/expired)
          if (booking.unavailableMessage != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: booking.status.color.withValues(alpha: 0.1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: booking.status.color,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      booking.unavailableMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: booking.status.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          if (booking.status.canStudentModify ||
              booking.status.canCancel ||
              booking.status.canRequestChange) ...[
            const SizedBox(height: AppSpacing.space3),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: [
                if (booking.status.canStudentModify)
                  OutlinedButton.icon(
                    onPressed: () => _onModify(context),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text(AppStrings.modify),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.ink),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                      ),
                    ),
                  ),
                if (booking.status.canRequestChange)
                  OutlinedButton.icon(
                    onPressed: () => _onRequestChange(context),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('일정 변경'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.paperAccent,
                      side: const BorderSide(color: AppColors.paperAccent),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                      ),
                    ),
                  ),
                if (booking.status.canCancel)
                  OutlinedButton.icon(
                    onPressed: () => _onCancel(context, ref),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text(AppStrings.cancel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.paperAccent,
                      side: const BorderSide(color: AppColors.paperAccent),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Retry button for unavailable/expired statuses
          if (booking.status.canRetry) ...[
            const SizedBox(height: AppSpacing.space3),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _onRetry(context),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('다른 시간으로 다시 신청'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onModify(BuildContext context) {
    context.push(
      AppRoutes.lessonBooking,
      extra: {
        'teacherId': booking.teacherId,
        'teacherName': booking.teacherName,
        'instrument': booking.instrument ?? '바이올린',
        'studentId': booking.studentId,
        'studentName': booking.studentName,
        'isTrialLesson': true,
      },
    );
  }

  void _onRequestChange(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('일정 변경 요청 기능 준비 중입니다'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('체험레슨 취소'),
            content: const Text('체험레슨 신청을 취소하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('아니오'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                ),
                child: const Text('취소하기'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(bookingsNotifierProvider.notifier)
            .cancelBooking(booking.id, null);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('체험레슨 신청이 취소되었습니다'),
              backgroundColor: AppColors.paperOk,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('취소 처리 중 오류가 발생했습니다. 다시 시도해주세요.'),
              backgroundColor: AppColors.paperAccent,
            ),
          );
        }
      }
    }
  }

  void _onRetry(BuildContext context) {
    context.push(
      AppRoutes.lessonBooking,
      extra: {
        'teacherId': booking.teacherId,
        'teacherName': booking.teacherName,
        'instrument': booking.instrument ?? '바이올린',
        'studentId': booking.studentId,
        'studentName': booking.studentName,
        'isTrialLesson': true,
      },
    );
  }
}
