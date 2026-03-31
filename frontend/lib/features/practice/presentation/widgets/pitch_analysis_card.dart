import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/pitch_analysis.dart';
import '../providers/pitch_analysis_provider.dart';

/// Card showing pitch analysis metrics for a recording.
class PitchAnalysisCard extends ConsumerWidget {
  const PitchAnalysisCard({super.key, required this.recordingId});

  final String recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(pitchAnalysisProvider(recordingId));

    return analysisAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (analysis) {
        if (analysis == null) return const SizedBox.shrink();
        return _buildCard(analysis.metrics);
      },
    );
  }

  Widget _buildCard(PitchAnalysisMetrics metrics) {
    final gradeColor = _gradeColor(metrics.gradeColorName);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.space2),
              Text('피치 분석', style: AppTypography.headingSmall),
              const Spacer(),
              // Grade badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  metrics.grade,
                  style: AppTypography.headingMedium.copyWith(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // In-tune percentage bar
          _buildMetricBar(
            label: '정확도',
            value: '${metrics.inTunePercent.round()}%',
            progress: metrics.inTunePercent / 100,
            color: gradeColor,
          ),

          const SizedBox(height: AppSpacing.space3),

          // Stability bar
          _buildMetricBar(
            label: '안정성',
            value: '${(metrics.stabilityScore * 100).round()}%',
            progress: metrics.stabilityScore,
            color: AppColors.info,
          ),

          const SizedBox(height: AppSpacing.space4),

          // Detail metrics row
          Row(
            children: [
              _buildDetailChip(
                icon: Icons.straighten,
                label: '평균 편차',
                value: '${metrics.averageCentDeviation.round()} cents',
              ),
              const SizedBox(width: AppSpacing.space2),
              _buildDetailChip(
                icon: Icons.music_note,
                label: '음역',
                value: '${metrics.frequencyMin.round()}-${metrics.frequencyMax.round()} Hz',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Note distribution
          if (metrics.noteDistribution.isNotEmpty) ...[
            Text(
              '음 분포',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            _buildNoteDistribution(metrics),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricBar({
    required String label,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space2),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiaryLight),
            const SizedBox(width: AppSpacing.space1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryLight,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteDistribution(PitchAnalysisMetrics metrics) {
    final sorted = metrics.noteDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sorted.first.value;

    return Wrap(
      spacing: AppSpacing.space1,
      runSpacing: AppSpacing.space1,
      children: sorted.take(7).map((entry) {
        final ratio = entry.value / maxCount;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05 + ratio * 0.2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1 + ratio * 0.3),
            ),
          ),
          child: Text(
            '${entry.key} (${entry.value})',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: ratio > 0.5 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _gradeColor(String colorName) => switch (colorName) {
        'success' => AppColors.success,
        'primary' => AppColors.primary,
        'info' => AppColors.info,
        'warning' => AppColors.warning,
        _ => AppColors.error,
      };
}
