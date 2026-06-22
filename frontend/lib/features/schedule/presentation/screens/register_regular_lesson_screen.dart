import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/booking/presentation/extensions/lesson_booking_visual_extensions.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/presentation/extensions/clock_time_ui_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../../core/booking/entities/time_slot.dart';
import '../../../../features/lessons/lessons_facade.dart';
import '../../../../features/settings/settings_facade.dart';
import '../../../../features/academy/academy_facade.dart';
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
  bool _isAcademyPrivate = false;
  String? _selectedAcademyId;

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(
      teacherAvailabilityProvider(widget.teacherId),
    );
    final settingsAsync = ref.watch(
      teacherSettingsByIdProvider(widget.teacherId),
    );
    final academiesAsync = ref.watch(
      teacherAcademiesProvider(widget.teacherId),
    );

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: const NotebookDetailAppBar(title: AppStrings.regularLessonTitle),
      body: settingsAsync.when(
        data:
            (settings) => availabilityAsync.when(
              data:
                  (slots) => academiesAsync.when(
                    data:
                        (academies) =>
                            _buildContent(settings, slots, academies),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildContent(settings, slots, []),
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) =>
                      const Center(child: Text(AppStrings.timeInfoLoadError)),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) =>
                const Center(child: Text(AppStrings.settingsInfoLoadError)),
      ),
    );
  }

  Widget _buildContent(
    TeacherSettings settings,
    List<TimeSlot> slots,
    List<TeacherAcademyMembership> academies,
  ) {
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
          const RegularLessonSectionTitle(
            AppStrings.lessonTypeLabel,
            romanIndex: 0,
          ),
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

          // Flexible schedule guide card
          if (_scheduleType == ScheduleType.flexible) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.scheduleMutedBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                AppStrings.flexibleScheduleGuide,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Fixed time slot selection
          if (_scheduleType == ScheduleType.fixed) ...[
            // Lesson duration selection
            const RegularLessonSectionTitle(
              AppStrings.lessonDurationLabel,
              romanIndex: 1,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.teacherDefaultDuration(
                LessonDurations.format(settings.defaultLessonDuration),
              ),
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
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
            const RegularLessonSectionTitle(
              AppStrings.daySelectLabel,
              romanIndex: 2,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.daySelectHint(_lessonsPerWeek),
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
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
              const RegularLessonSectionTitle(
                AppStrings.timeSelectLabel,
                romanIndex: 3,
              ),
              const SizedBox(height: AppSpacing.space3),
              ..._selectedDays.map(
                (day) => RegularLessonTimeSelector(
                  dayOfWeek: day,
                  availableSlots: slots,
                  selectedTime: _selectedTimesPerDay[day],
                  lessonDuration: _selectedLessonDuration,
                  onTimeSelected: (time) {
                    setState(() {
                      _selectedTimesPerDay[day] = time;
                    });
                  },
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.space6),
          ],

          // Lessons per week
          const RegularLessonSectionTitle(
            AppStrings.lessonCountLabel,
            romanIndex: 4,
          ),
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
          // 정책 footnote = 객관적 정보 → Tier 3 Pretendard bodyMedium
          // (README §1.1.1 결정 가이드, §7.128 자필 회피).
          Text(
            AppStrings.fifthWeekFootnote,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Monthly fee
          const RegularLessonSectionTitle(
            AppStrings.monthlyFeeLabel,
            romanIndex: 5,
          ),
          const SizedBox(height: AppSpacing.space3),
          RegularLessonFeeSelector(
            monthlyFee: _monthlyFee,
            onFeeChanged: (fee) => setState(() => _monthlyFee = fee),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Start date
          const RegularLessonSectionTitle(
            AppStrings.startDateLabel,
            romanIndex: 6,
          ),
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

          // Academy privacy toggle (only show if teacher belongs to academy)
          if (academies.isNotEmpty) ...[
            const RegularLessonSectionTitle(
              AppStrings.academyPrivacyLabel,
              romanIndex: 7,
            ),
            const SizedBox(height: AppSpacing.space3),
            if (academies.length == 1)
              SwitchListTile(
                title: Text(
                  AppStrings.academyPrivacyLabel,
                  style: AppTypography.bodyMedium,
                ),
                subtitle: Text(
                  AppStrings.academyPrivacyHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                value: _isAcademyPrivate,
                onChanged: (value) {
                  setState(() {
                    _isAcademyPrivate = value;
                    if (value && _selectedAcademyId == null) {
                      _selectedAcademyId = academies.first.academyId;
                    }
                  });
                },
              )
            else ...[
              // Multiple academies: show dropdown to select academy
              DropdownButton<String>(
                value: _selectedAcademyId,
                hint: const Text(AppStrings.academy),
                items:
                    academies.map((academy) {
                      return DropdownMenuItem(
                        value: academy.academyId,
                        child: Text(academy.academyName),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() => _selectedAcademyId = value);
                },
              ),
              const SizedBox(height: AppSpacing.space3),
              if (_selectedAcademyId != null)
                SwitchListTile(
                  title: Text(
                    AppStrings.academyPrivacyLabel,
                    style: AppTypography.bodyMedium,
                  ),
                  subtitle: Text(
                    AppStrings.academyPrivacyHint,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  value: _isAcademyPrivate,
                  onChanged: (value) {
                    setState(() => _isAcademyPrivate = value);
                  },
                ),
            ],
            const SizedBox(height: AppSpacing.space6),
          ],

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
            content: Text(AppStrings.selectDaysCountHint(_lessonsPerWeek)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (_selectedTimesPerDay.length != _lessonsPerWeek) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.selectTimeForEachDay),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Create time slots from selected days and times
      final fixedSlots =
          _selectedDays.map((day) {
            final time = _selectedTimesPerDay[day]!;
            return TimeSlot(
              id: 'slot_$day',
              dayOfWeek: day,
              startTime: time.toClockTime(),
              endTime: addMinutes(time, _selectedLessonDuration).toClockTime(),
            );
          }).toList();

      final registration = RegularLessonRegistration(
        studentId: widget.studentId ?? 'new_student',
        scheduleType: _scheduleType,
        fixedTimeSlots: fixedSlots,
        lessonsPerWeek: _lessonsPerWeek,
        monthlyFee: _monthlyFee,
        startDate: _startDate,
        academyId: _selectedAcademyId,
        isAcademyPrivate: _isAcademyPrivate,
      );

      await ref
          .read(bookingsNotifierProvider.notifier)
          .registerRegularLesson(
            teacherId: widget.teacherId,
            teacherName: widget.teacherName,
            studentId: widget.studentId ?? 'new_student',
            studentName: widget.studentName ?? AppStrings.newStudentDefault,
            registration: registration,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.regularLessonRegistered),
            backgroundColor: AppColors.paperOk,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.registrationErrorRetry),
            backgroundColor: AppColors.paperAccent,
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
