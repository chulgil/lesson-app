import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson.dart';
import '../../../../models/student.dart';
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

    // Handle preselected student after first frame (ref not available in initState)
    if (widget.preselectedStudentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final studentsAsync = ref.read(studentsProvider);
        final students = studentsAsync.valueOrNull ?? [];
        if (students.isNotEmpty) {
          final match = students.where(
            (s) => s.id == widget.preselectedStudentId,
          );
          if (match.isNotEmpty) {
            final student = match.first;
            setState(() {
              _selectedStudent = _studentToInfo(student);
            });
            _autoFillFromStudent(student);
          }
        }
      });
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
          onPressed:
              () => showLessonExitConfirmation(
                context: context,
                hasData: _hasFormData(),
                onExit: () => context.pop(),
              ),
          icon: const Icon(Icons.close),
        ),
        actions: [TextButton(onPressed: _saveLesson, child: const Text('저장'))],
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

              // Quick select chips for recent students
              _buildRecentStudentChips(),

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

  /// Build recent student quick-select chips (top 5 by recent lesson).
  Widget _buildRecentStudentChips() {
    final studentsAsync = ref.watch(studentsProvider);
    final lessonsAsync = ref.watch(lessonsProvider);

    final students = studentsAsync.valueOrNull ?? [];
    final lessons = lessonsAsync.valueOrNull ?? [];

    if (students.isEmpty) return const SizedBox.shrink();

    // Sort students by most recent lesson date
    final studentLastLesson = <String, DateTime>{};
    for (final lesson in lessons) {
      final existing = studentLastLesson[lesson.studentId];
      if (existing == null || lesson.date.isAfter(existing)) {
        studentLastLesson[lesson.studentId] = lesson.date;
      }
    }

    final recentStudents = List<Student>.from(students)
      ..sort((a, b) {
        final aDate = studentLastLesson[a.id] ?? DateTime(2000);
        final bDate = studentLastLesson[b.id] ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

    final topStudents = recentStudents.take(5).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: topStudents.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final student = topStudents[index];
            final isSelected = _selectedStudent?.id == student.id;
            return ActionChip(
              avatar: CircleAvatar(
                radius: 12,
                backgroundColor: student.profileColor.withValues(alpha: 0.3),
                child: Text(
                  student.initial,
                  style: TextStyle(
                    fontSize: 11,
                    color: student.profileColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              label: Text(
                student.name,
                style: AppTypography.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : null,
                ),
              ),
              backgroundColor: isSelected
                  ? student.profileColor
                  : student.profileColor.withValues(alpha: 0.08),
              side: BorderSide(
                color: student.profileColor.withValues(alpha: isSelected ? 1 : 0.3),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: () {
                setState(() => _selectedStudent = _studentToInfo(student));
                _autoFillFromStudent(student);
              },
            );
          },
        ),
      ),
    );
  }

  bool _hasFormData() {
    return _selectedStudent != null ||
        _pieceController.text.isNotEmpty ||
        _notesController.text.isNotEmpty;
  }

  /// Convert Student entity to LessonStudentInfo for picker display
  LessonStudentInfo _studentToInfo(Student student) {
    return LessonStudentInfo(
      id: student.id,
      name: student.name,
      instrument: student.instrument,
      currentPiece: student.lessonSchedule ?? student.level.label,
      color: student.profileColor,
    );
  }

  void _showStudentPicker() {
    final studentsAsync = ref.read(studentsProvider);
    final students = studentsAsync.valueOrNull ?? [];

    // Convert Student entities to LessonStudentInfo for picker
    final studentInfos = students.map(_studentToInfo).toList();

    showLessonStudentPicker(
      context: context,
      students: studentInfos,
      selectedStudent: _selectedStudent,
      onStudentSelected: (selected) {
        setState(() => _selectedStudent = selected);
        // Auto-fill from student's regular lesson pattern
        final student = students.firstWhere((s) => s.id == selected.id);
        _autoFillFromStudent(student);
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
      pieces.add(
        LessonPiece(
          id: 'piece_${DateTime.now().millisecondsSinceEpoch}',
          name: _pieceController.text,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
        ),
      );
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

  /// Auto-fill lesson date, time, and duration from student's regular lesson pattern
  void _autoFillFromStudent(Student student) {
    setState(() {
      // Auto-fill lesson day
      if (student.lessonDay != null) {
        final nextDate = _getNextLessonDate(student.lessonDay!);
        if (nextDate != null) {
          _selectedDate = nextDate;
        }
      }

      // Auto-fill lesson time
      if (student.lessonTime != null) {
        final parts = student.lessonTime!.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            _selectedTime = TimeOfDay(hour: hour, minute: minute);
          }
        }
      }

      // Auto-fill lesson duration
      if (student.lessonDuration > 0) {
        _lessonDuration = student.lessonDuration;
      }
    });
  }

  /// Calculate the next occurrence of a given day name
  DateTime? _getNextLessonDate(String dayName) {
    const dayMap = {
      '월요일': DateTime.monday,
      '화요일': DateTime.tuesday,
      '수요일': DateTime.wednesday,
      '목요일': DateTime.thursday,
      '금요일': DateTime.friday,
      '토요일': DateTime.saturday,
      '일요일': DateTime.sunday,
    };

    final targetDay = dayMap[dayName];
    if (targetDay == null) return null;

    final now = DateTime.now();
    var daysUntil = targetDay - now.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    return DateTime(now.year, now.month, now.day + daysUntil);
  }
}
