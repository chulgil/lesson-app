import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../providers/goal_achievement_storage_provider.dart';
import '../../providers/practice_goal_provider.dart';
import 'goal_achieved_dialog.dart';

/// Compact, top-of-tab widget that shows daily and weekly practice goal
/// progress bars. Tapping the trailing pencil opens the goal-setting screen.
///
/// When the active goal becomes newly achieved (and the celebration has not
/// been shown for that day / week), this widget pops the
/// [GoalAchievedDialog] exactly once and records the event in the storage
/// provider so subsequent rebuilds do not re-trigger it.
class GoalProgressWidget extends ConsumerStatefulWidget {
  final String studentId;

  const GoalProgressWidget({super.key, required this.studentId});

  @override
  ConsumerState<GoalProgressWidget> createState() => _GoalProgressWidgetState();
}

class _GoalProgressWidgetState extends ConsumerState<GoalProgressWidget> {
  @override
  Widget build(BuildContext context) {
    final goalStatusAsync = ref.watch(goalStatusProvider(widget.studentId));

    return goalStatusAsync.when(
      data: (status) {
        // Schedule the achievement dialog check after this build completes
        // — we cannot synchronously show a dialog while building.
        _maybeShowAchievementDialog(status);

        if (!status.hasGoal) {
          return _GoalEmptyCard(studentId: widget.studentId);
        }
        return _GoalProgressCard(studentId: widget.studentId, status: status);
      },
      loading: () => const _GoalSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _maybeShowAchievementDialog(GoalStatus status) {
    if (!status.hasGoal) return;
    if (!status.isDailyGoalAchieved && !status.isWeeklyGoalAchieved) return;

    final storageAsync = ref.read(
      goalAchievementStorageProvider(widget.studentId),
    );
    final storage = storageAsync.valueOrNull;
    if (storage == null) return; // still loading; will recheck on next rebuild

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = status.weeklyProgress.weekStart;
    final weekStartDay = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    final shouldShowWeekly =
        status.isWeeklyGoalAchieved &&
        !storage.isWeeklyAlreadyShown(weekStartDay);
    final shouldShowDaily =
        status.isDailyGoalAchieved && !storage.isDailyAlreadyShown(today);

    // Weekly takes priority over daily because it is rarer.
    if (!shouldShowWeekly && !shouldShowDaily) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final scope = shouldShowWeekly
          ? GoalAchievementScope.weekly
          : GoalAchievementScope.daily;
      final notifier = ref.read(
        goalAchievementStorageProvider(widget.studentId).notifier,
      );
      if (scope == GoalAchievementScope.weekly) {
        await notifier.markWeeklyAchieved(weekStartDay);
      } else {
        await notifier.markDailyAchieved(today);
      }
      if (!mounted) return;
      await GoalAchievedDialog.show(context, scope: scope);
    });
  }
}

class _GoalEmptyCard extends StatelessWidget {
  final String studentId;

  const _GoalEmptyCard({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space3,
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

class _GoalProgressCard extends StatelessWidget {
  final String studentId;
  final GoalStatus status;

  const _GoalProgressCard({required this.studentId, required this.status});

  @override
  Widget build(BuildContext context) {
    final goal = status.goal!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag,
                size: AppSpacing.iconSM,
                color: AppColors.paperAccent,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                AppStrings.goalProgressTitle,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  context.push(
                    '${AppRoutes.practiceGoalSettings}?studentId=$studentId',
                  );
                },
                icon: Icon(
                  Icons.edit_outlined,
                  size: AppSpacing.iconXS,
                  color: AppColors.inkSecondary,
                ),
                tooltip: AppStrings.goalProgressEditTooltip,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (goal.hasDailyGoal) ...[
            const SizedBox(height: AppSpacing.space2),
            _GoalRow(
              scopeLabel: AppStrings.goalProgressDaily,
              isAchieved: status.isDailyGoalAchieved,
              metrics: [
                if (goal.dailyTimeMinutes != null)
                  _GoalMetric(
                    label: AppStrings.goalProgressTime,
                    percent: status.dailyTimeProgressPercent,
                    valueText:
                        '${status.todayProgress.practiceTimeText} / ${goal.dailyTimeText}',
                  ),
                if (goal.dailySectionCount != null)
                  _GoalMetric(
                    label: AppStrings.goalProgressSection,
                    percent: status.dailySectionProgressPercent,
                    valueText:
                        '${status.todayProgress.completedSectionCount} / ${goal.dailySectionCount}',
                  ),
              ],
            ),
          ],
          if (goal.hasWeeklyGoal) ...[
            const SizedBox(height: AppSpacing.space3),
            _GoalRow(
              scopeLabel: AppStrings.goalProgressWeekly,
              isAchieved: status.isWeeklyGoalAchieved,
              metrics: [
                if (goal.weeklyTimeMinutes != null)
                  _GoalMetric(
                    label: AppStrings.goalProgressTime,
                    percent: status.weeklyTimeProgressPercent,
                    valueText:
                        '${status.weeklyProgress.totalTimeText} / ${goal.weeklyTimeText}',
                  ),
                if (goal.weeklyDayCount != null)
                  _GoalMetric(
                    label: AppStrings.goalProgressDay,
                    percent: status.weeklyDayProgressPercent,
                    valueText:
                        '${status.weeklyProgress.practiceDayCount} / ${goal.weeklyDayCount}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String scopeLabel;
  final bool isAchieved;
  final List<_GoalMetric> metrics;

  const _GoalRow({
    required this.scopeLabel,
    required this.isAchieved,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              scopeLabel,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isAchieved) ...[
              const SizedBox(width: AppSpacing.space1),
              Icon(
                Icons.check_circle,
                color: AppColors.paperOk,
                size: AppSpacing.iconXS,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space2),
          _GoalMetricBar(metric: metrics[i]),
        ],
      ],
    );
  }
}

class _GoalMetric {
  final String label;
  final int percent; // 0..100+
  final String valueText;

  const _GoalMetric({
    required this.label,
    required this.percent,
    required this.valueText,
  });
}

class _GoalMetricBar extends StatelessWidget {
  final _GoalMetric metric;

  const _GoalMetricBar({required this.metric});

  @override
  Widget build(BuildContext context) {
    final ratio = (metric.percent / 100).clamp(0.0, 1.0);
    final achieved = metric.percent >= 100;
    final fillColor = achieved ? AppColors.paperOk : AppColors.paperAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              metric.label,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const Spacer(),
            Text(
              metric.valueText,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          child: Stack(
            children: [
              Container(height: 6, color: AppColors.inkQuaternary),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(height: 6, color: fillColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalSkeleton extends StatelessWidget {
  const _GoalSkeleton();

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
