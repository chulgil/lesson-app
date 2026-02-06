import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../relationship/presentation/providers/relationship_providers.dart';
import '../../domain/entities/lesson_request.dart';
import '../providers/lesson_request_providers.dart';

/// Screen for students to send lesson request to previous teachers.
///
/// Used when a student (past status) wants to resume lessons.
/// Shows previous schedule information and allows message input.
class LessonRequestScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;

  /// Previous lesson period (e.g., "2024.03 ~ 2024.12")
  final String? previousLessonPeriod;

  const LessonRequestScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
    this.previousLessonPeriod,
  });

  @override
  ConsumerState<LessonRequestScreen> createState() =>
      _LessonRequestScreenState();
}

class _LessonRequestScreenState extends ConsumerState<LessonRequestScreen> {
  final _messageController = TextEditingController();
  PreferredStartTiming _selectedTiming = PreferredStartTiming.nextWeek;
  bool _keepPreviousSchedule = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previousScheduleAsync = ref.watch(
      previousScheduleProvider(
        teacherId: widget.teacherId,
        studentId: widget.studentId,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('레슨 요청'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teacher info header
            _buildTeacherHeader(),
            const SizedBox(height: AppSpacing.space6),

            // Previous schedule section
            previousScheduleAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.space4),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (schedule) {
                if (schedule == null) return const SizedBox.shrink();
                return _buildPreviousScheduleSection(schedule);
              },
            ),

            const SizedBox(height: AppSpacing.space6),

            // Message input
            _buildMessageSection(),
            const SizedBox(height: AppSpacing.space6),

            // Preferred timing selection
            _buildTimingSection(),
            const SizedBox(height: AppSpacing.space8),

            // Submit button
            _buildSubmitButton(previousScheduleAsync.valueOrNull),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.person,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.teacherName,
                  style: AppTypography.headingSmall,
                ),
                const SizedBox(height: 4),
                if (widget.previousLessonPeriod != null)
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '이전 레슨: ${widget.previousLessonPeriod}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousScheduleSection(PreviousSchedule schedule) {
    final scheduleText = LessonDateUtils.formatScheduleDisplay(
      weekday: schedule.lessonDay,
      time: schedule.lessonTime,
      includeWeekly: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.space2),
            Text('이전 스케줄', style: AppTypography.headingSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: AppColors.info.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: AppColors.info, size: 24),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scheduleText,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (schedule.lessonDuration != null)
                          Text(
                            '${schedule.lessonDuration}분 레슨',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.space3),
              InkWell(
                onTap: () {
                  setState(() {
                    _keepPreviousSchedule = !_keepPreviousSchedule;
                  });
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: _keepPreviousSchedule,
                      onChanged: (value) {
                        setState(() {
                          _keepPreviousSchedule = value ?? true;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: Text(
                        '이전 스케줄 유지하기',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: _keepPreviousSchedule
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_keepPreviousSchedule)
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(
                    '선생님과 새로운 시간을 상담합니다',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.message, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.space2),
            Text('메시지', style: AppTypography.headingSmall),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '(선택)',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        TextField(
          controller: _messageController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: '선생님께 전달할 메시지를 입력하세요',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.space2),
            Text('희망 시작', style: AppTypography.headingSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: PreferredStartTiming.values.map((timing) {
            final isSelected = _selectedTiming == timing;
            return ChoiceChip(
              label: Text(timing.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTiming = timing;
                  });
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundColor: Colors.white,
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(PreviousSchedule? schedule) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : () => _submitRequest(schedule),
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send),
        label: Text(_isSubmitting ? '요청 보내는 중...' : '레슨 요청 보내기'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Future<void> _submitRequest(PreviousSchedule? schedule) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final request = LessonRequest(
        id: const Uuid().v4(),
        studentId: widget.studentId,
        teacherId: widget.teacherId,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        preferredTiming: _selectedTiming,
        keepPreviousSchedule: _keepPreviousSchedule,
        previousLessonDay: schedule?.lessonDay,
        previousLessonTime: schedule?.lessonTime,
        previousLessonDuration: schedule?.lessonDuration,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)),
      );

      // Save request to repository
      await ref.read(lessonRequestActionsProvider.notifier).createRequest(request);

      // TODO: Send push notification to teacher
      // await ref.read(notificationServiceProvider).sendLessonRequestNotification(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.teacherName}에게 레슨 요청을 보냈습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('요청 전송에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
