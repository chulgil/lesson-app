import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../providers/booking/booking_providers.dart';

/// Trial Booking Card - displays a single trial lesson booking with status and actions
class TrialBookingCard extends ConsumerWidget {
  final LessonBooking booking;

  const TrialBookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                backgroundColor: AppColors.primary,
                child: Text(
                  booking.teacherName.isNotEmpty ? booking.teacherName[0] : 'T',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
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
                            color: AppColors.info.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '체험레슨',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      booking.status.icon,
                      size: 14,
                      color: booking.status.color,
                    ),
                    const SizedBox(width: 4),
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
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  booking.timeRange,
                  style: AppTypography.bodyMedium,
                ),
                if (booking.instrument != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      booking.instrument!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
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
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '변경 요청: ${booking.formattedRequestedDate} ${booking.requestedTimeRange}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warning,
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                    label: const Text('수정'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                if (booking.status.canRequestChange)
                  OutlinedButton.icon(
                    onPressed: () => _onRequestChange(context),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('일정 변경'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: const BorderSide(color: AppColors.info),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                if (booking.status.canCancel)
                  OutlinedButton.icon(
                    onPressed: () => _onCancel(context, ref),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('취소'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
      '${AppRoutes.trialLessonRequest}?teacherId=${booking.teacherId}&teacherName=${booking.teacherName}&bookingId=${booking.id}',
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
      builder: (context) => AlertDialog(
        title: const Text('체험레슨 취소'),
        content: const Text('체험레슨 신청을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(bookingsNotifierProvider.notifier).cancelBooking(
              booking.id,
              null,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('체험레슨 신청이 취소되었습니다'),
              backgroundColor: AppColors.practiceGood,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('취소 처리 중 오류가 발생했습니다: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _onRetry(BuildContext context) {
    context.push(
      '/schedule/trial/request?teacherId=${booking.teacherId}&teacherName=${Uri.encodeComponent(booking.teacherName)}',
    );
  }
}
