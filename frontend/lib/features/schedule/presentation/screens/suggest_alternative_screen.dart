import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/week_lessons_provider.dart';
import '../widgets/alternative_time_grid.dart';

/// Result type for this screen.
/// - slots not empty + acceptedSlotIndex == null → propose alternatives
/// - slots empty + acceptedSlotIndex == null → reject
/// - acceptedSlotIndex != null → accept student's preferred slot directly
typedef SuggestAlternativeResult =
    ({String message, List<TimeSlot> slots, int? acceptedSlotIndex});

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

  int _parseTimeMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int _lessonEndMinutes(Lesson lesson) =>
      _parseTimeMinutes(lesson.startTime) + lesson.duration;

  bool get _isAcceptMode => _selectedPreferredIndex != null;

  /// Check if a preferred slot conflicts with existing lessons.
  /// Returns: null=no conflict, 'confirmed'=hard conflict, 'preview'=preview conflict
  String? _checkSlotConflict(PreferredTimeSlot slot, List<Lesson> lessons) {
    if (slot.date == null) return null;
    final slotDate = slot.date!;
    final startParts = slot.startTime.split(':');
    final endParts = slot.endTime.split(':');
    final slotStart = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final slotEnd = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    for (final lesson in lessons) {
      if (lesson.date.year == slotDate.year &&
          lesson.date.month == slotDate.month &&
          lesson.date.day == slotDate.day) {
        final lessonParts = lesson.startTime.split(':');
        final lessonStart =
            int.parse(lessonParts[0]) * 60 + int.parse(lessonParts[1]);
        final lessonEnd = lessonStart + lesson.duration;
        if (slotStart < lessonEnd && slotEnd > lessonStart) {
          return lesson.isPreview ? 'preview' : 'confirmed';
        }
      }
    }
    return null;
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
    if (selected.date == null) return null;

    final startParts = selected.startTime.split(':');
    final endParts = selected.endTime.split(':');
    return PreferredTimeSlotHighlight(
      date: selected.date!,
      startMinutes: int.parse(startParts[0]) * 60 + int.parse(startParts[1]),
      endMinutes: int.parse(endParts[0]) * 60 + int.parse(endParts[1]),
    );
  }

  String get _effectiveTeacherId =>
      widget.teacherId ?? ref.read(currentUserIdProvider) ?? 'teacher_1';

  @override
  Widget build(BuildContext context) {
    final teacherId = _effectiveTeacherId;
    final weekLessonsAsync = ref.watch(
      weekLessonsWithPreviewProvider((
        weekStart: _weekStart,
        teacherId: teacherId,
      )),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: Text(AppStrings.counterPropose),
      ),
      body: Column(
        children: [
          // Student's preferred slots (if any)
          if (widget.preferredSlots.isNotEmpty)
            _buildPreferredSlotsSection(weekLessonsAsync.valueOrNull ?? []),

          // Week navigation
          _buildWeekNav(),

          // Grid
          Expanded(
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
                  (e, _) => Center(child: Text('${AppStrings.loadFailed}: $e')),
            ),
          ),

          // Suggested slots list (hidden in accept mode)
          if (_suggestedSlots.isNotEmpty && !_isAcceptMode)
            _buildSuggestedSlotsList(),

          // Bottom section: message + buttons
          _buildBottomSection(),
        ],
      ),
    );
  }

  /// Student's preferred time slots as selectable cards.
  Widget _buildPreferredSlotsSection(List<Lesson> currentWeekLessons) {
    final sorted = [...widget.preferredSlots]
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space3,
        AppSpacing.screenPadding,
        AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: AppSpacing.iconSM,
                color: AppColors.info,
              ),
              const SizedBox(width: AppSpacing.space1),
              Text(
                AppStrings.studentPreferredSlots,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ...sorted.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;
            final isSelected = _selectedPreferredIndex == slot.priority;
            final conflict = _checkSlotConflict(slot, currentWeekLessons);

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
                      if (slot.date != null) {
                        _weekStart = _getWeekStart(slot.date!);
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
                    color:
                        isSelected
                            ? AppColors.success.withValues(alpha: 0.08)
                            : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.success
                              : AppColors.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.success
                                  : AppColors.info.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child:
                              isSelected
                                  ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                  : Text(
                                    '${index + 1}',
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.info,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          slot.displayLabel,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? AppColors.success
                                    : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      // Conflict hint
                      if (conflict == 'confirmed') ...[
                        const SizedBox(width: AppSpacing.space1),
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          AppStrings.slotConflict,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ] else if (conflict == 'preview') ...[
                        const SizedBox(width: AppSpacing.space1),
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          AppStrings.previewConflict,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
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
  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space3,
        AppSpacing.screenPadding,
        MediaQuery.of(context).padding.bottom + AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message input (same style as chat input)
          TextField(
            controller: _messageController,
            maxLines: _isAcceptMode ? 2 : 8,
            minLines: 1,
            maxLength: 200,
            style: AppTypography.bodySmall,
            decoration: InputDecoration(
              hintText:
                  _isAcceptMode
                      ? AppStrings.acceptMessageHint
                      : AppStrings.messageHint,
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.borderLight),
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
              )
              : _buildProposeButtons(),
        ],
      ),
    );
  }

  /// Accept mode: confirm button — 3 states:
  /// - null conflict: green "이 일정으로 확정"
  /// - 'preview' conflict: warning "프리뷰 겹침 — 확정" (enabled)
  /// - 'confirmed' conflict: disabled "일정 겹침"
  Widget _buildAcceptButton(List<Lesson> lessons) {
    final selectedSlot = widget.preferredSlots.firstWhere(
      (s) => s.priority == _selectedPreferredIndex,
      orElse: () => widget.preferredSlots.first,
    );
    final conflict = _checkSlotConflict(selectedSlot, lessons);
    final hasHardConflict = conflict == 'confirmed';
    final hasPreviewConflict = conflict == 'preview';

    final Color bgColor;
    final IconData icon;
    final String label;

    if (hasHardConflict) {
      bgColor = AppColors.error;
      icon = Icons.block;
      label = AppStrings.slotConflict;
    } else if (hasPreviewConflict) {
      bgColor = AppColors.warning;
      icon = Icons.warning_amber_rounded;
      label = AppStrings.previewConflictConfirm;
    } else {
      bgColor = AppColors.success;
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
          style: AppTypography.buttonSmall.copyWith(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeightSmall),
          backgroundColor: bgColor,
          disabledBackgroundColor: AppColors.scheduleMutedAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
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
              side: const BorderSide(color: AppColors.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Text(
              AppStrings.rejectAction,
              style: AppTypography.buttonSmall.copyWith(
                color: AppColors.textSecondaryLight,
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
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.scheduleMutedAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Text(
              _suggestedSlots.isEmpty
                  ? AppStrings.selectTimePrompt
                  : AppStrings.proposeAction(_suggestedSlots.length),
              style: AppTypography.buttonSmall.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Show reject bottom sheet with message input.
  Future<void> _showRejectBottomSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
            onPressed:
                () => setState(() {
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
            onPressed:
                () => setState(() {
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

    setState(() {
      _suggestedSlots = [
        ..._suggestedSlots,
        TimeSlot(
          id: 'suggest_${DateTime.now().millisecondsSinceEpoch}',
          dayOfWeek: date.weekday,
          startTime: TimeOfDay(hour: hour, minute: minute),
          endTime: TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60),
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
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
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
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: AppColors.textSecondaryLight,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed:
                          () => setState(() {
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
      helpText: AppStrings.selectDate,
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.confirm,
    );
    if (newDate == null || !mounted) return;

    final newStartTime = await showTimePicker(
      context: context,
      initialTime: slot.startTime,
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

    setState(() {
      _suggestedSlots = [
        ..._suggestedSlots.sublist(0, index),
        TimeSlot(
          id: slot.id,
          dayOfWeek: newDate.weekday,
          startTime: newStartTime,
          endTime: TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60),
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
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLarge),
        ),
      ),
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
          Text(
            AppStrings.rejectBottomSheetTitle,
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: AppSpacing.space2),

          // Guide text
          Text(
            AppStrings.rejectBottomSheetGuide,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
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
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: Text(
                AppStrings.rejectSendAndClose,
                style: AppTypography.buttonSmall.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
