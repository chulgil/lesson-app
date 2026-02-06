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
            icon: Icons.calendar_month,
            value: '${student.totalLessons}',
            label: '총 레슨',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: StudentStatCard(
            icon: Icons.event_note,
            value: '${student.monthlyLessons}',
            label: '이번 달',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: StudentStatCard(
            icon: Icons.fitness_center,
            value: '${student.practiceRate}일',
            label: '주간 연습',
            color: student.practiceStatus.color,
          ),
        ),
      ],
    );
  }
}

/// Individual stat card widget
class StudentStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StudentStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.space2),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(color: color),
          ),
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
