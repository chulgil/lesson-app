import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../providers/week_lessons_provider.dart';
import '../widgets/alternative_time_grid.dart';

/// Result from the schedule change slot selection screen.
typedef ScheduleChangeSlotResult = ({String message, List<TimeSlot> slots});

/// Parameters for navigating to this screen.
class ScheduleChangeSlotParams {
  final String teacherId;
  final String studentId;
  final int durationMinutes;
  final String currentScheduleLabel;

  /// When true, selected slots represent recurring weekly schedules
  /// (e.g., "매주 일 10:00"). Accepted slot becomes the new fixed schedule.
  final bool isBulkChange;

  const ScheduleChangeSlotParams({
    required this.teacherId,
    required this.studentId,
    required this.durationMinutes,
    required this.currentScheduleLabel,
    this.isBulkChange = false,
  });
}

/// Screen for selecting alternative time slots for a single lesson change.
///
/// Reuses [AlternativeTimeGrid] from the decline/counter-propose flow.
/// Shows teacher's weekly schedule and allows selecting up to 3 slots.
class ScheduleChangeSlotScreen extends ConsumerStatefulWidget {
  final ScheduleChangeSlotParams params;

  const ScheduleChangeSlotScreen({super.key, required this.params});

  @override
  ConsumerState<ScheduleChangeSlotScreen> createState() =>
      _ScheduleChangeSlotScreenState();
}

class _ScheduleChangeSlotScreenState
    extends ConsumerState<ScheduleChangeSlotScreen> {
  late DateTime _weekStart;
  final List<TimeSlot> _suggestedSlots = [];
  final _messageController = TextEditingController();

  ScheduleChangeSlotParams get params => widget.params;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(
      weekLessonsWithPreviewProvider((
        weekStart: _weekStart,
        teacherId: params.teacherId,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          params.isBulkChange
              ? AppStrings.scheduleChangeRegularTitle
              : AppStrings.scheduleChangeSlotTitle,
        ),
      ),
      body: Column(
        children: [
          // Current schedule info
          _buildCurrentScheduleInfo(),
          // Bulk change info banner
          if (params.isBulkChange) _buildBulkChangeInfo(),
          // Week navigation
          _buildWeekNavigation(),
          // Grid
          Expanded(
            child: lessonsAsync.when(
              data: (lessons) => _buildGrid(lessons),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
          // Suggested slots list
          if (_suggestedSlots.isNotEmpty) _buildSuggestedSlotsList(),
          // Message + Submit
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildBulkChangeInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space1,
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              AppStrings.bulkChangeSlotGuide,
              style: AppTypography.caption.copyWith(color: AppColors.paperAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScheduleInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: AppColors.inkSecondary, size: 20),
          const SizedBox(width: AppSpacing.space2),
          Text(
            '${AppStrings.scheduleChangeCurrentSchedule}: ',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          Text(params.currentScheduleLabel, style: AppTypography.button),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                () => setState(() {
                  _weekStart = _weekStart.subtract(const Duration(days: 7));
                }),
          ),
          Text(
            '${_weekStart.month}/${_weekStart.day} - '
            '${weekEnd.month}/${weekEnd.day}',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                () => setState(() {
                  _weekStart = _weekStart.add(const Duration(days: 7));
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Lesson> lessons) {
    return AlternativeTimeGrid(
      weekStart: _weekStart,
      lessons: lessons,
      suggestedSlots: _suggestedSlots,
      maxSlots: 3,
      onEmptyCellTap: _addSlotFromGrid,
    );
  }

  void _addSlotFromGrid(({DateTime date, int hour, int minute}) cellInfo) {
    if (_suggestedSlots.length >= 3) {
      showInfoSnackBar(context, AppStrings.maxSlotsReached);
      return;
    }

    final endMinute = cellInfo.minute + params.durationMinutes;
    final endHour = cellInfo.hour + endMinute ~/ 60;
    final endMin = endMinute % 60;

    final slot = TimeSlot(
      id: 'slot_${DateTime.now().millisecondsSinceEpoch}',
      dayOfWeek: cellInfo.date.weekday % 7,
      startTime: TimeOfDay(hour: cellInfo.hour, minute: cellInfo.minute),
      endTime: TimeOfDay(hour: endHour, minute: endMin),
      isActive: true,
      specificDate: cellInfo.date,
    );

    setState(() => _suggestedSlots.add(slot));
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
            '${AppStrings.scheduleChangePropose} (${_suggestedSlots.length}/3)',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          ...List.generate(_suggestedSlots.length, (i) {
            final slot = _suggestedSlots[i];
            final circleNumbers = ['\u2776', '\u2777', '\u2778'];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space1),
              child: Row(
                children: [
                  Text(
                    circleNumbers[i],
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      params.isBulkChange
                          ? '${AppStrings.everyWeek} ${slot.displayLabel}'
                          : slot.displayLabel,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed:
                        () => setState(() => _suggestedSlots.removeAt(i)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space3,
        top: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border(
          top: BorderSide(color: AppColors.inkQuaternary, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _messageController,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                hintText:
                    params.isBulkChange
                        ? AppStrings.scheduleChangeBulkDesc
                        : AppStrings.scheduleChangeSingleDesc,
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.space3),
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _suggestedSlots.isEmpty ? null : _submit,
                child: Text(AppStrings.scheduleChangePropose),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final result = (
      message: _messageController.text.trim(),
      slots: List<TimeSlot>.from(_suggestedSlots),
    );
    Navigator.pop(context, result);
  }
}
