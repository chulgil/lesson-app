import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../providers/practice_goal_provider.dart';

/// Widget displaying daily and weekly goal progress
class GoalProgressWidget extends ConsumerWidget {
  final String studentId;
  final VoidCallback? onSettingsTap;

  const GoalProgressWidget({
    super.key,
    required this.studentId,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalStatusAsync = ref.watch(goalStatusProvider(studentId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: goalStatusAsync.when(
        data: (status) => _buildContent(context, status),
        loading:
            () => const Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Center(
                child: Text(
                  '목표를 불러올 수 없습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GoalStatus status) {
    if (!status.hasGoal) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.flag, color: AppColors.paperAccent, size: 20),
              const SizedBox(width: AppSpacing.space2),
              // Notebook × Score: 카드 섹션 제목은 Playfair sectionTitle
              // 로 통일 (§7.17).
              Text('오늘의 목표', style: NotebookTypography.sectionTitle),
              const Spacer(),
              if (status.isDailyGoalAchieved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paperOk.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.paperOk,
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.space1),
                      Text(
                        '달성!',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.paperOk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              IconButton(
                onPressed: onSettingsTap,
                icon: Icon(
                  Icons.settings,
                  color: AppColors.inkSecondary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '목표 설정',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Daily goals
          if (status.goal?.dailyTimeMinutes != null) ...[
            _buildProgressBar(
              context,
              icon: Icons.timer,
              label: '연습 시간',
              current: status.todayProgress.practiceTimeText,
              target: status.goal!.dailyTimeText,
              progress: status.dailyTimeProgressPercent / 100,
              isAchieved: status.todayProgress.isTimeGoalAchieved(
                status.goal!.dailyTimeMinutes,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
          ],

          if (status.goal?.dailySectionCount != null) ...[
            _buildProgressBar(
              context,
              icon: Icons.check_box,
              label: '완료 섹션',
              current: '${status.todayProgress.completedSectionCount}개',
              target: '${status.goal!.dailySectionCount}개',
              progress: status.dailySectionProgressPercent / 100,
              isAchieved: status.todayProgress.isSectionGoalAchieved(
                status.goal!.dailySectionCount,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
          ],

          // Divider
          if (status.goal?.hasWeeklyGoal == true) ...[
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.space3),

            // Weekly summary
            Row(
              children: [
                Icon(Icons.date_range, color: AppColors.inkSecondary, size: 16),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '이번 주',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (status.isWeeklyGoalAchieved)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: AppColors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.space1),
                      Text(
                        '주간 목표 달성!',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),

            Row(
              children: [
                if (status.goal?.weeklyTimeMinutes != null)
                  Expanded(
                    child: _buildWeeklyStat(
                      icon: Icons.timer,
                      label: '시간',
                      value: status.weeklyProgress.totalTimeText,
                      target: status.goal!.weeklyTimeText,
                      percent: status.weeklyTimeProgressPercent,
                    ),
                  ),
                if (status.goal?.weeklyTimeMinutes != null &&
                    status.goal?.weeklyDayCount != null)
                  const SizedBox(width: AppSpacing.space4),
                if (status.goal?.weeklyDayCount != null)
                  Expanded(
                    child: _buildWeeklyStat(
                      icon: Icons.calendar_today,
                      label: '연습일',
                      value: '${status.weeklyProgress.practiceDayCount}일',
                      target: '${status.goal!.weeklyDayCount}일',
                      percent: status.weeklyDayProgressPercent,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return InkWell(
      onTap: onSettingsTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withAlpha(25),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Icon(
                Icons.flag_outlined,
                color: AppColors.paperAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '연습 목표를 설정해보세요',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '일일/주간 목표를 설정하고 달성률을 확인하세요',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.inkSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String current,
    required String target,
    required double progress,
    required bool isAchieved,
  }) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.inkSecondary, size: 16),
            const SizedBox(width: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '$current / $target',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isAchieved) ...[
              const SizedBox(width: AppSpacing.space1),
              Icon(Icons.check_circle, color: AppColors.paperOk, size: 14),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.paperDark,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
            ),
            FractionallySizedBox(
              widthFactor: clampedProgress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isAchieved
                            ? [AppColors.paperOk, AppColors.paperOk]
                            : [AppColors.paperAccent, AppColors.paperAccent],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$percent%',
            style: AppTypography.caption.copyWith(
              color: isAchieved ? AppColors.paperOk : AppColors.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyStat({
    required IconData icon,
    required String label,
    required String value,
    required String target,
    required int percent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.inkSecondary, size: 14),
            const SizedBox(width: AppSpacing.space1),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '$value / $target',
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          '($percent%)',
          style: AppTypography.caption.copyWith(
            color: percent >= 100 ? AppColors.paperOk : AppColors.inkTertiary,
          ),
        ),
      ],
    );
  }
}
