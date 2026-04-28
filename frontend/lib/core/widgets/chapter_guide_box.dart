import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Chapter-stage guide variant — Phase 3 색상 2색 원칙 (chat_guide_message_spec.md §27).
///
/// 2색 원칙: action(내 차례) = paperAccent / wait(대기·종료) = ink grey.
/// neutral 은 wait 의 별칭으로 보존 — 호출자가 명시적 분기 못하는 자리에서 default.
enum ChapterGuideVariant {
  /// 사용자(뷰어)가 행동해야 하는 상태 — paperAccent 강조.
  action,

  /// 상대방의 행동을 기다리는 또는 종료된 상태 — ink grey 약화.
  wait,

  /// 기본 — wait 와 동일 색상. variant 미지정 시 default.
  neutral,
}

/// Chapter-stage guide box: [title] chip + [situation] text in a row with icon.
///
/// 레슨 신청·스케줄 변경 챕터의 상단 가이드 박스를 통일된 시그니처로 표현.
/// 동일한 비주얼을 두 화면(`request_history_chat`, `schedule_change_slot_screen`)에서 공유한다.
///
/// 기존 `_buildSystemGuide()` 패턴을 추출 (request_history_chat.dart §366-421).
class ChapterGuideBox extends StatelessWidget {
  /// 칩 라벨 — 리스트 actionLabel 과 동일 ([chat_guide_message_spec.md §25] 참조).
  final String title;

  /// 한 줄 가이드 본문.
  final String situation;

  /// 색 변형. Phase 1 에서는 [ChapterGuideVariant.neutral] 만 사용.
  final ChapterGuideVariant variant;

  const ChapterGuideBox({
    super.key,
    required this.title,
    required this.situation,
    this.variant = ChapterGuideVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(variant);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(color: colors.background),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: colors.icon),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.chipBackground,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    title,
                    style: AppTypography.caption.copyWith(
                      color: colors.chipText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  situation,
                  style: AppTypography.caption.copyWith(color: colors.bodyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static _GuideColors _resolveColors(ChapterGuideVariant variant) {
    switch (variant) {
      case ChapterGuideVariant.action:
        return _GuideColors(
          background: AppColors.paperAccentSoft,
          icon: AppColors.paperAccent,
          chipBackground: AppColors.paperAccent,
          chipText: AppColors.paper,
          bodyText: AppColors.ink,
        );
      case ChapterGuideVariant.wait:
      case ChapterGuideVariant.neutral:
        return _GuideColors(
          background: AppColors.ink.withValues(alpha: 0.06),
          icon: AppColors.inkTertiary,
          chipBackground: AppColors.ink.withValues(alpha: 0.12),
          chipText: AppColors.inkSecondary,
          bodyText: AppColors.inkTertiary,
        );
    }
  }
}

class _GuideColors {
  final Color background;
  final Color icon;
  final Color chipBackground;
  final Color chipText;
  final Color bodyText;

  const _GuideColors({
    required this.background,
    required this.icon,
    required this.chipBackground,
    required this.chipText,
    required this.bodyText,
  });
}
