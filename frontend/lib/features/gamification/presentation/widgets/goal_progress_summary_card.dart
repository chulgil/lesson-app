// 학생 대시보드용 연습 목표 요약 카드 (doc 46 §4, P2 데일리 만족 루프).
// #1269: 목표 위젯 단일화 — 이전에는 이 카드가 device-local `DailyPracticeGoal`
// 값을 썼지만, 이제 practice 탭 [GoalProgressWidget]과 동일한 원격 영속
// [PracticeGoal] (`practiceGoalProvider`)을 컴팩트하게 요약해 보여준다. 목표
// 편집은 이 위젯이 자체 UI를 갖지 않고 practice 목표 설정 화면 하나로
// 위임한다 — 목표 데이터가 관리되는 곳이 두 곳으로 갈라지지 않도록 한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../practice/practice_facade.dart' show practiceGoalProvider;
import '../providers/today_practice_minutes_provider.dart';

/// 오늘의 연습 목표 카드 — 학생 대시보드 상단.
///
/// [PracticeGoal.dailyTimeMinutes]가 목표(target), heatmap 오늘 cell
/// ([todayPracticeMinutesProvider])이 진행값(progress)이다 — 진행값은
/// [growthHeatmapProvider]가 채우는 실제 연습 신호(메트로놈/튜너/유튜브/
/// 수동 기록)에서 파생하므로, 이 카드와 성장 히트맵의 오늘 칸은 항상 같은
/// 분(分)을 표시한다.
///
/// 목표가 설정되지 않았으면 practice 탭의 [GoalProgressWidget] 과 동일한
/// 빈 상태 CTA 를 보여준다 — 임의의 기본 목표를 조용히 가정하지 않는다.
class GoalProgressSummaryCard extends ConsumerWidget {
  const GoalProgressSummaryCard({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(practiceGoalProvider(studentId));
    final todayMinutes =
        ref.watch(todayPracticeMinutesProvider(studentId)).valueOrNull ?? 0;

    return goalAsync.when(
      data: (goal) {
        final goalMinutes = goal?.dailyTimeMinutes;
        if (goalMinutes == null) {
          return _GoalSummaryEmptyCard(studentId: studentId);
        }
        return _GoalSummaryProgressCard(
          studentId: studentId,
          goalMinutes: goalMinutes,
          todayMinutes: todayMinutes,
        );
      },
      loading: () => const _GoalSummarySkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _GoalSummaryEmptyCard extends StatelessWidget {
  const _GoalSummaryEmptyCard({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('goal_summary_card_empty'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flag_outlined,
            size: AppSpacing.iconSM,
            color: AppColors.inkSecondary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              AppStrings.goalProgressEmptyTitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
              ),
              foregroundColor: AppColors.paperAccent,
            ),
            onPressed: () {
              context.push(
                '${AppRoutes.practiceGoalSettings}?studentId=$studentId',
              );
            },
            child: Text(
              AppStrings.goalProgressEmptyAction,
              style: AppTypography.buttonSmall.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalSummaryProgressCard extends StatelessWidget {
  const _GoalSummaryProgressCard({
    required this.studentId,
    required this.goalMinutes,
    required this.todayMinutes,
  });

  final String studentId;
  final int goalMinutes;
  final int todayMinutes;

  @override
  Widget build(BuildContext context) {
    final ratio = goalMinutes > 0
        ? (todayMinutes / goalMinutes).clamp(0.0, 1.0)
        : 0.0;
    final achieved = goalMinutes > 0 && todayMinutes >= goalMinutes;

    return GestureDetector(
      key: const ValueKey('goal_summary_card'),
      onTap: () {
        context.push('${AppRoutes.practiceGoalSettings}?studentId=$studentId');
      },
      child: Container(
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
                Icon(
                  achieved ? Icons.check_circle : Icons.flag_outlined,
                  size: AppSpacing.iconMD,
                  color: achieved ? AppColors.paperOk : AppColors.ink,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    AppStrings.dailyGoalCardTitle,
                    style: NotebookTypography.sectionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.edit_outlined,
                  size: AppSpacing.iconXS,
                  color: AppColors.inkTertiary,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  AppStrings.dailyGoalProgressLabel(todayMinutes, goalMinutes),
                  key: const ValueKey('goal_summary_progress_label'),
                  style: AppTypography.bodyMedium.copyWith(
                    color: achieved
                        ? AppColors.paperOk
                        : AppColors.inkSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: LinearProgressIndicator(
                key: const ValueKey('goal_summary_progress_bar'),
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.inkQuaternary,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.paperOk,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              _footerLabel(achieved: achieved),
              key: const ValueKey('goal_summary_footer_label'),
              style: AppTypography.bodySmall.copyWith(
                color: achieved ? AppColors.paperOk : AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _footerLabel({required bool achieved}) {
    if (achieved) return AppStrings.dailyGoalAchievedLabel;
    if (todayMinutes <= 0) return AppStrings.dailyGoalStartPrompt;
    return AppStrings.dailyGoalRemainingLabel(goalMinutes - todayMinutes);
  }
}

class _GoalSummarySkeleton extends StatelessWidget {
  const _GoalSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
    );
  }
}
