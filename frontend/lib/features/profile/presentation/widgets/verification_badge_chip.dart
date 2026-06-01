import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/teacher_profile.dart';

/// 선생님 인증 배지 칩 — 아이콘 + 라벨.
///
/// `VerificationBadge` enum 의 3가지 케이스(phoneVerified / certified /
/// premium)를 단일 위젯에서 일관된 형태로 렌더링한다. #430 후속에서 본인
/// 프로필 미리보기에 표시하기 위해 신설되었다.
class VerificationBadgeChip extends StatelessWidget {
  const VerificationBadgeChip({super.key, required this.badge});

  final VerificationBadge badge;

  @override
  Widget build(BuildContext context) {
    final color = _color(badge);
    final background = _background(badge);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(badge), size: 14, color: color),
          const SizedBox(width: AppSpacing.space1),
          Text(
            _label(badge),
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _icon(VerificationBadge badge) {
    switch (badge) {
      case VerificationBadge.phoneVerified:
        return Icons.verified_user_outlined;
      case VerificationBadge.certified:
        return Icons.workspace_premium;
      case VerificationBadge.premium:
        return Icons.star;
    }
  }

  static String _label(VerificationBadge badge) {
    switch (badge) {
      case VerificationBadge.phoneVerified:
        return AppStrings.verificationBadgePhoneLabel;
      case VerificationBadge.certified:
        return AppStrings.verificationBadgeCertifiedLabel;
      case VerificationBadge.premium:
        return AppStrings.verificationBadgePremiumLabel;
    }
  }

  static Color _color(VerificationBadge badge) {
    switch (badge) {
      case VerificationBadge.phoneVerified:
        return AppColors.paperAccent;
      case VerificationBadge.certified:
        return AppColors.paperOk;
      case VerificationBadge.premium:
        return AppColors.amber;
    }
  }

  static Color _background(VerificationBadge badge) {
    switch (badge) {
      case VerificationBadge.phoneVerified:
        return AppColors.paperAccentSoft;
      case VerificationBadge.certified:
        return AppColors.paperOk.withValues(alpha: 0.12);
      case VerificationBadge.premium:
        return AppColors.amberLight;
    }
  }
}
