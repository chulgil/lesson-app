import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'notebook_glyph.dart';

/// Notebook × Score 좋아요 도장(stamp).
///
/// **OFF/ON 비대칭** — 인지 카테고리 자체를 분리한다.
/// - OFF (verb, 행동 초대): outline icon + 회색 라벨, **container/border 없음** —
///   "빈 종이" 처럼 보이게 하여 "아직 도장 찍히지 않음" 을 명확화.
/// - ON  (noun, 기록된 결과): filled icon + paper 라벨 + paperAccent solid pill —
///   "잉크 도장 찍힘" 메타포.
///
/// `onTap == null` 이면 read-only (학생 측 read-only 표시 또는 선생님 OFF 비표시).
class LikeStamp extends StatelessWidget {
  final bool isLiked;
  final VoidCallback? onTap;

  const LikeStamp({super.key, required this.isLiked, this.onTap});

  @override
  Widget build(BuildContext context) {
    final stamp = isLiked ? _buildOnStamp() : _buildOffLink();

    if (onTap == null) return stamp;

    return Semantics(
      button: true,
      toggled: isLiked,
      label: isLiked ? AppStrings.practiceLikeOn : AppStrings.practiceLikeOff,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: stamp,
      ),
    );
  }

  /// ON 상태: solid stamp pill (잉크 도장 찍힘).
  Widget _buildOnStamp() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperAccent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NotebookGlyph(
            NotebookGlyph.heartFilled,
            size: 14,
            color: AppColors.paper,
          ),
          const SizedBox(width: 4),
          Text(
            AppStrings.practiceLikeOn,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.paper,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// OFF 상태: 텍스트 링크 — border/bg 없는 verb 행동 초대.
  Widget _buildOffLink() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NotebookGlyph(
            NotebookGlyph.heartOutline,
            size: 14,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            AppStrings.practiceLikeOff,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.inkTertiary,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
