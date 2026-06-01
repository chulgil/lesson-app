import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/domain/value_objects/clock_time.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../settings/settings_facade.dart';
import '../widgets/first_availability_celebration_sheet.dart';

/// First availability setup screen for teacher onboarding (#422).
///
/// Simple single-screen UI per
/// `docs/specs/onboarding/teacher_first_availability_setup.md` §4.2:
/// multi-day chip selection + a single start/end time pair + apply.
/// Lesson duration / break / start interval use the spec defaults
/// (50 / 10 / 60 minutes) and are shown read-only.
class FirstAvailabilitySetupScreen extends ConsumerStatefulWidget {
  const FirstAvailabilitySetupScreen({super.key});

  @override
  ConsumerState<FirstAvailabilitySetupScreen> createState() =>
      _FirstAvailabilitySetupScreenState();
}

class _FirstAvailabilitySetupScreenState
    extends ConsumerState<FirstAvailabilitySetupScreen> {
  // Default selection: weekdays Mon-Fri.
  final Set<int> _selectedDays = {1, 2, 3, 4, 5};
  ClockTime _startTime = const ClockTime(hour: 14, minute: 0);
  ClockTime _endTime = const ClockTime(hour: 18, minute: 0);
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.firstAvailabilitySetupTitle,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDaysSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildHoursSection(context),
              const SizedBox(height: AppSpacing.space6),
              _buildDefaultsSection(),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  _errorMessage!,
                  style: NotebookTypography.hand.copyWith(
                    color: AppColors.paperAccent,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space6),
              _buildApplyButton(),
              const SizedBox(height: AppSpacing.space3),
              _buildAdvancedLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaysSection() {
    const labels = [
      AppStrings.firstAvailabilityDayMon,
      AppStrings.firstAvailabilityDayTue,
      AppStrings.firstAvailabilityDayWed,
      AppStrings.firstAvailabilityDayThu,
      AppStrings.firstAvailabilityDayFri,
      AppStrings.firstAvailabilityDaySat,
      AppStrings.firstAvailabilityDaySun,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.firstAvailabilityDaysLabel,
          style: NotebookTypography.sectionLabel.copyWith(
            color: AppColors.ink,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (int i = 0; i < labels.length; i++)
              _DayChip(
                label: labels[i],
                // Domain dayOfWeek = 1=Mon..7=Sun (matches TimeSlot.dayOfWeek).
                dayOfWeek: i + 1,
                isSelected: _selectedDays.contains(i + 1),
                onTap: () => _toggleDay(i + 1),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHoursSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.firstAvailabilityHoursLabel,
          style: NotebookTypography.sectionLabel.copyWith(
            color: AppColors.ink,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: AppStrings.firstAvailabilityStartTimeLabel,
                value: _startTime,
                onTap: () => _pickStartTime(context),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _TimeField(
                label: AppStrings.firstAvailabilityEndTimeLabel,
                value: _endTime,
                onTap: () => _pickEndTime(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultsSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.inkQuaternary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.firstAvailabilityDefaultsHeader,
            style: NotebookTypography.sectionLabel.copyWith(
              color: AppColors.inkSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          _DefaultLine(AppStrings.firstAvailabilityLessonDurationDefault),
          _DefaultLine(AppStrings.firstAvailabilityBreakTimeDefault),
          _DefaultLine(AppStrings.firstAvailabilityStartIntervalDefault),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isSubmitting ? null : _submit,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.paper,
                ),
              )
            : const Text(AppStrings.firstAvailabilityApplyAction),
      ),
    );
  }

  Widget _buildAdvancedLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          // Skip to full settings — recorded as opt-out per spec §5.3.
          context.go(AppRoutes.lessonTimeSettings);
        },
        child: const Text(AppStrings.firstAvailabilityAdvancedAction),
      ),
    );
  }

  void _toggleDay(int dayOfWeek) {
    setState(() {
      if (_selectedDays.contains(dayOfWeek)) {
        _selectedDays.remove(dayOfWeek);
      } else {
        _selectedDays.add(dayOfWeek);
      }
      _errorMessage = null;
    });
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _startTime.hour, minute: _startTime.minute),
    );
    if (result == null || !mounted) return;
    setState(() {
      _startTime = ClockTime(hour: result.hour, minute: result.minute);
      _errorMessage = null;
    });
  }

  Future<void> _pickEndTime(BuildContext context) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _endTime.hour, minute: _endTime.minute),
    );
    if (result == null || !mounted) return;
    setState(() {
      _endTime = ClockTime(hour: result.hour, minute: result.minute);
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (_selectedDays.isEmpty) {
      setState(
        () => _errorMessage = AppStrings.firstAvailabilityValidationDayMissing,
      );
      return;
    }
    // Minimum 1 hour difference per spec §4.2.1.
    if (_endTime.inMinutes - _startTime.inMinutes < 60) {
      setState(
        () => _errorMessage = AppStrings.firstAvailabilityValidationTimeInvalid,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final notifier = ref.read(teacherSettingsNotifierProvider.notifier);
    final current = ref.read(teacherSettingsNotifierProvider).value;
    if (current == null) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = AppStrings.firstAvailabilitySaveFailed;
      });
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final newSlots = <TimeSlot>[
      ...current.availableSlots,
      for (final day in _selectedDays)
        TimeSlot(
          id: 'first_${now}_$day',
          dayOfWeek: day,
          startTime: _startTime,
          endTime: _endTime,
        ),
    ];

    try {
      // Persist via the existing settings notifier — reuses the
      // updateAvailableSlots repository path (mock + remote both wired).
      await notifier.replaceAvailableSlots(newSlots);
      if (!mounted) return;
      // Celebration sheet — modal sheet, no skip.
      await showFirstAvailabilityCelebrationSheet(context);
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = AppStrings.firstAvailabilitySaveFailed;
      });
    }
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final int dayOfWeek;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.dayOfWeek,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.inkTertiary,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: NotebookTypography.hand.copyWith(
            color: isSelected ? AppColors.paper : AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final ClockTime value;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.inkTertiary, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: NotebookTypography.hand.copyWith(
                color: AppColors.inkSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              value.format24Hour(),
              style: NotebookTypography.hand.copyWith(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultLine extends StatelessWidget {
  final String text;
  const _DefaultLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '· $text',
        style: NotebookTypography.hand.copyWith(
          color: AppColors.inkSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}
