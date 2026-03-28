import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../providers/week_lessons_provider.dart';
import '../widgets/alternative_time_grid.dart';

/// Screen for suggesting alternative time slots via a weekly schedule grid.
///
/// Shows the teacher's existing lessons and allows tapping empty cells
/// to add suggested time slots (up to 3). Each slot can be edited or removed.
class SuggestAlternativeScreen extends ConsumerStatefulWidget {
  final String message;
  final int durationMinutes;
  final String? teacherId;
  final bool isStudentView;

  const SuggestAlternativeScreen({
    super.key,
    required this.message,
    required this.durationMinutes,
    this.teacherId,
    this.isStudentView = false,
  });

  @override
  ConsumerState<SuggestAlternativeScreen> createState() =>
      _SuggestAlternativeScreenState();
}

class _SuggestAlternativeScreenState
    extends ConsumerState<SuggestAlternativeScreen> {
  var _suggestedSlots = <TimeSlot>[];
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

  int _parseTimeMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int _lessonEndMinutes(Lesson lesson) =>
      _parseTimeMinutes(lesson.startTime) + lesson.duration;

  @override
  Widget build(BuildContext context) {
    final teacherId =
        widget.teacherId ?? ref.watch(currentUserIdProvider) ?? 'teacher_1';
    final weekLessonsAsync = ref.watch(weekLessonsProvider(_weekStart));

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
              data: (lessons) => AlternativeTimeGrid(
                weekStart: _weekStart,
                lessons: lessons,
                suggestedSlots: _suggestedSlots,
                hideStudentNames: widget.isStudentView,
                onEmptyCellTap: (cell) =>
                    _addSlotFromGrid(cell.date, cell.hour, cell.minute),
              ),
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
          showErrorSnackBar(context, '이미 수업이 있는 시간입니다');
          return;
        }
      }
    }

    setState(() {
      _suggestedSlots = [
        ..._suggestedSlots,
        TimeSlot(
          id: 'suggest_${DateTime.now().millisecondsSinceEpoch}',
          dayOfWeek: date.weekday,
          startTime: TimeOfDay(hour: hour, minute: minute),
          endTime: TimeOfDay(
            hour: endMinutes ~/ 60,
            minute: endMinutes % 60,
          ),
          isActive: true,
          specificDate: date,
        ),
      ];
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
                      ['❶', '❷', '❸'][index.clamp(0, 2)],
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
                          setState(() {
                            _suggestedSlots = [
                              ..._suggestedSlots.sublist(0, index),
                              ..._suggestedSlots.sublist(index + 1),
                            ];
                          }),
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
      _suggestedSlots = [
        ..._suggestedSlots.sublist(0, index),
        TimeSlot(
          id: slot.id,
          dayOfWeek: newDate.weekday,
          startTime: newStartTime,
          endTime: TimeOfDay(
            hour: endMinutes ~/ 60,
            minute: endMinutes % 60,
          ),
          isActive: true,
          specificDate: newDate,
        ),
        ..._suggestedSlots.sublist(index + 1),
      ];
    });
  }

  void _submit() {
    Navigator.pop(context, _suggestedSlots);
  }
}
