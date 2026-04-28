import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
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
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.space2),
              // Notebook × Score: 카드 섹션 제목은 Playfair sectionTitle
              // 로 통일 (§7.17).
              Text('피치 분석', style: NotebookTypography.sectionTitle),
              const Spacer(),
              // Grade badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.15),
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
            color: AppColors.ink,
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
                value:
                    '${metrics.frequencyMin.round()}-${metrics.frequencyMax.round()} Hz',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Note distribution
          if (metrics.noteDistribution.isNotEmpty) ...[
            Text(
              '음 분포',
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
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
                color: AppColors.inkSecondary,
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
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.inkQuaternary,
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
        decoration: BoxDecoration(color: AppColors.paper),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.inkTertiary),
            const SizedBox(width: AppSpacing.space1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.inkTertiary,
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
    final sorted =
        metrics.noteDistribution.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sorted.first.value;

    return Wrap(
      spacing: AppSpacing.space1,
      runSpacing: AppSpacing.space1,
      children:
          sorted.take(7).map((entry) {
            final ratio = entry.value / maxCount;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(
                  alpha: 0.05 + ratio * 0.2,
                ),
                border: Border.all(
                  color: AppColors.paperAccent.withValues(
                    alpha: 0.1 + ratio * 0.3,
                  ),
                ),
              ),
              child: Text(
                '${entry.key} (${entry.value})',
                style: AppTypography.caption.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: ratio > 0.5 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
    );
  }

  Color _gradeColor(String colorName) => switch (colorName) {
    'success' => AppColors.paperOk,
    'primary' => AppColors.paperAccent,
    'info' => AppColors.ink,
    'warning' => AppColors.paperAccent,
    _ => AppColors.paperAccent,
  };
}
