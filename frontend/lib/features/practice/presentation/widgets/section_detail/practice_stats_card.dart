// Practice stats card widget

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../features/practice/domain/entities/practice_repertoire.dart';

/// Practice stats card showing practice count, time, and recordings
class PracticeStatsCard extends StatelessWidget {
  final PracticeSection section;

  const PracticeStatsCard({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.repeat,
                label: '연습 횟수',
                value: '${section.practiceCount}회',
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.inkQuaternary,
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.timer,
                label: '총 연습 시간',
                value: section.formattedTotalTime,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.inkQuaternary,
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.mic,
                label: '녹음',
                value: '${section.recordings.length}개',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.paperAccent, size: 20),
        const SizedBox(height: AppSpacing.space1),
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(
            color: AppColors.paperAccent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }
}
