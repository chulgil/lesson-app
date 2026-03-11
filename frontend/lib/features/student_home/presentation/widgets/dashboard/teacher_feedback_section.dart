import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Section showing the most recent teacher feedback.
class TeacherFeedbackSection extends StatelessWidget {
  final String studentId;

  const TeacherFeedbackSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 피드백', style: AppTypography.headingMedium),
            TextButton(
              onPressed: () {
                context.push(
                    '${AppRoutes.repertoireHistory}?studentId=$studentId');
              },
              child: const Text('더보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        _buildTeacherFeedback(),
      ],
    );
  }

  Widget _buildTeacherFeedback() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  '김',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '김선생님',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '12월 18일',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          Text(
            '이번 주 바흐 파르티타 연습 잘 하고 있어요! '
            'Allemande 부분에서 보잉이 많이 좋아졌습니다. '
            '다음 레슨까지 Sarabande 첫 페이지 천천히 읽어오세요.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          Wrap(
            spacing: AppSpacing.space2,
            children: [
              _buildTag('보잉 개선', AppColors.practiceGood),
              _buildTag('Sarabande 예습', AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
