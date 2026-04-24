import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'duration_selector.dart';
import 'student_form_helpers.dart';

/// Schedule section with day selector and per-day time picker.
class ScheduleSection extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onDayToggle;
  final TimeOfDay lessonTime;
  final VoidCallback onTimeTap;
  final int lessonDuration;
  final ValueChanged<int> onDurationChanged;
  final List<String> dayNames;

  /// Per-day time overrides. If a day has no entry, lessonTime is used.
  final Map<int, TimeOfDay>? dayTimeMap;

  /// Called when a per-day time is changed.
  final void Function(int dayIndex, TimeOfDay time)? onDayTimeChanged;

  const ScheduleSection({
    super.key,
    required this.selectedDays,
    required this.onDayToggle,
    required this.lessonTime,
    required this.onTimeTap,
    required this.lessonDuration,
    required this.onDurationChanged,
    this.dayNames = const ['월', '화', '수', '목', '금', '토', '일'],
    this.dayTimeMap,
    this.onDayTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortedDays = selectedDays.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson days
          Text(
            '레슨 요일',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isSelected = selectedDays.contains(index);
              return GestureDetector(
                onTap: () => onDayToggle(index),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.paperDark,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      dayNames[index],
                      style: AppTypography.bodySmall.copyWith(
                        // Notebook × Score §7.50: Vermillion selected day foreground = paper.
                        color:
                            isSelected
                                ? AppColors.paper
                                : AppColors.inkSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: AppSpacing.space4),
          const Divider(),
          const SizedBox(height: AppSpacing.space4),

          // Per-day time settings (if multiple days selected)
          if (sortedDays.length > 1 && onDayTimeChanged != null) ...[
            Text(
              '요일별 레슨 시간',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              '각 요일의 시작 시간을 개별 설정할 수 있습니다',
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            ...sortedDays.map((dayIndex) {
              final time = dayTimeMap?[dayIndex] ?? lessonTime;
              return _DayTimeRow(
                dayName: dayNames[dayIndex],
                time: time,
                onTimeTap: () async {
                  final picked = await selectTime(context, time);
                  if (picked != null) {
                    onDayTimeChanged!(dayIndex, picked);
                  }
                },
              );
            }),
          ] else ...[
            // Single day or no per-day callback — show simple time picker
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '레슨 시간',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        '기본 레슨 시작 시간',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: onTimeTap,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(
                      formatTime(lessonTime),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space4,
                        vertical: AppSpacing.space2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.space4),
          const Divider(),
          const SizedBox(height: AppSpacing.space4),

          // Lesson duration
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '레슨 시간 (분)',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '1회 레슨 시간',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              DurationSelector(
                selectedDuration: lessonDuration,
                onChanged: onDurationChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Row showing a single day's time with change button.
class _DayTimeRow extends StatelessWidget {
  final String dayName;
  final TimeOfDay time;
  final VoidCallback onTimeTap;

  const _DayTimeRow({
    required this.dayName,
    required this.time,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.paperAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                dayName,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              formatTime(time),
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onTimeTap,
            icon: const Icon(Icons.access_time, size: 16),
            label: const Text('변경'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
