import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/teacher_availability.dart';
import '../providers/teacher_availability_providers.dart';
import '../widgets/lesson_settings_bottom_sheet.dart';
import '../widgets/schedule_edit_bottom_sheet.dart';
import 'time_exception_screen.dart';

/// Unified teacher availability settings screen.
///
/// Combines weekly schedule, lesson settings, preview, and
/// exception management into a single scrollable page.
///
/// Sections:
/// 1. Weekly lesson times (day-by-day ON/OFF with time ranges)
/// 2. Lesson settings (duration, break, interval)
/// 3. Weekly preview (mini grid)
/// 4. Special schedules (holidays, additional slots)
class TeacherAvailabilityScreen extends ConsumerStatefulWidget {
  final String teacherId;

  const TeacherAvailabilityScreen({super.key, required this.teacherId});

  @override
  ConsumerState<TeacherAvailabilityScreen> createState() =>
      _TeacherAvailabilityScreenState();
}

class _TeacherAvailabilityScreenState
    extends ConsumerState<TeacherAvailabilityScreen> {
  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(
      teacherAvailabilityProvider(widget.teacherId),
    );

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text(AppStrings.teacherAvailabilityTitle)),
      body: availabilityAsync.when(
        data: (availability) => _buildBody(availability),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => Center(
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
                  TextButton(
                    onPressed:
                        () => ref.invalidate(
                          teacherAvailabilityProvider(widget.teacherId),
                        ),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildBody(TeacherAvailability? availability) {
    final avail =
        availability ??
        TeacherAvailability(
          id: '',
          teacherId: widget.teacherId,
          createdAt: DateTime.now(),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Weekly lesson times
          _buildSectionHeader(
            romanIndex: 0,
            title: AppStrings.weeklyLessonTimes,
            subtitle: AppStrings.weeklyLessonTimesSubtitle,
            helpText: AppStrings.weeklyLessonTimesHelp,
          ),
          const SizedBox(height: AppSpacing.space3),
          _buildWeeklySchedule(avail),

          const SizedBox(height: AppSpacing.space8),

          // Section 2: Lesson settings
          _buildSectionHeader(
            romanIndex: 1,
            title: AppStrings.lessonBasicSettings,
            subtitle: null,
          ),
          const SizedBox(height: AppSpacing.space3),
          _buildLessonSettings(avail),

          const SizedBox(height: AppSpacing.space8),

          // Section 3: Preview
          _buildSectionHeader(
            romanIndex: 2,
            title: AppStrings.weeklyPreview,
            subtitle: AppStrings.weeklyPreviewSubtitle,
          ),
          const SizedBox(height: AppSpacing.space3),
          _buildWeeklyPreview(avail),

          const SizedBox(height: AppSpacing.space8),

          // Section 4: Special schedules
          _buildSectionHeader(
            romanIndex: 3,
            title: AppStrings.specialSchedules,
            subtitle: AppStrings.specialSchedulesSubtitle,
          ),
          const SizedBox(height: AppSpacing.space3),
          _buildExceptions(avail),

          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  // ─── Section Header ────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    String? helpText,
    int? romanIndex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle + 선택적 로마숫자 (§7.87).
        if (romanIndex != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(romanOf(romanIndex), style: NotebookTypography.roman),
              const SizedBox(width: AppSpacing.space2),
              Text(title, style: NotebookTypography.sectionTitle),
            ],
          )
        else
          Text(title, style: NotebookTypography.sectionTitle),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
        if (helpText != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.ink),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    helpText,
                    style: AppTypography.caption.copyWith(color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Section 1: Weekly Schedule ────────────────────────────

  Widget _buildWeeklySchedule(TeacherAvailability avail) {
    final grouped = <int, List<WeeklySchedule>>{};
    for (final s in avail.weeklySchedules) {
      grouped.putIfAbsent(s.dayOfWeek, () => []);
      grouped[s.dayOfWeek]!.add(s);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return Column(
      children: List.generate(7, (dayIndex) {
        final schedules = grouped[dayIndex] ?? [];
        return _buildDayRow(dayIndex, schedules);
      }),
    );
  }

  Widget _buildDayRow(int dayIndex, List<WeeklySchedule> schedules) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final dayName = days[dayIndex];
    final isWeekend = dayIndex >= 5;
    final hasSchedules = schedules.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                hasSchedules
                    ? AppColors.paperAccentSoft
                    : isWeekend
                    ? AppColors.paperAccentSoft
                    : AppColors.paper,
          ),
          child: Center(
            child: Text(
              dayName,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    hasSchedules
                        ? AppColors.paperAccent
                        : isWeekend
                        ? AppColors.paperAccent
                        : AppColors.inkSecondary,
              ),
            ),
          ),
        ),
        title:
            hasSchedules
                ? Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space1,
                  children: schedules.map((s) => _buildTimeChip(s)).toList(),
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
          onPressed: () => _showScheduleDialog(preselectedDay: dayIndex),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space1,
        ),
      ),
    );
  }

  Widget _buildTimeChip(WeeklySchedule schedule) {
    return GestureDetector(
      onTap: () => _showScheduleDialog(existing: schedule),
      onLongPress: () => _confirmDeleteSchedule(schedule),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color:
              schedule.isActive
                  ? AppColors.paperOk.withValues(alpha: 0.1)
                  : AppColors.inkTertiary.withValues(alpha: 0.1),
          border: Border.all(
            color:
                schedule.isActive
                    ? AppColors.paperOk.withValues(alpha: 0.3)
                    : AppColors.inkTertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '${schedule.startTime} - ${schedule.endTime}',
          style: AppTypography.caption.copyWith(
            color:
                schedule.isActive ? AppColors.paperOk : AppColors.inkTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── Section 2: Lesson Settings ────────────────────────────

  Widget _buildLessonSettings(TeacherAvailability avail) {
    return InkWell(
      onTap: () => _showLessonSettingsDialog(avail),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Column(
          children: [
            _buildSettingRow(
              icon: Icons.timer_outlined,
              label: AppStrings.lessonLengthLabel,
              value: AppStrings.durationMinutesValue(avail.slotDurationMinutes),
              help: AppStrings.lessonLengthHelp,
            ),
            const Divider(height: 24),
            _buildSettingRow(
              icon: Icons.coffee_outlined,
              label: AppStrings.breakTimeLabel,
              value: AppStrings.durationMinutesValue(
                avail.breakTimeBetweenLessons,
              ),
              help: AppStrings.breakTimeHelp,
            ),
            const Divider(height: 24),
            _buildSettingRow(
              icon: Icons.schedule,
              label: AppStrings.startIntervalLabel,
              value: AppStrings.durationMinutesValue(avail.slotStartInterval),
              help: AppStrings.startIntervalHelp(avail.slotStartInterval),
            ),
            const SizedBox(height: AppSpacing.space2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  AppStrings.tapToChange,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.paperAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required String value,
    required String help,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.paperAccent),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.bodyMedium),
              const SizedBox(height: 2),
              Text(
                help,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.paperAccent,
          ),
        ),
      ],
    );
  }

  // ─── Section 3: Weekly Preview ─────────────────────────────

  Widget _buildWeeklyPreview(TeacherAvailability avail) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final grouped = <int, List<WeeklySchedule>>{};
    for (final s in avail.weeklySchedules) {
      grouped.putIfAbsent(s.dayOfWeek, () => []);
      grouped[s.dayOfWeek]!.add(s);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children: [
          // Day headers
          Row(
            children: List.generate(7, (i) {
              final hasSchedule = grouped[i]?.isNotEmpty == true;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    days[i],
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          hasSchedule
                              ? AppColors.paperAccent
                              : AppColors.inkTertiary,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.space1),
          // Time bars
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (dayIndex) {
              final schedules = grouped[dayIndex] ?? [];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child:
                      schedules.isEmpty
                          ? Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.inkTertiary.withValues(
                                alpha: 0.15,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '—',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.inkTertiary,
                                ),
                              ),
                            ),
                          )
                          : Column(
                            children:
                                schedules.map((s) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 2),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.paperAccentSoft,
                                      border: Border.all(
                                        color: AppColors.paperAccent,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          s.startTime,
                                          style: AppTypography.captionXSmall
                                              .copyWith(
                                                color: AppColors.paperAccent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          s.endTime,
                                          style: AppTypography.captionXSmall
                                              .copyWith(
                                                color: AppColors.paperAccent,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Section 4: Exceptions ─────────────────────────────────

  Widget _buildExceptions(TeacherAvailability avail) {
    final upcoming =
        avail.exceptions
            .where((e) => !e.endDate.isBefore(DateTime.now()))
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return Column(
      children: [
        if (upcoming.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space6),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_available,
                  size: 32,
                  color: AppColors.inkTertiary,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  AppStrings.noSpecialSchedules,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          )
        else
          ...upcoming.map((exc) => _buildExceptionTile(exc)),
        const SizedBox(height: AppSpacing.space3),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TimeExceptionScreen(),
                  ),
                ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(AppStrings.manageSpecialSchedules),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: AppColors.paperAccent.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExceptionTile(TimeException exc) {
    final isHoliday = exc.type != ExceptionType.additionalSlot;
    final dateText =
        exc.startDate == exc.endDate
            ? formatDateYMD(exc.startDate)
            : '${formatDateYMD(exc.startDate)} ~ ${formatDateYMD(exc.endDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  isHoliday
                      ? AppColors.paperAccent.withValues(alpha: 0.1)
                      : AppColors.paperOk.withValues(alpha: 0.1),
            ),
            child: Icon(
              isHoliday ? Icons.event_busy : Icons.add_circle_outline,
              size: 18,
              color: isHoliday ? AppColors.paperAccent : AppColors.paperOk,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exc.type.displayName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  dateText +
                      (exc.reason != null && exc.reason!.isNotEmpty
                          ? ' · ${exc.reason}'
                          : ''),
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

  // ─── Dialogs ───────────────────────────────────────────────

  Future<void> _showScheduleDialog({
    int? preselectedDay,
    WeeklySchedule? existing,
  }) async {
    final result = await showModalBottomSheet<WeeklySchedule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ScheduleEditBottomSheet(
            preselectedDay: preselectedDay,
            existingSchedule: existing,
          ),
    );

    if (result != null && mounted) {
      if (existing != null && result.id == existing.id) {
        // Update existing schedule
        await ref
            .read(
              teacherAvailabilityNotifierProvider(widget.teacherId).notifier,
            )
            .updateWeeklySchedule(result);
      } else {
        // Add new schedule
        await ref
            .read(
              teacherAvailabilityNotifierProvider(widget.teacherId).notifier,
            )
            .addWeeklySchedule(result);
      }
    }
  }

  Future<void> _showLessonSettingsDialog(TeacherAvailability avail) async {
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => LessonSettingsBottomSheet(
            currentLessonDuration: avail.slotDurationMinutes,
            currentStartInterval: avail.slotStartInterval,
            currentBreakTime: avail.breakTimeBetweenLessons,
          ),
    );

    if (result != null && mounted) {
      await ref
          .read(teacherAvailabilityNotifierProvider(widget.teacherId).notifier)
          .updateLessonSettings(
            slotDurationMinutes: result['lessonDuration']!,
            slotStartInterval: result['startInterval']!,
            breakTimeBetweenLessons: result['breakTime']!,
          );
    }
  }

  Future<void> _confirmDeleteSchedule(WeeklySchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(AppStrings.deleteScheduleTitle),
            content: Text(
              AppStrings.deleteScheduleConfirm(
                dayName: schedule.dayName,
                startTime: schedule.startTime,
                endTime: schedule.endTime,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(teacherAvailabilityNotifierProvider(widget.teacherId).notifier)
          .removeWeeklySchedule(schedule.id);
    }
  }
}
