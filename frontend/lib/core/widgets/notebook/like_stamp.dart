import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Notebook × Score 좋아요 도장(stamp).
///
/// outline ↔ filled stamp pill 이중 시그널로 OFF/ON 을 명확히 구분.
/// - OFF: outline thumb + 회색 라벨 + transparent bg (선생님 토글 미평가)
/// - ON : filled thumb + paper 라벨 + paperAccent solid bg (잉크 도장 찍힘)
///
/// `onTap == null` 이면 read-only (학생 측 read-only 표시 또는 선생님 OFF 비표시).
class LikeStamp extends StatelessWidget {
  final bool isLiked;
  final VoidCallback? onTap;

  const LikeStamp({super.key, required this.isLiked, this.onTap});

  @override
  Widget build(BuildContext context) {
    final stamp = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isLiked ? AppColors.paperAccent : Colors.transparent,
        border: Border.all(
          color: isLiked ? AppColors.paperAccent : AppColors.inkQuaternary,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
            size: 14,
            color: isLiked ? AppColors.paper : AppColors.inkTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            isLiked ? AppStrings.practiceLikeOn : AppStrings.practiceLikeOff,
            style: AppTypography.captionSmall.copyWith(
              color: isLiked ? AppColors.paper : AppColors.inkTertiary,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
    );

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
}
