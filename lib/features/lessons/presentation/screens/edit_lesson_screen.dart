import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/lesson_form_widgets.dart';

/// Screen for editing an existing lesson
class EditLessonScreen extends StatefulWidget {
  final String lessonId;

  const EditLessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<EditLessonScreen> createState() => _EditLessonScreenState();
}

class _EditLessonScreenState extends State<EditLessonScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  void _loadLessonData() {
    // TODO: Load from database
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _selectedStudent = _mockStudents.firstWhere(
            (s) => s.id == 'student_1',
          );
          _selectedDate = DateTime.now().add(const Duration(days: 2));
          _selectedTime = const TimeOfDay(hour: 14, minute: 0);
          _lessonDuration = 60;
          _pieceController.text = '바흐 파르티타 2번 - Allemande';
          _notesController.text = '보잉 연습에 집중';
          _enableReminder = true;
          _reminderMinutes = 30;
          _isLoading = false;
        });
      }
    });
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
          onPressed: () => showEditLessonExitConfirmation(
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
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.event_busy, color: AppColors.warning),
                    const SizedBox(width: 8),
                    const Text('레슨 취소'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('레슨 삭제', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: _hasChanges ? _saveLesson : null,
            child: Text(
              '저장',
              style: TextStyle(
                color: _hasChanges ? null : AppColors.textTertiaryLight,
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
                    context.push('/students/${_selectedStudent!.id}');
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
                  onPressed: _hasChanges ? _saveLesson : null,
                  child: const Text('변경사항 저장'),
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
    showDeleteLessonDialog(
      context: context,
      onConfirm: _deleteLesson,
    );
  }

  void _cancelLesson() {
    // TODO: Update lesson status to cancelled

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedStudent?.name ?? ''} 학생의 레슨이 취소되었습니다'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.warning,
      ),
    );

    context.pop();
  }

  void _deleteLesson() {
    // TODO: Delete lesson from database

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('레슨이 삭제되었습니다'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.pop();
  }

  void _saveLesson() {
    // TODO: Update lesson in database
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('레슨 정보가 수정되었습니다'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.practiceGood,
      ),
    );

    context.pop();
  }

  // Mock data
  List<EditLessonStudentInfo> get _mockStudents => [
        EditLessonStudentInfo(
          id: 'student_1',
          name: '홍길동',
          instrument: '바이올린',
          color: Colors.blue,
        ),
        EditLessonStudentInfo(
          id: 'student_2',
          name: '김철수',
          instrument: '피아노',
          color: Colors.green,
        ),
        EditLessonStudentInfo(
          id: 'student_3',
          name: '이영희',
          instrument: '첼로',
          color: Colors.orange,
        ),
      ];
}
