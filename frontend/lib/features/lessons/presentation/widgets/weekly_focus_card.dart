import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/lesson.dart';

/// #1106 — 피드백 → 연습 연결 카드.
///
/// 학생이 레슨 피드백을 "정보"로만 소비하고 행동으로 이어지지 않는 문제를 해결한다.
/// 이번 주 집중할 한 가지(첫 keyPoint, 없으면 practiceTips)를 강조하고
/// "지금 연습하기" CTA 로 연습 허브(/practice/repertoire)로 바로 이동시킨다.
///
/// 게이팅: 학생 뷰 전용. 교사 뷰이거나 집중 항목이 없으면 렌더하지 않는다.
class WeeklyFocusCard extends StatelessWidget {
  final Lesson lesson;
  final bool isTeacher;

  const WeeklyFocusCard({
    super.key,
    required this.lesson,
    required this.isTeacher,
  });

  /// 이번 주 집중 항목: 첫 keyPoint → practiceTips → null.
  static String? focusContentOf(Lesson lesson) {
    final points = lesson.keyPoints;
    if (points != null) {
      for (final point in points) {
        if (point.trim().isNotEmpty) return point;
      }
    }
    final tips = lesson.practiceTips;
    if (tips != null && tips.trim().isNotEmpty) return tips;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isTeacher) return const SizedBox.shrink();
    final content = focusContentOf(lesson);
    if (content == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.center_focus_strong,
                color: AppColors.paperAccent,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                AppStrings.weeklyFocusTitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.space3),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => context.push(AppRoutes.practiceRepertoire),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
              ),
              child: Text(
                AppStrings.weeklyFocusPracticeCta,
                style: AppTypography.buttonSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
