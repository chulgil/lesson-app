import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../models/student.dart';
import '../../../../models/time_slot.dart';
import '../../../../providers/booking/booking_providers.dart';
import '../../../../providers/student/student_providers.dart';
import '../widgets/time_slot_selector.dart';

/// Screen for student to request a trial lesson
class TrialLessonRequestScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName;
  final String? studentId; // Optional: for existing students

  const TrialLessonRequestScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    this.studentId,
  });

  @override
  ConsumerState<TrialLessonRequestScreen> createState() =>
      _TrialLessonRequestScreenState();
}

class _TrialLessonRequestScreenState
    extends ConsumerState<TrialLessonRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _selectedTime; // Changed from TimeSlot
  static const int _trialLessonDuration = 60; // Trial lesson duration in minutes
  LessonGoal _selectedGoal = LessonGoal.hobby;
  ExperienceLevel _selectedExperience = ExperienceLevel.beginner;
  bool _isSubmitting = false;
  Student? _currentStudent;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserDefaults();
  }

  /// Load current user data and apply defaults
  Future<void> _loadCurrentUserDefaults() async {
    try {
      // If studentId is provided, load that student's data
      // Otherwise, use mock current user (TODO: replace with actual auth user)
      final studentId = widget.studentId ?? 'student_1';
      final student = await ref.read(studentProvider(studentId).future);

      if (student != null && mounted) {
        setState(() {
          _currentStudent = student;
          // Apply defaults based on existing level
          _selectedGoal = LessonGoal.hobby;
          _selectedExperience =
              ExperienceLevel.fromStudentLevel(student.level);
        });
      }
    } catch (e) {
      // Silently fail - use defaults
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get teacher's available time for the selected date's day of week
    final availabilityAsync =
        ref.watch(teacherAvailabilityProvider(widget.teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('체험레슨 신청'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher info
              _buildTeacherInfo(),

              const SizedBox(height: AppSpacing.space6),

              // Date selection
              _buildSectionTitle('날짜 선택'),
              const SizedBox(height: AppSpacing.space3),
              _buildDateSelector(),

              const SizedBox(height: AppSpacing.space6),

              // Time selection with new UI
              _buildSectionTitle('시간 선택'),
              const SizedBox(height: AppSpacing.space3),
              availabilityAsync.when(
                data: (slots) => _buildTimeSelector(slots),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.space6),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => const Text('시간을 불러올 수 없습니다'),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Message
              _buildSectionTitle('메시지 (선택)'),
              const SizedBox(height: AppSpacing.space3),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '선생님께 전달할 메시지를 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: AppSpacing.space8),

              // Submit button
              _buildSubmitButton(),

              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(List<TimeSlot> allSlots) {
    // Get the slot for the selected date's day of week
    final dayOfWeek = _selectedDate.weekday;
    final daySlot = allSlots.firstWhere(
      (slot) => slot.dayOfWeek == dayOfWeek && slot.isActive,
      orElse: () => TimeSlot(
        id: 'default',
        dayOfWeek: dayOfWeek,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 21, minute: 0),
        isActive: false, // Mark as inactive if no slot found
      ),
    );

    // If no available slot for this day
    if (!daySlot.isActive) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space6),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '선택한 날짜에 가능한 시간이 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '다른 날짜를 선택해주세요',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      );
    }

    // Determine display range based on available times
    final displayStart = daySlot.startTime.hour < 9
        ? TimeOfDay(hour: daySlot.startTime.hour, minute: 0)
        : const TimeOfDay(hour: 9, minute: 0);
    final displayEnd = daySlot.endTime.hour > 22
        ? TimeOfDay(hour: daySlot.endTime.hour + 1, minute: 0)
        : const TimeOfDay(hour: 22, minute: 0);

    final showAm = daySlot.startTime.hour < 12;
    final showPm = daySlot.endTime.hour >= 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Available time info badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${_formatTimeOfDay(daySlot.startTime)}-${_formatTimeOfDay(daySlot.endTime)} 가능',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Time slot selector
        TimeSlotSelector(
          selectedTime: _selectedTime,
          onTimeSelected: (time) {
            setState(() => _selectedTime = time);
          },
          availableStart: daySlot.startTime,
          availableEnd: daySlot.endTime,
          lessonDurationMinutes: _trialLessonDuration,
          bookedSlots: const [], // TODO: Get from provider when backend is ready
          showAmSection: showAm,
          showPmSection: showPm,
          displayStart: displayStart,
          displayEnd: displayEnd,
        ),

        // Selection summary
        if (_selectedTime != null) ...[
          const SizedBox(height: AppSpacing.space4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: AppColors.success),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '${_formatTimeOfDay(_selectedTime!)} ~ ${_formatTimeOfDay(_addMinutes(_selectedTime!, _trialLessonDuration))} ($_trialLessonDuration분)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  Widget _buildTeacherInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.teacherName.isNotEmpty ? widget.teacherName[0] : 'T',
              style: AppTypography.headingMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.teacherName,
                  style: AppTypography.headingSmall,
                ),
                Text(
                  '체험레슨 30,000원',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.headingSmall);
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('M월 d일 (E)', 'ko');
    final now = DateTime.now();

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: now.add(const Duration(days: 1)),
          lastDate: now.add(const Duration(days: 60)),
          locale: const Locale('ko'),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            _selectedTime = null;
          });
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: const Icon(Icons.calendar_today, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '레슨 날짜',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    dateFormat.format(_selectedDate),
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              size: 18,
              color: AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: FilledButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('체험레슨 신청하기'),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('레슨 시간을 선택해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_currentStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Use current user's info from Student model
      final request = TrialLessonRequest(
        studentName: _currentStudent!.name,
        studentPhone: _currentStudent!.phone,
        studentEmail: _currentStudent!.email,
        goal: _selectedGoal,
        experience: _selectedExperience,
        message:
            _messageController.text.isEmpty ? null : _messageController.text,
        preferredDate: _selectedDate,
        preferredStartTime: _selectedTime!,
        preferredEndTime: _addMinutes(_selectedTime!, _trialLessonDuration),
      );

      await ref.read(bookingsNotifierProvider.notifier).requestTrialLesson(
            teacherId: widget.teacherId,
            teacherName: widget.teacherName,
            request: request,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('체험레슨 신청이 완료되었습니다'),
            backgroundColor: AppColors.practiceGood,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신청 처리 중 오류가 발생했습니다: $e'),
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
