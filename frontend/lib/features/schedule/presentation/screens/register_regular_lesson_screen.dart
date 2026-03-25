import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../../core/booking/entities/time_slot.dart';
import '../../../../features/lessons/presentation/providers/booking_providers.dart';
import '../../../../features/settings/presentation/providers/teacher_settings_provider.dart';
import '../widgets/regular_lesson_widgets.dart';
import '../widgets/schedule_type_selector.dart';

/// Screen for registering a regular lesson after trial
class RegisterRegularLessonScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName;
  final String? studentId;
  final String? studentName;

  const RegisterRegularLessonScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    this.studentId,
    this.studentName,
  });

  @override
  ConsumerState<RegisterRegularLessonScreen> createState() =>
      _RegisterRegularLessonScreenState();
}

class _RegisterRegularLessonScreenState
    extends ConsumerState<RegisterRegularLessonScreen> {
  ScheduleType _scheduleType = ScheduleType.fixed;
  int _selectedLessonDuration = 60;
  final Set<int> _selectedDays = {};
  final Map<int, TimeOfDay> _selectedTimesPerDay = {};
  int _lessonsPerWeek = 1;
  int _monthlyFee = 200000;
  DateTime _startDate = getNextMonday();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final availabilityAsync =
        ref.watch(teacherAvailabilityProvider(widget.teacherId));
    final settingsAsync =
        ref.watch(teacherSettingsByIdProvider(widget.teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('정규레슨 등록'),
      ),
      body: settingsAsync.when(
        data: (settings) => availabilityAsync.when(
          data: (slots) => _buildContent(settings, slots),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('시간 정보를 불러올 수 없습니다')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('설정 정보를 불러올 수 없습니다')),
      ),
    );
  }

  Widget _buildContent(TeacherSettings settings, List<TimeSlot> slots) {
    // Initialize lesson duration from teacher's default if not set
    if (_selectedLessonDuration == 60 && settings.defaultLessonDuration != 60) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedLessonDuration = settings.defaultLessonDuration;
        });
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info
          if (widget.studentName != null)
            RegularLessonStudentInfo(studentName: widget.studentName!),

          const SizedBox(height: AppSpacing.space6),

          // Schedule type
          const RegularLessonSectionTitle('레슨 유형'),
          const SizedBox(height: AppSpacing.space3),
          ScheduleTypeSelector(
            selectedType: _scheduleType,
            onTypeSelected: (type) {
              setState(() {
                _scheduleType = type;
                if (type == ScheduleType.flexible) {
                  _selectedDays.clear();
                  _selectedTimesPerDay.clear();
                }
              });
            },
          ),

          const SizedBox(height: AppSpacing.space6),

          // Fixed time slot selection
          if (_scheduleType == ScheduleType.fixed) ...[
            // Lesson duration selection
            const RegularLessonSectionTitle('레슨 시간'),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '선생님 기본 설정: ${LessonDurations.format(settings.defaultLessonDuration)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            RegularLessonDurationSelector(
              selectedDuration: _selectedLessonDuration,
              settings: settings,
              onDurationChanged: (duration) {
                setState(() {
                  _selectedLessonDuration = duration;
                  // Clear time selections when duration changes
                  _selectedTimesPerDay.clear();
                });
              },
            ),

            const SizedBox(height: AppSpacing.space6),

            // Day selection
            const RegularLessonSectionTitle('요일 선택'),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '주 $_lessonsPerWeek회 레슨 - $_lessonsPerWeek개 요일을 선택하세요',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            RegularLessonDaySelector(
              selectedDays: _selectedDays,
              lessonsPerWeek: _lessonsPerWeek,
              availableSlots: slots,
              onDayToggle: (dayOfWeek) {
                setState(() {
                  if (_selectedDays.contains(dayOfWeek)) {
                    _selectedDays.remove(dayOfWeek);
                  } else {
                    _selectedDays.add(dayOfWeek);
                  }
                });
              },
              selectedTimesPerDay: _selectedTimesPerDay,
              onTimeRemoved: (day, _) {
                setState(() {
                  _selectedTimesPerDay.remove(day);
                });
              },
            ),

            const SizedBox(height: AppSpacing.space6),

            // Time selection for each selected day
            if (_selectedDays.isNotEmpty) ...[
              const RegularLessonSectionTitle('시간 선택'),
              const SizedBox(height: AppSpacing.space3),
              ..._selectedDays.map((day) => RegularLessonTimeSelector(
                    dayOfWeek: day,
                    availableSlots: slots,
                    selectedTime: _selectedTimesPerDay[day],
                    lessonDuration: _selectedLessonDuration,
                    onTimeSelected: (time) {
                      setState(() {
                        _selectedTimesPerDay[day] = time;
                      });
                    },
                  )),
            ],

            const SizedBox(height: AppSpacing.space6),
          ],

          // Lessons per week
          const RegularLessonSectionTitle('레슨 횟수'),
          const SizedBox(height: AppSpacing.space3),
          LessonsPerWeekSelector(
            lessonsPerWeek: _lessonsPerWeek,
            onChanged: (value) => setState(() => _lessonsPerWeek = value),
            onDecreaseLessons: () {
              // Keep only first selected day when decreasing to 1
              if (_lessonsPerWeek == 1 && _selectedDays.length > 1) {
                final first = _selectedDays.first;
                setState(() {
                  _selectedDays.clear();
                  _selectedDays.add(first);
                  _selectedTimesPerDay.removeWhere((key, _) => key != first);
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '* 5주차가 있는 달은 기본 휴강입니다. 추가 레슨이 필요하시면 1회 레슨을 신청해주세요.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Monthly fee
          const RegularLessonSectionTitle('월 수강료'),
          const SizedBox(height: AppSpacing.space3),
          RegularLessonFeeSelector(
            monthlyFee: _monthlyFee,
            onFeeChanged: (fee) => setState(() => _monthlyFee = fee),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Start date
          const RegularLessonSectionTitle('시작일'),
          const SizedBox(height: AppSpacing.space3),
          RegularLessonStartDateSelector(
            startDate: _startDate,
            onTap: () async {
              final picked = await selectStartDate(context, _startDate);
              if (picked != null) {
                setState(() => _startDate = picked);
              }
            },
          ),

          const SizedBox(height: AppSpacing.space8),

          // Summary
          RegularLessonSummary(
            scheduleTypeLabel: _scheduleType.label,
            isFixedSchedule: _scheduleType == ScheduleType.fixed,
            lessonDuration: _selectedLessonDuration,
            selectedDays: _selectedDays,
            selectedTimesPerDay: _selectedTimesPerDay,
            lessonsPerWeek: _lessonsPerWeek,
            monthlyFee: _monthlyFee,
            startDate: _startDate,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Submit button
          RegularLessonSubmitButton(
            isValid: _isFormValid(),
            isSubmitting: _isSubmitting,
            onSubmit: _submitRegistration,
          ),

          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  bool _isFormValid() {
    return _scheduleType == ScheduleType.flexible ||
        (_selectedDays.length == _lessonsPerWeek &&
            _selectedTimesPerDay.length == _lessonsPerWeek);
  }

  Future<void> _submitRegistration() async {
    if (_scheduleType == ScheduleType.fixed) {
      if (_selectedDays.length != _lessonsPerWeek) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_lessonsPerWeek개의 요일을 선택해주세요'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (_selectedTimesPerDay.length != _lessonsPerWeek) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('각 요일의 레슨 시간을 선택해주세요'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Create time slots from selected days and times
      final fixedSlots = _selectedDays.map((day) {
        final time = _selectedTimesPerDay[day]!;
        return TimeSlot(
          id: 'slot_$day',
          dayOfWeek: day,
          startTime: time,
          endTime: addMinutes(time, _selectedLessonDuration),
        );
      }).toList();

      final registration = RegularLessonRegistration(
        studentId: widget.studentId ?? 'new_student',
        scheduleType: _scheduleType,
        fixedTimeSlot: fixedSlots.isNotEmpty ? fixedSlots.first : null,
        lessonsPerWeek: _lessonsPerWeek,
        monthlyFee: _monthlyFee,
        startDate: _startDate,
      );

      await ref.read(bookingsNotifierProvider.notifier).registerRegularLesson(
            teacherId: widget.teacherId,
            teacherName: widget.teacherName,
            studentId: widget.studentId ?? 'new_student',
            studentName: widget.studentName ?? '신규 학생',
            registration: registration,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정규레슨이 등록되었습니다'),
            backgroundColor: AppColors.practiceGood,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('등록 중 오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
