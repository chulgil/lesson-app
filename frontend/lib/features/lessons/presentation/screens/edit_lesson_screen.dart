// Screen for editing an existing lesson with real data.

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../students/students_facade.dart';
import '../../../students/presentation/extensions/student_domain_visuals.dart';
import '../extensions/lesson_visuals.dart';
import '../providers/lesson_crud_provider.dart';
import '../widgets/lesson_form_widgets.dart';

/// Screen for editing an existing lesson
class EditLessonScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const EditLessonScreen({super.key, required this.lessonId});

  @override
  ConsumerState<EditLessonScreen> createState() => _EditLessonScreenState();
}

class _EditLessonScreenState extends ConsumerState<EditLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pieceController = TextEditingController();
  final _notesController = TextEditingController();

  EditLessonStudentInfo? _selectedStudent;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  int _lessonDuration = 60;
  bool _enableReminder = true;
  int _reminderMinutes = 30;

  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isSaving = false;
  Lesson? _originalLesson;

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  Future<void> _loadLessonData() async {
    final lesson = await ref.read(lessonProvider(widget.lessonId).future);
    if (lesson == null || !mounted) return;

    _originalLesson = lesson;

    // Load student info for profile color
    final student = await ref.read(studentProvider(lesson.studentId).future);
    final profileColor = student?.profileColor ?? AppColors.inkTertiary;

    // Parse startTime "HH:mm" to TimeOfDay
    final timeParts = lesson.startTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 14;
    final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

    if (mounted) {
      setState(() {
        _selectedStudent = EditLessonStudentInfo(
          id: lesson.studentId,
          name: lesson.studentName,
          instrument: lesson.instrument,
          color: profileColor,
        );
        _selectedDate = lesson.date;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
        _lessonDuration = lesson.duration;
        _pieceController.text =
            lesson.pieces.isNotEmpty ? lesson.pieces.first.displayName : '';
        _notesController.text = lesson.feedback ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pieceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return NotebookScreenScaffold(
        appBar: AppBar(title: const Text(AppStrings.editLessonTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isSubscriptionLesson = _originalLesson?.subscriptionId != null;

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editLessonTitle),
        leading: IconButton(
          onPressed:
              () => showEditLessonExitConfirmation(
                context: context,
                hasChanges: _hasChanges,
                onExit: () => context.pop(),
              ),
          icon: const Icon(Icons.close),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'cancel':
                  _showCancelDialog();
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.event_busy, color: AppColors.paperAccent),
                        const SizedBox(width: AppSpacing.space2),
                        const Text(AppStrings.actionLessonCancel),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: AppColors.paperAccent,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Text(
                          AppStrings.deleteLessonTitle,
                          style: TextStyle(color: AppColors.paperAccent),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
          TextButton(
            onPressed: (_hasChanges && !_isSaving) ? _saveLesson : null,
            child: Text(
              AppStrings.save,
              style: TextStyle(
                color:
                    (_hasChanges && !_isSaving) ? null : AppColors.inkTertiary,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: _markChanged,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subscription lesson info banner
              if (isSubscriptionLesson)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.space4),
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.paperDark,
                    border: Border.all(color: AppColors.inkQuaternary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.inkTertiary,
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          Expanded(
                            child: Text(
                              AppStrings.subscriptionFieldLocked,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      GestureDetector(
                        onTap:
                            () => context.push(
                              AppRoutes.subscriptionDetail.replaceFirst(
                                ':id',
                                _originalLesson!.subscriptionId!,
                              ),
                              extra: {'viewerRole': 'teacher'},
                            ),
                        child: Text(
                          AppStrings.goToScheduleChange,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.paperAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Student info (read-only for subscription lessons, also read-only for manual)
              const LessonFormSectionTitle(AppStrings.student),
              const SizedBox(height: AppSpacing.space3),
              if (_selectedStudent != null)
                isSubscriptionLesson
                    ? _LockedFieldWrapper(
                      child: EditLessonStudentCard(
                        student: _selectedStudent!,
                        onViewProfile: () {
                          context.push(
                            AppRoutes.studentDetail.replaceFirst(
                              ':id',
                              _selectedStudent!.id,
                            ),
                          );
                        },
                      ),
                    )
                    : EditLessonStudentCard(
                      student: _selectedStudent!,
                      onViewProfile: () {
                        context.push(
                          AppRoutes.studentDetail.replaceFirst(
                            ':id',
                            _selectedStudent!.id,
                          ),
                        );
                      },
                    ),

              const SizedBox(height: AppSpacing.space6),

              // Date and time selection
              const LessonFormSectionTitle(AppStrings.dateTimeLabel),
              const SizedBox(height: AppSpacing.space3),
              isSubscriptionLesson
                  ? _LockedFieldWrapper(
                    child: LessonDateTimeSection(
                      selectedDate: _selectedDate,
                      selectedTime: _selectedTime,
                      onDateTap: () {},
                      onTimeTap: () {},
                    ),
                  )
                  : LessonDateTimeSection(
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    onDateTap: _selectDate,
                    onTimeTap: _selectTime,
                  ),

              const SizedBox(height: AppSpacing.space6),

              // Lesson duration
              const LessonFormSectionTitle(AppStrings.lessonDurationLabel),
              const SizedBox(height: AppSpacing.space3),
              isSubscriptionLesson
                  ? _LockedFieldWrapper(
                    child: LessonDurationSelector(
                      selectedDuration: _lessonDuration,
                      onDurationChanged: (_) {},
                    ),
                  )
                  : LessonDurationSelector(
                    selectedDuration: _lessonDuration,
                    onDurationChanged: (value) {
                      setState(() {
                        _lessonDuration = value;
                        _hasChanges = true;
                      });
                    },
                  ),

              const SizedBox(height: AppSpacing.space6),

              // Lesson content — always editable
              const LessonFormSectionTitle(AppStrings.lessonContentLabel),
              const SizedBox(height: AppSpacing.space3),
              LessonContentFields(
                pieceController: _pieceController,
                notesController: _notesController,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Reminder settings
              isSubscriptionLesson
                  ? _LockedFieldWrapper(
                    child: LessonReminderSection(
                      enableReminder: _enableReminder,
                      onReminderChanged: (_) {},
                      reminderMinutes: _reminderMinutes,
                      onReminderTimeChanged: (_) {},
                    ),
                  )
                  : LessonReminderSection(
                    enableReminder: _enableReminder,
                    onReminderChanged: (value) {
                      setState(() {
                        _enableReminder = value;
                        _hasChanges = true;
                      });
                    },
                    reminderMinutes: _reminderMinutes,
                    onReminderTimeChanged: (value) {
                      setState(() {
                        _reminderMinutes = value;
                        _hasChanges = true;
                      });
                    },
                  ),

              const SizedBox(height: AppSpacing.space8),

              // Save button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: (_hasChanges && !_isSaving) ? _saveLesson : null,
                  child:
                      _isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              // Notebook × Score §7.50: Vermillion CTA foreground = paper.
                              color: AppColors.paper,
                            ),
                          )
                          : const Text(AppStrings.saveChangesButton),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),

              // Cancel/Delete buttons
              LessonActionButtons(
                onCancel: _showCancelDialog,
                onDelete: _showDeleteDialog,
              ),

              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await selectLessonDateForEdit(context, _selectedDate);
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await selectLessonTime(context, _selectedTime);
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _hasChanges = true;
      });
    }
  }

  void _showCancelDialog() {
    if (_selectedStudent == null) return;
    showCancelLessonDialog(
      context: context,
      studentName: _selectedStudent!.name,
      lessonDate: _selectedDate,
      lessonTime: _selectedTime,
      onConfirm: _cancelLesson,
    );
  }

  void _showDeleteDialog() {
    showDeleteLessonDialog(context: context, onConfirm: _deleteLesson);
  }

  Future<void> _cancelLesson() async {
    try {
      await ref
          .read(lessonsNotifierProvider.notifier)
          .cancelLesson(widget.lessonId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.lessonCancelledForStudent(
                _selectedStudent?.name ?? '',
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperAccent,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.cancelLessonFailedRetry),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteLesson() async {
    try {
      await ref
          .read(lessonsNotifierProvider.notifier)
          .deleteLesson(widget.lessonId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.lessonDeletedMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.deleteLessonFailedRetry),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  /// Check if the edited lesson conflicts with existing lessons on the same day.
  /// Excludes the lesson being edited (by lessonId).
  /// Returns the conflicting lesson's student name, or null if no conflict.
  String? _findConflict(
    DateTime date,
    TimeOfDay time,
    int duration,
    List<Lesson> existingLessons,
    String excludeLessonId,
  ) {
    final newStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final newEnd = newStart.add(Duration(minutes: duration));

    for (final lesson in existingLessons) {
      if (lesson.id == excludeLessonId) continue;

      if (lesson.date.year == date.year &&
          lesson.date.month == date.month &&
          lesson.date.day == date.day) {
        final parts = lesson.startTime.split(':');
        if (parts.length < 2) continue;
        final lessonStart = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        final lessonEnd = lessonStart.add(Duration(minutes: lesson.duration));

        if (newStart.isBefore(lessonEnd) && newEnd.isAfter(lessonStart)) {
          return lesson.studentName;
        }
      }
    }
    return null;
  }

  /// Show a confirmation dialog when a time conflict is detected.
  /// Returns true if the user chooses to proceed.
  Future<bool> _showConflictDialog(String conflictStudentName) async {
    final result = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.timeConflictTitle,
      content: Text(AppStrings.timeConflictMessage(conflictStudentName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.continueAction),
        ),
      ],
    );
    return result ?? false;
  }

  Future<void> _saveLesson() async {
    if (_originalLesson == null) return;

    // Check for time conflicts with existing lessons (excluding self)
    final existingLessons = ref.read(lessonsProvider).valueOrNull ?? [];
    final conflictName = _findConflict(
      _selectedDate,
      _selectedTime,
      _lessonDuration,
      existingLessons,
      widget.lessonId,
    );
    if (conflictName != null) {
      final shouldProceed = await _showConflictDialog(conflictName);
      if (!shouldProceed) return;
    }

    setState(() => _isSaving = true);

    try {
      final timeStr =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      final updatedLesson = _originalLesson!.copyWith(
        date: _selectedDate,
        startTime: timeStr,
        duration: _lessonDuration,
        feedback:
            _notesController.text.isNotEmpty ? _notesController.text : null,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(lessonsNotifierProvider.notifier)
          .updateLesson(updatedLesson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.editLessonSuccess),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperOk,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.editLessonFailedRetry),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Grey overlay wrapper that disables interaction for subscription-locked fields.
///
/// Notebook × Score: paperDark background tint + inkTertiary foreground.
class _LockedFieldWrapper extends StatelessWidget {
  final Widget child;

  const _LockedFieldWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.55,
        child: ColoredBox(color: AppColors.paperDark, child: child),
      ),
    );
  }
}
