// Compact gamification header showing level and points.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/gamification.dart';
import '../providers/gamification_provider.dart';

/// Gamification header widget showing level, points, and progress.
class GamificationHeader extends ConsumerWidget {
  final String studentId;
  final VoidCallback? onTap;

  const GamificationHeader({super.key, required this.studentId, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationAsync = ref.watch(studentGamificationProvider(studentId));

    return gamificationAsync.when(
      data: (gamification) => _buildHeader(context, gamification),
      loading: () => _buildLoadingState(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildHeader(BuildContext context, StudentGamification data) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getLevelGradient(data.level),
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          children: [
            // Level + Points row
            Row(
              children: [
                // Level badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.paper.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Lv.${data.level}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.paper,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),

                // Title + Points
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.levelTitle,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.paper,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.totalPoints}P',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.paper.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                // Earned badges count
                if (data.earnedBadges.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 14,
                          color: AppColors.paper,
                        ),
                        const SizedBox(width: AppSpacing.space1),
                        Text(
                          '${data.earnedBadges.where((b) => b.isEarned).length}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.paper,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.space3),

            // Progress bar
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: LinearProgressIndicator(
                    value: data.levelProgress,
                    minHeight: 6,
                    backgroundColor: AppColors.paper.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.paper,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '다음 레벨까지 ${data.pointsToNextLevel}P',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paper.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      '${(data.levelProgress * 100).toInt()}%',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paper.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.zero,
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  List<Color> _getLevelGradient(int level) {
    switch (level) {
      case 1:
        return [AppColors.paperAccent, AppColors.paperAccentSoft];
      case 2:
        return [AppColors.levelSilverStart, AppColors.levelSilverEnd];
      case 3:
        return [AppColors.levelPlatinumStart, AppColors.levelPlatinumEnd];
      case 4:
        return [AppColors.levelGoldStart, AppColors.levelGoldEnd];
      case 5:
        return [AppColors.levelBronzeStart, AppColors.levelBronzeEnd];
      default:
        return [AppColors.levelDiamondStart, AppColors.levelDiamondEnd];
    }
  }
}
