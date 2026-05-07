import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart'
    show formatDateYMDWithDay;
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../core/booking/presentation/extensions/lesson_booking_visual_extensions.dart';

/// Compact trial booking card for dashboard
class CompactTrialBookingCard extends StatelessWidget {
  final LessonBooking booking;

  const CompactTrialBookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: InkWell(
        onTap: () => _showTrialDetailSheet(context),
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
                          decoration: BoxDecoration(color: AppColors.paperDark),
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

  void _showTrialDetailSheet(BuildContext context) {
    showNotebookBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      padding: EdgeInsets.zero,
      showHandle: false,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(color: AppColors.paper),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space3,
            AppSpacing.screenPadding,
            MediaQuery.of(ctx).padding.bottom + AppSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: BottomSheetHandle(width: 36, margin: EdgeInsets.zero),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Title
              Text(
                AppStrings.trialLessonDetail,
                style: NotebookTypography.appBarTitle,
              ),
              const SizedBox(height: AppSpacing.space4),

              // Teacher
              _detailRow(AppStrings.teacher, booking.teacherName),

              // Instrument
              if (booking.instrument != null)
                _detailRow(AppStrings.instrumentLabel, booking.instrument!),

              // Date & Time
              _detailRow(
                AppStrings.lessonDate,
                formatDateYMDWithDay(booking.lessonDate),
              ),
              _detailRow(AppStrings.lessonTime, booking.timeRange),

              // Status
              _detailRow(AppStrings.statusLabel, booking.status.label),

              // Message
              if (booking.studentMessage != null &&
                  booking.studentMessage!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space3),
                Text(
                  AppStrings.myMessage,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: const BoxDecoration(color: AppColors.paperDark),
                  child: Text(
                    booking.studentMessage!,
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.space4),

              // Close button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeightSmall,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.paperAccent,
                    shape: RoundedRectangleBorder(),
                  ),
                  child: Text(
                    AppStrings.confirm,
                    style: AppTypography.buttonSmall.copyWith(
                      color: AppColors.paper,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}
