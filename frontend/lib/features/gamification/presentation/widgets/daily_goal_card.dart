// 오늘의 연습 목표 진행바 — 잔디(성장 히트맵) 연동 (doc 46 §4, P2 데일리 만족 루프).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../providers/daily_practice_goal_provider.dart';

/// 오늘의 연습 목표 카드 — 학생 대시보드 상단.
///
/// ESL 앱 관행: "오늘 목표"만 다룬다. 진행바는 100% 상한(clamp)이며 밀린
/// 목표를 누적 표시하지 않는다. 진행 숫자는 [growthHeatmapProvider]가
/// 채우는 오늘 cell 과 동일 소스([todayPracticeMinutesProvider]) — 이 카드의
/// 진행바와 성장 히트맵의 오늘 칸은 항상 같은 분(分)을 표시한다.
///
/// tap → [showNotebookModalBottomSheet] 로 5~60분 stepper 를 연다.
class DailyGoalCard extends ConsumerWidget {
  const DailyGoalCard({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal =
        ref.watch(dailyPracticeGoalProvider(studentId)).valueOrNull ??
        DailyPracticeGoal.defaultGoalMinutes;
    final todayMinutes =
        ref.watch(todayPracticeMinutesProvider(studentId)).valueOrNull ?? 0;

    final ratio = goal > 0 ? (todayMinutes / goal).clamp(0.0, 1.0) : 0.0;
    final achieved = goal > 0 && todayMinutes >= goal;

    return GestureDetector(
      key: const ValueKey('daily_goal_card'),
      onTap: () => _openAdjustSheet(context, goal),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.zero,
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
                const SizedBox(width: AppSpacing.space2),
                Text(
                  AppStrings.dailyGoalProgressLabel(todayMinutes, goal),
                  key: const ValueKey('daily_goal_progress_label'),
                  style: AppTypography.bodyMedium.copyWith(
                    color:
                        achieved ? AppColors.paperOk : AppColors.inkSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: LinearProgressIndicator(
                key: const ValueKey('daily_goal_progress_bar'),
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
              _footerLabel(
                achieved: achieved,
                todayMinutes: todayMinutes,
                goal: goal,
              ),
              key: const ValueKey('daily_goal_footer_label'),
              style: AppTypography.bodySmall.copyWith(
                color: achieved ? AppColors.paperOk : AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _footerLabel({
    required bool achieved,
    required int todayMinutes,
    required int goal,
  }) {
    if (achieved) return AppStrings.dailyGoalAchievedLabel;
    if (todayMinutes <= 0) return AppStrings.dailyGoalStartPrompt;
    return AppStrings.dailyGoalRemainingLabel(goal - todayMinutes);
  }

  void _openAdjustSheet(BuildContext context, int currentGoal) {
    showNotebookModalBottomSheet<void>(
      context: context,
      builder:
          (_) => _DailyGoalAdjustSheet(
            studentId: studentId,
            initialGoal: currentGoal,
          ),
    );
  }
}

/// 목표(분) stepper 시트 — 5~60분, 5분 단위.
class _DailyGoalAdjustSheet extends ConsumerStatefulWidget {
  const _DailyGoalAdjustSheet({
    required this.studentId,
    required this.initialGoal,
  });

  final String studentId;
  final int initialGoal;

  @override
  ConsumerState<_DailyGoalAdjustSheet> createState() =>
      _DailyGoalAdjustSheetState();
}

class _DailyGoalAdjustSheetState extends ConsumerState<_DailyGoalAdjustSheet> {
  static const int _step = 5;

  late int _pendingGoal;

  @override
  void initState() {
    super.initState();
    _pendingGoal = widget.initialGoal;
  }

  void _adjust(int delta) {
    setState(() {
      _pendingGoal = (_pendingGoal + delta).clamp(
        DailyPracticeGoal.minGoalMinutes,
        DailyPracticeGoal.maxGoalMinutes,
      );
    });
  }

  void _confirm() {
    ref
        .read(dailyPracticeGoalProvider(widget.studentId).notifier)
        .setGoal(_pendingGoal);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canDecrease = _pendingGoal > DailyPracticeGoal.minGoalMinutes;
    final canIncrease = _pendingGoal < DailyPracticeGoal.maxGoalMinutes;

    return NotebookBottomSheet(
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.dailyGoalAdjustSheetTitle,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              AppStrings.dailyGoalAdjustSheetHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  key: const ValueKey('daily_goal_stepper_decrease'),
                  onPressed: canDecrease ? () => _adjust(-_step) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: AppSpacing.iconLG,
                  color:
                      canDecrease
                          ? AppColors.paperAccent
                          : AppColors.inkQuaternary,
                ),
                SizedBox(
                  width: 88,
                  child: Text(
                    AppStrings.heatmapDayDetailMinutes(_pendingGoal),
                    key: const ValueKey('daily_goal_stepper_value'),
                    textAlign: TextAlign.center,
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('daily_goal_stepper_increase'),
                  onPressed: canIncrease ? () => _adjust(_step) : null,
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: AppSpacing.iconLG,
                  color:
                      canIncrease
                          ? AppColors.paperAccent
                          : AppColors.inkQuaternary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space5),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('daily_goal_stepper_confirm'),
                onPressed: _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                  minimumSize: Size(0, AppSpacing.buttonHeight),
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(AppStrings.confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
