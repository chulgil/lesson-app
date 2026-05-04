// Summary card showing total, completed, and in-progress repertoire counts

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Summary card for repertoire history
class HistorySummaryCard extends StatelessWidget {
  final int totalCount;
  final int completedCount;
  final int inProgressCount;

  const HistorySummaryCard({
    super.key,
    required this.totalCount,
    required this.completedCount,
    required this.inProgressCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: const BoxDecoration(color: AppColors.paper),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.music_note,
            iconColor: AppColors.paperAccent,
            label: AppStrings.practiceTotalLabel,
            value: '$totalCount곡',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.check_circle,
            iconColor: AppColors.paperOk,
            label: AppStrings.practiceCompletedLabel,
            value: '$completedCount',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.edit_note,
            iconColor: AppColors.paperAccent,
            label: AppStrings.practiceInProgress,
            value: '$inProgressCount',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: AppSpacing.iconMD),
        const SizedBox(height: AppSpacing.space1),
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: AppColors.inkQuaternary);
  }
}
