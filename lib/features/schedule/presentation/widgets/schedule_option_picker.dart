import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';

/// Picker mode for schedule option
enum ScheduleOptionPickerMode {
  /// Single lesson - date + time
  singleLesson,

  /// Regular lesson - dayOfWeek + time + startDate
  regularLesson,

  /// Regular 2x lesson - 2x (dayOfWeek + time) + startDate
  regularLesson2x,
}

/// A bottom sheet picker for schedule option
class ScheduleOptionPicker extends StatefulWidget {
  final ScheduleOptionPickerMode mode;
  final ScheduleOption? initialOption;
  final int priority;
  final int lessonDuration;
  final List<TimeOfDay>? availableSlots;
  final List<int>? blockedDays;
  final ValueChanged<ScheduleOption> onConfirm;

  const ScheduleOptionPicker({
    super.key,
    required this.mode,
    this.initialOption,
    required this.priority,
    this.lessonDuration = 60,
    this.availableSlots,
    this.blockedDays,
    required this.onConfirm,
  });

  /// Show as bottom sheet
  static Future<ScheduleOption?> show({
    required BuildContext context,
    required ScheduleOptionPickerMode mode,
    ScheduleOption? initialOption,
    required int priority,
    int lessonDuration = 60,
    List<TimeOfDay>? availableSlots,
    List<int>? blockedDays,
  }) async {
    return showModalBottomSheet<ScheduleOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXLarge),
              ),
            ),
            child: _ScheduleOptionPickerContent(
              mode: mode,
              initialOption: initialOption,
              priority: priority,
              lessonDuration: lessonDuration,
              availableSlots: availableSlots,
              blockedDays: blockedDays,
              scrollController: scrollController,
            ),
          );
        },
      ),
    );
  }

  @override
  State<ScheduleOptionPicker> createState() => _ScheduleOptionPickerState();
}

class _ScheduleOptionPickerState extends State<ScheduleOptionPicker> {
  @override
  Widget build(BuildContext context) {
    return _ScheduleOptionPickerContent(
      mode: widget.mode,
      initialOption: widget.initialOption,
      priority: widget.priority,
      lessonDuration: widget.lessonDuration,
      availableSlots: widget.availableSlots,
      blockedDays: widget.blockedDays,
    );
  }
}

class _ScheduleOptionPickerContent extends StatefulWidget {
  final ScheduleOptionPickerMode mode;
  final ScheduleOption? initialOption;
  final int priority;
  final int lessonDuration;
  final List<TimeOfDay>? availableSlots;
  final List<int>? blockedDays;
  final ScrollController? scrollController;

  const _ScheduleOptionPickerContent({
    required this.mode,
    this.initialOption,
    required this.priority,
    this.lessonDuration = 60,
    this.availableSlots,
    this.blockedDays,
    this.scrollController,
  });

  @override
  State<_ScheduleOptionPickerContent> createState() =>
      _ScheduleOptionPickerContentState();
}

class _ScheduleOptionPickerContentState
    extends State<_ScheduleOptionPickerContent> {
  final _uuid = const Uuid();

  // Single lesson fields
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Regular lesson fields
  int? _selectedDayOfWeek;
  DateTime? _selectedStartDate;

  // Regular 2x lesson fields
  int? _secondDayOfWeek;
  TimeOfDay? _secondTime;

  @override
  void initState() {
    super.initState();
    _initializeFromOption();
  }

  void _initializeFromOption() {
    final option = widget.initialOption;
    if (option == null) {
      // Set defaults
      if (widget.mode == ScheduleOptionPickerMode.singleLesson) {
        _selectedDate = DateTime.now().add(const Duration(days: 1));
        _selectedTime = const TimeOfDay(hour: 14, minute: 0);
      } else {
        _selectedDayOfWeek = DateTime.tuesday;
        _selectedTime = const TimeOfDay(hour: 16, minute: 0);
        _selectedStartDate = _getNextWeekday(DateTime.tuesday);
      }
      return;
    }

    // Initialize from existing option
    _selectedDate = option.date;
    _selectedTime = option.startTime;
    _selectedDayOfWeek = option.dayOfWeek;
    _selectedStartDate = option.startDate;
    _secondDayOfWeek = option.secondDayOfWeek;
    _secondTime = option.secondStartTime;
  }

  DateTime _getNextWeekday(int weekday) {
    final now = DateTime.now();
    int daysUntil = weekday - now.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    return now.add(Duration(days: daysUntil));
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  bool get _isValid {
    switch (widget.mode) {
      case ScheduleOptionPickerMode.singleLesson:
        return _selectedDate != null && _selectedTime != null;
      case ScheduleOptionPickerMode.regularLesson:
        return _selectedDayOfWeek != null &&
            _selectedTime != null &&
            _selectedStartDate != null;
      case ScheduleOptionPickerMode.regularLesson2x:
        return _selectedDayOfWeek != null &&
            _selectedTime != null &&
            _secondDayOfWeek != null &&
            _secondTime != null &&
            _selectedStartDate != null;
    }
  }

  ScheduleOption _buildOption() {
    final id = widget.initialOption?.id ?? _uuid.v4();
    final endTime = _addMinutes(_selectedTime!, widget.lessonDuration);

    switch (widget.mode) {
      case ScheduleOptionPickerMode.singleLesson:
        return ScheduleOption(
          id: id,
          priority: widget.priority,
          date: _selectedDate,
          startTime: _selectedTime,
          endTime: endTime,
        );

      case ScheduleOptionPickerMode.regularLesson:
        return ScheduleOption(
          id: id,
          priority: widget.priority,
          dayOfWeek: _selectedDayOfWeek,
          startTime: _selectedTime,
          endTime: endTime,
          startDate: _selectedStartDate,
        );

      case ScheduleOptionPickerMode.regularLesson2x:
        final secondEndTime = _addMinutes(_secondTime!, widget.lessonDuration);
        return ScheduleOption(
          id: id,
          priority: widget.priority,
          dayOfWeek: _selectedDayOfWeek,
          startTime: _selectedTime,
          endTime: endTime,
          startDate: _selectedStartDate,
          secondDayOfWeek: _secondDayOfWeek,
          secondStartTime: _secondTime,
          secondEndTime: secondEndTime,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: AppSpacing.space2),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Text(
                '${widget.priority}순위 일정 선택',
                style: AppTypography.headingSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        Divider(color: AppColors.borderLight, height: 1),

        // Content
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(AppSpacing.space4),
            children: [
              if (widget.mode == ScheduleOptionPickerMode.singleLesson)
                _buildSingleLessonContent()
              else
                _buildRegularLessonContent(),
            ],
          ),
        ),

        // Confirm button
        Container(
          padding: EdgeInsets.only(
            left: AppSpacing.space4,
            right: AppSpacing.space4,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.space4,
            top: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border(
              top: BorderSide(color: AppColors.borderLight),
            ),
          ),
          child: FilledButton(
            onPressed: _isValid
                ? () {
                    Navigator.pop(context, _buildOption());
                  }
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Text(
              '확인',
              style: AppTypography.button.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleLessonContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date section
        _buildSectionTitle('날짜'),
        const SizedBox(height: AppSpacing.space2),
        _buildDateSelector(),

        const SizedBox(height: AppSpacing.space5),

        // Time section
        _buildSectionTitle('시간'),
        const SizedBox(height: AppSpacing.space2),
        _buildTimeSelector(_selectedTime, (time) {
          setState(() => _selectedTime = time);
        }),
      ],
    );
  }

  Widget _buildRegularLessonContent() {
    final is2x = widget.mode == ScheduleOptionPickerMode.regularLesson2x;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First day
        _buildSectionTitle(is2x ? '첫번째 요일' : '요일'),
        const SizedBox(height: AppSpacing.space2),
        _buildDayOfWeekSelector(_selectedDayOfWeek, (day) {
          setState(() {
            _selectedDayOfWeek = day;
            _selectedStartDate = _getNextWeekday(day);
          });
        }),

        const SizedBox(height: AppSpacing.space4),

        // First time
        _buildSectionTitle(is2x ? '첫번째 시간' : '시간'),
        const SizedBox(height: AppSpacing.space2),
        _buildTimeSelector(_selectedTime, (time) {
          setState(() => _selectedTime = time);
        }),

        if (is2x) ...[
          const SizedBox(height: AppSpacing.space5),
          Divider(color: AppColors.borderLight),
          const SizedBox(height: AppSpacing.space4),

          // Second day
          _buildSectionTitle('두번째 요일'),
          const SizedBox(height: AppSpacing.space2),
          _buildDayOfWeekSelector(_secondDayOfWeek, (day) {
            setState(() => _secondDayOfWeek = day);
          }),

          const SizedBox(height: AppSpacing.space4),

          // Second time
          _buildSectionTitle('두번째 시간'),
          const SizedBox(height: AppSpacing.space2),
          _buildTimeSelector(_secondTime, (time) {
            setState(() => _secondTime = time);
          }),
        ],

        const SizedBox(height: AppSpacing.space5),
        Divider(color: AppColors.borderLight),
        const SizedBox(height: AppSpacing.space4),

        // Start date
        _buildSectionTitle('시작일'),
        const SizedBox(height: AppSpacing.space2),
        _buildStartDateSelector(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.bodyLarge.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final dates = List.generate(14, (i) => now.add(Duration(days: i + 1)));
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: dates.map((date) {
        final isSelected = _selectedDate != null &&
            _selectedDate!.year == date.year &&
            _selectedDate!.month == date.month &&
            _selectedDate!.day == date.day;
        final weekday = weekdays[date.weekday - 1];
        final isWeekend = date.weekday >= 6;

        return InkWell(
          onTap: () => setState(() => _selectedDate = date),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: Container(
            width: 60,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  weekday,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? Colors.white
                        : isWeekend
                            ? AppColors.error
                            : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayOfWeekSelector(int? selected, ValueChanged<int> onChanged) {
    final days = [
      (1, '월'),
      (2, '화'),
      (3, '수'),
      (4, '목'),
      (5, '금'),
      (6, '토'),
      (7, '일'),
    ];

    return Wrap(
      spacing: AppSpacing.space2,
      children: days.map((day) {
        final isSelected = selected == day.$1;
        final isWeekend = day.$1 >= 6;

        return InkWell(
          onTap: () => onChanged(day.$1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
            ),
            child: Text(
              day.$2,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isWeekend
                        ? AppColors.error
                        : AppColors.textPrimaryLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSelector(TimeOfDay? selected, ValueChanged<TimeOfDay> onChanged) {
    // Generate time slots from 9:00 to 21:00
    final slots = <TimeOfDay>[];
    for (int hour = 9; hour <= 20; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      if (hour < 20) {
        slots.add(TimeOfDay(hour: hour, minute: 30));
      }
    }

    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: slots.map((slot) {
        final isSelected = selected != null &&
            selected.hour == slot.hour &&
            selected.minute == slot.minute;
        final timeStr =
            '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';

        return InkWell(
          onTap: () => onChanged(slot),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
            ),
            child: Text(
              timeStr,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartDateSelector() {
    if (_selectedStartDate == null) {
      return const SizedBox.shrink();
    }

    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[_selectedStartDate!.weekday - 1];

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedStartDate!,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        if (picked != null) {
          setState(() => _selectedStartDate = picked);
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppSpacing.space3),
            Text(
              '${_selectedStartDate!.year}년 ${_selectedStartDate!.month}월 ${_selectedStartDate!.day}일 ($weekday)',
              style: AppTypography.bodyLarge,
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
