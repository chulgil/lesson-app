import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../domain/entities/teacher_availability.dart';
import '../providers/teacher_availability_providers.dart';
import '../widgets/availability/availability_preview_grid.dart';
import '../widgets/availability/availability_vacation_banner.dart';
import '../widgets/schedule_edit_bottom_sheet.dart';
import 'time_exception_screen.dart';

/// G5 #433 — Split layout availability settings page.
///
/// Two-column layout (desktop / wide tablet):
/// - Left column: settings (weekly hours, lesson duration, break time, exceptions)
/// - Right column: live preview of the slot grid the student will see
///
/// Mobile fallback (width <= 768): vertical stack (preview pinned above settings).
///
/// Defaults to 50/10/60 (lesson / break / interval) when no record exists yet
/// — see schedule_master.md §2.1.
class TeacherAvailabilitySplitPage extends ConsumerWidget {
  /// Mobile breakpoint per spec (availability_settings_ux_redesign_spec.md).
  static const double mobileBreakpoint = 768;

  final String teacherId;

  const TeacherAvailabilitySplitPage({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(teacherAvailabilityProvider(teacherId));
    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: const NotebookDetailAppBar(
        title: AppStrings.teacherAvailabilityTitle,
      ),
      body: availabilityAsync.when(
        data: (availability) {
          // Apply 50/10/60 defaults for first-time setup. User overrides win.
          final effective = _ensureDefaults(availability);
          return _SplitLayout(teacherId: teacherId, availability: effective);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(
          onRetry: () => ref.invalidate(teacherAvailabilityProvider(teacherId)),
        ),
      ),
    );
  }

  /// Materialize a TeacherAvailability with 50/10/60 defaults when no record
  /// exists yet. Existing user settings are preserved as-is.
  TeacherAvailability _ensureDefaults(TeacherAvailability? availability) {
    if (availability != null) return availability;
    return TeacherAvailability(
      id: '',
      teacherId: teacherId,
      // Defaults already set in TeacherAvailability constructor (50/10/60),
      // but we materialize an instance for the preview to render.
      createdAt: DateTime.now(),
    );
  }
}

class _SplitLayout extends ConsumerWidget {
  final String teacherId;
  final TeacherAvailability availability;

  const _SplitLayout({required this.teacherId, required this.availability});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > TeacherAvailabilitySplitPage.mobileBreakpoint;

    final settings = _SettingsPanel(
      teacherId: teacherId,
      availability: availability,
    );
    final preview = AvailabilityPreviewGrid(availability: availability);

    if (isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AvailabilityVacationBanner(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: settings),
                const SizedBox(width: AppSpacing.space5),
                Expanded(child: preview),
              ],
            ),
          ],
        ),
      );
    }
    // Mobile: preview first (so the user sees the result immediately),
    // then settings below.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AvailabilityVacationBanner(),
          preview,
          const SizedBox(height: AppSpacing.space5),
          settings,
        ],
      ),
    );
  }
}

class _SettingsPanel extends ConsumerWidget {
  final String teacherId;
  final TeacherAvailability availability;

  const _SettingsPanel({required this.teacherId, required this.availability});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.availabilitySettingsPanel,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Section 1: Weekly lesson times
        _SectionHeader(
          title: AppStrings.weeklyLessonTimes,
          subtitle: AppStrings.weeklyLessonTimesSubtitle,
        ),
        const SizedBox(height: AppSpacing.space2),
        _WeeklySchedulePanel(teacherId: teacherId, availability: availability),

        const SizedBox(height: AppSpacing.space6),

        // Section 2: Lesson settings (duration + break) — friendly names.
        _SectionHeader(title: AppStrings.lessonBasicSettings),
        const SizedBox(height: AppSpacing.space2),
        _LessonSettingsPanel(teacherId: teacherId, availability: availability),

        const SizedBox(height: AppSpacing.space6),

        // Section 3: Special schedules (exceptions placeholder — full
        // editing kept in time_exception_screen; vacation mode lives in
        // #431).
        _SectionHeader(
          title: AppStrings.specialSchedules,
          subtitle: AppStrings.specialSchedulesSubtitle,
        ),
        const SizedBox(height: AppSpacing.space2),
        _ExceptionsPanel(availability: availability),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Weekly schedule panel ───────────────────────────────────────

class _WeeklySchedulePanel extends ConsumerWidget {
  final String teacherId;
  final TeacherAvailability availability;

  const _WeeklySchedulePanel({
    required this.teacherId,
    required this.availability,
  });

  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = <int, List<WeeklySchedule>>{};
    for (final s in availability.weeklySchedules) {
      grouped.putIfAbsent(s.dayOfWeek, () => []).add(s);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return Column(
      children: List.generate(7, (dayIndex) {
        final schedules = grouped[dayIndex] ?? const <WeeklySchedule>[];
        return _DayRow(
          dayIndex: dayIndex,
          dayLabel: _dayLabels[dayIndex],
          schedules: schedules,
          onAddOrEdit: (existing) => _openEditSheet(
            context,
            ref,
            preselectedDay: dayIndex,
            existing: existing,
          ),
        );
      }),
    );
  }

  Future<void> _openEditSheet(
    BuildContext context,
    WidgetRef ref, {
    int? preselectedDay,
    WeeklySchedule? existing,
  }) async {
    final result = await showNotebookBottomSheet<WeeklySchedule>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ScheduleEditBottomSheet(
        preselectedDay: preselectedDay,
        existingSchedule: existing,
      ),
    );
    if (result == null) return;
    final notifier = ref.read(
      teacherAvailabilityNotifierProvider(teacherId).notifier,
    );
    if (existing != null && result.id == existing.id) {
      await notifier.updateWeeklySchedule(result);
    } else {
      await notifier.addWeeklySchedule(result);
    }
    ref.invalidate(teacherAvailabilityProvider(teacherId));
  }
}

class _DayRow extends StatelessWidget {
  final int dayIndex;
  final String dayLabel;
  final List<WeeklySchedule> schedules;
  final void Function(WeeklySchedule? existing) onAddOrEdit;

  const _DayRow({
    required this.dayIndex,
    required this.dayLabel,
    required this.schedules,
    required this.onAddOrEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasSchedules = schedules.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hasSchedules ? AppColors.paperAccentSoft : AppColors.paper,
          ),
          child: Center(
            child: Text(
              dayLabel,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: hasSchedules
                    ? AppColors.paperAccent
                    : AppColors.inkSecondary,
              ),
            ),
          ),
        ),
        title: hasSchedules
            ? Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children: schedules
                    .map(
                      (s) =>
                          _TimeChip(schedule: s, onTap: () => onAddOrEdit(s)),
                    )
                    .toList(),
              )
            : Text(
                AppStrings.dayOff,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
        trailing: IconButton(
          icon: Icon(
            hasSchedules ? Icons.edit_outlined : Icons.add,
            size: 20,
            color: AppColors.paperAccent,
          ),
          onPressed: () => onAddOrEdit(null),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: 0,
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final WeeklySchedule schedule;
  final VoidCallback onTap;
  const _TimeChip({required this.schedule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.paperOk.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.paperOk.withValues(alpha: 0.3)),
        ),
        child: Text(
          '${schedule.startTime} - ${schedule.endTime}',
          style: AppTypography.caption.copyWith(
            color: AppColors.paperOk,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Lesson settings panel (duration + break) ────────────────────

class _LessonSettingsPanel extends ConsumerWidget {
  final String teacherId;
  final TeacherAvailability availability;

  const _LessonSettingsPanel({
    required this.teacherId,
    required this.availability,
  });

  /// Allowed options per schedule_master.md §2.1.
  static const _durationOptions = <int>[30, 45, 50, 60];
  static const _breakOptions = <int>[0, 5, 10, 15];

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
          _OptionRow(
            label: AppStrings.lessonDurationLabel,
            helpText: AppStrings.lessonLengthHelp,
            options: _durationOptions,
            selected: availability.slotDurationMinutes,
            buildLabel: AppStrings.lessonDurationOptionLabel,
            onSelected: (value) => _updateSettings(
              ref,
              slotDurationMinutes: value,
              breakTimeBetweenLessons: availability.breakTimeBetweenLessons,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          const ThinRule(),
          const SizedBox(height: AppSpacing.space3),
          _OptionRow(
            label: AppStrings.breakTimeLabel,
            helpText: AppStrings.breakTimeHelp,
            options: _breakOptions,
            selected: availability.breakTimeBetweenLessons,
            buildLabel: (m) => m == 0 ? AppStrings.breakTimeNoneOption : '$m분',
            onSelected: (value) => _updateSettings(
              ref,
              slotDurationMinutes: availability.slotDurationMinutes,
              breakTimeBetweenLessons: value,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSettings(
    WidgetRef ref, {
    required int slotDurationMinutes,
    required int breakTimeBetweenLessons,
  }) async {
    // slotStartInterval is the internal computed value: duration + break.
    final interval = slotDurationMinutes + breakTimeBetweenLessons;
    await ref
        .read(teacherAvailabilityNotifierProvider(teacherId).notifier)
        .updateLessonSettings(
          slotDurationMinutes: slotDurationMinutes,
          slotStartInterval: interval,
          breakTimeBetweenLessons: breakTimeBetweenLessons,
        );
    ref.invalidate(teacherAvailabilityProvider(teacherId));
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final String helpText;
  final List<int> options;
  final int selected;
  final String Function(int) buildLabel;
  final ValueChanged<int> onSelected;

  const _OptionRow({
    required this.label,
    required this.helpText,
    required this.options,
    required this.selected,
    required this.buildLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          helpText,
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space1,
          children: options.map((value) {
            final isActive = value == selected;
            return GestureDetector(
              onTap: () => onSelected(value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.paperAccentSoft : AppColors.paper,
                  border: Border.all(
                    color: isActive
                        ? AppColors.paperAccent
                        : AppColors.inkQuaternary,
                  ),
                ),
                child: Text(
                  buildLabel(value),
                  style: AppTypography.bodySmall.copyWith(
                    color: isActive
                        ? AppColors.paperAccent
                        : AppColors.inkSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Exceptions panel ─────────────────────────────────────────────

class _ExceptionsPanel extends StatelessWidget {
  final TeacherAvailability availability;
  const _ExceptionsPanel({required this.availability});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming =
        availability.exceptions
            .where(
              (e) => !DateTime(
                e.endDate.year,
                e.endDate.month,
                e.endDate.day,
              ).isBefore(today),
            )
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (upcoming.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            alignment: Alignment.center,
            child: Text(
              AppStrings.noSpecialSchedules,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          )
        else
          ...upcoming.map((exc) => _ExceptionTile(exception: exc)),
        const SizedBox(height: AppSpacing.space2),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TimeExceptionScreen()),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text(AppStrings.manageSpecialSchedules),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
            side: BorderSide(
              color: AppColors.paperAccent.withValues(alpha: 0.3),
            ),
            shape: const RoundedRectangleBorder(),
          ),
        ),
      ],
    );
  }
}

class _ExceptionTile extends StatelessWidget {
  final TimeException exception;
  const _ExceptionTile({required this.exception});

  @override
  Widget build(BuildContext context) {
    final isHoliday = exception.type != ExceptionType.additionalSlot;
    final dateText = exception.startDate == exception.endDate
        ? formatDateYMD(exception.startDate)
        : '${formatDateYMD(exception.startDate)} ~ '
              '${formatDateYMD(exception.endDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Icon(
            isHoliday ? Icons.event_busy : Icons.add_circle_outline,
            size: 18,
            color: isHoliday ? AppColors.paperAccent : AppColors.paperOk,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exception.type.displayName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  dateText,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.paperAccent,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            AppStrings.cannotLoadData,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          TextButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    );
  }
}
