import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Teacher action surface for an unconfirmed lesson (#473).
///
/// Shown on the lesson detail screen when a lesson is still `scheduled`
/// but its end time has already passed. Offers two clear choices:
/// - 출석 확인 → mark completed (deducts 1 session)
/// - 휴강 → mark cancelledByTeacher (no deduction)
///
/// Stateless + callback-driven so the screen owns the provider/dialog flow.
class AttendanceActionCard extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onDayOff;

  const AttendanceActionCard({
    super.key,
    required this.onConfirm,
    required this.onDayOff,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check,
                color: AppColors.paperAccent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  AppStrings.attendanceActionTitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.attendanceActionDescription,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              Expanded(
                child: _AttendanceActionButton(
                  icon: Icons.check_circle,
                  label: AppStrings.attendanceConfirmAction,
                  sublabel: AppStrings.attendanceConfirmSubLabel,
                  color: AppColors.paperOk,
                  onTap: onConfirm,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: _AttendanceActionButton(
                  icon: Icons.event_busy,
                  label: AppStrings.attendanceDayOffAction,
                  sublabel: AppStrings.attendanceDayOffSubLabel,
                  color: AppColors.ink,
                  onTap: onDayOff,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _AttendanceActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space4,
        ),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: AppTypography.caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
