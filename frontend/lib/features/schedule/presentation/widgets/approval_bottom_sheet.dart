import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../features/lessons/presentation/providers/booking_providers.dart';
import 'schedule_option_card.dart';
import 'decline_bottom_sheet.dart';

/// Bottom sheet for booking approval with multi-option support.
class ApprovalBottomSheet extends ConsumerStatefulWidget {
  final LessonBooking booking;
  final String teacherId;
  final ScrollController scrollController;
  final VoidCallback onApproved;

  const ApprovalBottomSheet({
    super.key,
    required this.booking,
    required this.teacherId,
    required this.scrollController,
    required this.onApproved,
  });

  @override
  ConsumerState<ApprovalBottomSheet> createState() =>
      _ApprovalBottomSheetState();
}

class _ApprovalBottomSheetState extends ConsumerState<ApprovalBottomSheet> {
  String? _selectedOptionId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Pre-select primary option if available
    if (widget.booking.hasScheduleOptions) {
      _selectedOptionId = widget.booking.primaryOption?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final options = booking.sortedScheduleOptions;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          const Center(
            child: BottomSheetHandle(
              margin: EdgeInsets.only(top: AppSpacing.space2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              children: [
                _buildLessonTypeBadge(booking),
                const Spacer(),
                Text(
                  _getTimeSinceRequest(booking),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.inkQuaternary, height: 1),

          // Content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                // Student info
                _buildStudentInfo(booking),

                const SizedBox(height: AppSpacing.space5),

                // Schedule options or single schedule
                if (options.isNotEmpty) ...[
                  Text(
                    '희망 일정 중 하나를 선택해주세요',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  ...options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                      child: ScheduleOptionCard(
                        option: option,
                        mode: ScheduleOptionCardMode.teacher,
                        isSelected: option.id == _selectedOptionId,
                        onTap: () {
                          setState(() => _selectedOptionId = option.id);
                        },
                      ),
                    ),
                  ),
                ] else ...[
                  // Legacy single option display
                  _buildLegacyScheduleCard(booking),
                ],

                const SizedBox(height: AppSpacing.space4),

                // Warning note
                _buildWarningNote(),
              ],
            ),
          ),

          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildLessonTypeBadge(LessonBooking booking) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: booking.lessonType.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
      child: Text(
        '${booking.lessonType.label}레슨 신청',
        style: AppTypography.bodySmall.copyWith(
          color: booking.lessonType.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStudentInfo(LessonBooking booking) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            booking.studentName.isNotEmpty ? booking.studentName[0] : '?',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.studentName, style: AppTypography.headingSmall),
              if (booking.lessonGoal != null || booking.experienceLevel != null)
                Text(
                  [
                    if (booking.lessonGoal != null) booking.lessonGoal!.label,
                    if (booking.experienceLevel != null)
                      booking.experienceLevel!.label,
                  ].join(' · '),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              if (booking.studentMessage != null &&
                  booking.studentMessage!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: AppColors.inkSecondary,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          booking.studentMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegacyScheduleCard(LessonBooking booking) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.ink,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                booking.fullFormattedDate,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 18,
                color: AppColors.inkSecondary,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(booking.timeRange, style: AppTypography.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningNote() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              '모든 일정이 불가능하면 거절 후 메시지로 대안을 제안해주세요',
              style: AppTypography.caption.copyWith(color: AppColors.paperAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final hasOptions = widget.booking.hasScheduleOptions;
    final canApprove = !hasOptions || _selectedOptionId != null;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.space4,
        right: AppSpacing.space4,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.space4,
        top: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border(top: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : _handleReject,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space3,
                ),
                side: BorderSide(color: AppColors.inkQuaternary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: Text(
                '거절하기',
                style: AppTypography.button.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: FilledButton(
              onPressed: canApprove && !_isProcessing ? _handleApprove : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space3,
                ),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.inkSecondary
                    .withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child:
                  _isProcessing
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        '승인하기',
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove() async {
    setState(() => _isProcessing = true);

    try {
      await ref
          .read(bookingsNotifierProvider.notifier)
          .approveTrialLesson(
            widget.booking.id,
            selectedOptionId: _selectedOptionId,
          );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onApproved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.booking.studentName}님의 레슨이 승인되었습니다'),
          backgroundColor: AppColors.paperOk,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('승인 처리 중 오류가 발생했습니다. 다시 시도해주세요.'),
          backgroundColor: AppColors.paperAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleReject() async {
    final result = await showDeclineBottomSheet(
      context,
      durationMinutes: widget.booking.durationMinutes,
      teacherId: widget.teacherId,
    );

    if (result == null || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      await ref
          .read(bookingsNotifierProvider.notifier)
          .markUnavailable(
            widget.booking.id,
            result.message,
            suggestedTimeSlots:
                result.suggestedSlots.isNotEmpty ? result.suggestedSlots : null,
          );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onApproved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.suggestedSlots.isNotEmpty
                ? '대안 시간과 함께 학생에게 안내가 전달되었습니다'
                : '학생에게 안내가 전달되었습니다',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('처리 중 오류가 발생했습니다. 다시 시도해주세요.'),
          backgroundColor: AppColors.paperAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _getTimeSinceRequest(LessonBooking booking) {
    final now = DateTime.now();
    final diff = now.difference(booking.createdAt);

    if (diff.inDays > 0) {
      return '${diff.inDays}일 전 신청';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전 신청';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전 신청';
    } else {
      return '방금 신청';
    }
  }
}
