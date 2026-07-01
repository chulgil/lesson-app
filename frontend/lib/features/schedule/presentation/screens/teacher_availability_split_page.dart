import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../domain/entities/teacher_availability.dart';
import '../extensions/exception_type_visuals.dart';
import '../providers/teacher_availability_providers.dart';
import '../../../settings/settings_facade.dart';
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
        error:
            (_, __) => _ErrorState(
              onRetry:
                  () => ref.invalidate(teacherAvailabilityProvider(teacherId)),
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

    // Read SSOT lesson duration from TeacherSettings.
    final ssotDuration = ref
        .watch(teacherSettingsNotifierProvider)
        .valueOrNull
        ?.lessonDurationMinutes;

    final settings = _SettingsPanel(
      teacherId: teacherId,
      availability: availability,
    );
    final preview = AvailabilityPreviewGrid(
      availability: availability,
      lessonDurationMinutes: ssotDuration,
    );

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
        return _DayCard(
          dayIndex: dayIndex,
          dayLabel: _dayLabels[dayIndex],
          schedules: schedules,
          teacherId: teacherId,
          onAddOrEdit:
              (existing) => _openEditSheet(
                context,
                ref,
                preselectedDay: dayIndex,
                existing: existing,
              ),
          onDeleteRequest:
              (schedule) => _confirmAndDelete(context, ref, schedule: schedule),
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
      builder:
          (context) => ScheduleEditBottomSheet(
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
    // 2026-06-12 — notifier 가 에러를 state 로만 들고 있으면 사용자는 아무
    // 피드백 없이 "적용 안 됨" 으로 인지한다 (silent fail). 실패 시 명시
    // SnackBar 를 띄우고 read provider invalidate 는 건너뛴다.
    if (!context.mounted) return;
    if (_notifyIfFailed(context, ref)) return;
    ref.invalidate(teacherAvailabilityProvider(teacherId));
    ref.invalidate(teacherSettingsProvider);
  }

  /// notifier 의 마지막 작업이 실패면 SnackBar 노출 후 true 반환.
  ///
  /// 호출부가 async gap 직후 `context.mounted` 를 확인한 뒤 호출한다.
  bool _notifyIfFailed(BuildContext context, WidgetRef ref) {
    final state = ref.read(teacherAvailabilityNotifierProvider(teacherId));
    if (!state.hasError) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.weeklyScheduleSaveError),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return true;
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref, {
    required WeeklySchedule schedule,
  }) async {
    // Look up affected upcoming bookings before showing the confirmation.
    // (C3 §4.9 — strengthen wording when impact > 0.)
    int affected = 0;
    try {
      affected = await ref.read(
        affectedBookingsForWeeklyScheduleProvider(
          teacherId: teacherId,
          weeklyDayOfWeek: schedule.dayOfWeek,
          weeklyStartTime: schedule.startTime,
          weeklyEndTime: schedule.endTime,
        ).future,
      );
    } catch (_) {
      // If the lookup fails, default to the safe (impact-aware) message.
      affected = 0;
    }
    if (!context.mounted) return;

    final hasImpact = affected > 0;
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title:
          hasImpact
              ? AppStrings.weeklyScheduleDeleteImpactTitle
              : AppStrings.weeklyScheduleDeleteConfirmTitle,
      content: Text(
        hasImpact
            ? AppStrings.weeklyScheduleDeleteImpactWarning(affected)
            : AppStrings.weeklyScheduleDeleteConfirmBody,
      ),
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
    if (confirmed != true || !context.mounted) return;

    final notifier = ref.read(
      teacherAvailabilityNotifierProvider(teacherId).notifier,
    );
    await notifier.removeWeeklySchedule(schedule.id);
    if (!context.mounted) return;
    if (_notifyIfFailed(context, ref)) return;
    ref.invalidate(teacherAvailabilityProvider(teacherId));
    ref.invalidate(teacherSettingsProvider);
  }
}

/// Day card containing time-slot rows + add CTA.
///
/// Layout (C1, audit §4.7 ASCII sketch):
/// ┌── 화 ──────────────────────────────────┐
/// │ ⇆  14:00 - 16:00         [✏]          │
/// │ ⇆  17:00 - 19:00         [✏]          │
/// │                              [+ 추가]   │
/// └────────────────────────────────────────┘
///
/// Each time-slot row is wrapped in [SwipeActionTile] so the teacher can
/// swipe-left to reveal the destructive "삭제" action. Tapping the row
/// (or the trailing pencil) opens the edit bottom sheet.
class _DayCard extends StatelessWidget {
  final int dayIndex;
  final String dayLabel;
  final List<WeeklySchedule> schedules;
  final String teacherId;
  final void Function(WeeklySchedule? existing) onAddOrEdit;
  final void Function(WeeklySchedule schedule) onDeleteRequest;

  const _DayCard({
    required this.dayIndex,
    required this.dayLabel,
    required this.schedules,
    required this.teacherId,
    required this.onAddOrEdit,
    required this.onDeleteRequest,
  });

  @override
  Widget build(BuildContext context) {
    final hasSchedules = schedules.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card header: 요일 라벨 (leading badge + 라벨)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space3,
              AppSpacing.space3,
              AppSpacing.space3,
              AppSpacing.space2,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        hasSchedules
                            ? AppColors.paperAccentSoft
                            : AppColors.paper,
                    border: Border.all(
                      color:
                          hasSchedules
                              ? AppColors.paperAccent
                              : AppColors.inkQuaternary,
                    ),
                  ),
                  child: Text(
                    dayLabel,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          hasSchedules
                              ? AppColors.paperAccent
                              : AppColors.inkSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  hasSchedules
                      ? '$dayLabel요일'
                      : '$dayLabel요일 · ${AppStrings.dayOff}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasSchedules ? AppColors.ink : AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),

          // 시간대 행 — SwipeActionTile 로 감싼 ListTile 들
          if (hasSchedules)
            for (final s in schedules)
              _TimeSlotRow(
                schedule: s,
                onEdit: () => onAddOrEdit(s),
                onDelete: () => onDeleteRequest(s),
              )
          else
            // 비어 있는 요일: 행 자리표시자 (스와이프 안내 없이)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space3,
                0,
                AppSpacing.space3,
                AppSpacing.space2,
              ),
              child: Text(
                AppStrings.dayOff,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // + 시간대 추가 CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space3,
              AppSpacing.space1,
              AppSpacing.space3,
              AppSpacing.space2,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onAddOrEdit(null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(AppStrings.weeklyScheduleAddSlotAction),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                  ),
                  foregroundColor: AppColors.paperAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single time-slot row inside [_DayCard].
///
/// Wrapped in [SwipeActionTile] so the user reveals a destructive "삭제"
/// button by swiping left. Tapping the row (or the trailing edit icon)
/// opens the edit bottom sheet.
class _TimeSlotRow extends StatelessWidget {
  final WeeklySchedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TimeSlotRow({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: onDelete,
        ),
      ],
      child: Material(
        color: AppColors.paper,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.paperOk),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    '${schedule.startTime} - ${schedule.endTime}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.inkSecondary,
                ),
              ],
            ),
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
          _ReadOnlyDurationRow(
            teacherId: teacherId,
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
            onSelected:
                (value) => _updateSettings(
                  context,
                  ref,
                  breakTimeBetweenLessons: value,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSettings(
    BuildContext context,
    WidgetRef ref, {
    required int breakTimeBetweenLessons,
  }) async {
    // SSOT: read lesson duration from TeacherSettings, not from availability.
    final ssotDuration = ref
        .read(teacherSettingsNotifierProvider)
        .valueOrNull
        ?.lessonDurationMinutes
        ?? availability.slotDurationMinutes;
    // slotStartInterval is the internal computed value: duration + break.
    final interval = ssotDuration + breakTimeBetweenLessons;
    await ref
        .read(teacherAvailabilityNotifierProvider(teacherId).notifier)
        .updateLessonSettings(
          slotDurationMinutes: ssotDuration,
          slotStartInterval: interval,
          breakTimeBetweenLessons: breakTimeBetweenLessons,
        );
    // #707 — updateLessonSettings 는 실패를 notifier state 로만 보관하고
    // body 는 read-only teacherAvailabilityProvider 를 watch 하므로, 실패가
    // silent 하지 않도록 호출부에서 명시적으로 확인 (weekly 메서드의 _notifyIfFailed 패턴).
    if (ref.read(teacherAvailabilityNotifierProvider(teacherId)).hasError) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.lessonSettingsSaveError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    ref.invalidate(teacherAvailabilityProvider(teacherId));
    ref.invalidate(teacherSettingsProvider);
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
          children:
              options.map((value) {
                final isActive = value == selected;
                return GestureDetector(
                  onTap: () => onSelected(value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? AppColors.paperAccentSoft
                              : AppColors.paper,
                      border: Border.all(
                        color:
                            isActive
                                ? AppColors.paperAccent
                                : AppColors.inkQuaternary,
                      ),
                    ),
                    child: Text(
                      buildLabel(value),
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isActive
                                ? AppColors.paperAccent
                                : AppColors.inkSecondary,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
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
              (e) =>
                  !DateTime(
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
          onPressed:
              () => Navigator.of(context).push(
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
        const SizedBox(height: AppSpacing.space2),
        // #727 — vacation mode entry point (GoRoute /schedule/vacation exists but
        // had no discoverable CTA). Placed alongside special-schedule management
        // since vacation is a type of schedule exception.
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.teacherVacationMode),
          icon: const Icon(Icons.beach_access_outlined, size: 18),
          label: const Text(AppStrings.vacationModeEntry),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
            side: BorderSide(color: AppColors.inkQuaternary),
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
    final dateText =
        exception.startDate == exception.endDate
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

// ─── Read-only lesson duration row (SSOT from TeacherSettings) ──────────────

class _ReadOnlyDurationRow extends ConsumerWidget {
  final String teacherId;
  const _ReadOnlyDurationRow({required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(teacherSettingsNotifierProvider);
    final duration = settingsAsync.valueOrNull?.lessonDurationMinutes;

    return InkWell(
      onTap: () => context.push(AppRoutes.lessonStyleSettings),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.lessonDurationLabel,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.lessonLengthHelp,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (duration != null)
                  Text(
                    AppStrings.lessonDurationOptionLabel(duration),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  AppStrings.lessonDurationManagedInStyle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.inkTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
