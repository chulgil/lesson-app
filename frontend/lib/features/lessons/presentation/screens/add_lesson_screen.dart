import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/lesson.dart';
import '../../../../providers/providers.dart';
import '../widgets/lesson_form_widgets.dart';

/// Screen for adding a new lesson
class AddLessonScreen extends ConsumerStatefulWidget {
  final String? preselectedStudentId;
  final String? preselectedDate; // Format: YYYY-MM-DD
  final int? preselectedHour; // 0-23

  const AddLessonScreen({
    super.key,
    this.preselectedStudentId,
    this.preselectedDate,
    this.preselectedHour,
  });

  @override
  ConsumerState<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends ConsumerState<AddLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pieceController = TextEditingController();
  final _notesController = TextEditingController();

  LessonStudentInfo? _selectedStudent;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  int _lessonDuration = 60;
  bool _isRecurring = false;
  final Set<int> _recurringDays = {};
  bool _enableReminder = true;
  int _reminderMinutes = 30;

  @override
  void initState() {
    super.initState();

    // Handle preselected student
    if (widget.preselectedStudentId != null) {
      _selectedStudent = _mockStudents.firstWhere(
        (s) => s.id == widget.preselectedStudentId,
        orElse: () => _mockStudents.first,
      );
    }

    // Handle preselected date (format: YYYY-MM-DD)
    if (widget.preselectedDate != null) {
      try {
        final parts = widget.preselectedDate!.split('-');
        if (parts.length == 3) {
          _selectedDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (e) {
        // Keep default date if parsing fails
      }
    }

    // Handle preselected hour (0-23)
    if (widget.preselectedHour != null) {
      final hour = widget.preselectedHour!.clamp(0, 23);
      _selectedTime = TimeOfDay(hour: hour, minute: 0);
    }
  }

  @override
  void dispose() {
    _pieceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('레슨 추가'),
        leading: IconButton(
          onPressed: () => showLessonExitConfirmation(
            context: context,
            hasData: _hasFormData(),
            onExit: () => context.pop(),
          ),
          icon: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: _saveLesson,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student selection
              const LessonFormSectionTitle('학생 선택'),
              const SizedBox(height: AppSpacing.space3),
              LessonStudentSelector(
                selectedStudent: _selectedStudent,
                onTap: _showStudentPicker,
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
                  setState(() => _lessonDuration = value);
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Recurring lesson
              LessonRecurringSection(
                isRecurring: _isRecurring,
                onRecurringChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurringDays.clear();
                    }
                  });
                },
                selectedDays: _recurringDays,
                onDayToggle: (index) {
                  setState(() {
                    if (_recurringDays.contains(index)) {
                      _recurringDays.remove(index);
                    } else {
                      _recurringDays.add(index);
                    }
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
                  setState(() => _enableReminder = value);
                },
                reminderMinutes: _reminderMinutes,
                onReminderTimeChanged: (value) {
                  setState(() => _reminderMinutes = value);
                },
              ),

              const SizedBox(height: AppSpacing.space8),

              // Save button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: _saveLesson,
                  child: Text(_isRecurring ? '정기 레슨 예약하기' : '레슨 추가하기'),
                ),
              ),

              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasFormData() {
    return _selectedStudent != null ||
        _pieceController.text.isNotEmpty ||
        _notesController.text.isNotEmpty;
  }

  void _showStudentPicker() {
    showLessonStudentPicker(
      context: context,
      students: _mockStudents,
      selectedStudent: _selectedStudent,
      onStudentSelected: (student) {
        setState(() => _selectedStudent = student);
      },
    );
  }

  Future<void> _selectDate() async {
    final picked = await selectLessonDate(context, _selectedDate);
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await selectLessonTime(context, _selectedTime);
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveLesson() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('학생을 선택해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isRecurring && _recurringDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('반복 요일을 선택해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Create lesson pieces from input
    final pieces = <LessonPiece>[];
    if (_pieceController.text.isNotEmpty) {
      pieces.add(LessonPiece(
        id: 'piece_${DateTime.now().millisecondsSinceEpoch}',
        name: _pieceController.text,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      ));
    }

    // Create the lesson object
    final lesson = Lesson(
      id: '', // Will be set by repository
      studentId: _selectedStudent!.id,
      studentName: _selectedStudent!.name,
      teacherName: '김선생님', // TODO: Get from auth
      instrument: _selectedStudent!.instrument,
      date: _selectedDate,
      startTime: formatLessonTime(_selectedTime),
      duration: _lessonDuration,
      status: LessonStatus.scheduled,
      pieces: pieces,
      createdAt: DateTime.now(),
    );

    try {
      // Add lesson using the notifier
      await ref.read(lessonsNotifierProvider.notifier).addLesson(lesson);

      // Invalidate the lessonsProvider to refresh calendar
      ref.invalidate(lessonsProvider);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRecurring
                ? '${_selectedStudent!.name} 학생의 정기 레슨이 예약되었습니다'
                : '${_selectedStudent!.name} 학생의 레슨이 추가되었습니다',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.practiceGood,
        ),
      );

      // Go back
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('레슨 추가 실패: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Mock data
  List<LessonStudentInfo> get _mockStudents => [
        LessonStudentInfo(
          id: 'student_1',
          name: '홍길동',
          instrument: '바이올린',
          currentPiece: '바흐 파르티타 2번',
          color: Colors.blue,
        ),
        LessonStudentInfo(
          id: 'student_2',
          name: '김철수',
          instrument: '피아노',
          currentPiece: '쇼팽 에튀드 Op.10',
          color: Colors.green,
        ),
        LessonStudentInfo(
          id: 'student_3',
          name: '이영희',
          instrument: '첼로',
          currentPiece: '드보르작 첼로 협주곡',
          color: Colors.orange,
        ),
        LessonStudentInfo(
          id: 'student_4',
          name: '박민수',
          instrument: '플루트',
          currentPiece: '모차르트 플루트 협주곡',
          color: Colors.purple,
        ),
        LessonStudentInfo(
          id: 'student_5',
          name: '최지원',
          instrument: '바이올린',
          currentPiece: '비발디 사계 - 봄',
          color: Colors.teal,
        ),
      ];
}
