import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/subscription.dart';

/// Result from the reschedule bottom sheet.
class RescheduleResult {
  final DateTime newDateTime;
  final bool usedRescheduleCredit;

  const RescheduleResult({
    required this.newDateTime,
    required this.usedRescheduleCredit,
  });
}

/// Shows a bottom sheet for rescheduling a lesson session.
/// Checks deadline hours and warns about reschedule credit usage.
Future<RescheduleResult?> showRescheduleBottomSheet(
  BuildContext context, {
  required Subscription subscription,
  required DateTime currentLessonDateTime,
  required int sessionNumber,
}) {
  return showModalBottomSheet<RescheduleResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RescheduleBottomSheet(
      subscription: subscription,
      currentLessonDateTime: currentLessonDateTime,
      sessionNumber: sessionNumber,
    ),
  );
}

class _RescheduleBottomSheet extends StatefulWidget {
  final Subscription subscription;
  final DateTime currentLessonDateTime;
  final int sessionNumber;

  const _RescheduleBottomSheet({
    required this.subscription,
    required this.currentLessonDateTime,
    required this.sessionNumber,
  });

  @override
  State<_RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<_RescheduleBottomSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool get _isWithinDeadline {
    final hoursUntilLesson =
        widget.currentLessonDateTime.difference(DateTime.now()).inHours;
    return hoursUntilLesson < widget.subscription.rescheduleDeadlineHours;
  }

  bool get _canSubmit => _selectedDate != null && _selectedTime != null;

  DateTime? get _newDateTime {
    if (_selectedDate == null || _selectedTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                AppStrings.sessionRescheduleTitle(widget.sessionNumber),
                style: AppTypography.headingSmall,
              ),
              const SizedBox(height: AppSpacing.space4),

              // Current schedule
              _buildInfoRow(
                AppStrings.current,
                '${formatDateMDWithDay(widget.currentLessonDateTime)} ${formatTimeHM(widget.currentLessonDateTime)}',
              ),

              const SizedBox(height: AppSpacing.space4),

              // Date picker
              _buildDatePicker(context),

              const SizedBox(height: AppSpacing.space3),

              // Time picker
              _buildTimePicker(context),

              const SizedBox(height: AppSpacing.space4),

              // Deadline warning
              _buildDeadlineNotice(),

              const SizedBox(height: AppSpacing.space4),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: Text(
                    _isWithinDeadline
                        ? AppStrings.rescheduleRequestWithCredit
                        : AppStrings.rescheduleRequest,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: widget.currentLessonDateTime,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.space3),
            Text(
              _selectedDate != null
                  ? formatDateYMDLong(_selectedDate!)
                  : AppStrings.selectDatePlaceholder,
              style: AppTypography.bodyMedium.copyWith(
                color: _selectedDate != null
                    ? AppColors.textPrimaryLight
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(widget.currentLessonDateTime),
        );
        if (picked != null) {
          setState(() => _selectedTime = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.space3),
            Text(
              _selectedTime != null
                  ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                  : AppStrings.selectTimePlaceholder,
              style: AppTypography.bodyMedium.copyWith(
                color: _selectedTime != null
                    ? AppColors.textPrimaryLight
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineNotice() {
    final deadlineHours = widget.subscription.rescheduleDeadlineHours;
    final remaining = widget.subscription.remainingReschedule;

    if (_isWithinDeadline) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, size: 18, color: AppColors.warning),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    AppStrings.rescheduleDeadlineWarning(deadlineHours),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.rescheduleCreditsChange(remaining, remaining - 1),
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
          const SizedBox(width: AppSpacing.space2),
          Text(
            AppStrings.rescheduleDeadlineFree(deadlineHours),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_newDateTime == null) return;

    if (_isWithinDeadline && !widget.subscription.canReschedule) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.rescheduleCreditsExhausted)),
      );
      return;
    }

    Navigator.pop(
      context,
      RescheduleResult(
        newDateTime: _newDateTime!,
        usedRescheduleCredit: _isWithinDeadline,
      ),
    );
  }
}
