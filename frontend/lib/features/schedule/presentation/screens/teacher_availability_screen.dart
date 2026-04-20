import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
      appBar: AppBar(
        title: const Text('레슨 운영 시간 설정'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundLight,
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
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    '데이터를 불러올 수 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  TextButton(
                    onPressed:
                        () => ref.invalidate(
                          teacherAvailabilityProvider(widget.teacherId),
                        ),
                    child: const Text('다시 시도'),
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
            title: '주간 레슨 시간',
            subtitle: '레슨하는 요일과 시간을 설정하세요',
            helpText: '설정한 시간이 스케줄과 학생 예약 화면에 반영됩니다',
          ),
          const SizedBox(height: AppSpacing.space3),
          _buildWeeklySchedule(avail),

          const SizedBox(height: AppSpacing.space8),

          // Section 2: Lesson settings
          _buildSectionHeader(title: '레슨 기본 설정', subtitle: null),
          const SizedBox(height: AppSpacing.space3),
          _buildLessonSettings(avail),

          const SizedBox(height: AppSpacing.space8),

          // Section 3: Preview
          _buildSectionHeader(title: '이번 주 예상 스케줄', subtitle: '설정한 시간 기반 미리보기'),
          const SizedBox(height: AppSpacing.space3),
          _buildWeeklyPreview(avail),

          const SizedBox(height: AppSpacing.space8),

          // Section 4: Special schedules
          _buildSectionHeader(
            title: '특별 일정',
            subtitle: '휴가, 공휴일, 추가 오픈 등을 관리합니다',
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.headingSmall),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
        if (helpText != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    helpText,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.info,
                    ),
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                hasSchedules
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : isWeekend
                    ? AppColors.secondary.withValues(alpha: 0.1)
                    : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Center(
            child: Text(
              dayName,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    hasSchedules
                        ? AppColors.primary
                        : isWeekend
                        ? AppColors.secondary
                        : AppColors.textSecondaryLight,
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
                  '쉬는날',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        trailing: IconButton(
          icon: Icon(
            hasSchedules ? Icons.edit_outlined : Icons.add,
            size: 20,
            color: AppColors.primary,
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
                  ? AppColors.practiceGood.withValues(alpha: 0.1)
                  : AppColors.textTertiaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(
            color:
                schedule.isActive
                    ? AppColors.practiceGood.withValues(alpha: 0.3)
                    : AppColors.textTertiaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '${schedule.startTime} - ${schedule.endTime}',
          style: AppTypography.caption.copyWith(
            color:
                schedule.isActive
                    ? AppColors.practiceGood
                    : AppColors.textTertiaryLight,
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            _buildSettingRow(
              icon: Icons.timer_outlined,
              label: '레슨 길이',
              value: '${avail.slotDurationMinutes}분',
              help: '학생이 예약 시 이 길이로 예약됩니다',
            ),
            const Divider(height: 24),
            _buildSettingRow(
              icon: Icons.coffee_outlined,
              label: '쉬는 시간',
              value: '${avail.breakTimeBetweenLessons}분',
              help: '연속 레슨 사이에 자동으로 쉬는 시간이 추가됩니다',
            ),
            const Divider(height: 24),
            _buildSettingRow(
              icon: Icons.schedule,
              label: '시작 간격',
              value: '${avail.slotStartInterval}분',
              help:
                  '${avail.slotStartInterval}분이면 10:00, 10:${avail.slotStartInterval == 30 ? '30, 11:00' : '00 → 11:00'} 시작 가능',
            ),
            const SizedBox(height: AppSpacing.space2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '탭하여 변경',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
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
        Icon(icon, size: 20, color: AppColors.primary),
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
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
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
                              ? AppColors.primary
                              : AppColors.textTertiaryLight,
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
                              color: AppColors.textTertiaryLight.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSmall,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '—',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiaryLight,
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
                                      color: AppColors.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSmall,
                                      ),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          s.startTime,
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 9,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          s.endTime,
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 9,
                                            color: AppColors.primary,
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
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_available,
                  size: 32,
                  color: AppColors.textTertiaryLight,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '설정된 특별 일정이 없습니다',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
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
            label: const Text('특별 일정 관리'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  isHoliday
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.practiceGood.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(
              isHoliday ? Icons.event_busy : Icons.add_circle_outline,
              size: 18,
              color: isHoliday ? AppColors.error : AppColors.practiceGood,
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
                    color: AppColors.textSecondaryLight,
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
            title: const Text('스케줄 삭제'),
            content: Text(
              '${schedule.dayName}요일 ${schedule.startTime} - ${schedule.endTime} 스케줄을 삭제하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('삭제'),
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
