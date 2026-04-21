import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/booking/entities/lesson_booking.dart';

/// Compact trial booking card for dashboard
class CompactTrialBookingCard extends StatelessWidget {
  final LessonBooking booking;

  const CompactTrialBookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to my bookings for this teacher
          context.push(
            AppRoutes.myBookings,
            extra: {
              'studentId': booking.studentId,
              'studentName': booking.studentName,
              'teacherId': booking.teacherId,
              'teacherName': booking.teacherName,
              'instrument': booking.instrument ?? '바이올린',
              'remainingReschedules': 3,
              'totalReschedules': 3,
            },
          );
        },
        child: Row(
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

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        booking.teacherName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (booking.instrument != null) ...[
                        const SizedBox(width: AppSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paperDark,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSmall,
                            ),
                          ),
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
                  const SizedBox(height: 2),
                  Text(
                    booking.timeRange,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: booking.status.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: Text(
                booking.status.label,
                style: AppTypography.caption.copyWith(
                  color: booking.status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
