// Repertoire card for timeline history display

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/practice_repertoire.dart';

/// Card displaying a single repertoire in the history timeline
class RepertoireTimelineCard extends StatelessWidget {
  final PracticeRepertoire repertoire;

  const RepertoireTimelineCard({super.key, required this.repertoire});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space1,
      ),
      child: InkWell(
        onTap: () {
          context.push(
            '${AppRoutes.repertoireDetail.replaceFirst(':id', repertoire.id)}'
            '?studentId=${repertoire.studentId}',
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      repertoire.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),

              // Period text
              Text(
                _periodText,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),

              // Section & recording counts
              Text(
                _countsText,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                child: LinearProgressIndicator(
                  value: repertoire.completionRate.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.inkQuaternary,
                  valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build status badge based on repertoire state
  Widget _buildStatusBadge() {
    final String label;
    final Color backgroundColor;
    final Color textColor;

    if (repertoire.isArchived) {
      label = '아카이브';
      backgroundColor = AppColors.inkTertiary.withValues(alpha: 0.15);
      textColor = AppColors.inkTertiary;
    } else if (repertoire.endDate != null) {
      label = '완료';
      backgroundColor = AppColors.paperOk.withValues(alpha: 0.15);
      textColor = AppColors.paperOk;
    } else {
      label = '진행 중';
      backgroundColor = AppColors.paperAccent.withValues(alpha: 0.15);
      textColor = AppColors.paperAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Period text (e.g., "1월~ (진행 중)" or "3월~9월 (6개월)")
  String get _periodText {
    final startMonth = '${repertoire.startDate.month}월';
    if (repertoire.endDate == null) {
      return '$startMonth~ (진행 중)';
    }
    final endMonth = '${repertoire.endDate!.month}월';
    final months = _monthsBetween(repertoire.startDate, repertoire.endDate!);
    return '$startMonth~$endMonth ($months개월)';
  }

  /// Calculate months between two dates
  int _monthsBetween(DateTime start, DateTime end) {
    final diff = (end.year - start.year) * 12 + (end.month - start.month);
    return diff < 1 ? 1 : diff;
  }

  /// Section and recording counts text
  String get _countsText {
    final sectionCount = repertoire.sections.length;
    final recordingCount = repertoire.sections.fold<int>(
      0,
      (sum, s) => sum + s.recordings.length,
    );
    return '섹션 $sectionCount개 \u00B7 녹음 $recordingCount개';
  }

  /// Progress bar color based on completion
  Color get _progressColor {
    if (repertoire.isArchived) return AppColors.inkTertiary;
    if (repertoire.completionRate >= 1.0) return AppColors.paperOk;
    return AppColors.paperAccent;
  }
}
