import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/domain/value_objects/clock_time.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/presentation/extensions/clock_time_ui_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../auth/auth_facade.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/teacher_availability_providers.dart';
import '../providers/week_lessons_provider.dart';
import '../screens/suggest_alternative_screen.dart'
    show SuggestAlternativeResult;
import 'alternative_time_grid.dart';
import 'reject_message_bottom_sheet.dart';
import 'suggest_alternative/suggest_alternative_bottom_section.dart';
import 'suggest_alternative/suggest_alternative_conflict.dart';
import 'suggest_alternative/suggest_alternative_header.dart';
import 'suggest_alternative/suggest_alternative_preferred_slots_section.dart';
import 'suggest_alternative/suggest_alternative_suggested_slots_list.dart';
import 'suggest_alternative/suggest_alternative_week_nav.dart';

/// Shows the counter-propose / re-proposal bottom sheet.
///
/// Bottom-sheet counterpart of [SuggestAlternativeScreen] (P1-4 first
/// increment) — same weekly schedule grid, preferred-slot accept mode, and
/// reject flow, presented as a self-surfaced sheet instead of a pushed
/// full-screen route. Returns [SuggestAlternativeResult] or null if
/// dismissed.
Future<SuggestAlternativeResult?> showSuggestAlternativeBottomSheet(
  BuildContext context, {
  required String message,
  required int durationMinutes,
  String? teacherId,
  bool isStudentView = false,
  List<PreferredTimeSlot> preferredSlots = const [],
}) {
  return showNotebookModalBottomSheet<SuggestAlternativeResult>(
    context: context,
    isScrollControlled: true,
    builder:
        (_) => _SuggestAlternativeBottomSheet(
          message: message,
          durationMinutes: durationMinutes,
          teacherId: teacherId,
          isStudentView: isStudentView,
          preferredSlots: preferredSlots,
        ),
  );
}

/// Self-surfaced bottom sheet — same weekly grid + preferred-slot logic as
/// [SuggestAlternativeScreen], reusing [AlternativeTimeGrid] and the shared
/// [showRejectMessageBottomSheet] reject step.
///
/// UI sections live in `widgets/suggest_alternative/` (P1-4 file-size
/// split, golden-principles #5) — this class owns state and orchestration
/// only.
class _SuggestAlternativeBottomSheet extends ConsumerStatefulWidget {
  final String message;
  final int durationMinutes;
  final String? teacherId;
  final bool isStudentView;
  final List<PreferredTimeSlot> preferredSlots;

  const _SuggestAlternativeBottomSheet({
    required this.message,
    required this.durationMinutes,
    this.teacherId,
    this.isStudentView = false,
    this.preferredSlots = const [],
  });

  @override
  ConsumerState<_SuggestAlternativeBottomSheet> createState() =>
      _SuggestAlternativeBottomSheetState();
}

class _SuggestAlternativeBottomSheetState
    extends ConsumerState<_SuggestAlternativeBottomSheet> {
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

  /// Compute highlight for the selected preferred slot (for grid display).
  PreferredTimeSlotHighlight? get _selectedHighlight {
    if (_selectedPreferredIndex == null) return null;
    final sorted = [...widget.preferredSlots]
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final selected = sorted.firstWhere(
      (s) => s.priority == _selectedPreferredIndex,
      orElse: () => sorted.first,
    );
    final selectedDate = dateForPreferredSlot(selected, _weekStart);
    if (selectedDate == null) return null;

    return PreferredTimeSlotHighlight(
      date: selectedDate,
      startMinutes: _parseTimeMinutes(selected.startTime),
      endMinutes: _parseTimeMinutes(selected.endTime),
    );
  }

  String get _effectiveTeacherId =>
      widget.teacherId ?? ref.read(currentUserIdProvider);

  /// Current value of the teacher's availability (vacation + operating
  /// hours) for #526 window conflict checks. Read non-blocking — when the
  /// provider is still loading or errored we get null and the check is
  /// skipped rather than blocking the UI.
  TeacherAvailability? _teacherAvailability() =>
      ref.watch(teacherAvailabilityProvider(_effectiveTeacherId)).valueOrNull;

  @override
  Widget build(BuildContext context) {
    final teacherId = _effectiveTeacherId;
    final weekLessonsAsync = ref.watch(
      weekLessonsWithPreviewProvider((
        weekStart: _weekStart,
        teacherId: teacherId,
      )),
    );
    final mq = MediaQuery.of(context);

    return Container(
      // proposal_bottom_sheet / schedule_change_slot_bottom_sheet 패턴 —
      // maxHeight 으로 sheet 상한 고정. FractionallySizedBox 금지 (scrim 삼킴).
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
      decoration: const BoxDecoration(color: AppColors.paperDark),
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.space3),
              child: Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),
            ),
            const SizedBox(height: AppSpacing.space2),
            buildSuggestAlternativeHeader(
              onClose: () => Navigator.of(context).pop(),
            ),

            // Student's preferred slots (if any)
            if (widget.preferredSlots.isNotEmpty)
              buildSuggestAlternativePreferredSlotsSection(
                preferredSlots: widget.preferredSlots,
                currentWeekLessons: weekLessonsAsync.valueOrNull ?? [],
                availability: _teacherAvailability(),
                weekStart: _weekStart,
                selectedPreferredIndex: _selectedPreferredIndex,
                onSlotTap: _handlePreferredSlotTap,
              ),

            // Week navigation
            buildSuggestAlternativeWeekNav(
              weekStart: _weekStart,
              onPrevWeek:
                  () => setState(() {
                    _weekStart = _weekStart.subtract(const Duration(days: 7));
                  }),
              onNextWeek:
                  () => setState(() {
                    _weekStart = _weekStart.add(const Duration(days: 7));
                  }),
            ),

            // Grid
            Flexible(
              child: weekLessonsAsync.when(
                data:
                    (lessons) => AlternativeTimeGrid(
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
                error:
                    (e, _) =>
                        Center(child: Text('${AppStrings.loadFailed}: $e')),
              ),
            ),

            // Suggested slots list (hidden in accept mode)
            if (_suggestedSlots.isNotEmpty && !_isAcceptMode)
              buildSuggestAlternativeSuggestedSlotsList(
                suggestedSlots: _suggestedSlots,
                onEdit: _editSlot,
                onRemove: _removeSuggestedSlot,
              ),

            buildSuggestAlternativeBottomSection(
              messageController: _messageController,
              isAcceptMode: _isAcceptMode,
              lessons:
                  ref
                      .watch(
                        weekLessonsWithPreviewProvider((
                          weekStart: _weekStart,
                          teacherId: _effectiveTeacherId,
                        )),
                      )
                      .valueOrNull ??
                  [],
              availability: _teacherAvailability(),
              preferredSlots: widget.preferredSlots,
              selectedPreferredIndex: _selectedPreferredIndex,
              weekStart: _weekStart,
              suggestedSlotsCount: _suggestedSlots.length,
              onSubmitAccept: _submitAccept,
              onReject: _showRejectBottomSheet,
              onSubmitPropose:
                  _suggestedSlots.isNotEmpty ? _submitPropose : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Tapping a preferred-slot card toggles accept mode for that slot.
  void _handlePreferredSlotTap(PreferredTimeSlot slot) {
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
        final selectedDate = dateForPreferredSlot(slot, _weekStart);
        if (selectedDate != null) {
          _weekStart = _getWeekStart(selectedDate);
        }
      }
    });
  }

  /// Show reject bottom sheet with message input — stacks on top of this
  /// sheet, same as [SuggestAlternativeScreen]'s reject step.
  Future<void> _showRejectBottomSheet() async {
    final result = await showRejectMessageBottomSheet(context);

    if (result != null && mounted) {
      Navigator.pop<SuggestAlternativeResult>(context, (
        message: result,
        slots: <TimeSlot>[],
        acceptedSlotIndex: null,
      ));
    }
  }

  /// ref.read (not `_teacherAvailability()`'s watch) — called from event
  /// handlers (_addSlotFromGrid/_editSlot), not during build.
  String? _windowConflictMessage(
    DateTime date,
    int startMinutes,
    int endMinutes,
  ) {
    final availability =
        ref.read(teacherAvailabilityProvider(_effectiveTeacherId)).valueOrNull;
    return windowConflictMessage(
      availability: availability,
      date: date,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );
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
    final windowMessage = _windowConflictMessage(
      date,
      startMinutes,
      endMinutes,
    );
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
          endTime:
              TimeOfDay(
                hour: endMinutes ~/ 60,
                minute: endMinutes % 60,
              ).toClockTime(),
          isActive: true,
          specificDate: date,
        ),
      ];
    });
  }

  void _removeSuggestedSlot(int index) {
    setState(() {
      _suggestedSlots = [
        ..._suggestedSlots.sublist(0, index),
        ..._suggestedSlots.sublist(index + 1),
      ];
    });
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
          endTime:
              TimeOfDay(
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
