import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/profile_facade.dart';
import '../../../students/students_facade.dart';
import '../../../students/presentation/extensions/student_domain_visuals.dart';
import '../../lessons_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../widgets/lesson_form_widgets.dart';
import '../widgets/lesson_form/lesson_location_section.dart';
import '../widgets/lesson_form/lesson_overflow_mode_sheet.dart';
import '../widgets/lesson_form/makeup_credit_toggle.dart';
import '../widgets/lesson_form/manual_lesson_subscription_section.dart';

/// Screen for adding a new lesson
class AddLessonScreen extends ConsumerStatefulWidget {
  final String? preselectedStudentId;
  final String? preselectedDate; // Format: YYYY-MM-DD
  final int? preselectedHour; // 0-23
  final int? preselectedMinute; // 0-59

  /// §8 다음 회차 CTA — 수강권 상세에서 진입 시 해당 수강권을 §2.5 자동
  /// 귀속보다 우선 선택한다 (활성 목록에 있을 때만).
  final String? preselectedSubscriptionId;

  const AddLessonScreen({
    super.key,
    this.preselectedStudentId,
    this.preselectedDate,
    this.preselectedHour,
    this.preselectedMinute,
    this.preselectedSubscriptionId,
  });

  @override
  ConsumerState<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends ConsumerState<AddLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pieceController = TextEditingController();
  final _notesController = TextEditingController();

  LessonStudentInfo? _selectedStudent;

  /// Subscription this lesson is deducted from (spec §2.5).
  /// null = 0개(체험 자동생성) 또는 2+개 미선택 상태.
  Subscription? _selectedSubscription;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  int _lessonDuration = 60;
  bool _isRecurring = false;
  bool _isSaving = false;

  /// S4 (spec §2.6.1, D3) — spend a makeup credit for this lesson. Default OFF.
  bool _useMakeupCredit = false;
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
            _onStudentChosen(match.first);
          }
        }
      });
    } else {
      // #749: auto-select the only student when none is preselected
      // (mirrors the subscription auto-select in _resolveSubscriptionForStudent).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedStudent != null) return;
        final students = ref.read(studentsProvider).valueOrNull ?? [];
        if (students.length == 1) {
          _onStudentChosen(students.first);
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
    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: NotebookDetailAppBar(
        title:
            _isRecordMode
                ? AppStrings.lessonRecordTitle
                : AppStrings.lessonAddTitle,
        onLeadingTap:
            () => showLessonExitConfirmation(
              context: context,
              hasData: _hasFormData(),
              onExit: () => context.pop(),
            ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student selection
              const LessonFormSectionTitle(AppStrings.bulkFeedbackStepStudent),
              const SizedBox(height: AppSpacing.space3),

              LessonStudentSelector(
                selectedStudent: _selectedStudent,
                onTap: _showStudentPicker,
              ),

              // Subscription status + instrument inheritance (spec §2.5)
              if (_selectedStudent != null)
                ManualLessonSubscriptionSection(
                  studentId: _selectedStudent!.id,
                  studentInstrument: _selectedStudent!.instrument,
                  selectedSubscription: _selectedSubscription,
                  onPickRequested:
                      () => _openSubscriptionPicker(_selectedStudent!.id),
                  onIssueRequested: _openIssueSubscription,
                ),

              // S4 — makeup credit spend toggle (hidden when no credits)
              if (_selectedStudent != null)
                MakeupCreditToggle(
                  studentId: _selectedStudent!.id,
                  value: _useMakeupCredit,
                  onChanged:
                      (value) => setState(() => _useMakeupCredit = value),
                ),

              const SizedBox(height: AppSpacing.space6),

              // Date and time selection
              const LessonFormSectionTitle(AppStrings.dateTimeLabel),
              const SizedBox(height: AppSpacing.space3),
              LessonDateTimeSection(
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                onDateTap: _selectDate,
                onTimeTap: _selectTime,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Lesson duration
              const LessonFormSectionTitle(AppStrings.lessonDurationLabel),
              const SizedBox(height: AppSpacing.space3),
              LessonDurationSelector(
                selectedDuration: _lessonDuration,
                onDurationChanged: (value) {
                  setState(() => _lessonDuration = value);
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Lesson location (selected from teacher's registered locations)
              const LessonFormSectionTitle(AppStrings.lessonLocationLabel),
              const SizedBox(height: AppSpacing.space3),
              LessonLocationSection(
                teacherId: ref.watch(currentTeacherIdProvider),
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
              const LessonFormSectionTitle(AppStrings.lessonContentLabel),
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
                  onPressed: _isSaving ? null : _saveLesson,
                  child: Text(
                    _isRecurring
                        ? AppStrings.reserveRecurringLessonButton
                        : _isRecordMode
                        ? AppStrings.recordLessonButton
                        : AppStrings.addLessonButton,
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
        final matches = students.where((s) => s.id == selected.id);
        if (matches.isEmpty) return; // #72 선택이 목록에서 사라진 race 무시
        _onStudentChosen(matches.first);
      },
      onAddStudentRequested: _addNewStudentAndSelect,
    );
  }

  /// 경로 4 (§2.6.4) — 신규 학생 인라인 등록 후 방금 학생 자동 선택.
  /// 등록 화면은 returnTo=addLesson 으로 발급 다이얼로그를 건너뛰고
  /// 생성된 학생 id 를 반환한다.
  Future<void> _addNewStudentAndSelect() async {
    final result = await context.push(
      '${AppRoutes.addStudent}?returnTo=addLesson',
    );
    if (!mounted || result is! String) return;
    ref.invalidate(studentsProvider);
    try {
      final students = await ref.read(studentsProvider.future);
      if (!mounted) return;
      final matches = students.where((s) => s.id == result);
      if (matches.isNotEmpty) {
        _onStudentChosen(matches.first);
      }
    } catch (_) {
      // 목록 재조회 실패 시 선택만 생략 — 선생님이 시트에서 다시 고를 수 있다.
    }
  }

  /// Unified student-selection flow: set student, reset subscription, auto-fill
  /// the regular pattern, then resolve the subscription branch (spec §2.5).
  void _onStudentChosen(Student student) {
    setState(() {
      _selectedStudent = _studentToInfo(student);
      _selectedSubscription = null;
      _useMakeupCredit = false;
    });
    _autoFillFromStudent(student);
    _resolveSubscriptionForStudent(student.id);
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

  /// Resolve which subscription this lesson is deducted from after a student is
  /// chosen (spec §2.5): 0개 → null(체험 자동생성), 1개 → 자동 귀속,
  /// 2+개 → 선택 시트.
  Future<void> _resolveSubscriptionForStudent(String studentId) async {
    try {
      final actives = await ref.read(
        activeStudentSubscriptionsProvider(studentId).future,
      );
      if (!mounted || _selectedStudent?.id != studentId) return;
      final sorted = sortSubscriptionsForPicker(actives);

      // §8 다음 회차 CTA — 프리필 수강권이 활성 목록에 있으면 최우선 선택
      // (선택 시트 생략). 목록에 없으면(만료 등) 일반 분기로 폴백.
      final preselectedId = widget.preselectedSubscriptionId;
      if (preselectedId != null) {
        final match = sorted.where((s) => s.id == preselectedId);
        if (match.isNotEmpty) {
          setState(() => _selectedSubscription = match.first);
          return;
        }
      }

      if (sorted.length == 1) {
        setState(() => _selectedSubscription = sorted.first);
      } else if (sorted.length >= 2) {
        await _openSubscriptionPicker(studentId, presorted: sorted);
      }
      // 0개: subscription_id 미지정 — BE 가 체험 수강권 자동 생성
    } catch (_) {
      // 조회 실패는 배너(provider watch)가 자체 표시. 저장은 막지 않는다.
    }
  }

  /// Open the subscription picker sheet (2+ active) and store the choice.
  Future<void> _openSubscriptionPicker(
    String studentId, {
    List<Subscription>? presorted,
  }) async {
    final sorted =
        presorted ??
        sortSubscriptionsForPicker(
          await ref.read(activeStudentSubscriptionsProvider(studentId).future),
        );
    if (!mounted || _selectedStudent?.id != studentId || sorted.isEmpty) return;
    final picked = await showSubscriptionPickerSheet(
      context: context,
      subscriptions: sorted,
      recommendedId: sorted.first.id,
    );
    if (!mounted || _selectedStudent?.id != studentId) return;
    if (picked != null) {
      setState(() => _selectedSubscription = picked);
    }
  }

  /// Show confirmation dialog when saving a lesson with a past date/time.
  /// Explains that past lessons are saved as "completed" with subscription deduction.
  Future<bool> _showPastDateConfirmDialog() async {
    final result = await showNotebookDialog<bool>(
      context: context,
      titleWidget: Row(
        children: [
          Icon(Icons.history, color: AppColors.paperAccent, size: 24),
          const SizedBox(width: AppSpacing.space2),
          const Text(AppStrings.pastLessonRecordTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.pastTimeMessage),
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(color: AppColors.paperDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.recordLessonChecklistHeader,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  AppStrings.recordLessonChecklistItems,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.lessonRecordTitle),
        ),
      ],
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
    final result = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.timeConflictTitle,
      content: Text(AppStrings.conflictDialogContent(conflictInfo)),
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
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _doSaveLesson();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _doSaveLesson() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.selectStudentValidation),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isRecurring && _recurringDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.selectRecurringDaysValidation),
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
      const dayNames = AppStrings.dayNamesShort;
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
          conflictDays.add(AppStrings.recurringConflictDay(dayLabel, conflict));
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

    // S3 (spec §2.6.1~2.6.2) — explicit accounting when the target subscription
    // is exhausted: the silent bonus expansion is promoted to a choice sheet.
    // Recurring keeps the legacy path (multi-lesson overflow semantics are not
    // defined by the spec; regular students renew instead).
    String? overflowMode;
    var routeToIssueAfterSave = false;
    if (_useMakeupCredit && !_isRecurring) {
      // S4 toggle ON — credit-funded lesson regardless of remaining sessions
      // (§5.4). The S3 sheet is skipped: the accounting choice is already made.
      overflowMode = LessonOverflowChoice.makeupCredit.wireValue;
    } else if (shouldPromptOverflowMode(
      subscription: _selectedSubscription,
      isRecurring: _isRecurring,
    )) {
      final choice = await _resolveOverflowChoice(_selectedSubscription!);
      if (choice == null) return; // sheet dismissed — abort save
      overflowMode = choice.wireValue;
      routeToIssueAfterSave =
          choice == LessonOverflowChoice.renewalProposal ||
          choice == LessonOverflowChoice.renewalIssue;
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
    // Instrument: subscription (membership) is the SSOT; fall back to the
    // student value only when no subscription is chosen (0개 trial path).
    final lessonInstrument = resolveLessonInstrument(
      subscription: _selectedSubscription,
      studentInstrument: _selectedStudent!.instrument,
    );

    final lesson = Lesson(
      id: '', // Will be set by repository
      studentId: _selectedStudent!.id,
      studentName: _selectedStudent!.name,
      teacherName:
          ref.read(teacherExtendedProfileProvider).valueOrNull?.name ??
          AppStrings.teacher,
      instrument: lessonInstrument,
      subscriptionId: _selectedSubscription?.id,
      // Calendar date only: strip any time so the BE `LessonCreate.date`
      // (Pydantic `date`) accepts it. Defense-in-depth with the date-only
      // JSON serializer on `Lesson.date`.
      date: DateUtils.dateOnly(_selectedDate),
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
              AppStrings.recurringLessonsCreated(
                _selectedStudent!.name,
                createdCount,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperOk,
          ),
        );
      } else {
        // Single lesson creation — capture the returned Lesson so its server-
        // assigned id is used for subscription usage (not the local empty id).
        final savedLesson = await ref
            .read(lessonsNotifierProvider.notifier)
            .addLesson(lesson, overflowMode: overflowMode);

        // If past lesson (record mode), auto-deduct subscription.
        // makeup_credit lessons are credit-funded — the BE consumed the credit
        // and the regular counter must stay untouched (makeup_credit_spec §5.3).
        if (isPastLesson && overflowMode != 'makeup_credit') {
          await _recordSubscriptionUsage(savedLesson);
        }

        // Invalidate the lessonsProvider to refresh calendar
        ref.invalidate(lessonsProvider);

        if (!mounted) return;

        if (routeToIssueAfterSave) {
          // §2.6.2 renewal — the lesson is a preview until the renewal is
          // issued (BE promotes it on deposit confirmation). Continue straight
          // into the issue flow with the student prefilled.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.overflowRenewalPreviewSnack),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.paperOk,
            ),
          );
          context.pushReplacement(
            '${AppRoutes.issueSubscription}?studentId=${_selectedStudent!.id}',
          );
          return;
        }

        final message =
            isPastLesson
                ? AppStrings.lessonRecordedFor(_selectedStudent!.name)
                : AppStrings.lessonAddedFor(_selectedStudent!.name);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperOk,
          ),
        );
      }

      // Go back
      context.pop();
    } catch (e) {
      if (!mounted) return;
      // S6 (spec §2.6.5) — the free auto trial was already used for this
      // connected student; guide the teacher to issue a real subscription.
      if (e is ValidationException && e.message == 'trial_already_used') {
        await _showTrialAlreadyUsedDialog();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.addLessonFailed),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.paperAccent,
        ),
      );
    }
  }

  /// S3 (spec §2.6.2) — resolve the overflow choice for an exhausted
  /// subscription via the bottom sheet. Returns null when dismissed.
  Future<LessonOverflowChoice?> _resolveOverflowChoice(
    Subscription subscription,
  ) async {
    final studentId = _selectedStudent!.id;

    // Available makeup credits gate the first sheet option (S4 source).
    var availableCredits = 0;
    try {
      final credits = await ref.read(
        teacherMakeupCreditsProvider(studentId).future,
      );
      final now = DateTime.now();
      availableCredits = credits.where((c) => c.isAvailable(now)).length;
    } catch (_) {
      // Credit lookup failure just hides the option — save is not blocked.
    }

    // §2.7 — unconnected (manual) students can't receive proposals; the sheet
    // swaps the renewal option for direct issuance. Unknown → assume connected.
    final students = ref.read(studentsProvider).valueOrNull ?? [];
    final match = students.where((s) => s.id == studentId);
    final isConnected = match.isEmpty || match.first.isAppConnected;

    if (!mounted) return null;
    return showLessonOverflowModeSheet(
      context: context,
      studentName: _selectedStudent!.name,
      subscriptionName: subscription.typeLabel,
      availableCredits: availableCredits,
      isConnectedStudent: isConnected,
      // Record mode saves as completed — it can't wait for a renewal.
      allowRenewal: !_isRecordMode,
    );
  }

  /// S5/S6 — route to the issue-subscription flow with the student prefilled
  /// (§2.6.3 returnTo continuity). On direct-issue success the form resumes
  /// with the new subscription auto-attached (S1 state).
  Future<void> _openIssueSubscription() async {
    final studentId = _selectedStudent?.id;
    if (studentId == null) return;
    final issued = await context.push(
      '${AppRoutes.issueSubscription}?studentId=$studentId&returnTo=addLesson',
    );
    if (!mounted || issued != true || _selectedStudent?.id != studentId) {
      return;
    }
    ref.invalidate(activeStudentSubscriptionsProvider(studentId));
    await _resolveSubscriptionForStudent(studentId);
  }

  Future<void> _showTrialAlreadyUsedDialog() async {
    final issue = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.trialAlreadyUsedTitle,
      content: const Text(AppStrings.trialAlreadyUsedMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.issueSubscriptionAction),
        ),
      ],
    );
    if (issue == true && mounted) {
      _openIssueSubscription();
    }
  }

  /// Record subscription usage for a past lesson (auto-deduct).
  /// Uses the chosen subscription (spec §2.5); falls back to the resolved
  /// active subscription. Silently skips if none exists (0개 — BE handles trial).
  Future<void> _recordSubscriptionUsage(Lesson lesson) async {
    try {
      Subscription? subscription = _selectedSubscription;
      if (subscription == null) {
        final subscriptions = await ref.read(
          activeStudentSubscriptionsProvider(lesson.studentId).future,
        );
        if (subscriptions.isEmpty) return;
        subscription = sortSubscriptionsForPicker(subscriptions).first;
      }

      final usage = SubscriptionUsage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subscriptionId: subscription.id,
        lessonId: lesson.id,
        usedAt: lesson.date,
        teacherName: lesson.teacherName,
        instrument: lesson.instrument,
        note: AppStrings.lessonRecordPostNote,
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
    final result = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.recurringConflictTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.recurringConflictHeader),
          const SizedBox(height: AppSpacing.space2),
          ...conflictDays.map(
            (d) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                '• $d',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          const Text(AppStrings.continueProgressQuestion),
        ],
      ),
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
}
