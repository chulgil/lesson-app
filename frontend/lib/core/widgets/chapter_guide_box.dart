import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Chapter-stage guide variant — prepared for Phase 3 color split.
///
/// Phase 1 (현재): 모두 [neutral] 로 사용 — 기존 동작 보존.
/// Phase 3: [action] / [wait] 분기 도입 (chat_guide_message_spec.md §25).
enum ChapterGuideVariant {
  /// 사용자(뷰어)가 행동해야 하는 상태 — primary 강조 (Phase 3).
  action,

  /// 상대방의 행동을 기다리는 상태 — grey 약화 (Phase 3).
  wait,

  /// 기본 — 모든 챕터 단계의 기본 회색조. Phase 1 디폴트.
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
      case ChapterGuideVariant.wait:
      case ChapterGuideVariant.neutral:
        return _GuideColors(
          background: AppColors.ink.withValues(alpha: 0.06),
          icon: AppColors.ink,
          chipBackground: AppColors.ink.withValues(alpha: 0.12),
          chipText: AppColors.ink,
          bodyText: AppColors.inkSecondary,
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
