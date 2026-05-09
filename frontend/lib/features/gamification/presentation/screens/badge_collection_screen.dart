// Badge collection and point history screen.

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../domain/entities/gamification.dart';
import '../providers/gamification_provider.dart';
import '../widgets/challenges_card.dart';

/// Badge collection and gamification detail screen.
class BadgeCollectionScreen extends ConsumerWidget {
  final String studentId;

  const BadgeCollectionScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationAsync = ref.watch(studentGamificationProvider(studentId));

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.gamificationMyGrowth,
      ),
      body: gamificationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => const Center(
              child: Text(AppStrings.gamificationDataLoadFailed),
            ),
        data: (data) => _buildContent(context, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StudentGamification data) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Level info card
        _buildLevelCard(data),

        const SizedBox(height: AppSpacing.space5),

        // Challenges section
        ChallengesCard(studentId: studentId),

        const SizedBox(height: AppSpacing.space5),

        // Badges section
        // Notebook × Score: 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
        Text(
          AppStrings.gamificationEarnedBadges,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),
        _buildBadgeGrid(data.earnedBadges),

        const SizedBox(height: AppSpacing.space5),

        // Point history
        // Notebook × Score: 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
        Text(
          AppStrings.gamificationPointHistory,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),
        _buildPointHistory(data.recentHistory),

        const SizedBox(height: AppSpacing.space8),
      ],
    );
  }

  Widget _buildLevelCard(StudentGamification data) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children: [
          // Level circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.paperAccentSoft,
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.center,
            child: Text(
              'Lv.${data.level}',
              style: AppTypography.headingMedium.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            data.levelTitle,
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '총 ${data.totalPoints}P',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: data.levelProgress,
              minHeight: 8,
              backgroundColor: AppColors.paperDark,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.paperAccent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '다음 레벨까지 ${data.pointsToNextLevel}P',
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGrid(List<PracticeBadge> badges) {
    final earned = badges.where((b) => b.isEarned).toList();
    final locked = badges.where((b) => !b.isEarned).toList();

    return Column(
      children: [
        // Earned badges
        ...earned.map((badge) => _buildBadgeTile(badge)),

        if (locked.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space3),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '미획득',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          ...locked.map((badge) => _buildBadgeTile(badge)),
        ],
      ],
    );
  }

  Widget _buildBadgeTile(PracticeBadge badge) {
    final rarityColor = _getRarityColor(badge.rarity);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: badge.isEarned ? AppColors.paper : AppColors.paperDark,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color:
              badge.isEarned
                  ? rarityColor.withValues(alpha: 0.3)
                  : AppColors.inkQuaternary,
        ),
      ),
      child: Row(
        children: [
          // Badge icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  badge.isEarned
                      ? rarityColor.withValues(alpha: 0.15)
                      : AppColors.paperDark,
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.center,
            child: Icon(
              _getIconData(badge.icon),
              size: 20,
              color: badge.isEarned ? rarityColor : AppColors.inkTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        badge.isEarned ? AppColors.ink : AppColors.inkTertiary,
                  ),
                ),
                Text(
                  badge.description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Rarity label
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: rarityColor.withValues(
                alpha: badge.isEarned ? 0.15 : 0.05,
              ),
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              _getRarityLabel(badge.rarity),
              style: AppTypography.captionSmall.copyWith(
                color: badge.isEarned ? rarityColor : AppColors.inkTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointHistory(List<PointHistory> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          borderRadius: BorderRadius.zero,
        ),
        child: Center(
          child: Text(
            '포인트 기록이 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children:
            history.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == history.length - 1;
              final d = item.earnedAt;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                      vertical: AppSpacing.space3,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getPointTypeIcon(item.type),
                          size: 18,
                          color: AppColors.inkSecondary,
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: Text(
                            item.description,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+${item.points}P',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.paperAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${d.month}/${d.day} ${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: AppSpacing.space4,
                      endIndent: AppSpacing.space4,
                      color: AppColors.inkQuaternary,
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return AppColors.ink;
      case BadgeRarity.rare:
        return AppColors.paperAccent;
      case BadgeRarity.epic:
        return AppColors.paperAccent;
      case BadgeRarity.legendary:
        return AppColors.paperAccent;
    }
  }

  String _getRarityLabel(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return '일반';
      case BadgeRarity.rare:
        return '희귀';
      case BadgeRarity.epic:
        return '영웅';
      case BadgeRarity.legendary:
        return '전설';
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'music_note':
        return Icons.music_note;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'whatshot':
        return Icons.whatshot;
      case 'star':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }

  IconData _getPointTypeIcon(PointType type) {
    switch (type) {
      case PointType.practiceComplete:
        return Icons.music_note;
      case PointType.streakBonus:
        return Icons.local_fire_department;
      case PointType.lessonAttendance:
        return Icons.school;
      case PointType.goalAchieved:
        return Icons.flag;
      case PointType.badgeEarned:
        return Icons.emoji_events;
    }
  }
}
