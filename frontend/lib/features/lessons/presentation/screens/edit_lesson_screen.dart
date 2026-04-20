// Screen for editing an existing lesson with real data.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
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
    final profileColor = student?.profileColor ?? AppColors.textTertiaryLight;

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
      return Scaffold(
        appBar: AppBar(title: const Text('레슨 수정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('레슨 수정'),
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
                        Icon(Icons.event_busy, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.space2),
                        const Text('레슨 취소'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error),
                        const SizedBox(width: AppSpacing.space2),
                        Text('레슨 삭제', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
          ),
          TextButton(
            onPressed: (_hasChanges && !_isSaving) ? _saveLesson : null,
            child: Text(
              '저장',
              style: TextStyle(
                color:
                    (_hasChanges && !_isSaving)
                        ? null
                        : AppColors.textTertiaryLight,
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
              // Student info (read-only)
              const LessonFormSectionTitle('학생'),
              const SizedBox(height: AppSpacing.space3),
              if (_selectedStudent != null)
                EditLessonStudentCard(
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
              const LessonFormSectionTitle('일시'),
              const SizedBox(height: AppSpacing.space3),
              LessonDateTimeSection(
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                onDateTap: _selectDate,
                onTimeTap: _selectTime,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Lesson duration
              const LessonFormSectionTitle('레슨 시간'),
              const SizedBox(height: AppSpacing.space3),
              LessonDurationSelector(
                selectedDuration: _lessonDuration,
                onDurationChanged: (value) {
                  setState(() {
                    _lessonDuration = value;
                    _hasChanges = true;
                  });
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Lesson content
              const LessonFormSectionTitle('레슨 내용'),
              const SizedBox(height: AppSpacing.space3),
              LessonContentFields(
                pieceController: _pieceController,
                notesController: _notesController,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Reminder settings
              LessonReminderSection(
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
                              color: Colors.white,
                            ),
                          )
                          : const Text('변경사항 저장'),
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
            content: Text('${_selectedStudent?.name ?? ''} 학생의 레슨이 취소되었습니다'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.warning,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('레슨 취소에 실패했습니다. 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
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
            content: Text('레슨이 삭제되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('레슨 삭제에 실패했습니다. 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
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
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('시간 충돌'),
            content: Text(
              "해당 시간에 이미 '$conflictStudentName' 레슨이 있습니다. 계속하시겠습니까?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('계속'),
              ),
            ],
          ),
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
            content: const Text('레슨 정보가 수정되었습니다'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.practiceGood,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('레슨 수정에 실패했습니다. 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
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
