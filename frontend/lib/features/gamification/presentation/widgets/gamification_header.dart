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

  const GamificationHeader({
    super.key,
    required this.studentId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationAsync =
        ref.watch(studentGamificationProvider(studentId));

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
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
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
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Lv.${data.level}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
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
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.totalPoints}P',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data.earnedBadges.where((b) => b.isEarned).length}',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
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
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data.levelProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
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
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      '${(data.levelProgress * 100).toInt()}%',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
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
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  List<Color> _getLevelGradient(int level) {
    switch (level) {
      case 1:
        return [AppColors.primary, AppColors.primaryLight];
      case 2:
        return [const Color(0xFF5B8C5A), const Color(0xFF78AB78)];
      case 3:
        return [const Color(0xFF4A7FB5), const Color(0xFF6BA3D6)];
      case 4:
        return [const Color(0xFFB8860B), const Color(0xFFDAA520)];
      case 5:
        return [const Color(0xFF8B4513), const Color(0xFFCD853F)];
      default:
        return [const Color(0xFF6B21A8), const Color(0xFF9333EA)];
    }
  }
}
