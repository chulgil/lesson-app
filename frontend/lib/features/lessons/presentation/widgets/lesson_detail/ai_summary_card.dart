// AI summary card widget

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// AI-generated lesson summary card
class AISummaryCard extends StatelessWidget {
  final String summary;

  const AISummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.paperAccent.withValues(alpha: 0.05),
            AppColors.paperAccent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.paperAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: AppColors.paperAccent),
              const SizedBox(width: AppSpacing.space2),
              Text(
                'AI가 생성한 레슨 요약',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(summary, style: AppTypography.bodyMedium.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
