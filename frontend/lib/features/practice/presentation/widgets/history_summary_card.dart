// Summary card showing total, completed, and in-progress repertoire counts

import 'package:flutter/material.dart';

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
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.music_note,
            iconColor: AppColors.primary,
            label: '전체',
            value: '$totalCount곡',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.check_circle,
            iconColor: AppColors.success,
            label: '완료',
            value: '$completedCount',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.edit_note,
            iconColor: AppColors.secondary,
            label: '진행 중',
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
          style: AppTypography.headingSmall.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: AppColors.borderLight);
  }
}
