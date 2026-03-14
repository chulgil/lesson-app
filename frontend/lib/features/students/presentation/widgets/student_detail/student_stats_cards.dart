// Student stats cards widgets

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/student.dart';

/// Stats cards row for student detail screen
class StudentStatsCards extends StatelessWidget {
  final Student student;

  const StudentStatsCards({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StudentStatCard(
            value: '${student.totalLessons}',
            label: '총 레슨',
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: StudentStatCard(
            value: '${student.monthlyLessons}',
            label: '이번 달',
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: StudentStatCard(
            value: '${student.practiceRate}일',
            label: '주간 연습',
          ),
        ),
      ],
    );
  }
}

/// Individual stat card widget — neutral tone, no icon
class StudentStatCard extends StatelessWidget {
  final String value;
  final String label;

  const StudentStatCard({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
