import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Dialog to confirm lesson booking with reschedule policy notice
class BookingConfirmDialog extends StatelessWidget {
  final String teacherName;
  final DateTime lessonDate;
  final String startTime;
  final String endTime;
  final int? remainingReschedules;
  final int? totalReschedules;
  final bool isReschedule;
  final bool isTrialLesson;

  const BookingConfirmDialog({
    super.key,
    required this.teacherName,
    required this.lessonDate,
    required this.startTime,
    required this.endTime,
    this.remainingReschedules,
    this.totalReschedules,
    this.isReschedule = false,
    this.isTrialLesson = false,
  });

  /// Show the dialog and return true if user confirms, false otherwise
  static Future<bool> show(
    BuildContext context, {
    required String teacherName,
    required DateTime lessonDate,
    required String startTime,
    required String endTime,
    int? remainingReschedules,
    int? totalReschedules,
    bool isReschedule = false,
    bool isTrialLesson = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => BookingConfirmDialog(
            teacherName: teacherName,
            lessonDate: lessonDate,
            startTime: startTime,
            endTime: endTime,
            remainingReschedules: remainingReschedules,
            totalReschedules: totalReschedules,
            isReschedule: isReschedule,
            isTrialLesson: isTrialLesson,
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
      ),
      // Notebook × Score: AlertDialog title 은 전역 dialogTheme.titleTextStyle
      // (NotebookTypography.dialogTitle) 을 상속. 인라인 style 오버라이드 제거 (§7.41 cleanup 패턴).
      title: Text(
        isReschedule ? '레슨 시간을 변경하시겠습니까?' : '예약을 확정하시겠습니까?',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson info card
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.paperAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.paperAccent),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      teacherName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.paperAccent,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      _formatDate(lessonDate),
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space1),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.paperAccent,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '$startTime - $endTime',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Policy notices (not for trial lessons)
          if (!isTrialLesson) ...[
            _buildPolicyNotice(
              icon: Icons.info_outline,
              text:
                  isReschedule
                      ? '확정 시 변경권 1회가 차감됩니다.'
                      : '예약 확정 후 변경 시 변경권이 차감됩니다.',
              color: AppColors.paperAccent,
            ),
            const SizedBox(height: AppSpacing.space2),
            _buildPolicyNotice(
              icon: Icons.warning_amber_outlined,
              text: '변경권이 없는 경우 레슨 시간 변경이 불가합니다.',
              color: AppColors.inkSecondary,
            ),

            // Show remaining reschedules if available
            if (remainingReschedules != null && totalReschedules != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getRescheduleCountColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      size: 18,
                      color: _getRescheduleCountColor(),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '잔여 변경권: $remainingReschedules / $totalReschedules회',
                      style: AppTypography.bodyMedium.copyWith(
                        color: _getRescheduleCountColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Trial lesson notice
            _buildPolicyNotice(
              icon: Icons.school,
              text: '체험 레슨은 1회만 가능합니다.',
              color: AppColors.paperAccent,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            '취소',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.paperAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
          child: Text(isReschedule ? '변경 확정' : '예약 확정'),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        AppSpacing.space4,
      ),
    );
  }

  Widget _buildPolicyNotice({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(color: color, height: 1.4),
          ),
        ),
      ],
    );
  }

  Color _getRescheduleCountColor() {
    if (remainingReschedules == null) return AppColors.inkSecondary;
    if (remainingReschedules! <= 0) return AppColors.paperAccent;
    if (remainingReschedules! == 1) return AppColors.paperAccent;
    return AppColors.paperOk;
  }

  String _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}년 ${date.month}월 ${date.day}일 ($weekday)';
  }
}
