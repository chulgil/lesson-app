import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../models/student.dart';
import '../../../../models/teacher_student_relation.dart';
import '../../../../providers/booking/booking_providers.dart';
import '../../../../providers/student/student_providers.dart';
import '../widgets/schedule_option_card.dart';
import '../widgets/schedule_option_picker.dart';

/// Screen for student to request a trial or one-time lesson
/// Supports multi-option scheduling (1-3 options with priority)
class TrialLessonRequestScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName;
  final String? studentId;
  final RelationLessonType lessonType;

  const TrialLessonRequestScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    this.studentId,
    this.lessonType = RelationLessonType.trial,
  });

  @override
  ConsumerState<TrialLessonRequestScreen> createState() =>
      _TrialLessonRequestScreenState();
}

class _TrialLessonRequestScreenState
    extends ConsumerState<TrialLessonRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _uuid = const Uuid();

  // Multi-option schedule
  List<ScheduleOption> _scheduleOptions = [];
  static const int _lessonDuration = 60;
  static const int _maxOptions = 3;
  static const int _minOptions = 1;

  LessonGoal _selectedGoal = LessonGoal.hobby;
  ExperienceLevel _selectedExperience = ExperienceLevel.beginner;
  bool _isSubmitting = false;
  Student? _currentStudent;

  // Helper getters
  bool get _isTrialLesson => widget.lessonType == RelationLessonType.trial;
  String get _screenTitle => _isTrialLesson ? '체험레슨 신청' : '1회 레슨 신청';
  String get _priceLabel => _isTrialLesson ? '체험레슨 30,000원' : '1회 레슨 50,000원';
  String get _submitButtonLabel =>
      _isTrialLesson ? '체험레슨 신청하기' : '1회 레슨 신청하기';
  String get _successMessage =>
      _isTrialLesson ? '체험레슨 신청이 완료되었습니다' : '1회 레슨 신청이 완료되었습니다';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserDefaults();
    _initializeDefaultOption();
  }

  void _initializeDefaultOption() {
    // Start with one default option
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _scheduleOptions = [
      ScheduleOption(
        id: _uuid.v4(),
        priority: 1,
        date: tomorrow,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 15, minute: 0),
      ),
    ];
  }

  Future<void> _loadCurrentUserDefaults() async {
    try {
      final studentId = widget.studentId ?? 'student_1';
      final student = await ref.read(studentProvider(studentId).future);

      if (student != null && mounted) {
        setState(() {
          _currentStudent = student;
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

  Future<void> _editOption(int index) async {
    final isNew = index >= _scheduleOptions.length;
    final priority = isNew ? _scheduleOptions.length + 1 : index + 1;
    final existingOption = isNew ? null : _scheduleOptions[index];

    final result = await ScheduleOptionPicker.show(
      context: context,
      mode: ScheduleOptionPickerMode.singleLesson,
      initialOption: existingOption,
      priority: priority,
      lessonDuration: _lessonDuration,
    );

    if (result != null && mounted) {
      setState(() {
        if (isNew) {
          _scheduleOptions.add(result);
        } else {
          _scheduleOptions[index] = result;
        }
      });
    }
  }

  void _removeOption(int index) {
    if (_scheduleOptions.length <= _minOptions) return;

    setState(() {
      _scheduleOptions.removeAt(index);
      // Reorder priorities
      for (int i = 0; i < _scheduleOptions.length; i++) {
        _scheduleOptions[i] = _scheduleOptions[i].copyWith(priority: i + 1);
      }
    });
  }

  void _onReorderOptions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _scheduleOptions.removeAt(oldIndex);
      _scheduleOptions.insert(newIndex, item);
      // Update priorities after reorder
      for (int i = 0; i < _scheduleOptions.length; i++) {
        _scheduleOptions[i] = _scheduleOptions[i].copyWith(priority: i + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Teacher info
                    _buildTeacherInfo(),

                    const SizedBox(height: AppSpacing.space6),

                    // Schedule options
                    _buildScheduleOptionsSection(),

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

                    const SizedBox(height: AppSpacing.space6),
                  ],
                ),
              ),
            ),

            // Submit button (fixed at bottom)
            _buildBottomButton(),
          ],
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
                  _priceLabel,
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

  Widget _buildScheduleOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              '희망 일정 선택',
              style: AppTypography.headingSmall,
            ),
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              ),
              child: Text(
                '최대 $_maxOptions개',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.space2),

        // Reorder hint
        if (_scheduleOptions.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: Row(
              children: [
                Icon(
                  Icons.drag_handle,
                  size: 16,
                  color: AppColors.textTertiaryLight,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  '드래그하여 우선순위 변경',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),

        // Options list with reorderable
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _scheduleOptions.length,
          onReorder: _onReorderOptions,
          proxyDecorator: (child, index, animation) {
            return Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final option = _scheduleOptions[index];
            return Padding(
              key: ValueKey(option.id),
              padding: EdgeInsets.only(
                bottom: index < _scheduleOptions.length - 1
                    ? AppSpacing.space3
                    : AppSpacing.space2,
              ),
              child: ScheduleOptionCard(
                option: option,
                mode: ScheduleOptionCardMode.student,
                showDragHandle: _scheduleOptions.length > 1,
                onTap: () => _editOption(index),
                onEdit: () => _editOption(index),
                onDelete: _scheduleOptions.length > _minOptions
                    ? () => _removeOption(index)
                    : null,
              ),
            );
          },
        ),

        // Add option button
        if (_scheduleOptions.length < _maxOptions)
          AddScheduleOptionButton(
            optionNumber: _scheduleOptions.length + 1,
            onTap: () => _editOption(_scheduleOptions.length),
          ),

        const SizedBox(height: AppSpacing.space3),

        // Tip
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppColors.info,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  '여러 일정을 제안하면 빠르게 확정될 확률이 높아요',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.space4,
        top: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: SizedBox(
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
              : Text(_submitButtonLabel),
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_scheduleOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개의 희망 일정을 선택해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate all options have complete data
    for (final option in _scheduleOptions) {
      if (option.date == null ||
          option.startTime == null ||
          option.endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${option.priorityLabel} 일정을 완성해주세요'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
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
      // Create request with multiple schedule options
      final request = TrialLessonRequest(
        studentName: _currentStudent!.name,
        studentPhone: _currentStudent!.phone,
        studentEmail: _currentStudent!.email,
        goal: _selectedGoal,
        experience: _selectedExperience,
        message:
            _messageController.text.isEmpty ? null : _messageController.text,
        scheduleOptions: _scheduleOptions,
      );

      await ref.read(bookingsNotifierProvider.notifier).requestTrialLesson(
            teacherId: widget.teacherId,
            teacherName: widget.teacherName,
            request: request,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage),
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
