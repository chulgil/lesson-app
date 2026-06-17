import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../domain/entities/gamification.dart';
import '../extensions/badge_rarity_visuals.dart';

/// 트로피 모음 카드 — 학생 성장 시각화 (단일 모음, 카테고리 분류 노출 X).
///
/// 스펙 §4.4 / §16 / 플랜 Job 7 Task 7.1 / AC-6.3 / #783.
/// - badges 0개 → "곧 첫 트로피!" 빈 상태
/// - badges 1-8개 → 인라인 표시 (티어 한글 라벨 포함)
/// - badges 9+ → 첫 8개 + 더보기 버튼 (TrophyGridScreen 진입)
/// - rarity 라벨/그룹 노출 X (단일 "모음" 카드 정책) — 티어 라벨은 각 아이콘 아래 소형 표시
/// - viewerIsTeacher=true 시 제목 → '학생 트로피' (#783)
/// - 시그니처 영역 - NotebookGlyph.starFilled 사용 (Material Icons 금지)
class TrophyCollectionCard extends StatelessWidget {
  const TrophyCollectionCard({
    super.key,
    required this.badges,
    this.onMoreTap,
    this.previewLimit = 8,
    this.viewerIsTeacher = false,
  });

  final List<PracticeBadge> badges;
  final VoidCallback? onMoreTap;
  final int previewLimit;

  /// 교사 뷰에서 true — 제목이 '학생 트로피'로 변경됨 (#783).
  final bool viewerIsTeacher;

  @override
  Widget build(BuildContext context) {
    final count = badges.length;
    final hasOverflow = count > previewLimit;
    final visibleBadges = hasOverflow
        ? badges.take(previewLimit).toList()
        : badges;

    final title = viewerIsTeacher
        ? AppStrings.trophyCollectionTitleTeacher
        : AppStrings.trophyCollectionTitle;

    return Container(
      key: const ValueKey('trophy_collection_card'),
      padding: EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(color: AppColors.paper),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            NotebookGlyph.starFilled,
            style: AppTypography.headingMedium.copyWith(
              color: badge.rarity.tierColor,
            ),
          ),
          Text(
            badge.rarity.tierLabel,
            style: AppTypography.caption.copyWith(
              color: badge.rarity.tierColor,
            ),
          ),
        ],
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
