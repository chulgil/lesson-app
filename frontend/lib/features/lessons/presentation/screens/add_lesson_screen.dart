import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../../features/students/domain/entities/student.dart';
import '../../../../features/students/domain/entities/lesson_location.dart';
import '../../../../features/profile/presentation/providers/teacher_extended_profile_provider.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../providers/lesson_crud_provider.dart';
import '../../../subscription/subscription_facade.dart';
import '../widgets/lesson_form_widgets.dart';
import '../widgets/lesson_form/lesson_location_section.dart';

/// Screen for adding a new lesson
class AddLessonScreen extends ConsumerStatefulWidget {
  final String? preselectedStudentId;
  final String? preselectedDate; // Format: YYYY-MM-DD
  final int? preselectedHour; // 0-23
  final int? preselectedMinute; // 0-59

  const AddLessonScreen({
    super.key,
    this.preselectedStudentId,
    this.preselectedDate,
    this.preselectedHour,
    this.preselectedMinute,
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
  LessonLocation? _selectedLocation;

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

    // Handle preselected hour (0-23) and minute (0-59)
    if (widget.preselectedHour != null) {
      final hour = widget.preselectedHour!.clamp(0, 23);
      final minute = (widget.preselectedMinute ?? 0).clamp(0, 59);
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
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

  /// Whether the current date+time selection is in the past (record mode).
  bool get _isRecordMode =>
      !_isRecurring && isLessonDateTimeInPast(_selectedDate, _selectedTime);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRecordMode ? '레슨 기록' : '레슨 추가'),
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

              // Subscription status banner
              if (_selectedStudent != null) _buildSubscriptionBanner(),

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

              // Lesson location (selected from teacher's registered locations)
              const LessonFormSectionTitle('레슨 장소'),
              const SizedBox(height: AppSpacing.space3),
              LessonLocationSection(
                teacherId: 'teacher_1',
                selectedLocationId: _selectedLocation?.id,
                onSelected: (loc) {
                  setState(() => _selectedLocation = loc);
                },
                onAutoPrefill: (loc) {
                  if (_selectedLocation == null) {
                    setState(() => _selectedLocation = loc);
                  }
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Recurring lesson (hidden in record mode — past lessons can't recur)
              if (!_isRecordMode)
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

              // Reminder settings (hidden in record mode — past lessons don't need reminders)
              if (!_isRecordMode) ...[
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
              ],

              const SizedBox(height: AppSpacing.space8),

              // Save button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: _saveLesson,
                  child: Text(
                    _isRecurring
                        ? '정기 레슨 예약하기'
                        : _isRecordMode
                        ? '레슨 기록하기'
                        : '레슨 추가하기',
                  ),
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

    final recentStudents = List<Student>.from(students)..sort((a, b) {
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
              backgroundColor:
                  isSelected
                      ? student.profileColor
                      : student.profileColor.withValues(alpha: 0.08),
              side: BorderSide(
                color: student.profileColor.withValues(
                  alpha: isSelected ? 1 : 0.3,
                ),
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

  /// Build subscription status banner for the selected student.
  Widget _buildSubscriptionBanner() {
    final studentId = _selectedStudent!.id;
    final subscriptionsAsync = ref.watch(
      activeStudentSubscriptionsProvider(studentId),
    );

    return subscriptionsAsync.when(
      data: (subscriptions) {
        if (subscriptions.isNotEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space2),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 18),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    '이 학생은 현재 유효한 수강권이 없습니다. 레슨 기록은 가능하지만, 수강권을 먼저 발급하면 횟수가 자동 관리됩니다.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Show confirmation dialog when saving a lesson with a past date/time.
  /// Explains that past lessons are saved as "completed" with subscription deduction.
  Future<bool> _showPastDateConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.history, color: AppColors.warning, size: 24),
                const SizedBox(width: 8),
                const Text('과거 레슨 기록'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('선택한 시간은 이미 지난 시간입니다.'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '레슨 기록 시:',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• "완료" 상태로 저장됩니다\n• 수강권이 있으면 1회 자동 차감됩니다\n• 학생에게 레슨 기록으로 표시됩니다',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('레슨 기록'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  /// Check if a new lesson conflicts with existing lessons on the same day.
  /// Returns all conflicting lesson student names, or null if no conflict.
  String? _findConflict(
    DateTime date,
    TimeOfDay time,
    int duration,
    List<Lesson> existingLessons,
  ) {
    final newStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final newEnd = newStart.add(Duration(minutes: duration));
    final conflicts = <String>[];

    for (final lesson in existingLessons) {
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
          conflicts.add('${lesson.studentName} (${lesson.startTime})');
        }
      }
    }
    return conflicts.isEmpty ? null : conflicts.join(', ');
  }

  /// Show a confirmation dialog when a time conflict is detected.
  /// Returns true if the user chooses to proceed.
  Future<bool> _showConflictDialog(String conflictInfo) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('시간 충돌'),
            content: Text(
              '해당 시간에 기존 레슨이 있습니다:\n$conflictInfo\n\n그래도 계속 진행하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
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

    // Check if selected date+time is in the past (single lesson only)
    if (!_isRecurring) {
      final isPast = isLessonDateTimeInPast(_selectedDate, _selectedTime);
      if (isPast) {
        final shouldProceed = await _showPastDateConfirmDialog();
        if (!shouldProceed) return;
      }
    }

    // Check for time conflicts with existing lessons
    final existingLessons = ref.read(lessonsProvider).valueOrNull ?? [];

    if (_isRecurring && _recurringDays.isNotEmpty) {
      // Check conflicts for each recurring day (int: 0=Mon...6=Sun)
      const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
      final conflictDays = <String>[];
      for (final dayIndex in _recurringDays) {
        final weekday =
            dayIndex + 1; // Convert 0-based to DateTime.weekday (1=Mon)
        final now = DateTime.now();
        var daysUntil = weekday - now.weekday;
        if (daysUntil <= 0) daysUntil += 7;
        final targetDate = DateTime(now.year, now.month, now.day + daysUntil);
        final conflict = _findConflict(
          targetDate,
          _selectedTime,
          _lessonDuration,
          existingLessons,
        );
        if (conflict != null) {
          final dayLabel =
              dayIndex < dayNames.length ? dayNames[dayIndex] : '?';
          conflictDays.add('$dayLabel요일 ($conflict)');
        }
      }
      if (conflictDays.isNotEmpty) {
        final shouldProceed = await _showRecurringConflictDialog(conflictDays);
        if (!shouldProceed) return;
      }
    } else {
      final conflictName = _findConflict(
        _selectedDate,
        _selectedTime,
        _lessonDuration,
        existingLessons,
      );
      if (conflictName != null) {
        final shouldProceed = await _showConflictDialog(conflictName);
        if (!shouldProceed) return;
      }
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

    // Past date → completed status (record mode), future → scheduled
    final isPastLesson = isLessonDateTimeInPast(_selectedDate, _selectedTime);
    final lessonStatus =
        isPastLesson && !_isRecurring
            ? LessonStatus.completed
            : LessonStatus.scheduled;

    // Create the lesson object
    final lesson = Lesson(
      id: '', // Will be set by repository
      studentId: _selectedStudent!.id,
      studentName: _selectedStudent!.name,
      teacherName:
          ref.read(teacherExtendedProfileProvider).valueOrNull?.name ?? '선생님',
      instrument: _selectedStudent!.instrument,
      date: _selectedDate,
      startTime: formatLessonTime(_selectedTime),
      duration: _lessonDuration,
      status: lessonStatus,
      pieces: pieces,
      location:
          _selectedLocation == null
              ? null
              : LessonLocationInfo(
                name: _selectedLocation!.name,
                address: _selectedLocation!.address,
              ),
      createdAt: DateTime.now(),
    );

    try {
      if (_isRecurring && _recurringDays.isNotEmpty) {
        // Batch-create lessons for each recurring day, 4 weeks ahead
        const weeksAhead = 4;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        int createdCount = 0;

        for (final dayIndex in _recurringDays) {
          final weekday = dayIndex + 1; // 0-based → DateTime.weekday (1=Mon)
          for (int week = 0; week < weeksAhead; week++) {
            // Calculate target date for this weekday and week offset
            var daysUntil = weekday - today.weekday;
            if (daysUntil <= 0) daysUntil += 7;
            final targetDate = today.add(
              Duration(days: daysUntil + (week * 7)),
            );

            final recurringLesson = lesson.copyWith(
              id: '', // Will be set by repository
              date: targetDate,
              createdAt: DateTime.now(),
            );
            await ref
                .read(lessonsNotifierProvider.notifier)
                .addLesson(recurringLesson);
            createdCount++;
          }
        }

        // Invalidate the lessonsProvider to refresh calendar
        ref.invalidate(lessonsProvider);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedStudent!.name} 학생의 정기 레슨 $createdCount개가 생성되었습니다 (4주간)',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.practiceGood,
          ),
        );
      } else {
        // Single lesson creation
        await ref.read(lessonsNotifierProvider.notifier).addLesson(lesson);

        // If past lesson (record mode), auto-deduct subscription
        if (isPastLesson) {
          await _recordSubscriptionUsage(lesson);
        }

        // Invalidate the lessonsProvider to refresh calendar
        ref.invalidate(lessonsProvider);

        if (!mounted) return;

        final message =
            isPastLesson
                ? '${_selectedStudent!.name} 학생의 레슨이 기록되었습니다'
                : '${_selectedStudent!.name} 학생의 레슨이 추가되었습니다';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.practiceGood,
          ),
        );
      }

      // Go back
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('레슨 추가에 실패했습니다. 다시 시도해주세요.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Record subscription usage for a past lesson (auto-deduct).
  /// Silently skips if no active subscription exists.
  Future<void> _recordSubscriptionUsage(Lesson lesson) async {
    try {
      final subscriptions = await ref.read(
        activeStudentSubscriptionsProvider(lesson.studentId).future,
      );
      if (subscriptions.isEmpty) return;

      final subscription = subscriptions.first;
      final usage = SubscriptionUsage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subscriptionId: subscription.id,
        lessonId: lesson.id,
        usedAt: lesson.date,
        teacherName: lesson.teacherName,
        instrument: lesson.instrument,
        note: '레슨 기록 (사후 등록)',
        createdAt: DateTime.now(),
        usageType: UsageType.normal,
        deducted: true,
      );

      final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
      await subscriptionRepo.addUsage(usage);
      ref.invalidate(activeStudentSubscriptionsProvider(lesson.studentId));
    } catch (_) {
      // Subscription deduction failure should not block lesson creation
    }
  }

  void _autoFillFromStudent(Student student) {
    setState(() {
      final slot = student.primarySlot;
      if (slot != null) {
        // Auto-fill lesson day
        final weekday =
            slot.dayOfWeek + 1; // 0-based → DateTime.weekday (1=Mon)
        final now = DateTime.now();
        var daysUntil = weekday - now.weekday;
        if (daysUntil <= 0) daysUntil += 7;
        _selectedDate = DateTime(now.year, now.month, now.day + daysUntil);

        // Auto-fill lesson time
        final parts = slot.startTime.split(':');
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

  /// Show conflict dialog for recurring lessons with multiple days.
  Future<bool> _showRecurringConflictDialog(List<String> conflictDays) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('반복 레슨 시간 충돌'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('다음 요일에 기존 레슨과 시간이 겹칩니다:'),
                const SizedBox(height: 8),
                ...conflictDays.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      '• $d',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('그래도 계속 진행하시겠습니까?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
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
}
