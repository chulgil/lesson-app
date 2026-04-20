import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/subscription.dart';

/// Cancellation reason enum.
enum CancelReason {
  studentSchedule,
  studentSick,
  teacherCancel,
  mutual;

  String get label {
    switch (this) {
      case CancelReason.studentSchedule:
        return AppStrings.cancelReasonStudentSchedule;
      case CancelReason.studentSick:
        return AppStrings.cancelReasonStudentSick;
      case CancelReason.teacherCancel:
        return AppStrings.cancelReasonTeacher;
      case CancelReason.mutual:
        return AppStrings.cancelReasonMutual;
    }
  }

  /// Whether this cancellation deducts a lesson.
  bool get deductsLesson {
    switch (this) {
      case CancelReason.studentSchedule:
      case CancelReason.studentSick:
        return true;
      case CancelReason.teacherCancel:
      case CancelReason.mutual:
        return false;
    }
  }
}

/// Result from the cancel lesson bottom sheet.
class CancelLessonResult {
  final CancelReason reason;
  final String? note;
  final bool usedRescheduleCredit;

  const CancelLessonResult({
    required this.reason,
    this.note,
    required this.usedRescheduleCredit,
  });
}

/// Shows a bottom sheet for canceling a lesson session.
Future<CancelLessonResult?> showCancelLessonBottomSheet(
  BuildContext context, {
  required Subscription subscription,
  required DateTime lessonDateTime,
  required int sessionNumber,
}) {
  return showModalBottomSheet<CancelLessonResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => _CancelLessonBottomSheet(
          subscription: subscription,
          lessonDateTime: lessonDateTime,
          sessionNumber: sessionNumber,
        ),
  );
}

class _CancelLessonBottomSheet extends StatefulWidget {
  final Subscription subscription;
  final DateTime lessonDateTime;
  final int sessionNumber;

  const _CancelLessonBottomSheet({
    required this.subscription,
    required this.lessonDateTime,
    required this.sessionNumber,
  });

  @override
  State<_CancelLessonBottomSheet> createState() =>
      _CancelLessonBottomSheetState();
}

class _CancelLessonBottomSheetState extends State<_CancelLessonBottomSheet> {
  CancelReason? _selectedReason;

  bool get _isWithinDeadline {
    final hoursUntilLesson =
        widget.lessonDateTime.difference(DateTime.now()).inHours;
    return hoursUntilLesson < widget.subscription.rescheduleDeadlineHours;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              const Center(
                child: BottomSheetHandle(
                  margin: EdgeInsets.only(bottom: AppSpacing.space4),
                ),
              ),

              // Title
              Text(
                AppStrings.sessionCancelTitle(widget.sessionNumber),
                style: AppTypography.headingSmall,
              ),
              const SizedBox(height: 4),
              Text(
                formatDateTimeMDHM(widget.lessonDateTime),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: AppSpacing.space4),

              // Reason selection
              Text(
                AppStrings.cancelReasonPrompt,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              ...CancelReason.values.map((reason) => _buildReasonTile(reason)),

              const SizedBox(height: AppSpacing.space4),

              // Deadline notice
              if (_selectedReason != null && _selectedReason!.deductsLesson)
                _buildDeductionNotice(),

              if (_selectedReason != null && _isWithinDeadline)
                _buildDeadlineNotice(),

              const SizedBox(height: AppSpacing.space4),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedReason != null ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: Text(AppStrings.cancelRequest),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonTile(CancelReason reason) {
    final isSelected = _selectedReason == reason;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: InkWell(
        onTap: () => setState(() => _selectedReason = reason),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            color:
                isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color:
                    isSelected
                        ? AppColors.primary
                        : AppColors.textTertiaryLight,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason.label,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (reason.deductsLesson)
                      Text(
                        AppStrings.lessonDeductWarning,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    if (!reason.deductsLesson)
                      Text(
                        AppStrings.makeupAvailable,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeductionNotice() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: AppColors.warning),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                AppStrings.studentCancelDeductNotice,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineNotice() {
    final deadlineHours = widget.subscription.rescheduleDeadlineHours;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 18, color: AppColors.error),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              AppStrings.rescheduleDeadlineWarning(deadlineHours),
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_selectedReason == null) return;

    if (_isWithinDeadline && !widget.subscription.canReschedule) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.rescheduleCreditsExhausted)),
      );
      return;
    }

    Navigator.pop(
      context,
      CancelLessonResult(
        reason: _selectedReason!,
        usedRescheduleCredit: _isWithinDeadline,
      ),
    );
  }
}
