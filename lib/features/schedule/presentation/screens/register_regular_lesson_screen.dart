import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../models/time_slot.dart';
import '../../../../providers/booking/booking_providers.dart';
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
  TimeSlot? _selectedTimeSlot;
  int _lessonsPerWeek = 1;
  int _monthlyFee = 200000;
  DateTime _startDate = _getNextMonday();
  bool _isSubmitting = false;

  static DateTime _getNextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync =
        ref.watch(teacherAvailabilityProvider(widget.teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('정규레슨 등록'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student info
            if (widget.studentName != null) _buildStudentInfo(),

            const SizedBox(height: AppSpacing.space6),

            // Schedule type
            _buildSectionTitle('레슨 유형'),
            const SizedBox(height: AppSpacing.space3),
            ScheduleTypeSelector(
              selectedType: _scheduleType,
              onTypeSelected: (type) {
                setState(() {
                  _scheduleType = type;
                  if (type == ScheduleType.flexible) {
                    _selectedTimeSlot = null;
                  }
                });
              },
            ),

            const SizedBox(height: AppSpacing.space6),

            // Fixed time slot selection
            if (_scheduleType == ScheduleType.fixed) ...[
              _buildSectionTitle('고정 레슨 시간'),
              const SizedBox(height: AppSpacing.space3),
              availabilityAsync.when(
                data: (slots) => _buildTimeSlotGrid(slots),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('시간 정보를 불러올 수 없습니다'),
              ),
              const SizedBox(height: AppSpacing.space6),
            ],

            // Lessons per week
            _buildSectionTitle('레슨 횟수'),
            const SizedBox(height: AppSpacing.space3),
            _buildLessonsPerWeekSelector(),

            const SizedBox(height: AppSpacing.space6),

            // Monthly fee
            _buildSectionTitle('월 수강료'),
            const SizedBox(height: AppSpacing.space3),
            _buildFeeSelector(),

            const SizedBox(height: AppSpacing.space6),

            // Start date
            _buildSectionTitle('시작일'),
            const SizedBox(height: AppSpacing.space3),
            _buildStartDateSelector(),

            const SizedBox(height: AppSpacing.space8),

            // Summary
            _buildSummary(),

            const SizedBox(height: AppSpacing.space6),

            // Submit button
            _buildSubmitButton(),

            const SizedBox(height: AppSpacing.space6),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
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
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.studentName![0],
              style: AppTypography.headingSmall.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName!,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '정규레슨으로 등록합니다',
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

  Widget _buildTimeSlotGrid(List<TimeSlot> slots) {
    // Group by day
    final Map<int, List<TimeSlot>> slotsByDay = {};
    for (final slot in slots) {
      slotsByDay.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
    }

    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: List.generate(6, (dayIndex) {
          final dayOfWeek = dayIndex + 1;
          final daySlots = slotsByDay[dayOfWeek] ?? [];

          if (daySlots.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dayNames[dayIndex]}요일',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: daySlots.map((slot) {
                  final isSelected = _selectedTimeSlot?.id == slot.id;
                  return _TimeSlotButton(
                    slot: slot,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedTimeSlot = slot);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLessonsPerWeekSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
            title: '주 1회',
            subtitle: '월 4회',
            isSelected: _lessonsPerWeek == 1,
            onTap: () => setState(() => _lessonsPerWeek = 1),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _buildOptionCard(
            title: '주 2회',
            subtitle: '월 8회',
            isSelected: _lessonsPerWeek == 2,
            onTap: () => setState(() => _lessonsPerWeek = 2),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeSelector() {
    final fees = [160000, 180000, 200000, 240000];
    final labels = ['입문', '초급', '중급', '고급'];

    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: List.generate(fees.length, (index) {
        final isSelected = _monthlyFee == fees[index];
        return ChoiceChip(
          label: Text('${labels[index]} ${_formatFee(fees[index])}'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _monthlyFee = fees[index]);
          },
          backgroundColor: AppColors.surfaceLight,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }),
    );
  }

  Widget _buildStartDateSelector() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _startDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 60)),
          locale: const Locale('ko'),
        );
        if (picked != null) {
          setState(() => _startDate = picked);
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
            Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                '${_startDate.year}년 ${_startDate.month}월 ${_startDate.day}일부터',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.edit, size: 18, color: AppColors.textTertiaryLight),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final perLessonFee = _monthlyFee ~/ (_lessonsPerWeek * 4);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('레슨 유형', style: AppTypography.bodyMedium),
              Text(_scheduleType.label,
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          if (_scheduleType == ScheduleType.fixed &&
              _selectedTimeSlot != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('고정 시간', style: AppTypography.bodyMedium),
                Text(
                  '${_selectedTimeSlot!.fullDayName} ${_selectedTimeSlot!.timeRange}',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('레슨 횟수', style: AppTypography.bodyMedium),
              Text('주 $_lessonsPerWeek회 (월 ${_lessonsPerWeek * 4}회)',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('회당 수강료', style: AppTypography.bodyMedium),
              Text(_formatFee(perLessonFee),
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: AppSpacing.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('월 수강료', style: AppTypography.headingSmall),
              Text(
                _formatFee(_monthlyFee),
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isValid =
        _scheduleType == ScheduleType.flexible || _selectedTimeSlot != null;

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: FilledButton(
        onPressed: isValid && !_isSubmitting ? _submitRegistration : null,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('정규레슨 등록하기'),
      ),
    );
  }

  String _formatFee(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted원';
  }

  Future<void> _submitRegistration() async {
    if (_scheduleType == ScheduleType.fixed && _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('레슨 시간을 선택해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final registration = RegularLessonRegistration(
        studentId: widget.studentId ?? 'new_student',
        scheduleType: _scheduleType,
        fixedTimeSlot: _selectedTimeSlot,
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
            content: Text('등록 중 오류가 발생했습니다: $e'),
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

class _TimeSlotButton extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotButton({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
            ),
          ),
          child: Text(
            slot.timeRange,
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimaryLight,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
