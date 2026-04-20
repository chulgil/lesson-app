import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
      appBar: AppBar(
        title: const Text('주간 스케줄 설정'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: availabilityAsync.when(
        data: (availability) => _buildContent(availability),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          '스케줄 추가',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
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
          Text('주간 스케줄', style: AppTypography.headingSmall),
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.settings, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '레슨 시간 설정',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            // Settings summary
            Row(
              children: [
                Expanded(
                  child: _buildSettingItem(
                    icon: Icons.timer_outlined,
                    label: '레슨 시간',
                    value: '$lessonDuration분',
                  ),
                ),
                Expanded(
                  child: _buildSettingItem(
                    icon: Icons.schedule,
                    label: '시작 간격',
                    value: '$startInterval분',
                  ),
                ),
                Expanded(
                  child: _buildSettingItem(
                    icon: Icons.coffee_outlined,
                    label: '쉬는 시간',
                    value: '$breakTime분',
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '예약 가능 시간: 10:00, ${startInterval == 30 ? '10:30, ' : ''}11:00${startInterval == 30 ? ', 11:30' : ''}...',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
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
        Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
        const SizedBox(height: AppSpacing.space1),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
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
        color: Colors.white,
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
                  '탭하여 시간 추가',
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
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '설정된 스케줄이 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '아래 버튼을 눌러 레슨 가능 시간을 추가하세요',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
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
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '데이터를 불러올 수 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          TextButton(
            onPressed: () {
              ref.invalidate(teacherAvailabilityProvider(teacherId));
            },
            child: const Text('다시 시도'),
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
            title: const Text('스케줄 삭제'),
            content: Text(
              '${schedule.dayName}요일 ${schedule.startTime} - ${schedule.endTime} 스케줄을 삭제하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancel),
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
      final teacherId = ref.read(currentUserIdProvider);
      await ref
          .read(teacherAvailabilityNotifierProvider(teacherId).notifier)
          .removeWeeklySchedule(schedule.id);
    }
  }
}
