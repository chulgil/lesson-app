import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Pre-notice banner (#473) shown when a lesson is unconfirmed and ended
/// within the last 24h. Warns that the backend will auto-complete the lesson
/// (deducting 1 session) once 24h have elapsed.
///
/// Reuses the lesson detail banner pattern (soft accent bg + accent border).
class AttendanceAutoCompleteBanner extends StatelessWidget {
  const AttendanceAutoCompleteBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule,
            color: AppColors.paperAccent,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              AppStrings.attendanceAutoCompleteNotice,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deduction result indicator (#473).
///
/// - [deducted] true  → "수강권 1회 차감됨" (completed lessons)
/// - [deducted] false → "차감 없음" (휴강/취소 lessons)
class AttendanceDeductionResultChip extends StatelessWidget {
  final bool deducted;

  const AttendanceDeductionResultChip({super.key, required this.deducted});

  @override
  Widget build(BuildContext context) {
    final color = deducted ? AppColors.paperAccent : AppColors.inkSecondary;
    final label =
        deducted
            ? AppStrings.attendanceDeductedResult
            : AppStrings.attendanceNoDeductionResult;
    final icon = deducted ? Icons.remove_circle_outline : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppSpacing.space2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
