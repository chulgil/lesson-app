// Practice ranking list showing TOP 5 students by practice rate.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/teacher_stats.dart';

/// Practice ranking list widget showing top practicing students.
class PracticeRankingList extends StatelessWidget {
  final List<StudentPracticeRank> rankings;

  const PracticeRankingList({super.key, required this.rankings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('연습률 TOP 5', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child:
              rankings.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.space6),
                    child: Center(
                      child: Text(
                        '연습 데이터가 없습니다',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                    ),
                  )
                  : Column(
                    children:
                        rankings.asMap().entries.map((entry) {
                          final index = entry.key;
                          final rank = entry.value;
                          final isLast = index == rankings.length - 1;
                          return Column(
                            children: [
                              _buildRankingTile(index + 1, rank),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  indent: AppSpacing.space4,
                                  endIndent: AppSpacing.space4,
                                  color: AppColors.inkQuaternary,
                                ),
                            ],
                          );
                        }).toList(),
                  ),
        ),
      ],
    );
  }

  Widget _buildRankingTile(int rank, StudentPracticeRank student) {
    final Color rankColor;
    if (rank == 1) {
      rankColor = AppColors.paperAccent;
    } else if (rank == 2) {
      rankColor = AppColors.inkSecondary;
    } else if (rank == 3) {
      rankColor = AppColors.paperAccent;
    } else {
      rankColor = AppColors.inkTertiary;
    }

    final percent = (student.practiceRate * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: AppTypography.bodySmall.copyWith(
                color: rankColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),

          // Name + instrument
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  student.instrument,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              child: LinearProgressIndicator(
                value: student.practiceRate,
                minHeight: 8,
                backgroundColor: AppColors.paperDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  student.practiceRate >= 0.8
                      ? AppColors.paperOk
                      : student.practiceRate >= 0.5
                      ? AppColors.practiceNormal
                      : AppColors.paperAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),

          // Percentage
          SizedBox(
            width: 40,
            child: Text(
              '$percent%',
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
