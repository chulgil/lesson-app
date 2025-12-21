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
import '../widgets/time_slot_picker.dart';

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
  TimeSlot? _selectedTimeSlot;
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
    final availableSlots = ref.watch(bookingAvailableTimeSlotsProvider(
      (teacherId: widget.teacherId, date: _selectedDate),
    ));

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

              // Time selection
              _buildSectionTitle('시간 선택'),
              const SizedBox(height: AppSpacing.space3),
              availableSlots.when(
                data: (slots) => TimeSlotPicker(
                  availableSlots: slots,
                  selectedSlot: _selectedTimeSlot,
                  onSlotSelected: (slot) {
                    setState(() => _selectedTimeSlot = slot);
                  },
                ),
                loading: () => TimeSlotPicker(
                  availableSlots: const [],
                  onSlotSelected: (_) {},
                  isLoading: true,
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
            _selectedTimeSlot = null;
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

    if (_selectedTimeSlot == null) {
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
        preferredStartTime: _selectedTimeSlot!.startTime,
        preferredEndTime: _selectedTimeSlot!.endTime,
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
