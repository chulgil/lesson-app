import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../models/teacher_settings.dart';
import '../../../../models/time_slot.dart';
import '../../../../providers/booking/booking_providers.dart';
import '../../../../providers/settings/teacher_settings_provider.dart';
import '../widgets/schedule_type_selector.dart';
import '../widgets/time_slot_selector.dart';

/// Screen for registering a regular lesson after trial
class RegisterRegularLessonScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName;
  final String? studentId;
  final String? studentName;

  const RegisterRegularLessonScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    this.studentId,
    this.studentName,
  });

  @override
  ConsumerState<RegisterRegularLessonScreen> createState() =>
      _RegisterRegularLessonScreenState();
}

class _RegisterRegularLessonScreenState
    extends ConsumerState<RegisterRegularLessonScreen> {
  ScheduleType _scheduleType = ScheduleType.fixed;
  int _selectedLessonDuration = 60; // Default, will be updated from teacher settings
  final Set<int> _selectedDays = {}; // Selected days of week (1=Mon, 7=Sun)
  final Map<int, TimeOfDay> _selectedTimesPerDay = {}; // Day -> selected start time
  int _lessonsPerWeek = 1;
  int _monthlyFee = 200000;
  DateTime _startDate = _getNextMonday();
  bool _isSubmitting = false;

  static DateTime _getNextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync =
        ref.watch(teacherAvailabilityProvider(widget.teacherId));
    final settingsAsync =
        ref.watch(teacherSettingsByIdProvider(widget.teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('정규레슨 등록'),
      ),
      body: settingsAsync.when(
        data: (settings) => availabilityAsync.when(
          data: (slots) => _buildContent(settings, slots),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('시간 정보를 불러올 수 없습니다')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('설정 정보를 불러올 수 없습니다')),
      ),
    );
  }

  Widget _buildContent(TeacherSettings settings, List<TimeSlot> slots) {
    // Initialize lesson duration from teacher's default if not set
    if (_selectedLessonDuration == 60 && settings.defaultLessonDuration != 60) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedLessonDuration = settings.defaultLessonDuration;
        });
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info
          if (widget.studentName != null) _buildStudentInfo(),

          const SizedBox(height: AppSpacing.space6),

          // Schedule type
          _buildSectionTitle('레슨 유형'),
          const SizedBox(height: AppSpacing.space3),
          ScheduleTypeSelector(
            selectedType: _scheduleType,
            onTypeSelected: (type) {
              setState(() {
                _scheduleType = type;
                if (type == ScheduleType.flexible) {
                  _selectedDays.clear();
                  _selectedTimesPerDay.clear();
                }
              });
            },
          ),

          const SizedBox(height: AppSpacing.space6),

          // Fixed time slot selection
          if (_scheduleType == ScheduleType.fixed) ...[
            // Lesson duration selection
            _buildSectionTitle('레슨 시간'),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '선생님 기본 설정: ${LessonDurations.format(settings.defaultLessonDuration)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            _buildLessonDurationSelector(settings),

            const SizedBox(height: AppSpacing.space6),

            // Day selection
            _buildSectionTitle('요일 선택'),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '주 $_lessonsPerWeek회 레슨 - $_lessonsPerWeek개 요일을 선택하세요',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            _buildDaySelector(slots),

            const SizedBox(height: AppSpacing.space6),

            // Time selection for each selected day
            if (_selectedDays.isNotEmpty) ...[
              _buildSectionTitle('시간 선택'),
              const SizedBox(height: AppSpacing.space3),
              ..._selectedDays.map((day) => _buildTimeSelectionForDay(day, slots)),
            ],

            const SizedBox(height: AppSpacing.space6),
          ],

          // Lessons per week
          _buildSectionTitle('레슨 횟수'),
          const SizedBox(height: AppSpacing.space3),
          _buildLessonsPerWeekSelector(),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '* 5주차가 있는 달은 기본 휴강입니다. 추가 레슨이 필요하시면 1회 레슨을 신청해주세요.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Monthly fee
          _buildSectionTitle('월 수강료'),
          const SizedBox(height: AppSpacing.space3),
          _buildFeeSelector(),

          const SizedBox(height: AppSpacing.space6),

          // Start date
          _buildSectionTitle('시작일'),
          const SizedBox(height: AppSpacing.space3),
          _buildStartDateSelector(),

          const SizedBox(height: AppSpacing.space8),

          // Summary
          _buildSummary(),

          const SizedBox(height: AppSpacing.space6),

          // Submit button
          _buildSubmitButton(),

          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.studentName![0],
              style: AppTypography.headingSmall.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName!,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '정규레슨으로 등록합니다',
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.headingSmall);
  }

  Widget _buildLessonDurationSelector(TeacherSettings settings) {
    final durations = settings.allLessonDurations;

    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: durations.map((duration) {
        final isSelected = _selectedLessonDuration == duration;
        final isDefault = duration == settings.defaultLessonDuration;

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(LessonDurations.format(duration)),
              if (isDefault) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.star,
                  size: 12,
                  color: isSelected ? Colors.white : AppColors.secondary,
                ),
              ],
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedLessonDuration = duration;
                // Clear time selections when duration changes
                _selectedTimesPerDay.clear();
              });
            }
          },
          backgroundColor: AppColors.surfaceLight,
          selectedColor: AppColors.primary,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaySelector(List<TimeSlot> slots) {
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    // Get available days from teacher's slots
    final availableDays = slots
        .where((slot) => slot.isActive)
        .map((slot) => slot.dayOfWeek)
        .toSet();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final dayOfWeek = index + 1;
        final isAvailable = availableDays.contains(dayOfWeek);
        final isSelected = _selectedDays.contains(dayOfWeek);

        return _DayButton(
          label: dayNames[index],
          isAvailable: isAvailable,
          isSelected: isSelected,
          onTap: isAvailable
              ? () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(dayOfWeek);
                      _selectedTimesPerDay.remove(dayOfWeek);
                    } else if (_selectedDays.length < _lessonsPerWeek) {
                      _selectedDays.add(dayOfWeek);
                    } else {
                      // Replace oldest selection
                      final oldest = _selectedDays.first;
                      _selectedDays.remove(oldest);
                      _selectedTimesPerDay.remove(oldest);
                      _selectedDays.add(dayOfWeek);
                    }
                  });
                }
              : null,
        );
      }),
    );
  }

  Widget _buildTimeSelectionForDay(int dayOfWeek, List<TimeSlot> slots) {
    final dayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final daySlot = slots.firstWhere(
      (slot) => slot.dayOfWeek == dayOfWeek && slot.isActive,
      orElse: () => TimeSlot(
        id: 'default',
        dayOfWeek: dayOfWeek,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
      ),
    );

    final selectedTime = _selectedTimesPerDay[dayOfWeek];

    // Determine display range based on available times
    // Show from 9 AM to 10 PM by default, adjusted if available times are outside
    final displayStart = daySlot.startTime.hour < 9
        ? TimeOfDay(hour: daySlot.startTime.hour, minute: 0)
        : const TimeOfDay(hour: 9, minute: 0);
    final displayEnd = daySlot.endTime.hour > 22
        ? TimeOfDay(hour: daySlot.endTime.hour + 1, minute: 0)
        : const TimeOfDay(hour: 22, minute: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header with available time info
          Row(
            children: [
              Text(
                dayNames[dayOfWeek - 1],
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  '${_formatTimeOfDay(daySlot.startTime)}-${_formatTimeOfDay(daySlot.endTime)} 가능',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          // Time slot selector with AM/PM sections
          TimeSlotSelector(
            selectedTime: selectedTime,
            onTimeSelected: (time) {
              setState(() {
                _selectedTimesPerDay[dayOfWeek] = time;
              });
            },
            availableStart: daySlot.startTime,
            availableEnd: daySlot.endTime,
            lessonDurationMinutes: _selectedLessonDuration,
            bookedSlots: const [], // TODO: Get from provider when backend is ready
            displayStart: displayStart,
            displayEnd: displayEnd,
          ),

          // Selection summary
          if (selectedTime != null) ...[
            const SizedBox(height: AppSpacing.space4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '${_formatTimeOfDay(selectedTime)} ~ ${_formatTimeOfDay(_addMinutes(selectedTime, _selectedLessonDuration))} (${LessonDurations.format(_selectedLessonDuration)})',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildLessonsPerWeekSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
            title: '주 1회',
            subtitle: '월 4회',
            isSelected: _lessonsPerWeek == 1,
            onTap: () => setState(() {
              _lessonsPerWeek = 1;
              // Keep only first selected day
              if (_selectedDays.length > 1) {
                final first = _selectedDays.first;
                _selectedDays.clear();
                _selectedDays.add(first);
                _selectedTimesPerDay.removeWhere((key, _) => key != first);
              }
            }),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _buildOptionCard(
            title: '주 2회',
            subtitle: '월 8회',
            isSelected: _lessonsPerWeek == 2,
            onTap: () => setState(() => _lessonsPerWeek = 2),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeSelector() {
    final fees = [160000, 180000, 200000, 240000];
    final labels = ['입문', '초급', '중급', '고급'];

    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: List.generate(fees.length, (index) {
        final isSelected = _monthlyFee == fees[index];
        return ChoiceChip(
          label: Text('${labels[index]} ${_formatFee(fees[index])}'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _monthlyFee = fees[index]);
          },
          backgroundColor: AppColors.surfaceLight,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }),
    );
  }

  Widget _buildStartDateSelector() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _startDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 60)),
          locale: const Locale('ko'),
        );
        if (picked != null) {
          setState(() => _startDate = picked);
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                '${_startDate.year}년 ${_startDate.month}월 ${_startDate.day}일부터',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.edit, size: 18, color: AppColors.textTertiaryLight),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final perLessonFee = _monthlyFee ~/ (_lessonsPerWeek * 4);
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('레슨 유형', style: AppTypography.bodyMedium),
              Text(_scheduleType.label,
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          if (_scheduleType == ScheduleType.fixed) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('레슨 시간', style: AppTypography.bodyMedium),
                Text(
                  LessonDurations.format(_selectedLessonDuration),
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            if (_selectedDays.isNotEmpty)
              ...(_selectedDays.toList()..sort()).map((day) {
                final time = _selectedTimesPerDay[day];
                final timeStr = time != null
                    ? '${_formatTimeOfDay(time)}-${_formatTimeOfDay(_addMinutes(time, _selectedLessonDuration))}'
                    : '미선택';
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${dayNames[day - 1]}요일', style: AppTypography.bodyMedium),
                      Text(
                        timeStr,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: time != null ? null : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('레슨 횟수', style: AppTypography.bodyMedium),
              Text('주 $_lessonsPerWeek회 (월 ${_lessonsPerWeek * 4}회)',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('회당 수강료', style: AppTypography.bodyMedium),
              Text(_formatFee(perLessonFee),
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: AppSpacing.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('월 수강료', style: AppTypography.headingSmall),
              Text(
                _formatFee(_monthlyFee),
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          // First month prorated fee
          _buildFirstMonthFeeSection(),
        ],
      ),
    );
  }

  /// Build first month prorated fee section
  Widget _buildFirstMonthFeeSection() {
    final prorated = LessonDateUtils.calculateProratedFee(
      monthlyFee: _monthlyFee,
      startDate: _startDate,
      lessonsPerWeek: _lessonsPerWeek,
    );

    // Only show if prorated fee is different from monthly fee
    if (prorated.remainingWeeks >= 4) {
      return const SizedBox.shrink();
    }

    // Only show "5주차 휴강" when starting from week 1 in a 5-week month
    final currentWeek = LessonDateUtils.getWeekOfMonth(_startDate);
    final hasWeek5 = LessonDateUtils.hasWeek5(_startDate.year, _startDate.month);
    final showWeek5Notice = hasWeek5 && currentWeek == 1;
    final weekInfo = showWeek5Notice
        ? '${prorated.remainingWeeks}주분, 5주차 휴강'
        : '${prorated.remainingWeeks}주분';

    return Column(
      children: [
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '시작일 기준 첫 달은 일할 계산됩니다',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '첫 달 수강료',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatFee(prorated.proratedFee),
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '($weekInfo)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isValid = _scheduleType == ScheduleType.flexible ||
        (_selectedDays.length == _lessonsPerWeek &&
            _selectedTimesPerDay.length == _lessonsPerWeek);

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: FilledButton(
        onPressed: isValid && !_isSubmitting ? _submitRegistration : null,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('정규레슨 등록하기'),
      ),
    );
  }

  String _formatFee(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted원';
  }

  Future<void> _submitRegistration() async {
    if (_scheduleType == ScheduleType.fixed) {
      if (_selectedDays.length != _lessonsPerWeek) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_lessonsPerWeek개의 요일을 선택해주세요'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (_selectedTimesPerDay.length != _lessonsPerWeek) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('각 요일의 레슨 시간을 선택해주세요'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Create time slots from selected days and times
      final fixedSlots = _selectedDays.map((day) {
        final time = _selectedTimesPerDay[day]!;
        return TimeSlot(
          id: 'slot_$day',
          dayOfWeek: day,
          startTime: time,
          endTime: _addMinutes(time, _selectedLessonDuration),
        );
      }).toList();

      final registration = RegularLessonRegistration(
        studentId: widget.studentId ?? 'new_student',
        scheduleType: _scheduleType,
        fixedTimeSlot: fixedSlots.isNotEmpty ? fixedSlots.first : null,
        lessonsPerWeek: _lessonsPerWeek,
        monthlyFee: _monthlyFee,
        startDate: _startDate,
      );

      await ref.read(bookingsNotifierProvider.notifier).registerRegularLesson(
            teacherId: widget.teacherId,
            teacherName: widget.teacherName,
            studentId: widget.studentId ?? 'new_student',
            studentName: widget.studentName ?? '신규 학생',
            registration: registration,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정규레슨이 등록되었습니다'),
            backgroundColor: AppColors.practiceGood,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('등록 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Day selection button
class _DayButton extends StatelessWidget {
  final String label;
  final bool isAvailable;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DayButton({
    required this.label,
    required this.isAvailable,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isAvailable
                  ? AppColors.surfaceLight
                  : AppColors.surfaceSecondaryLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isAvailable
                    ? AppColors.borderLight
                    : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isSelected
                  ? Colors.white
                  : isAvailable
                      ? AppColors.textPrimaryLight
                      : AppColors.textTertiaryLight,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

