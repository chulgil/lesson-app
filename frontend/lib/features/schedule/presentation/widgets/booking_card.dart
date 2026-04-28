import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/booking/entities/lesson_booking.dart';

/// A card widget displaying booking information
class BookingCard extends StatelessWidget {
  final LessonBooking booking;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool showActions;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onApprove,
    this.onReject,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.inkQuaternary),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Type badge + Status
              Row(
                children: [
                  _buildTypeBadge(),
                  const SizedBox(width: AppSpacing.space2),
                  _buildStatusBadge(),
                  const Spacer(),
                  if (booking.daysUntilLesson >= 0 && booking.status.isActive)
                    Text(
                      _getDaysText(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.space3),

              // Student info
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.paperAccentSoft,
                    child: Text(
                      booking.studentName.isNotEmpty
                          ? booking.studentName[0]
                          : '?',
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.paperAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.studentName,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (booking.lessonGoal != null ||
                            booking.experienceLevel != null)
                          Text(
                            [
                              if (booking.lessonGoal != null)
                                booking.lessonGoal!.label,
                              if (booking.experienceLevel != null)
                                booking.experienceLevel!.label,
                            ].join(' · '),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.space3),

              // Date & Time
              Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(color: AppColors.paperDark),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppColors.inkSecondary,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      booking.formattedDate,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space4),
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: AppColors.inkSecondary,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      booking.timeRange,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Student message (for pending bookings)
              if (booking.studentMessage != null &&
                  booking.studentMessage!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space3),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.paperAccentSoft,
                    border: Border.all(color: AppColors.paperAccent),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 18,
                        color: AppColors.paperAccent,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          booking.studentMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons (for pending bookings)
              if (showActions && booking.isPending) ...[
                const SizedBox(height: AppSpacing.space3),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('거절'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.paperAccent,
                          side: const BorderSide(color: AppColors.paperAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('승인'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: booking.lessonType.color.withValues(alpha: 0.15),
      ),
      child: Text(
        booking.lessonType.label,
        style: AppTypography.caption.copyWith(
          color: booking.lessonType.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: booking.status.color.withValues(alpha: 0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(booking.status.icon, size: 12, color: booking.status.color),
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
    );
  }

  String _getDaysText() {
    final days = booking.daysUntilLesson;
    if (days == 0) return '오늘';
    if (days == 1) return '내일';
    return 'D-$days';
  }
}

/// Compact version of booking card for lists
class BookingCardCompact extends StatelessWidget {
  final LessonBooking booking;
  final VoidCallback? onTap;

  const BookingCardCompact({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: booking.lessonType.color.withValues(alpha: 0.15),
        child: Icon(
          booking.isTrial ? Icons.star : Icons.event,
          color: booking.lessonType.color,
          size: 20,
        ),
      ),
      title: Text(
        booking.studentName,
        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${booking.formattedDate} ${booking.timeRange}',
        style: AppTypography.bodySmall.copyWith(color: AppColors.inkSecondary),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: booking.status.color.withValues(alpha: 0.15),
        ),
        child: Text(
          booking.status.label,
          style: AppTypography.caption.copyWith(
            color: booking.status.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
