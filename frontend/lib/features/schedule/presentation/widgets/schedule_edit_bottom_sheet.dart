import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/value_objects/clock_time.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
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
    final clock = ClockTime.parse(time); // total — never throws (#64)
    return TimeOfDay(hour: clock.hour, minute: clock.minute);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final isEditing = widget.existingSchedule != null;

    return Container(
      decoration: BoxDecoration(color: AppColors.paper),
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
                const Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),

                const SizedBox(height: AppSpacing.space5),

                // Notebook × Score: 바텀시트 헤더 (§7.27) — Playfair sectionTitle.
                Text(
                  isEditing ? '스케줄 수정' : '스케줄 추가',
                  style: NotebookTypography.sectionTitle,
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
                      selectedColor: AppColors.paperAccentSoft,
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? AppColors.paperAccent
                            : isWeekend
                            ? AppColors.paperAccent
                            : AppColors.inkSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
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
                  title: Text(
                    AppStrings.scheduleActivate,
                    style: AppTypography.bodyMedium,
                  ),
                  subtitle: Text(
                    _isActive ? '학생들이 이 시간에 예약할 수 있습니다' : '이 스케줄은 비활성화 상태입니다',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  activeThumbColor: AppColors.paperAccent,
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
                        child: const Text(AppStrings.cancel),
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
                        child: Text(
                          isEditing ? AppStrings.edit : AppStrings.add,
                        ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 18, color: AppColors.inkSecondary),
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
          content: Text(AppStrings.scheduleEndTimeError),
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
