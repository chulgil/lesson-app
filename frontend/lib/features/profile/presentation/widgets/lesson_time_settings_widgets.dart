import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../../core/booking/entities/time_slot.dart';

/// Section title widget for lesson time settings
class LessonTimeSettingsSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onAddPressed;
  final String addButtonLabel;

  const LessonTimeSettingsSectionTitle({
    super.key,
    required this.title,
    this.onAddPressed,
    this.addButtonLabel = '추가',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.headingSmall),
        if (onAddPressed != null)
          TextButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add, size: 18),
            label: Text(addButtonLabel),
          ),
      ],
    );
  }
}

/// Duration option item widget
class DurationOptionItem extends StatelessWidget {
  final int duration;
  final bool isDefault;
  final bool isDisabled;
  final bool isCustom;
  final bool isOnlyActive;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<bool> onToggle;

  const DurationOptionItem({
    super.key,
    required this.duration,
    required this.isDefault,
    required this.isDisabled,
    required this.isCustom,
    required this.isOnlyActive,
    this.onTap,
    this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Radio<int>(value: duration, activeColor: AppColors.primary),
      title: Text(
        LessonDurations.format(duration),
        style: AppTypography.bodyLarge.copyWith(
          color:
              isDisabled
                  ? AppColors.textTertiaryLight
                  : AppColors.textPrimaryLight,
          decoration: isDisabled ? TextDecoration.lineThrough : null,
          fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle:
          isCustom
              ? Text(
                '커스텀',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              )
              : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delete button for custom durations
          if (isCustom && onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: AppColors.error.withValues(alpha: 0.7),
                size: 20,
              ),
              onPressed: onDelete,
              tooltip: '삭제',
            ),
          // Active/Disable switch
          Switch(
            value: !isDisabled,
            onChanged: isOnlyActive ? null : (value) => onToggle(value),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
      onTap: isDisabled ? null : onTap,
    );
  }
}

/// Empty state widget for time slots
class TimeSlotsEmptyState extends StatelessWidget {
  const TimeSlotsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.schedule, size: 48, color: AppColors.textTertiaryLight),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '설정된 시간대가 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '시간대를 추가하여 레슨 가능 시간을 설정하세요',
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
}

/// Day section card for time slots
class DaySectionCard extends StatelessWidget {
  final int dayOfWeek;
  final List<TimeSlot> slots;
  final void Function(TimeSlot) onToggleSlot;
  final void Function(TimeSlot) onEditSlot;
  final VoidCallback onAddSlot;

  const DaySectionCard({
    super.key,
    required this.dayOfWeek,
    required this.slots,
    required this.onToggleSlot,
    required this.onEditSlot,
    required this.onAddSlot,
  });

  static const _dayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

  @override
  Widget build(BuildContext context) {
    final dayName = _dayNames[dayOfWeek - 1];
    final hasSlots = slots.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: ExpansionTile(
        leading: Icon(
          hasSlots ? Icons.check_circle : Icons.cancel,
          color: hasSlots ? AppColors.success : AppColors.textTertiaryLight,
        ),
        title: Text(
          dayName,
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          hasSlots ? '${slots.length}개 시간대' : '휴무',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        children: [
          if (hasSlots)
            ...slots.map(
              (slot) => TimeSlotTile(
                slot: slot,
                onToggle: (value) => onToggleSlot(slot),
                onEdit: () => onEditSlot(slot),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Text(
                '등록된 시간대가 없습니다',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: TextButton.icon(
              onPressed: onAddSlot,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('시간대 추가'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Time slot tile widget
class TimeSlotTile extends StatelessWidget {
  final TimeSlot slot;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const TimeSlotTile({
    super.key,
    required this.slot,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.access_time,
        color: slot.isActive ? AppColors.primary : AppColors.textTertiaryLight,
      ),
      title: Text(
        slot.timeRange,
        style: AppTypography.bodyMedium.copyWith(
          color:
              slot.isActive
                  ? AppColors.textPrimaryLight
                  : AppColors.textTertiaryLight,
          decoration: slot.isActive ? null : TextDecoration.lineThrough,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: slot.isActive,
            onChanged: onToggle,
            activeThumbColor: AppColors.primary,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// Time picker button widget
class TimePickerButton extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const TimePickerButton({super.key, required this.time, required this.onTap});

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
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: AppTypography.bodyLarge,
            ),
            const Icon(Icons.access_time, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Dialog for adding/editing time slot
class TimeSlotDialog extends StatefulWidget {
  final int? preselectedDay;
  final TimeSlot? existingSlot;
  final void Function(TimeSlot) onSave;

  const TimeSlotDialog({
    super.key,
    this.preselectedDay,
    this.existingSlot,
    required this.onSave,
  });

  @override
  State<TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<TimeSlotDialog> {
  late int _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  static const _dayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

  @override
  void initState() {
    super.initState();
    if (widget.existingSlot != null) {
      _selectedDay = widget.existingSlot!.dayOfWeek;
      _startTime = widget.existingSlot!.startTime;
      _endTime = widget.existingSlot!.endTime;
    } else {
      _selectedDay = widget.preselectedDay ?? 1;
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 18, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSlot != null;

    return AlertDialog(
      title: Text(isEditing ? '시간대 수정' : '시간대 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day selector
          Text(
            '요일',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          DropdownButtonFormField<int>(
            initialValue: _selectedDay,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
            ),
            items: List.generate(7, (index) {
              final day = index + 1;
              return DropdownMenuItem(
                value: day,
                child: Text(_dayNames[index]),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDay = value);
              }
            },
          ),

          const SizedBox(height: AppSpacing.space4),

          // Time pickers
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '시작 시간',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    TimePickerButton(
                      time: _startTime,
                      onTap: () => _selectTime(isStart: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '종료 시간',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    TimePickerButton(
                      time: _endTime,
                      onTap: () => _selectTime(isStart: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _save, child: const Text('저장')),
      ],
    );
  }

  Future<void> _selectTime({required bool isStart}) async {
    final initialTime = isStart ? _startTime : _endTime;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      setState(() {
        if (isStart) {
          _startTime = selectedTime;
        } else {
          _endTime = selectedTime;
        }
      });
    }
  }

  void _save() {
    // Validate that end time is after start time
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종료 시간은 시작 시간 이후여야 합니다')));
      return;
    }

    final slot = TimeSlot(
      id:
          widget.existingSlot?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      dayOfWeek: _selectedDay,
      startTime: _startTime,
      endTime: _endTime,
      isActive: widget.existingSlot?.isActive ?? true,
    );

    widget.onSave(slot);
    Navigator.pop(context);
  }
}

/// Dialog for picking custom lesson duration with slider
class DurationPickerDialog extends StatefulWidget {
  final void Function(int duration) onSave;
  final List<int> existingDurations;

  const DurationPickerDialog({
    super.key,
    required this.onSave,
    required this.existingDurations,
  });

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late double _sliderValue;
  bool _showDirectInput = false;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sliderValue = 50; // Default 50 minutes
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  int get _currentDuration => _sliderValue.round();

  bool get _isDuplicate => widget.existingDurations.contains(_currentDuration);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('커스텀 레슨 시간 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Duration display
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space6,
              vertical: AppSpacing.space4,
            ),
            decoration: BoxDecoration(
              color:
                  _isDuplicate
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: Column(
              children: [
                Text(
                  LessonDurations.format(_currentDuration),
                  style: AppTypography.headingLarge.copyWith(
                    color: _isDuplicate ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isDuplicate)
                  Text(
                    '이미 존재하는 시간입니다',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Slider
          if (!_showDirectInput) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${LessonDurations.minDuration}분',
                  style: AppTypography.caption,
                ),
                Text(
                  '${LessonDurations.maxDuration ~/ 60}시간',
                  style: AppTypography.caption,
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.1),
                valueIndicatorColor: AppColors.primary,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Slider(
                value: _sliderValue,
                min: LessonDurations.minDuration.toDouble(),
                max: LessonDurations.maxDuration.toDouble(),
                divisions:
                    (LessonDurations.maxDuration -
                        LessonDurations.minDuration) ~/
                    5,
                label: LessonDurations.format(_currentDuration),
                onChanged: (value) {
                  setState(() {
                    // Snap to 5-minute intervals
                    _sliderValue = (value / 5).round() * 5.0;
                  });
                },
              ),
            ),

            const SizedBox(height: AppSpacing.space2),

            // Quick select buttons
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              alignment: WrapAlignment.center,
              children:
                  [35, 50, 75, 100, 150, 180].map((duration) {
                    final isSelected = _currentDuration == duration;
                    final exists = widget.existingDurations.contains(duration);
                    return FilterChip(
                      label: Text(
                        LessonDurations.format(duration),
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              exists
                                  ? AppColors.textTertiaryLight
                                  : isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimaryLight,
                          decoration:
                              exists ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      selected: isSelected && !exists,
                      onSelected:
                          exists
                              ? null
                              : (_) {
                                setState(() {
                                  _sliderValue = duration.toDouble();
                                });
                              },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space1,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
            ),

            const SizedBox(height: AppSpacing.space3),

            // Direct input toggle
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showDirectInput = true;
                  _textController.text = _currentDuration.toString();
                });
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('직접 입력'),
            ),
          ] else ...[
            // Direct input field
            TextField(
              controller: _textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '레슨 시간 (분)',
                hintText: '예: 50',
                helperText:
                    '${LessonDurations.minDuration}~${LessonDurations.maxDuration}분',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                suffixText: '분',
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null &&
                    parsed >= LessonDurations.minDuration &&
                    parsed <= LessonDurations.maxDuration) {
                  setState(() {
                    _sliderValue = parsed.toDouble();
                  });
                }
              },
            ),

            const SizedBox(height: AppSpacing.space3),

            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showDirectInput = false;
                });
              },
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('슬라이더로 선택'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed:
              _isDuplicate
                  ? null
                  : () {
                    Navigator.pop(context);
                    widget.onSave(_currentDuration);
                  },
          child: const Text('추가'),
        ),
      ],
    );
  }
}

/// Show add custom duration dialog
void showAddCustomDurationDialog({
  required BuildContext context,
  required WidgetRef ref,
  required List<int> existingDurations,
  required Future<void> Function(int duration) onSave,
}) {
  showDialog(
    context: context,
    builder:
        (dialogContext) => DurationPickerDialog(
          onSave: (duration) async {
            await onSave(duration);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${LessonDurations.format(duration)} 추가됨'),
                ),
              );
            }
          },
          existingDurations: existingDurations,
        ),
  );
}

/// Show delete duration confirmation dialog
void showDeleteDurationDialog({
  required BuildContext context,
  required int duration,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('레슨 시간 삭제'),
          content: Text('${LessonDurations.format(duration)}을(를) 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(AppStrings.delete),
            ),
          ],
        ),
  );
}

/// Show add time slot dialog
void showAddTimeSlotDialog({
  required BuildContext context,
  required void Function(TimeSlot) onSave,
  int? preselectedDay,
}) {
  showDialog(
    context: context,
    builder:
        (context) =>
            TimeSlotDialog(preselectedDay: preselectedDay, onSave: onSave),
  );
}

/// Show edit time slot dialog
void showEditTimeSlotDialog({
  required BuildContext context,
  required TimeSlot slot,
  required void Function(TimeSlot) onSave,
}) {
  showDialog(
    context: context,
    builder: (context) => TimeSlotDialog(existingSlot: slot, onSave: onSave),
  );
}
