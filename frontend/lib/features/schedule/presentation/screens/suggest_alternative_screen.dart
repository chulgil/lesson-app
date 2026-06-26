import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/domain/value_objects/clock_time.dart';
import '../../../../core/booking/presentation/extensions/lesson_booking_visual_extensions.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/presentation/extensions/clock_time_ui_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../auth/auth_facade.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../../domain/services/schedule_window_conflict_service.dart';
import '../extensions/unified_lesson_request_visuals.dart';
import '../providers/teacher_availability_providers.dart';
import '../providers/week_lessons_provider.dart';
import '../widgets/alternative_time_grid.dart';

/// Result type for this screen.
/// - slots not empty + acceptedSlotIndex == null → propose alternatives
/// - slots empty + acceptedSlotIndex == null → reject
/// - acceptedSlotIndex != null → accept student's preferred slot directly
typedef SuggestAlternativeResult = ({
  String message,
  List<TimeSlot> slots,
  int? acceptedSlotIndex,
});

/// Screen for suggesting alternative time slots via a weekly schedule grid.
///
/// Shows the teacher's existing lessons and allows tapping empty cells
/// to add suggested time slots (up to 3). Each slot can be edited or removed.
///
/// When [preferredSlots] are provided, shows the student's preferred times
/// as selectable cards. Tapping one switches to "confirm" mode.
class SuggestAlternativeScreen extends ConsumerStatefulWidget {
  final String message;
  final int durationMinutes;
  final String? teacherId;
  final bool isStudentView;
  final List<PreferredTimeSlot> preferredSlots;

  const SuggestAlternativeScreen({
    super.key,
    required this.message,
    required this.durationMinutes,
    this.teacherId,
    this.isStudentView = false,
    this.preferredSlots = const [],
  });

  @override
  ConsumerState<SuggestAlternativeScreen> createState() =>
      _SuggestAlternativeScreenState();
}

class _SuggestAlternativeScreenState
    extends ConsumerState<SuggestAlternativeScreen> {
  var _suggestedSlots = <TimeSlot>[];
  late DateTime _weekStart;
  late TextEditingController _messageController;
  int? _selectedPreferredIndex;

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    _messageController = TextEditingController(text: widget.message);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    final diff = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - diff);
  }

  int _parseTimeMinutes(String time) => ClockTime.parse(time).inMinutes;

  int _lessonEndMinutes(Lesson lesson) =>
      _parseTimeMinutes(lesson.startTime) + lesson.duration;

  bool get _isAcceptMode => _selectedPreferredIndex != null;

  DateTime? _dateForPreferredSlot(PreferredTimeSlot slot) {
    if (slot.date != null) return slot.date;
    final dayOfWeek = slot.dayOfWeek;
    if (dayOfWeek == null) return null;
    return _weekStart.add(Duration(days: dayOfWeek.clamp(0, 6)));
  }

  /// Check if a preferred slot conflicts with the teacher's schedule.
  /// Returns: null=no conflict, 'confirmed'=hard lesson conflict,
  /// 'preview'=preview lesson conflict, 'vacation'=vacation/holiday block,
  /// 'hours'=outside operating hours (#526). Vacation/operating-hours are
  /// evaluated first so a slot the teacher is unavailable for is never reported
  /// as conflict-free just because no lesson overlaps it.
  String? _checkSlotConflict(
    PreferredTimeSlot slot,
    List<Lesson> lessons,
    TeacherAvailability? availability,
  ) {
    final slotDate = _dateForPreferredSlot(slot);
    if (slotDate == null) return null;
    final slotStart = _parseTimeMinutes(slot.startTime);
    final slotEnd = _parseTimeMinutes(slot.endTime);

    // #526 — vacation / operating-hours window check (independent of lessons).
    final window = ScheduleWindowConflictService.check(
      availability: availability,
      date: slotDate,
      startMinutes: slotStart,
      endMinutes: slotEnd,
    );
    if (window == ScheduleWindowConflict.vacation) return 'vacation';
    if (window == ScheduleWindowConflict.outsideOperatingHours) return 'hours';

    for (final lesson in lessons) {
      if (lesson.date.year == slotDate.year &&
          lesson.date.month == slotDate.month &&
          lesson.date.day == slotDate.day) {
        final lessonStart = _parseTimeMinutes(lesson.startTime);
        final lessonEnd = lessonStart + lesson.duration;
        if (slotStart < lessonEnd && slotEnd > lessonStart) {
          return lesson.isPreview ? 'preview' : 'confirmed';
        }
      }
    }
    return null;
  }

  /// Human label for a conflict code, or null when there is no conflict.
  String? _conflictLabel(String? conflict) {
    switch (conflict) {
      case 'confirmed':
        return AppStrings.slotConflict;
      case 'preview':
        return AppStrings.previewConflict;
      case 'vacation':
        return AppStrings.slotVacationConflict;
      case 'hours':
        return AppStrings.slotOutsideOperatingHours;
      default:
        return null;
    }
  }

  /// Inline warning icon + label for a conflict code (empty when no conflict).
  List<Widget> _conflictHint(String? conflict) {
    final label = _conflictLabel(conflict);
    if (label == null) return const [];
    return [
      const SizedBox(width: AppSpacing.space1),
      Icon(
        Icons.warning_amber_rounded,
        size: 16,
        color: AppColors.paperAccent,
      ),
      const SizedBox(width: 2),
      Text(
        label,
        style: AppTypography.captionSmall.copyWith(
          color: AppColors.paperAccent,
        ),
      ),
    ];
  }

  /// Compute highlight for the selected preferred slot (for grid display).
  PreferredTimeSlotHighlight? get _selectedHighlight {
    if (_selectedPreferredIndex == null) return null;
    final sorted = [...widget.preferredSlots]
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final selected = sorted.firstWhere(
      (s) => s.priority == _selectedPreferredIndex,
      orElse: () => sorted.first,
    );
    final selectedDate = _dateForPreferredSlot(selected);
    if (selectedDate == null) return null;

    return PreferredTimeSlotHighlight(
      date: selectedDate,
      startMinutes: _parseTimeMinutes(selected.startTime),
      endMinutes: _parseTimeMinutes(selected.endTime),
    );
  }

  // 2026-06-12 — `?? 'teacher_1'` 데드코드 제거 (currentUserIdProvider 는
  // 비-nullable String 이라 도달 불가였음).
  String get _effectiveTeacherId =>
      widget.teacherId ?? ref.read(currentUserIdProvider);

  /// Current value of the teacher's availability (vacation + operating
  /// hours) for #526 window conflict checks. Read non-blocking — when the
  /// provider is still loading or errored we get null and the check is
  /// skipped rather than blocking the UI.
  TeacherAvailability? _teacherAvailability() => ref
      .watch(teacherAvailabilityProvider(_effectiveTeacherId))
      .valueOrNull;

  @override
  Widget build(BuildContext context) {
    final teacherId = _effectiveTeacherId;
    final weekLessonsAsync = ref.watch(
      weekLessonsWithPreviewProvider((
        weekStart: _weekStart,
        teacherId: teacherId,
      )),
    );

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      resizeToAvoidBottomInset: true,
      appBar: const NotebookDetailAppBar(title: AppStrings.counterPropose),
      body: Column(
        children: [
          // Student's preferred slots (if any)
          if (widget.preferredSlots.isNotEmpty)
            _buildPreferredSlotsSection(
              weekLessonsAsync.valueOrNull ?? [],
              _teacherAvailability(),
            ),

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
                highlightedSlot: _selectedHighlight,
                onEmptyCellTap: (cell) {
                  if (!_isAcceptMode) {
                    _addSlotFromGrid(cell.date, cell.hour, cell.minute);
                  }
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('${AppStrings.loadFailed}: $e')),
            ),
          ),

          // Suggested slots list (hidden in accept mode)
          if (_suggestedSlots.isNotEmpty && !_isAcceptMode)
            _buildSuggestedSlotsList(),
        ],
      ),
      // Bottom section as bottomNavigationBar — stays above keyboard
      bottomNavigationBar: _buildBottomSection(),
    );
  }

  /// Student's preferred time slots as selectable cards.
  Widget _buildPreferredSlotsSection(
    List<Lesson> currentWeekLessons,
    TeacherAvailability? availability,
  ) {
    final sorted = [...widget.preferredSlots]
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space3,
        AppSpacing.screenPadding,
        AppSpacing.space2,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: AppSpacing.iconSM,
                color: AppColors.ink,
              ),
              const SizedBox(width: AppSpacing.space1),
              Text(
                AppStrings.studentPreferredSlots,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ...sorted.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;
            final isSelected = _selectedPreferredIndex == slot.priority;
            final conflict = _checkSlotConflict(
      slot,
      currentWeekLessons,
      availability,
    );

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedPreferredIndex == slot.priority) {
                      // Deselect → back to propose mode
                      _selectedPreferredIndex = null;
                      _messageController.text = widget.message;
                    } else {
                      // Select → accept mode, clear propose message
                      _selectedPreferredIndex = slot.priority;
                      _suggestedSlots = [];
                      _messageController.clear();
                      // Navigate calendar to the selected slot's week
                      final selectedDate = _dateForPreferredSlot(slot);
                      if (selectedDate != null) {
                        _weekStart = _getWeekStart(selectedDate);
                      }
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.paperOk.withValues(alpha: 0.08)
                        : AppColors.paper,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.paperOk
                          : AppColors.inkQuaternary,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.paperOk
                              : AppColors.ink.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: AppColors.paper,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          slot.displayLabel,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.paperOk
                                : AppColors.ink,
                          ),
                        ),
                      ),
                      // Conflict hint (lesson / vacation / operating hours)
                      ..._conflictHint(conflict),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Bottom section with message input and action buttons.
  /// Rendered as [bottomNavigationBar] so it stays above the keyboard.
  Widget _buildBottomSection() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.space3,
          AppSpacing.screenPadding,
          AppSpacing.space4,
        ),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.inkQuaternary)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message input (same style as chat input)
            TextField(
              controller: _messageController,
              maxLines: _isAcceptMode ? 2 : 3,
              minLines: 1,
              maxLength: 200,
              style: AppTypography.bodySmall,
              decoration: InputDecoration(
                hintText: _isAcceptMode
                    ? AppStrings.acceptMessageHint
                    : AppStrings.messageHint,
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.ink),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),

            // Action buttons
            _isAcceptMode
                ? _buildAcceptButton(
                    ref
                            .watch(
                              weekLessonsWithPreviewProvider((
                                weekStart: _weekStart,
                                teacherId: _effectiveTeacherId,
                              )),
                            )
                            .valueOrNull ??
                        [],
                    _teacherAvailability(),
                  )
                : _buildProposeButtons(),
          ],
        ),
      ),
    );
  }

  /// Accept mode: confirm button — states:
  /// - null conflict: green "이 일정으로 확정"
  /// - 'preview' conflict: warning "프리뷰 겹침 — 확정" (enabled)
  /// - 'confirmed' conflict: disabled "일정 겹침"
  /// - 'vacation'/'hours' conflict (#526): disabled with the matching reason —
  ///   the teacher cannot accept a slot inside their own vacation or outside
  ///   operating hours.
  Widget _buildAcceptButton(
    List<Lesson> lessons,
    TeacherAvailability? availability,
  ) {
    final selectedSlot = widget.preferredSlots.firstWhere(
      (s) => s.priority == _selectedPreferredIndex,
      orElse: () => widget.preferredSlots.first,
    );
    final conflict = _checkSlotConflict(selectedSlot, lessons, availability);
    final hasPreviewConflict = conflict == 'preview';
    // Lesson overlap, vacation, and outside-operating-hours all hard-block.
    final hasHardConflict =
        conflict == 'confirmed' ||
        conflict == 'vacation' ||
        conflict == 'hours';

    final Color bgColor;
    final IconData icon;
    final String label;

    if (hasHardConflict) {
      bgColor = AppColors.paperAccent;
      icon = Icons.block;
      label = _conflictLabel(conflict) ?? AppStrings.slotConflict;
    } else if (hasPreviewConflict) {
      bgColor = AppColors.paperAccent;
      icon = Icons.warning_amber_rounded;
      label = AppStrings.previewConflictConfirm;
    } else {
      bgColor = AppColors.paperOk;
      icon = Icons.check_circle;
      label = AppStrings.confirmThisSchedule;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: hasHardConflict ? null : _submitAccept,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: AppTypography.buttonSmall.copyWith(color: AppColors.paper),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeightSmall),
          backgroundColor: bgColor,
          disabledBackgroundColor: AppColors.scheduleMutedAccent,
          shape: RoundedRectangleBorder(),
        ),
      ),
    );
  }

  /// Propose mode: [거절하기] [시간을 선택하세요/제안하기]
  Widget _buildProposeButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _showRejectBottomSheet,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.buttonHeightSmall),
              side: const BorderSide(color: AppColors.inkQuaternary),
              shape: RoundedRectangleBorder(),
            ),
            child: Text(
              AppStrings.rejectAction,
              style: AppTypography.buttonSmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: ElevatedButton(
            onPressed: _suggestedSlots.isNotEmpty ? _submitPropose : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.buttonHeightSmall),
              backgroundColor: AppColors.paperAccent,
              disabledBackgroundColor: AppColors.scheduleMutedAccent,
              shape: RoundedRectangleBorder(),
            ),
            child: Text(
              AppStrings.proposeAction(_suggestedSlots.length),
              style: AppTypography.buttonSmall.copyWith(color: AppColors.paper),
            ),
          ),
        ),
      ],
    );
  }

  /// Show reject bottom sheet with message input.
  Future<void> _showRejectBottomSheet() async {
    final result = await showNotebookBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      padding: EdgeInsets.zero,
      showHandle: false,
      builder: (context) => const _RejectBottomSheet(),
    );

    if (result != null && mounted) {
      Navigator.pop<SuggestAlternativeResult>(context, (
        message: result,
        slots: <TimeSlot>[],
        acceptedSlotIndex: null,
      ));
    }
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
              _weekStart = _weekStart.subtract(const Duration(days: 7));
            }),
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
          ),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
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

  /// Localized reason a proposed window is unavailable due to the teacher's
  /// own schedule (#526), or null when the window is fine. Existing-lesson
  /// overlap is checked separately by the caller.
  String? _windowConflictMessage(
    DateTime date,
    int startMinutes,
    int endMinutes,
  ) {
    // ref.read (not _teacherAvailability()'s watch) — called from event
    // handlers (_addSlotFromGrid/_editSlot), not during build.
    final availability = ref
        .read(teacherAvailabilityProvider(_effectiveTeacherId))
        .valueOrNull;
    final window = ScheduleWindowConflictService.check(
      availability: availability,
      date: date,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );
    switch (window) {
      case ScheduleWindowConflict.vacation:
        return AppStrings.slotVacationConflict;
      case ScheduleWindowConflict.outsideOperatingHours:
        return AppStrings.slotOutsideOperatingHours;
      case ScheduleWindowConflict.none:
        return null;
    }
  }

  void _addSlotFromGrid(DateTime date, int hour, int minute) {
    if (_suggestedSlots.length >= 3) {
      showErrorSnackBar(context, AppStrings.maxSlotsReached);
      return;
    }

    final weekLessons =
        ref
            .read(
              weekLessonsWithPreviewProvider((
                weekStart: _weekStart,
                teacherId: _effectiveTeacherId,
              )),
            )
            .valueOrNull ??
        [];
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
          showErrorSnackBar(context, AppStrings.slotConflict);
          return;
        }
      }
    }

    // #526 — block proposing a slot inside the teacher's vacation or outside
    // their operating hours.
    final windowMessage = _windowConflictMessage(date, startMinutes, endMinutes);
    if (windowMessage != null) {
      showErrorSnackBar(context, windowMessage);
      return;
    }

    setState(() {
      _suggestedSlots = [
        ..._suggestedSlots,
        TimeSlot(
          id: 'suggest_${DateTime.now().millisecondsSinceEpoch}',
          dayOfWeek: date.weekday,
          startTime: TimeOfDay(hour: hour, minute: minute).toClockTime(),
          endTime: TimeOfDay(
            hour: endMinutes ~/ 60,
            minute: endMinutes % 60,
          ).toClockTime(),
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
            AppStrings.suggestedSlotsCount(_suggestedSlots.length),
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          ..._suggestedSlots.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paperAccent.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppColors.paperAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      ['❶', '❷', '❸'][index.clamp(0, 2)],
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.paperAccent,
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
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: AppColors.inkSecondary,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _suggestedSlots = [
                          ..._suggestedSlots.sublist(0, index),
                          ..._suggestedSlots.sublist(index + 1),
                        ];
                      }),
                      icon: const Icon(Icons.close, size: 18),
                      color: AppColors.paperAccent,
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
      helpText: AppStrings.selectDate,
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.confirm,
    );
    if (newDate == null || !mounted) return;

    final newStartTime = await showTimePicker(
      context: context,
      initialTime: slot.startTime.toFlutterTimeOfDay(),
      helpText: AppStrings.selectStartTime,
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.confirm,
    );
    if (newStartTime == null || !mounted) return;

    final startMinutes = newStartTime.hour * 60 + newStartTime.minute;
    final endMinutes = startMinutes + widget.durationMinutes;

    // Duplicate check
    final weekLessons =
        ref
            .read(
              weekLessonsWithPreviewProvider((
                weekStart: _getWeekStart(newDate),
                teacherId: _effectiveTeacherId,
              )),
            )
            .valueOrNull ??
        [];
    for (final lesson in weekLessons) {
      if (lesson.date.year == newDate.year &&
          lesson.date.month == newDate.month &&
          lesson.date.day == newDate.day) {
        final lessonStart = _parseTimeMinutes(lesson.startTime);
        final lessonEnd = _lessonEndMinutes(lesson);
        if (startMinutes < lessonEnd && endMinutes > lessonStart) {
          if (mounted) {
            showErrorSnackBar(context, AppStrings.slotConflict);
          }
          return;
        }
      }
    }

    // #526 — block editing a slot into the teacher's vacation or outside hours.
    final windowMessage = _windowConflictMessage(
      newDate,
      startMinutes,
      endMinutes,
    );
    if (windowMessage != null) {
      if (mounted) {
        showErrorSnackBar(context, windowMessage);
      }
      return;
    }

    setState(() {
      _suggestedSlots = [
        ..._suggestedSlots.sublist(0, index),
        TimeSlot(
          id: slot.id,
          dayOfWeek: newDate.weekday,
          startTime: newStartTime.toClockTime(),
          endTime: TimeOfDay(
            hour: endMinutes ~/ 60,
            minute: endMinutes % 60,
          ).toClockTime(),
          isActive: true,
          specificDate: newDate,
        ),
        ..._suggestedSlots.sublist(index + 1),
      ];
    });
  }

  void _submitAccept() {
    // Convert priority (1-based) to sorted index (0-based)
    final sorted = [...widget.preferredSlots]
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final sortedIndex = sorted.indexWhere(
      (s) => s.priority == _selectedPreferredIndex,
    );

    Navigator.pop<SuggestAlternativeResult>(context, (
      message: _messageController.text.trim(),
      slots: <TimeSlot>[],
      acceptedSlotIndex: sortedIndex >= 0 ? sortedIndex : 0,
    ));
  }

  void _submitPropose() {
    Navigator.pop<SuggestAlternativeResult>(context, (
      message: _messageController.text.trim(),
      slots: _suggestedSlots,
      acceptedSlotIndex: null,
    ));
  }
}

/// Bottom sheet for rejecting a lesson request with a message.
class _RejectBottomSheet extends StatefulWidget {
  const _RejectBottomSheet();

  @override
  State<_RejectBottomSheet> createState() => _RejectBottomSheetState();
}

class _RejectBottomSheetState extends State<_RejectBottomSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppStrings.declineDefaultMessage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.paper),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space3,
        AppSpacing.screenPadding,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            AppSpacing.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          const Center(
            child: BottomSheetHandle(width: 36, margin: EdgeInsets.zero),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Title
          // Notebook × Score: BottomSheetHandle 선행 커스텀 바텀시트 헤더는
          // Playfair appBarTitle 로 통일 (§7.27, 18/w700).
          Text(
            AppStrings.rejectBottomSheetTitle,
            style: NotebookTypography.appBarTitle,
          ),
          const SizedBox(height: AppSpacing.space2),

          // Guide text
          Text(
            AppStrings.rejectBottomSheetGuide,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Message input
          TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: AppStrings.messageHint,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final message = _controller.text.trim();
                if (message.isNotEmpty) {
                  Navigator.pop(context, message);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(
                  AppSpacing.buttonHeightSmall,
                ),
                backgroundColor: AppColors.paperAccent,
                shape: RoundedRectangleBorder(),
              ),
              child: Text(
                AppStrings.rejectSendAndClose,
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.paper,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
