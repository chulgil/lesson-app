import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../providers/practice_goal_provider.dart';

/// Dialog shown when a goal is achieved
class GoalAchievedDialog extends StatelessWidget {
  final bool isDaily;
  final bool isWeekly;
  final GoalStatus status;
  final int streakDays;
  final String? newBadge;

  const GoalAchievedDialog({
    super.key,
    this.isDaily = false,
    this.isWeekly = false,
    required this.status,
    this.streakDays = 0,
    this.newBadge,
  });

  /// Show the dialog
  static Future<void> show(
    BuildContext context, {
    bool isDaily = false,
    bool isWeekly = false,
    required GoalStatus status,
    int streakDays = 0,
    String? newBadge,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => GoalAchievedDialog(
            isDaily: isDaily,
            isWeekly: isWeekly,
            status: status,
            streakDays: streakDays,
            newBadge: newBadge,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration emoji
            Text(isWeekly ? '🏆' : '🎉', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.space3),

            // Notebook × Score: 다이얼로그 헤드라인 (§7.89 3축 center+emoji+단일 헤드라인).
            // isWeekly 2원 유한집합 + 정적 명사 "목표 달성!" — §7.87-h 동적처럼 보이는 정적 명사.
            Text(
              isWeekly ? '이번 주 목표 달성!' : '오늘 목표 달성!',
              style: NotebookTypography.sectionTitle.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),

            // Achievement details
            if (isDaily) ...[_buildDailyAchievements()],
            if (isWeekly) ...[_buildWeeklyAchievements()],

            // Streak info
            if (streakDays > 0 && isDaily) ...[
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.paperAccent.withValues(alpha: 0.2),
                      AppColors.paperAccent.withValues(alpha: 0.2),
                    ],
                  ),
                  ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '$streakDays일 연속 스트릭!',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.paperAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // New badge
            if (newBadge != null) ...[
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '새로운 뱃지를 획득했어요!',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.amber,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎖️', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSpacing.space2),
                        Text(
                          '"$newBadge"',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.space5),

            // Confirm button
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(AppStrings.confirm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAchievements() {
    final goal = status.goal!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        ),
      child: Column(
        children: [
          if (goal.dailyTimeMinutes != null)
            _buildAchievementRow(
              icon: Icons.timer,
              label: '연습 시간',
              value: status.todayProgress.practiceTimeText,
              target: goal.dailyTimeText,
            ),
          if (goal.dailyTimeMinutes != null && goal.dailySectionCount != null)
            const Divider(height: AppSpacing.space4),
          if (goal.dailySectionCount != null)
            _buildAchievementRow(
              icon: Icons.check_box,
              label: '완료 섹션',
              value: '${status.todayProgress.completedSectionCount}개',
              target: '${goal.dailySectionCount}개',
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAchievements() {
    final goal = status.goal!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        ),
      child: Column(
        children: [
          if (goal.weeklyTimeMinutes != null)
            _buildAchievementRow(
              icon: Icons.timer,
              label: '총 연습 시간',
              value: status.weeklyProgress.totalTimeText,
              target: goal.weeklyTimeText,
            ),
          if (goal.weeklyTimeMinutes != null && goal.weeklyDayCount != null)
            const Divider(height: AppSpacing.space4),
          if (goal.weeklyDayCount != null)
            _buildAchievementRow(
              icon: Icons.calendar_today,
              label: '연습일',
              value: '${status.weeklyProgress.practiceDayCount}일',
              target: '${goal.weeklyDayCount}일',
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementRow({
    required IconData icon,
    required String label,
    required String value,
    required String target,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.inkSecondary, size: 18),
        const SizedBox(width: AppSpacing.space2),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          ' (목표: $target)',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Icon(Icons.check_circle, color: AppColors.paperOk, size: 18),
      ],
    );
  }
}
