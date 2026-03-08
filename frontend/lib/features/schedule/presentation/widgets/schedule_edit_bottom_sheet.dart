import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/teacher_availability.dart';

/// Bottom sheet for adding/editing a weekly schedule
class ScheduleEditBottomSheet extends StatefulWidget {
  final int? preselectedDay;
  final WeeklySchedule? existingSchedule;

  const ScheduleEditBottomSheet({
    super.key,
    this.preselectedDay,
    this.existingSchedule,
  });

  @override
  State<ScheduleEditBottomSheet> createState() =>
      _ScheduleEditBottomSheetState();
}

class _ScheduleEditBottomSheetState extends State<ScheduleEditBottomSheet> {
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
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
                      onSelected:
                          isEditing
                              ? null
                              : (selected) {
                                if (selected) {
                                  setState(() => _selectedDay = index);
                                }
                              },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color:
                            isSelected
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
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                      ),
                      child: Text('~'),
                    ),
                    Expanded(child: _buildTimePicker('종료', _endTime, false)),
                  ],
                ),

                const SizedBox(height: AppSpacing.space5),

                // Active toggle
                SwitchListTile(
                  title: Text('활성화', style: AppTypography.bodyMedium),
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
