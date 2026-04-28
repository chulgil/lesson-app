import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/currency_utils.dart';
import '../../../domain/entities/availability_slot.dart';

/// Preview widget for selected booking slot
///
/// Shows selected time, teacher info, and subscription info
/// before confirming the booking.
class AvailabilityBookingPreview extends StatelessWidget {
  final AvailabilitySlot selectedSlot;
  final String teacherName;
  final String instrument;
  final int? remainingLessons;
  final int? totalLessons;
  final int? lessonFee;
  final int? remainingReschedules;
  final int? totalReschedules;
  final VoidCallback? onBook;
  final bool isLoading;
  final bool isTrialLesson;

  const AvailabilityBookingPreview({
    super.key,
    required this.selectedSlot,
    required this.teacherName,
    required this.instrument,
    this.remainingLessons,
    this.totalLessons,
    this.lessonFee,
    this.remainingReschedules,
    this.totalReschedules,
    this.onBook,
    this.isLoading = false,
    this.isTrialLesson = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time and duration
          Row(
            children: [
              const Text('🎻', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${selectedSlot.formattedTimeRange} (${selectedSlot.durationMinutes}분)',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.ink,
                ),
              ),
              if (selectedSlot.isRecommended) ...[
                const SizedBox(width: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(color: AppColors.paperAccentSoft),
                  child: Text(
                    '⭐ 평소 시간',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.space2),

          // Teacher and instrument
          Text(
            '$teacherName · $instrument',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),

          // Subscription info
          if (remainingLessons != null && totalLessons != null) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              '수강권: $remainingLessons/$totalLessons회 남음',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ] else if (lessonFee != null) ...[
            // Show lesson fee if no subscription
            const SizedBox(height: AppSpacing.space1),
            Text(
              '레슨비: ${_formatFee(lessonFee!)}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],

          // Reschedule info (for reschedule mode)
          if (remainingReschedules != null && totalReschedules != null) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              '🔄 변경: $remainingReschedules/$totalReschedules회 남음',
              style: AppTypography.bodySmall.copyWith(
                color:
                    remainingReschedules == 1
                        ? AppColors.paperAccent
                        : AppColors.inkTertiary,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space4),

          // Book button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : onBook,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space3,
                ),
                shape: RoundedRectangleBorder(),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.paper,
                          ),
                        ),
                      )
                      : Text(
                        isTrialLesson ? '체험레슨 신청하기' : '예약하기',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.paper,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFee(int fee) => fee.toKoreanWon;
}
