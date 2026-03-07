import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/practice.dart';
import '../../../../providers/practice/practice_streak_provider.dart';

/// Compact streak display widget for dashboard
class PracticeStreakCard extends ConsumerWidget {
  final String studentId;
  final VoidCallback? onTap;

  const PracticeStreakCard({
    super.key,
    required this.studentId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(practiceStreakProvider(studentId));

    return streakAsync.when(
      data: (streak) => _buildCard(context, ref, streak),
      loading: () => _buildLoadingCard(),
      error: (_, __) => _buildErrorCard(),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, PracticeStreak streak) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(streak.streakLevel),
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: _getGradientColors(streak.streakLevel).first
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '연습 스트릭',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (streak.fireEmoji.isNotEmpty)
                  Text(
                    streak.fireEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.space2),

            // Streak count
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${streak.currentStreak}',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: Text(
                    '일 연속',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space2),

            // Motivation message
            Text(
              streak.motivationMessage,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),

            const SizedBox(height: AppSpacing.space3),

            // Weekly dots
            _buildWeeklyDots(streak),

            // Best streak
            if (streak.longestStreak > 0) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                '최고 기록: ${streak.longestStreak}일',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyDots(PracticeStreak streak) {
    final now = DateTime.now();
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        // Calculate if this day is within the streak
        final dayOffset = now.weekday - 1 - index;
        final isPracticed = streak.currentStreak > dayOffset && dayOffset >= 0;
        final isToday = index == now.weekday - 1;
        final isFuture = index > now.weekday - 1;

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isFuture
                    ? Colors.white.withValues(alpha: 0.2)
                    : isPracticed
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Center(
                child: isPracticed && !isFuture
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: _getGradientColors(streak.streakLevel).first,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              weekDays[index],
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: isToday ? 1.0 : 0.7),
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Color> _getGradientColors(int streakLevel) {
    switch (streakLevel) {
      case 3: // 30+ days - Gold
        return [AppColors.streakGreat1, AppColors.streakGreat2];
      case 2: // 7-29 days - Orange/Red
        return [AppColors.streakGood1, AppColors.streakGood2];
      case 1: // 1-6 days - Purple
        return [AppColors.primary, AppColors.primaryLight];
      default: // No streak - Gray
        return [AppColors.streakPaused1, AppColors.streakPaused2];
    }
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      height: 180,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '스트릭 정보를 불러올 수 없습니다',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini streak badge for compact display
class PracticeStreakBadge extends ConsumerWidget {
  final String studentId;

  const PracticeStreakBadge({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(practiceStreakProvider(studentId));

    return streakAsync.when(
      data: (streak) {
        if (streak.currentStreak == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(
            color: _getBadgeColor(streak.streakLevel),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (streak.fireEmoji.isNotEmpty) ...[
                Text(streak.fireEmoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 2),
              ],
              Text(
                '${streak.currentStreak}일',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _getBadgeColor(int streakLevel) {
    switch (streakLevel) {
      case 3:
        return AppColors.streakGreat1;
      case 2:
        return AppColors.streakGood1;
      default:
        return AppColors.primary;
    }
  }
}

/// Button to record practice for today
class RecordPracticeButton extends ConsumerWidget {
  final String studentId;
  final VoidCallback? onRecorded;

  const RecordPracticeButton({
    super.key,
    required this.studentId,
    this.onRecorded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(practiceStreakProvider(studentId));

    return streakAsync.when(
      data: (streak) {
        if (streak.practicedToday) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '오늘 연습 완료!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return FilledButton.icon(
          onPressed: () async {
            final notifier = ref.read(streakNotifierProvider(studentId).notifier);
            await notifier.recordPractice();
            ref.invalidate(practiceStreakProvider(studentId));
            onRecorded?.call();
          },
          icon: const Icon(Icons.music_note),
          label: const Text('오늘 연습 기록하기'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('오류 발생'),
    );
  }
}
