import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/spotlight_prompt.dart';
import '../../domain/entities/spotlight_type.dart';

/// 학생 게이미피케이션 P3 — Spotlight prompt 1슬롯.
///
/// 스펙 §7.4. "지금 볼래" / "다음에" 동일 비중 — 같은 높이/너비/폰트.
/// "꼭 해야 해요" / "필수입니다" 메시징 금지 (권유형 헤더만 노출).
///
/// [PracticeCelebrationOverlay] 안에 inline 또는 BottomSheet 로 사용.
class SpotlightSlot extends StatelessWidget {
  final SpotlightPrompt prompt;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const SpotlightSlot({
    super.key,
    required this.prompt,
    required this.onAccept,
    required this.onDecline,
  });

  String _headerFor(SpotlightType type) {
    switch (type) {
      case SpotlightType.teacherRec:
        return AppStrings.spotlightHeaderTeacherRec;
      case SpotlightType.seasonEvent:
        return AppStrings.spotlightHeaderSeasonEvent;
      case SpotlightType.routineSuggestion:
        return AppStrings.spotlightHeaderRoutineSuggestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
      side: BorderSide(color: AppColors.inkSecondary),
      foregroundColor: AppColors.ink,
      textStyle: AppTypography.buttonSmall,
    );

    return Container(
      key: const ValueKey('spotlight_slot'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _headerFor(prompt.type),
            key: const ValueKey('spotlight_header'),
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            prompt.title,
            key: const ValueKey('spotlight_title'),
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('spotlight_decline'),
                  style: buttonStyle,
                  onPressed: onDecline,
                  child: const Text(AppStrings.spotlightDeclineButton),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('spotlight_accept'),
                  style: buttonStyle,
                  onPressed: onAccept,
                  child: const Text(AppStrings.spotlightAcceptButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
