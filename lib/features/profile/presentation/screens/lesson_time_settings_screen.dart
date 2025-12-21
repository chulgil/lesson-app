import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/teacher_settings.dart';
import '../../../../models/time_slot.dart';
import '../../../../providers/providers.dart';

/// Screen for configuring lesson time settings
class LessonTimeSettingsScreen extends ConsumerWidget {
  const LessonTimeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(teacherSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('레슨 시간 설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) => _LessonTimeSettingsContent(settings: settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('오류가 발생했습니다: $error'),
              const SizedBox(height: AppSpacing.space4),
              FilledButton(
                onPressed: () =>
                    ref.read(teacherSettingsNotifierProvider.notifier).refresh(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonTimeSettingsContent extends ConsumerWidget {
  final TeacherSettings settings;

  const _LessonTimeSettingsContent({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Default lesson duration section
          _buildDefaultDurationSection(context, ref),

          const SizedBox(height: AppSpacing.space6),

          // Available time slots section
          _buildTimeSlotsSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildDefaultDurationSection(BuildContext context, WidgetRef ref) {
    final allDurations = settings.allConfiguredDurations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '레슨 시간 옵션',
              style: AppTypography.headingSmall,
            ),
            TextButton.icon(
              onPressed: () => _showAddCustomDurationDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('추가'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          '사용할 레슨 시간을 선택하세요. 체크된 시간이 기본값입니다.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Duration list with switches
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Column(
            children: allDurations.map((duration) {
              final isDefault = settings.defaultLessonDuration == duration;
              final isDisabled = settings.isDurationDisabled(duration);
              final isCustom = settings.customLessonDurations.contains(duration);
              final isOnlyActive = settings.allLessonDurations.length == 1 &&
                  !isDisabled;

              return Column(
                children: [
                  ListTile(
                    leading: Radio<int>(
                      value: duration,
                      groupValue: settings.defaultLessonDuration,
                      onChanged: isDisabled
                          ? null
                          : (value) {
                              if (value != null) {
                                _updateDefaultDuration(ref, value);
                              }
                            },
                      activeColor: AppColors.primary,
                    ),
                    title: Text(
                      LessonDurations.format(duration),
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDisabled
                            ? AppColors.textTertiaryLight
                            : AppColors.textPrimaryLight,
                        decoration:
                            isDisabled ? TextDecoration.lineThrough : null,
                        fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: isCustom
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
                        if (isCustom)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: AppColors.error.withValues(alpha: 0.7),
                              size: 20,
                            ),
                            onPressed: () =>
                                _showDeleteDurationDialog(context, ref, duration),
                            tooltip: '삭제',
                          ),
                        // Active/Disable switch
                        Switch(
                          value: !isDisabled,
                          onChanged: isOnlyActive
                              ? null
                              : (value) => _toggleDuration(ref, duration, value),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    onTap: isDisabled
                        ? null
                        : () => _updateDefaultDuration(ref, duration),
                  ),
                  if (duration != allDurations.last)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: AppSpacing.space2),
        Text(
          '최소 1개의 시간은 활성화 상태여야 합니다',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }

  void _toggleDuration(WidgetRef ref, int duration, bool isActive) {
    ref
        .read(teacherSettingsNotifierProvider.notifier)
        .toggleDuration(duration, isActive);
  }

  void _showAddCustomDurationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => _DurationPickerDialog(
        onSave: (duration) {
          ref
              .read(teacherSettingsNotifierProvider.notifier)
              .addCustomDuration(duration);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${LessonDurations.format(duration)} 추가됨'),
            ),
          );
        },
        existingDurations: settings.allLessonDurations,
      ),
    );
  }

  void _showDeleteDurationDialog(
    BuildContext context,
    WidgetRef ref,
    int duration,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('레슨 시간 삭제'),
        content: Text('${LessonDurations.format(duration)}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref
                  .read(teacherSettingsNotifierProvider.notifier)
                  .removeCustomDuration(duration);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${LessonDurations.format(duration)} 삭제됨'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsSection(BuildContext context, WidgetRef ref) {
    final slotsByDay = <int, List<TimeSlot>>{};
    for (final slot in settings.availableSlots) {
      slotsByDay.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
    }

    // Sort slots within each day
    for (final slots in slotsByDay.values) {
      slots.sort((a, b) => a.startTime.hour * 60 +
          a.startTime.minute -
          (b.startTime.hour * 60 + b.startTime.minute));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '운영 시간대',
              style: AppTypography.headingSmall,
            ),
            TextButton.icon(
              onPressed: () => _showAddTimeSlotDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('추가'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          '레슨 가능한 요일과 시간대를 설정하세요',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Time slots by day
        if (settings.availableSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.space6),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 48,
                    color: AppColors.textTertiaryLight,
                  ),
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
          )
        else
          ...List.generate(7, (index) {
            final dayOfWeek = index + 1;
            final slots = slotsByDay[dayOfWeek] ?? [];
            return _buildDaySection(context, ref, dayOfWeek, slots);
          }),
      ],
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    WidgetRef ref,
    int dayOfWeek,
    List<TimeSlot> slots,
  ) {
    final dayName = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'][dayOfWeek - 1];
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
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          hasSlots ? '${slots.length}개 시간대' : '휴무',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        children: [
          if (hasSlots)
            ...slots.map((slot) => _buildTimeSlotTile(context, ref, slot))
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
              onPressed: () => _showAddTimeSlotDialog(
                context,
                ref,
                preselectedDay: dayOfWeek,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('시간대 추가'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotTile(
    BuildContext context,
    WidgetRef ref,
    TimeSlot slot,
  ) {
    return ListTile(
      leading: Icon(
        Icons.access_time,
        color: slot.isActive ? AppColors.primary : AppColors.textTertiaryLight,
      ),
      title: Text(
        slot.timeRange,
        style: AppTypography.bodyMedium.copyWith(
          color: slot.isActive
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
            onChanged: (value) => _toggleTimeSlot(ref, slot.id, value),
            activeColor: AppColors.primary,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showEditTimeSlotDialog(context, ref, slot),
          ),
        ],
      ),
    );
  }

  void _updateDefaultDuration(WidgetRef ref, int duration) {
    ref
        .read(teacherSettingsNotifierProvider.notifier)
        .updateDefaultDuration(duration);
  }

  void _toggleTimeSlot(WidgetRef ref, String slotId, bool isActive) {
    ref
        .read(teacherSettingsNotifierProvider.notifier)
        .toggleTimeSlot(slotId, isActive);
  }

  void _showAddTimeSlotDialog(
    BuildContext context,
    WidgetRef ref, {
    int? preselectedDay,
  }) {
    showDialog(
      context: context,
      builder: (context) => _TimeSlotDialog(
        preselectedDay: preselectedDay,
        onSave: (slot) {
          ref.read(teacherSettingsNotifierProvider.notifier).updateTimeSlot(slot);
        },
      ),
    );
  }

  void _showEditTimeSlotDialog(
    BuildContext context,
    WidgetRef ref,
    TimeSlot slot,
  ) {
    showDialog(
      context: context,
      builder: (context) => _TimeSlotDialog(
        existingSlot: slot,
        onSave: (updatedSlot) {
          ref
              .read(teacherSettingsNotifierProvider.notifier)
              .updateTimeSlot(updatedSlot);
        },
      ),
    );
  }
}

class _TimeSlotDialog extends StatefulWidget {
  final int? preselectedDay;
  final TimeSlot? existingSlot;
  final void Function(TimeSlot) onSave;

  const _TimeSlotDialog({
    this.preselectedDay,
    this.existingSlot,
    required this.onSave,
  });

  @override
  State<_TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<_TimeSlotDialog> {
  late int _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

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
            value: _selectedDay,
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
              final dayName = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'][index];
              return DropdownMenuItem(
                value: day,
                child: Text(dayName),
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
                    _buildTimePicker(
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
                    _buildTimePicker(
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
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('저장'),
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료 시간은 시작 시간 이후여야 합니다')),
      );
      return;
    }

    final slot = TimeSlot(
      id: widget.existingSlot?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
class _DurationPickerDialog extends StatefulWidget {
  final void Function(int duration) onSave;
  final List<int> existingDurations;

  const _DurationPickerDialog({
    required this.onSave,
    required this.existingDurations,
  });

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
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
              color: _isDuplicate
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
                divisions: (LessonDurations.maxDuration - LessonDurations.minDuration) ~/ 5,
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
              children: [35, 50, 75, 100, 150, 180].map((duration) {
                final isSelected = _currentDuration == duration;
                final exists = widget.existingDurations.contains(duration);
                return FilterChip(
                  label: Text(
                    LessonDurations.format(duration),
                    style: TextStyle(
                      fontSize: 12,
                      color: exists
                          ? AppColors.textTertiaryLight
                          : isSelected
                              ? AppColors.primary
                              : AppColors.textPrimaryLight,
                      decoration: exists ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  selected: isSelected && !exists,
                  onSelected: exists
                      ? null
                      : (_) {
                          setState(() {
                            _sliderValue = duration.toDouble();
                          });
                        },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
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
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isDuplicate
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
