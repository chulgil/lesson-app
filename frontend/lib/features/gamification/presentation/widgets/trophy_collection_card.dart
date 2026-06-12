import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../domain/entities/gamification.dart';

/// 트로피 모음 카드 — 학생 성장 시각화 (단일 모음, 카테고리 분류 노출 X).
///
/// 스펙 §4.4 / §16 / 플랜 Job 7 Task 7.1 / AC-6.3.
/// - badges 0개 → "곧 첫 트로피!" 빈 상태
/// - badges 1-8개 → 인라인 표시
/// - badges 9+ → 첫 8개 + 더보기 버튼 (TrophyGridScreen 진입)
/// - rarity 라벨/그룹 노출 X (단일 "모음" 카드 정책)
/// - 시그니처 영역 - NotebookGlyph.starFilled 사용 (Material Icons 금지)
class TrophyCollectionCard extends StatelessWidget {
  const TrophyCollectionCard({
    super.key,
    required this.badges,
    this.onMoreTap,
    this.previewLimit = 8,
  });

  final List<PracticeBadge> badges;
  final VoidCallback? onMoreTap;
  final int previewLimit;

  @override
  Widget build(BuildContext context) {
    final count = badges.length;
    final hasOverflow = count > previewLimit;
    final visibleBadges =
        hasOverflow ? badges.take(previewLimit).toList() : badges;

    return Container(
      key: const ValueKey('trophy_collection_card'),
      padding: EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.space2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.trophyCollectionTitle,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.ink,
                ),
              ),
              if (count > 0) ...[
                SizedBox(width: AppSpacing.space2),
                Text(
                  AppStrings.trophyCollectionCountLabel(count),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: AppSpacing.space3),
          if (count == 0)
            Padding(
              key: const ValueKey('trophy_collection_empty'),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space3),
              child: Text(
                AppStrings.trophyCollectionEmptyMessage,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.space3,
              runSpacing: AppSpacing.space2,
              children: [
                for (final badge in visibleBadges) _TrophyItem(badge: badge),
                if (hasOverflow) _MoreButton(onTap: onMoreTap),
              ],
            ),
        ],
      ),
    );
  }
}

class _TrophyItem extends StatelessWidget {
  const _TrophyItem({required this.badge});

  final PracticeBadge badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      key: ValueKey('trophy_collection_item_${badge.id}'),
      message: badge.name,
      child: Text(
        NotebookGlyph.starFilled,
        style: AppTypography.headingMedium.copyWith(
          color: AppColors.paperAccent,
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('trophy_collection_more'),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1,
        ),
        child: Text(
          AppStrings.trophyCollectionMoreLabel,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.paperAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
