import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../../core/booking/entities/time_slot.dart';
import 'time_slot_selector.dart';

/// Section title widget for regular lesson forms
class RegularLessonSectionTitle extends StatelessWidget {
  final String title;

  const RegularLessonSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    // Notebook × Score: 정기 레슨 폼 섹션 제목도 Playfair sectionTitle(17) 로 통일.
    return Text(title, style: NotebookTypography.sectionTitle);
  }
}

/// Student info card for regular lesson registration
class RegularLessonStudentInfo extends StatelessWidget {
  final String studentName;

  const RegularLessonStudentInfo({super.key, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.paperAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.paperAccent,
            child: Text(
              studentName[0],
              style: AppTypography.headingSmall.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '정규레슨으로 등록합니다',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lesson duration selector with teacher defaults
class RegularLessonDurationSelector extends StatelessWidget {
  final int selectedDuration;
  final TeacherSettings settings;
  final ValueChanged<int> onDurationChanged;

  const RegularLessonDurationSelector({
    super.key,
    required this.selectedDuration,
    required this.settings,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final durations = settings.allLessonDurations;

    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children:
          durations.map((duration) {
            final isSelected = selectedDuration == duration;
            final isDefault = duration == settings.defaultLessonDuration;

            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LessonDurations.format(duration)),
                  if (isDefault) ...[
                    const SizedBox(width: AppSpacing.space1),
                    Icon(
                      Icons.star,
                      size: 12,
                      color: isSelected ? Colors.white : AppColors.paperAccent,
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onDurationChanged(duration);
                }
              },
              backgroundColor: AppColors.paper,
              selectedColor: AppColors.paperAccent,
              side: BorderSide(
                color:
                    isSelected
                        ? AppColors.paperAccent
                        : AppColors.inkQuaternary,
              ),
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.ink,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
    );
  }
}

/// Day selector for regular lessons
class RegularLessonDaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final int lessonsPerWeek;
  final List<TimeSlot> availableSlots;
  final ValueChanged<int> onDayToggle;
  final Map<int, TimeOfDay> selectedTimesPerDay;
  final void Function(int, TimeOfDay?) onTimeRemoved;

  const RegularLessonDaySelector({
    super.key,
    required this.selectedDays,
    required this.lessonsPerWeek,
    required this.availableSlots,
    required this.onDayToggle,
    required this.selectedTimesPerDay,
    required this.onTimeRemoved,
  });

  static const List<String> dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    // Get available days from teacher's slots
    final availableDays =
        availableSlots
            .where((slot) => slot.isActive)
            .map((slot) => slot.dayOfWeek)
            .toSet();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final dayOfWeek = index + 1;
        final isAvailable = availableDays.contains(dayOfWeek);
        final isSelected = selectedDays.contains(dayOfWeek);

        return DayButton(
          label: dayNames[index],
          isAvailable: isAvailable,
          isSelected: isSelected,
          onTap:
              isAvailable
                  ? () {
                    if (isSelected) {
                      onDayToggle(dayOfWeek);
                      onTimeRemoved(dayOfWeek, null);
                    } else if (selectedDays.length < lessonsPerWeek) {
                      onDayToggle(dayOfWeek);
                    } else {
                      // Replace oldest selection
                      final oldest = selectedDays.first;
                      onDayToggle(oldest);
                      onTimeRemoved(oldest, null);
                      onDayToggle(dayOfWeek);
                    }
                  }
                  : null,
        );
      }),
    );
  }
}

/// Day selection button
class DayButton extends StatelessWidget {
  final String label;
  final bool isAvailable;
  final bool isSelected;
  final VoidCallback? onTap;

  const DayButton({
    super.key,
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
          color:
              isSelected
                  ? AppColors.paperAccent
                  : isAvailable
                  ? AppColors.paper
                  : AppColors.paperDark,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isSelected
                    ? AppColors.paperAccent
                    : isAvailable
                    ? AppColors.inkQuaternary
                    : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color:
                  isSelected
                      ? Colors.white
                      : isAvailable
                      ? AppColors.ink
                      : AppColors.inkTertiary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Time selection for a specific day
class RegularLessonTimeSelector extends StatelessWidget {
  final int dayOfWeek;
  final List<TimeSlot> availableSlots;
  final TimeOfDay? selectedTime;
  final int lessonDuration;
  final ValueChanged<TimeOfDay> onTimeSelected;

  const RegularLessonTimeSelector({
    super.key,
    required this.dayOfWeek,
    required this.availableSlots,
    required this.selectedTime,
    required this.lessonDuration,
    required this.onTimeSelected,
  });

  static const List<String> dayNames = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];

  @override
  Widget build(BuildContext context) {
    final daySlot = availableSlots.firstWhere(
      (slot) => slot.dayOfWeek == dayOfWeek && slot.isActive,
      orElse:
          () => TimeSlot(
            id: 'default',
            dayOfWeek: dayOfWeek,
            startTime: const TimeOfDay(hour: 14, minute: 0),
            endTime: const TimeOfDay(hour: 18, minute: 0),
          ),
    );

    // Determine display range based on available times
    final displayStart =
        daySlot.startTime.hour < 9
            ? TimeOfDay(hour: daySlot.startTime.hour, minute: 0)
            : const TimeOfDay(hour: 9, minute: 0);
    final displayEnd =
        daySlot.endTime.hour > 22
            ? TimeOfDay(hour: daySlot.endTime.hour + 1, minute: 0)
            : const TimeOfDay(hour: 22, minute: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
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
                  color: AppColors.paperAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  '${formatTimeOfDay(daySlot.startTime)}-${formatTimeOfDay(daySlot.endTime)} 가능',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          // Time slot selector with AM/PM sections
          TimeSlotSelector(
            selectedTime: selectedTime,
            onTimeSelected: onTimeSelected,
            availableStart: daySlot.startTime,
            availableEnd: daySlot.endTime,
            lessonDurationMinutes: lessonDuration,
            bookedSlots:
                const [], // TODO: Get from provider when backend is ready
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
                color: AppColors.paperOk.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.paperOk.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.paperOk),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '${formatTimeOfDay(selectedTime!)} ~ ${formatTimeOfDay(addMinutes(selectedTime!, lessonDuration))} (${LessonDurations.format(lessonDuration)})',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.paperOk,
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
}

/// Lessons per week selector
class LessonsPerWeekSelector extends StatelessWidget {
  final int lessonsPerWeek;
  final ValueChanged<int> onChanged;
  final VoidCallback? onDecreaseLessons;

  const LessonsPerWeekSelector({
    super.key,
    required this.lessonsPerWeek,
    required this.onChanged,
    this.onDecreaseLessons,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OptionCard(
            title: '주 1회',
            subtitle: '월 4회',
            isSelected: lessonsPerWeek == 1,
            onTap: () {
              onChanged(1);
              onDecreaseLessons?.call();
            },
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: OptionCard(
            title: '주 2회',
            subtitle: '월 8회',
            isSelected: lessonsPerWeek == 2,
            onTap: () => onChanged(2),
          ),
        ),
      ],
    );
  }
}

/// Option card widget
class OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          isSelected
              ? AppColors.paperAccent.withValues(alpha: 0.1)
              : AppColors.paper,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color:
                  isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.paperAccent : AppColors.ink,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fee selector
class RegularLessonFeeSelector extends StatelessWidget {
  final int monthlyFee;
  final ValueChanged<int> onFeeChanged;

  const RegularLessonFeeSelector({
    super.key,
    required this.monthlyFee,
    required this.onFeeChanged,
  });

  static const List<int> fees = [160000, 180000, 200000, 240000];
  static const List<String> labels = ['입문', '초급', '중급', '고급'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: List.generate(fees.length, (index) {
        final isSelected = monthlyFee == fees[index];
        return ChoiceChip(
          label: Text('${labels[index]} ${formatFee(fees[index])}'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onFeeChanged(fees[index]);
          },
          backgroundColor: AppColors.paper,
          selectedColor: AppColors.paperAccent.withValues(alpha: 0.15),
          side: BorderSide(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
          ),
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.paperAccent : AppColors.ink,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }),
    );
  }
}

/// Start date selector
class RegularLessonStartDateSelector extends StatelessWidget {
  final DateTime startDate;
  final VoidCallback onTap;

  const RegularLessonStartDateSelector({
    super.key,
    required this.startDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.paperAccent),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                '${startDate.year}년 ${startDate.month}월 ${startDate.day}일부터',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.edit, size: 18, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }
}

/// Summary card for regular lesson registration
class RegularLessonSummary extends StatelessWidget {
  final String scheduleTypeLabel;
  final bool isFixedSchedule;
  final int lessonDuration;
  final Set<int> selectedDays;
  final Map<int, TimeOfDay> selectedTimesPerDay;
  final int lessonsPerWeek;
  final int monthlyFee;
  final DateTime startDate;

  const RegularLessonSummary({
    super.key,
    required this.scheduleTypeLabel,
    required this.isFixedSchedule,
    required this.lessonDuration,
    required this.selectedDays,
    required this.selectedTimesPerDay,
    required this.lessonsPerWeek,
    required this.monthlyFee,
    required this.startDate,
  });

  static const List<String> dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final perLessonFee = monthlyFee ~/ (lessonsPerWeek * 4);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.paperAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildRow('레슨 유형', scheduleTypeLabel),
          const SizedBox(height: AppSpacing.space2),
          if (isFixedSchedule) ...[
            _buildRow('레슨 시간', LessonDurations.format(lessonDuration)),
            const SizedBox(height: AppSpacing.space2),
            if (selectedDays.isNotEmpty)
              ...(selectedDays.toList()..sort()).map((day) {
                final time = selectedTimesPerDay[day];
                final timeStr =
                    time != null
                        ? '${formatTimeOfDay(time)}-${formatTimeOfDay(addMinutes(time, lessonDuration))}'
                        : '미선택';
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: _buildRow(
                    '${dayNames[day - 1]}요일',
                    timeStr,
                    valueColor: time != null ? null : AppColors.inkTertiary,
                  ),
                );
              }),
          ],
          _buildRow('레슨 횟수', '주 $lessonsPerWeek회 (월 ${lessonsPerWeek * 4}회)'),
          const SizedBox(height: AppSpacing.space2),
          _buildRow('회당 수강료', formatFee(perLessonFee)),
          const Divider(height: AppSpacing.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('월 수강료', style: AppTypography.headingSmall),
              Text(
                formatFee(monthlyFee),
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
            ],
          ),
          // First month prorated fee
          FirstMonthFeeSection(
            monthlyFee: monthlyFee,
            startDate: startDate,
            lessonsPerWeek: lessonsPerWeek,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// First month prorated fee section
class FirstMonthFeeSection extends StatelessWidget {
  final int monthlyFee;
  final DateTime startDate;
  final int lessonsPerWeek;

  const FirstMonthFeeSection({
    super.key,
    required this.monthlyFee,
    required this.startDate,
    required this.lessonsPerWeek,
  });

  @override
  Widget build(BuildContext context) {
    final prorated = LessonDateUtils.calculateProratedFee(
      monthlyFee: monthlyFee,
      startDate: startDate,
      lessonsPerWeek: lessonsPerWeek,
    );

    // Only show if prorated fee is different from monthly fee
    if (prorated.remainingWeeks >= 4) {
      return const SizedBox.shrink();
    }

    // Only show "5주차 휴강" when starting from week 1 in a 5-week month
    final currentWeek = LessonDateUtils.getWeekOfMonth(startDate);
    final hasWeek5 = LessonDateUtils.hasWeek5(startDate.year, startDate.month);
    final showWeek5Notice = hasWeek5 && currentWeek == 1;
    final weekInfo =
        showWeek5Notice
            ? '${prorated.remainingWeeks}주분, 5주차 휴강'
            : '${prorated.remainingWeeks}주분';

    return Column(
      children: [
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paperAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: AppColors.paperAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '시작일 기준 첫 달은 일할 계산됩니다',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperAccent,
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
                        formatFee(prorated.proratedFee),
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.paperAccent,
                        ),
                      ),
                      Text(
                        '($weekInfo)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
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
}

/// Submit button for regular lesson registration
class RegularLessonSubmitButton extends StatelessWidget {
  final bool isValid;
  final bool isSubmitting;
  final VoidCallback? onSubmit;

  const RegularLessonSubmitButton({
    super.key,
    required this.isValid,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: FilledButton(
        onPressed: isValid && !isSubmitting ? onSubmit : null,
        child:
            isSubmitting
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
}

// Helper functions

/// Format fee with commas
String formatFee(int amount) {
  final formatted = amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '$formatted원';
}

/// Format TimeOfDay to HH:mm string
String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Add minutes to TimeOfDay
TimeOfDay addMinutes(TimeOfDay time, int minutes) {
  final totalMinutes = time.hour * 60 + time.minute + minutes;
  return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
}

/// Get next Monday from today
DateTime getNextMonday() {
  final now = DateTime.now();
  final daysUntilMonday = (DateTime.monday - now.weekday) % 7;
  return now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
}

/// Select start date
Future<DateTime?> selectStartDate(
  BuildContext context,
  DateTime initialDate,
) async {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 60)),
    locale: const Locale('ko'),
  );
}
