import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/daily_practice.dart';

/// 1년 히트맵 셀 tap 시 노출되는 일별 분해 BottomSheet.
///
/// 스펙 §4.4 / 플랜 Job 6 Task 6.2 / AC-6.2. 5필드 (메트로놈 / 튜너 / YouTube /
/// 수동 분 + 녹음 회수) + 총 분 합산. 0분 필드는 hide (가독성).
class HeatmapDayDetailSheet extends StatelessWidget {
  const HeatmapDayDetailSheet({
    super.key,
    required this.date,
    required this.daily,
  });

  final DateTime date;
  final DailyPractice daily;

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hasAny = daily.totalMinutes > 0 || daily.recordingCount > 0;

    return Container(
      key: const ValueKey('heatmap_day_detail_sheet'),
      padding: EdgeInsets.all(AppSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(date),
            key: const ValueKey('heatmap_day_detail_date'),
            style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
          ),
          SizedBox(height: AppSpacing.space3),
          if (!hasAny)
            Padding(
              key: const ValueKey('heatmap_day_detail_empty'),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space3),
              child: Text(
                AppStrings.heatmapDayDetailEmptyMessage,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            )
          else ...[
            if (daily.metronomeMinutes > 0)
              _DetailRow(
                label: AppStrings.heatmapDayDetailMetronome,
                value: AppStrings.heatmapDayDetailMinutes(
                  daily.metronomeMinutes,
                ),
              ),
            if (daily.tunerMinutes > 0)
              _DetailRow(
                label: AppStrings.heatmapDayDetailTuner,
                value: AppStrings.heatmapDayDetailMinutes(daily.tunerMinutes),
              ),
            if (daily.youtubeMinutes > 0)
              _DetailRow(
                label: AppStrings.heatmapDayDetailYoutube,
                value: AppStrings.heatmapDayDetailMinutes(daily.youtubeMinutes),
              ),
            if (daily.manualMinutes > 0)
              _DetailRow(
                label: AppStrings.heatmapDayDetailManual,
                value: AppStrings.heatmapDayDetailMinutes(daily.manualMinutes),
              ),
            if (daily.recordingCount > 0)
              _DetailRow(
                label: AppStrings.heatmapDayDetailRecording,
                value: AppStrings.heatmapDayDetailCount(daily.recordingCount),
              ),
            SizedBox(height: AppSpacing.space3),
            Container(
              key: const ValueKey('heatmap_day_detail_total'),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space2),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.inkQuaternary)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.heatmapDayDetailTotalLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppStrings.heatmapDayDetailMinutes(daily.totalMinutes),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
