import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../domain/entities/teacher_availability.dart';
import '../providers/teacher_availability_providers.dart';
import '../widgets/lesson_settings_bottom_sheet.dart';
import '../widgets/schedule_edit_bottom_sheet.dart';

/// Screen for managing weekly recurring schedules
class WeeklyScheduleScreen extends ConsumerStatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  ConsumerState<WeeklyScheduleScreen> createState() =>
      _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends ConsumerState<WeeklyScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    final teacherId = ref.watch(currentUserIdProvider);
    final availabilityAsync = ref.watch(teacherAvailabilityProvider(teacherId));

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text(AppStrings.weeklyScheduleSetting)),
      body: availabilityAsync.when(
        data: (availability) => _buildContent(availability),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleDialog(),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addSchedule),
      ),
    );
  }

  Widget _buildContent(TeacherAvailability? availability) {
    if (availability == null) {
      return _buildEmptyState();
    }

    final schedules = availability.weeklySchedules;
    if (schedules.isEmpty) {
      return _buildEmptyState();
    }

    // Group by day of week
    final groupedSchedules = <int, List<WeeklySchedule>>{};
    for (final schedule in schedules) {
      groupedSchedules.putIfAbsent(schedule.dayOfWeek, () => []);
      groupedSchedules[schedule.dayOfWeek]!.add(schedule);
    }

    // Sort time ranges within each day
    for (final list in groupedSchedules.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card with lesson settings
          _buildInfoCard(availability),

          const SizedBox(height: AppSpacing.space6),

          // Weekly overview
          // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
          Text(
            AppStrings.weeklyScheduleSection,
            style: NotebookTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space3),

          // Days grid
          ...List.generate(7, (dayIndex) {
            final daySchedules = groupedSchedules[dayIndex] ?? [];
            return _buildDayRow(dayIndex, daySchedules);
          }),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildInfoCard(TeacherAvailability availability) {
    final lessonDuration = availability.slotDurationMinutes;
    final startInterval = availability.slotStartInterval;
    final breakTime = availability.breakTimeBetweenLessons;

    return InkWell(
      onTap: () => _showLessonSettingsDialog(availability),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paperAccent.withValues(alpha: 0.08),
          border: Border.all(
            color: AppColors.paperAccent.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.settings, size: 20, color: AppColors.paperAccent),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  AppStrings.lessonTimeSettings,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.paperAccent,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.paperAccent,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            // Settings summary
            Row(
              children: [
                Expanded(
                  child: _buildSettingItem(
                    icon: Icons.timer_outlined,
                    label: AppStrings.lessonDurationLabel,
                    value: AppStrings.durationMinutesValue(lessonDuration),
                  ),
                ),
                Expanded(
                  child: _buildSettingItem(
                    icon: Icons.schedule,
                    label: AppStrings.startIntervalLabel,
                    value: AppStrings.durationMinutesValue(startInterval),
                  ),
                ),
                Expanded(
                  child: _buildSettingItem(
                    icon: Icons.coffee_outlined,
                    label: AppStrings.breakTimeLabel,
                    value: AppStrings.durationMinutesValue(breakTime),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space3),

            // Example slots
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(color: AppColors.paper),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.inkSecondary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      AppStrings.availableSlotsExample(startInterval),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.paperAccent.withValues(alpha: 0.7),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
        ),
      ],
    );
  }

  Future<void> _showLessonSettingsDialog(
    TeacherAvailability availability,
  ) async {
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => LessonSettingsBottomSheet(
            currentLessonDuration: availability.slotDurationMinutes,
            currentStartInterval: availability.slotStartInterval,
            currentBreakTime: availability.breakTimeBetweenLessons,
          ),
    );

    if (result != null && mounted) {
      final teacherId = ref.read(currentUserIdProvider);
      await ref
          .read(teacherAvailabilityNotifierProvider(teacherId).notifier)
          .updateLessonSettings(
            slotDurationMinutes: result['lessonDuration']!,
            slotStartInterval: result['startInterval']!,
            breakTimeBetweenLessons: result['breakTime']!,
          );
    }
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
                    ? AppColors.paperAccent.withValues(alpha: 0.1)
                    : isWeekend
                    ? AppColors.paperAccent.withValues(alpha: 0.1)
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
                  AppStrings.tapToAddTime,
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
          onPressed: () => _showAddScheduleDialog(preselectedDay: dayIndex),
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
      onTap: () => _showEditScheduleDialog(schedule),
      onLongPress: () => _confirmDelete(schedule),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            // Notebook × Score: 빈 상태 타이틀은 Playfair sectionTitle (§7.87).
            Text(
              AppStrings.noScheduleSet,
              style: NotebookTypography.sectionTitle.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            // 빈 상태 부연 = 시스템 일반 안내 → Tier 3 Pretendard bodyMedium
            // (README §1.1.1 결정 가이드, §7.128 자필 회피).
            Text(
              AppStrings.addScheduleHint,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final teacherId = ref.read(currentUserIdProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            onPressed: () {
              ref.invalidate(teacherAvailabilityProvider(teacherId));
            },
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddScheduleDialog({int? preselectedDay}) async {
    final result = await showModalBottomSheet<WeeklySchedule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ScheduleEditBottomSheet(preselectedDay: preselectedDay),
    );

    if (result != null && mounted) {
      final teacherId = ref.read(currentUserIdProvider);
      await ref
          .read(teacherAvailabilityNotifierProvider(teacherId).notifier)
          .addWeeklySchedule(result);
    }
  }

  Future<void> _showEditScheduleDialog(WeeklySchedule schedule) async {
    final result = await showModalBottomSheet<WeeklySchedule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleEditBottomSheet(existingSchedule: schedule),
    );

    if (result != null && mounted) {
      final teacherId = ref.read(currentUserIdProvider);
      if (result.id == schedule.id) {
        // Update existing schedule
        await ref
            .read(teacherAvailabilityNotifierProvider(teacherId).notifier)
            .updateWeeklySchedule(result);
      } else {
        // New schedule
        await ref
            .read(teacherAvailabilityNotifierProvider(teacherId).notifier)
            .addWeeklySchedule(result);
      }
    }
  }

  Future<void> _confirmDelete(WeeklySchedule schedule) async {
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
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                ),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final teacherId = ref.read(currentUserIdProvider);
      await ref
          .read(teacherAvailabilityNotifierProvider(teacherId).notifier)
          .removeWeeklySchedule(schedule.id);
    }
  }
}
