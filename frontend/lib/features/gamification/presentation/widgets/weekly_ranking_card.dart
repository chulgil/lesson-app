// Weekly ranking card widget for class leaderboard display.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../domain/entities/weekly_ranking.dart';
import '../providers/leaderboard_provider.dart';

/// Displays weekly class ranking with tier icons and progress bars.
class WeeklyRankingCard extends ConsumerWidget {
  final String classId;

  const WeeklyRankingCard({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(weeklyClassRankingProvider(classId));

    return rankingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (ranking) {
        if (ranking.isEmpty) return const SizedBox.shrink();
        return _RankingContent(ranking: ranking);
      },
    );
  }
}

class _RankingContent extends StatelessWidget {
  final WeeklyRanking ranking;

  const _RankingContent({required this.ranking});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notebook × Score: 주간 랭킹 카드 제목도 Playfair sectionTitle 로 통일 (§7.17 패턴).
          Text(
            AppStrings.weeklyRanking,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          ...ranking.entries.map(
            (entry) =>
                _RankingEntryRow(entry: entry, maxPoints: ranking.maxPoints),
          ),
        ],
      ),
    );
  }
}

class _RankingEntryRow extends StatelessWidget {
  final WeeklyRankingEntry entry;
  final int maxPoints;

  const _RankingEntryRow({required this.entry, required this.maxPoints});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
      child: Row(
        children: [
          // Tier icon
          SizedBox(
            width: AppSpacing.iconLG,
            child: Text(
              _tierEmoji(entry.tier),
              style: AppTypography.headingMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          // Student name
          Expanded(
            flex: 3,
            child: Text(
              entry.studentName,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          // Points label
          Text(
            AppStrings.weeklyPointsValue(entry.weeklyPoints),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          // Progress bar
          Expanded(
            flex: 4,
            child: _ProgressBar(
              value: maxPoints > 0 ? entry.weeklyPoints / maxPoints : 0,
              tier: entry.tier,
            ),
          ),
        ],
      ),
    );
  }

  String _tierEmoji(RankingTier tier) {
    switch (tier) {
      case RankingTier.gold:
        return '\u{1F947}';
      case RankingTier.silver:
        return '\u{1F948}';
      case RankingTier.bronze:
        return '\u{1F949}';
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final RankingTier tier;

  const _ProgressBar({required this.value, required this.tier});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: AppColors.inkQuaternary,
        valueColor: AlwaysStoppedAnimation<Color>(_tierColor(tier)),
      ),
    );
  }

  Color _tierColor(RankingTier tier) {
    switch (tier) {
      case RankingTier.gold:
        return AppColors.amber;
      case RankingTier.silver:
        return AppColors.inkTertiary;
      case RankingTier.bronze:
        return AppColors.paperAccent;
    }
  }
}
