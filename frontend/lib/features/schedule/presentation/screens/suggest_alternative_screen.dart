import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/instrument_colors.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../../domain/entities/teacher_availability.dart';
import '../providers/teacher_availability_providers.dart';
import '../providers/week_lessons_provider.dart';

/// Screen for suggesting alternative time slots via a weekly schedule grid.
///
/// Shows the teacher's existing lessons and allows tapping empty cells
/// to add suggested time slots (up to 3). Each slot can be edited or removed.
class SuggestAlternativeScreen extends ConsumerStatefulWidget {
  final String message;
  final int durationMinutes;
  final String? teacherId;

  const SuggestAlternativeScreen({
    super.key,
    required this.message,
    required this.durationMinutes,
    this.teacherId,
  });

  @override
  ConsumerState<SuggestAlternativeScreen> createState() =>
      _SuggestAlternativeScreenState();
}

class _SuggestAlternativeScreenState
    extends ConsumerState<SuggestAlternativeScreen> {
  final _suggestedSlots = <TimeSlot>[];
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
  }

  DateTime _getWeekStart(DateTime date) {
    final diff = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - diff);
  }

  int _parseHour(String time) => int.parse(time.split(':')[0]);
  int _parseMinute(String time) => int.parse(time.split(':')[1]);
  int _parseTimeMinutes(String time) =>
      _parseHour(time) * 60 + _parseMinute(time);

  int _lessonEndMinutes(Lesson lesson) =>
      _parseTimeMinutes(lesson.startTime) + lesson.duration;

  @override
  Widget build(BuildContext context) {
    final teacherId =
        widget.teacherId ?? ref.watch(currentUserIdProvider) ?? 'teacher_1';
    final weekLessonsAsync = ref.watch(weekLessonsProvider(_weekStart));
    final availabilityAsync =
        ref.watch(teacherAvailabilityProvider(teacherId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: const Text('대안 시간 제안'),
      ),
      body: Column(
        children: [
          // Message preview
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.message_outlined,
                    size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    widget.message,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space2),

          // Week navigation
          _buildWeekNav(),

          // Grid
          Expanded(
            child: weekLessonsAsync.when(
              data: (lessons) {
                final availability = availabilityAsync.valueOrNull;
                return _buildGrid(lessons, availability);
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('불러오기 실패: $e')),
            ),
          ),

          // Suggested slots list
          if (_suggestedSlots.isNotEmpty) _buildSuggestedSlotsList(),

          // Submit button
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.space2,
              AppSpacing.screenPadding,
              MediaQuery.of(context).padding.bottom + AppSpacing.space4,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _suggestedSlots.isNotEmpty ? _submit : null,
                child: Text(
                  _suggestedSlots.isEmpty
                      ? '시간을 선택하세요'
                      : '제안하기 (${_suggestedSlots.length}개)',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNav() {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final label =
        '${_weekStart.month}/${_weekStart.day} - ${weekEnd.month}/${weekEnd.day}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() {
              _weekStart =
                  _weekStart.subtract(const Duration(days: 7));
            }),
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
          ),
          Text(label, style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          )),
          IconButton(
            onPressed: () => setState(() {
              _weekStart = _weekStart.add(const Duration(days: 7));
            }),
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
      List<Lesson> lessons, TeacherAvailability? availability) {
    int startHour = 9;
    int endHour = 21;
    if (lessons.isNotEmpty) {
      final minHour = lessons
          .map((l) => _parseHour(l.startTime))
          .reduce((a, b) => a < b ? a : b);
      final maxHour = lessons
          .map((l) {
            final end = _lessonEndMinutes(l);
            return end ~/ 60 + (end % 60 > 0 ? 1 : 0);
          })
          .reduce((a, b) => a > b ? a : b);
      startHour = minHour < startHour ? minHour : startHour;
      endHour = maxHour > endHour ? maxHour : endHour;
    }

    const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    const cellHeight = 28.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = (constraints.maxWidth - 36) / 7;

          return Column(
            children: [
              // Day headers
              Row(
                children: [
                  const SizedBox(width: 36),
                  ...List.generate(7, (i) {
                    final date = _weekStart.add(Duration(days: i));
                    final isToday = _isToday(date);
                    return SizedBox(
                      width: cellWidth,
                      child: Column(
                        children: [
                          Text(
                            dayLabels[i],
                            style: AppTypography.caption.copyWith(
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.textSecondaryLight,
                              fontWeight:
                                  isToday ? FontWeight.bold : null,
                            ),
                          ),
                          Text(
                            '${date.day}',
                            style: AppTypography.caption.copyWith(
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 4),

              // Grid body
              ...List.generate(
                (endHour - startHour) * 2,
                (slotIndex) {
                  final slotMinutes =
                      startHour * 60 + slotIndex * 30;
                  final hour = slotMinutes ~/ 60;
                  final minute = slotMinutes % 60;
                  final isHourBoundary = minute == 0;

                  return Row(
                    children: [
                      SizedBox(
                        width: 36,
                        height: cellHeight,
                        child: isHourBoundary
                            ? Text(
                                '$hour:00',
                                style:
                                    AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  color:
                                      AppColors.textTertiaryLight,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      ...List.generate(7, (dayIndex) {
                        final date = _weekStart
                            .add(Duration(days: dayIndex));
                        return _buildCell(
                          date: date,
                          slotMinutes: slotMinutes,
                          width: cellWidth,
                          height: cellHeight,
                          lessons: lessons,
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCell({
    required DateTime date,
    required int slotMinutes,
    required double width,
    required double height,
    required List<Lesson> lessons,
  }) {
    final hour = slotMinutes ~/ 60;
    final minute = slotMinutes % 60;

    // Check if this cell has a lesson
    final lesson = _findLessonAt(lessons, date, slotMinutes);
    if (lesson != null) {
      final lessonStartMinutes = _parseTimeMinutes(lesson.startTime);
      final isStart = lessonStartMinutes == slotMinutes;
      final colors = InstrumentColors.getColor(lesson.instrument);
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(
            top: isStart
                ? BorderSide(color: colors.accent, width: 2)
                : BorderSide.none,
          ),
        ),
        child: isStart
            ? Padding(
                padding: const EdgeInsets.only(left: 2, top: 1),
                child: Text(
                  NameUtils.givenName(lesson.studentName),
                  style: AppTypography.caption.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                ),
              )
            : null,
      );
    }

    // Check if this cell is a suggested slot
    final suggestedIndex = _findSuggestedSlotAt(date, slotMinutes);
    if (suggestedIndex >= 0) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            '❶❷❸'[suggestedIndex],
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Empty cell — tappable
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _suggestedSlots.length < 3
          ? () => _addSlotFromGrid(date, hour, minute)
          : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.borderLight.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  Lesson? _findLessonAt(
      List<Lesson> lessons, DateTime date, int cellMinutes) {
    for (final lesson in lessons) {
      if (lesson.date.year == date.year &&
          lesson.date.month == date.month &&
          lesson.date.day == date.day) {
        final lessonStart = _parseTimeMinutes(lesson.startTime);
        final lessonEnd = _lessonEndMinutes(lesson);
        if (cellMinutes >= lessonStart && cellMinutes < lessonEnd) {
          return lesson;
        }
      }
    }
    return null;
  }

  int _findSuggestedSlotAt(DateTime date, int cellMinutes) {
    for (int i = 0; i < _suggestedSlots.length; i++) {
      final slot = _suggestedSlots[i];
      if (slot.specificDate != null &&
          slot.specificDate!.year == date.year &&
          slot.specificDate!.month == date.month &&
          slot.specificDate!.day == date.day) {
        final slotStart =
            slot.startTime.hour * 60 + slot.startTime.minute;
        final slotEnd = slot.endTime.hour * 60 + slot.endTime.minute;
        if (cellMinutes >= slotStart && cellMinutes < slotEnd) {
          return i;
        }
      }
    }
    return -1;
  }

  void _addSlotFromGrid(DateTime date, int hour, int minute) {
    final weekLessons =
        ref.read(weekLessonsProvider(_weekStart)).valueOrNull ?? [];
    final startMinutes = hour * 60 + minute;
    final endMinutes = startMinutes + widget.durationMinutes;

    // Overlap check
    for (final lesson in weekLessons) {
      if (lesson.date.year == date.year &&
          lesson.date.month == date.month &&
          lesson.date.day == date.day) {
        final lessonStart = _parseTimeMinutes(lesson.startTime);
        final lessonEnd = _lessonEndMinutes(lesson);
        if (startMinutes < lessonEnd && endMinutes > lessonStart) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 수업이 있는 시간입니다'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }
    }

    HapticFeedback.lightImpact();
    setState(() {
      _suggestedSlots.add(TimeSlot(
        id: 'suggest_${DateTime.now().millisecondsSinceEpoch}',
        dayOfWeek: date.weekday,
        startTime: TimeOfDay(hour: hour, minute: minute),
        endTime: TimeOfDay(
          hour: endMinutes ~/ 60,
          minute: endMinutes % 60,
        ),
        isActive: true,
        specificDate: date,
      ));
    });
  }

  Widget _buildSuggestedSlotsList() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '제안 시간 (${_suggestedSlots.length}/3)',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          ..._suggestedSlots.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.space2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium),
                  border: Border.all(
                    color:
                        AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '❶❷❸'[index],
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        slot.displayLabel,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editSlot(index),
                      icon: const Icon(Icons.edit_outlined,
                          size: 18),
                      color: AppColors.textSecondaryLight,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _suggestedSlots.removeAt(index)),
                      icon: const Icon(Icons.close, size: 18),
                      color: AppColors.error,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _editSlot(int index) async {
    final slot = _suggestedSlots[index];

    final newDate = await showDatePicker(
      context: context,
      initialDate: slot.specificDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      helpText: '날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (newDate == null || !mounted) return;

    final newStartTime = await showTimePicker(
      context: context,
      initialTime: slot.startTime,
      helpText: '시작 시간',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (newStartTime == null || !mounted) return;

    final startMinutes =
        newStartTime.hour * 60 + newStartTime.minute;
    final endMinutes = startMinutes + widget.durationMinutes;

    // Duplicate check
    final weekLessons =
        ref.read(weekLessonsProvider(_getWeekStart(newDate))).valueOrNull ??
            [];
    for (final lesson in weekLessons) {
      if (lesson.date.year == newDate.year &&
          lesson.date.month == newDate.month &&
          lesson.date.day == newDate.day) {
        final lessonStart = _parseTimeMinutes(lesson.startTime);
        final lessonEnd = _lessonEndMinutes(lesson);
        if (startMinutes < lessonEnd && endMinutes > lessonStart) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이미 수업이 있는 시간입니다'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }
    }

    setState(() {
      _suggestedSlots[index] = TimeSlot(
        id: slot.id,
        dayOfWeek: newDate.weekday,
        startTime: newStartTime,
        endTime: TimeOfDay(
          hour: endMinutes ~/ 60,
          minute: endMinutes % 60,
        ),
        isActive: true,
        specificDate: newDate,
      );
    });
  }

  void _submit() {
    Navigator.pop(context, _suggestedSlots);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
