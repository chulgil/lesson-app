import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../domain/entities/teacher_availability.dart';
import '../providers/teacher_availability_providers.dart';

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
          // Info card
          _buildInfoCard(availability.slotDurationMinutes),

          const SizedBox(height: AppSpacing.space6),

          // Weekly overview
          Text(
            '주간 스케줄',
            style: AppTypography.headingSmall,
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

  Widget _buildInfoCard(int slotDuration) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 24,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '레슨 단위: $slotDuration분',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '설정한 시간대에 학생들이 예약할 수 있습니다.',
                  style: AppTypography.bodySmall.copyWith(
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
            color: hasSchedules
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
                color: hasSchedules
                    ? AppColors.primary
                    : isWeekend
                        ? AppColors.secondary
                        : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
        title: hasSchedules
            ? Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children: schedules.map((s) => _buildTimeChip(s)).toList(),
              )
            : Text(
                '휴무',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiaryLight,
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
          color: schedule.isActive
              ? AppColors.practiceGood.withValues(alpha: 0.1)
              : AppColors.textTertiaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(
            color: schedule.isActive
                ? AppColors.practiceGood.withValues(alpha: 0.3)
                : AppColors.textTertiaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '${schedule.startTime} - ${schedule.endTime}',
          style: AppTypography.caption.copyWith(
            color: schedule.isActive
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
        ],
      ),
    );
  }

  Future<void> _showAddScheduleDialog({int? preselectedDay}) async {
    final result = await showModalBottomSheet<WeeklySchedule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScheduleEditBottomSheet(
        preselectedDay: preselectedDay,
      ),
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
      builder: (context) => _ScheduleEditBottomSheet(
        existingSchedule: schedule,
      ),
    );

    if (result != null && mounted) {
      final teacherId = ref.read(currentUserIdProvider);
      if (result.id == schedule.id) {
        // Update existing
        await ref
            .read(teacherAvailabilityNotifierProvider(teacherId).notifier)
            .addWeeklySchedule(result);
      }
    }
  }

  Future<void> _confirmDelete(WeeklySchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
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

/// Bottom sheet for adding/editing a weekly schedule
class _ScheduleEditBottomSheet extends StatefulWidget {
  final int? preselectedDay;
  final WeeklySchedule? existingSchedule;

  const _ScheduleEditBottomSheet({
    this.preselectedDay,
    this.existingSchedule,
  });

  @override
  State<_ScheduleEditBottomSheet> createState() =>
      _ScheduleEditBottomSheetState();
}

class _ScheduleEditBottomSheetState extends State<_ScheduleEditBottomSheet> {
  late int _selectedDay;
  TimeOfDay _startTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedule != null) {
      final schedule = widget.existingSchedule!;
      _selectedDay = schedule.dayOfWeek;
      _startTime = _parseTime(schedule.startTime);
      _endTime = _parseTime(schedule.endTime);
      _isActive = schedule.isActive;
    } else {
      _selectedDay = widget.preselectedDay ?? 0;
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final isEditing = widget.existingSchedule != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space5),

                // Title
                Text(
                  isEditing ? '스케줄 수정' : '스케줄 추가',
                  style: AppTypography.headingMedium,
                ),

                const SizedBox(height: AppSpacing.space6),

                // Day selection
                Text(
                  '요일',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Wrap(
                  spacing: AppSpacing.space2,
                  children: List.generate(7, (index) {
                    final isSelected = _selectedDay == index;
                    final isWeekend = index >= 5;
                    return ChoiceChip(
                      label: Text(days[index]),
                      selected: isSelected,
                      onSelected: isEditing
                          ? null
                          : (selected) {
                              if (selected) {
                                setState(() => _selectedDay = index);
                              }
                            },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : isWeekend
                                ? AppColors.secondary
                                : AppColors.textSecondaryLight,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: AppSpacing.space5),

                // Time selection
                Text(
                  '시간',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    Expanded(child: _buildTimePicker('시작', _startTime, true)),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: AppSpacing.space2),
                      child: Text('~'),
                    ),
                    Expanded(child: _buildTimePicker('종료', _endTime, false)),
                  ],
                ),

                const SizedBox(height: AppSpacing.space5),

                // Active toggle
                SwitchListTile(
                  title: Text(
                    '활성화',
                    style: AppTypography.bodyMedium,
                  ),
                  subtitle: Text(
                    _isActive ? '학생들이 이 시간에 예약할 수 있습니다' : '이 스케줄은 비활성화 상태입니다',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: AppSpacing.space6),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.space3,
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.space3,
                          ),
                        ),
                        child: Text(isEditing ? '수정' : '추가'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, bool isStart) {
    return InkWell(
      onTap: () => _selectTime(isStart),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 18,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              _formatTime(time),
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          // Auto-adjust end time if it's before start time
          final startMinutes = _startTime.hour * 60 + _startTime.minute;
          final endMinutes = _endTime.hour * 60 + _endTime.minute;
          if (endMinutes <= startMinutes) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 4) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    // Validate time range
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('종료 시간은 시작 시간보다 늦어야 합니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final schedule = WeeklySchedule(
      id: widget.existingSchedule?.id ?? const Uuid().v4(),
      dayOfWeek: _selectedDay,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      isActive: _isActive,
      createdAt: widget.existingSchedule?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(schedule);
  }
}
