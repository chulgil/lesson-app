import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/core/widgets/notebook/thin_rule.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../core/booking/presentation/extensions/lesson_booking_visual_extensions.dart';
import 'schedule_option_card.dart';

/// A card for teacher to approve booking with multiple schedule options
class TeacherApprovalCard extends StatefulWidget {
  final LessonBooking booking;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final ValueChanged<String>? onOptionSelected;

  const TeacherApprovalCard({
    super.key,
    required this.booking,
    this.onApprove,
    this.onReject,
    this.onOptionSelected,
  });

  @override
  State<TeacherApprovalCard> createState() => _TeacherApprovalCardState();
}

class _TeacherApprovalCardState extends State<TeacherApprovalCard> {
  String? _selectedOptionId;

  @override
  void initState() {
    super.initState();
    // Pre-select the primary option if available
    if (widget.booking.hasScheduleOptions) {
      _selectedOptionId = widget.booking.primaryOption?.id;
    }
  }

  void _selectOption(String optionId) {
    setState(() {
      _selectedOptionId = optionId;
    });
    widget.onOptionSelected?.call(optionId);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final options = booking.sortedScheduleOptions;

    return NotebookCard(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.inkQuaternary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: AppSpacing.space4),

            // Student info
            _buildStudentInfo(),

            const SizedBox(height: AppSpacing.space4),

            // Divider
            const ThinRule(),

            const SizedBox(height: AppSpacing.space4),

            // Schedule options
            Text(
              '희망 일정 중 하나를 선택해주세요',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppSpacing.space3),

            // Option cards
            if (options.isNotEmpty) ...[
              ...options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                  child: ScheduleOptionCard(
                    option: option,
                    mode: ScheduleOptionCardMode.teacher,
                    isSelected: option.id == _selectedOptionId,
                    onTap: () => _selectOption(option.id),
                  ),
                ),
              ),
            ] else ...[
              // Fallback for legacy single-option bookings
              _buildLegacyScheduleCard(),
            ],

            const SizedBox(height: AppSpacing.space4),

            // Action buttons
            _buildActionButtons(),

            const SizedBox(height: AppSpacing.space3),

            // Warning note
            _buildWarningNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final booking = widget.booking;
    return Row(
      children: [
        // Lesson type badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(
            color: booking.lessonType.color.withValues(alpha: 0.1),
          ),
          child: Text(
            '${booking.lessonType.label}레슨 신청',
            style: AppTypography.bodySmall.copyWith(
              color: booking.lessonType.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const Spacer(),

        // Time since request
        Text(
          _getTimeSinceRequest(),
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
        ),
      ],
    );
  }

  Widget _buildStudentInfo() {
    final booking = widget.booking;
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.paperAccentSoft,
          child: Text(
            booking.studentName.isNotEmpty ? booking.studentName[0] : '?',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.studentName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  padding: const EdgeInsets.all(AppSpacing.space2),
                  decoration: BoxDecoration(
                    color: AppColors.paperDark,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: AppColors.inkSecondary,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          booking.studentMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildLegacyScheduleCard() {
    final booking = widget.booking;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent, width: 2),
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
              Icon(Icons.access_time, size: 18, color: AppColors.inkSecondary),
              const SizedBox(width: AppSpacing.space2),
              Text(booking.timeRange, style: AppTypography.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canApprove =
        _selectedOptionId != null || !widget.booking.hasScheduleOptions;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onReject,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              side: BorderSide(color: AppColors.inkQuaternary),
              shape: RoundedRectangleBorder(),
            ),
            child: Text(
              AppStrings.rejectAction,
              style: AppTypography.button.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: FilledButton(
            onPressed: canApprove ? widget.onApprove : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              backgroundColor: AppColors.paperAccent,
              disabledBackgroundColor: AppColors.inkSecondary.withValues(
                alpha: 0.3,
              ),
              shape: RoundedRectangleBorder(),
            ),
            child: Text(
              '승인하기',
              style: AppTypography.button.copyWith(color: AppColors.paper),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningNote() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(color: AppColors.paperAccentSoft),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              '모든 일정이 불가능하면 거절 후 메시지로 대안을 제안해주세요',
              style: AppTypography.caption.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeSinceRequest() {
    final now = DateTime.now();
    final diff = now.difference(widget.booking.createdAt);

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

  /// Get the currently selected option ID
  String? get selectedOptionId => _selectedOptionId;
}

/// A compact version for list views
class TeacherApprovalListItem extends StatelessWidget {
  final LessonBooking booking;
  final VoidCallback? onTap;

  const TeacherApprovalListItem({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    return NotebookCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.inkQuaternary),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              // Student avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.paperAccentSoft,
                child: Text(
                  booking.studentName.isNotEmpty ? booking.studentName[0] : '?',
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.space3),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          booking.studentName,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: booking.lessonType.color.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            booking.lessonType.label,
                            style: AppTypography.caption.copyWith(
                              color: booking.lessonType.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    if (booking.hasScheduleOptions)
                      Text(
                        '${booking.scheduleOptionsCount}개 일정 제안',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      )
                    else
                      Text(
                        '${booking.formattedDate} ${booking.timeRange}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.chevron_right, color: AppColors.inkSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
