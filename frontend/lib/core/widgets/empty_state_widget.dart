import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/notebook_typography.dart';

/// Empty state — **Notebook × Score 스타일**.
///
/// 종이 위의 "비어 있는 프로그램" 메타포:
/// - 아이콘: `ink` 톤, 32px (기존 64px → 축소, 과장 지양)
/// - 제목: Playfair `pieceTitle` (serif, serif italic 대신 정제형)
/// - 부제: Pretendard `bodyMedium` (시스템 일반 안내, §7.128 Tier 3 가이드)
/// - 액션: `OutlinedButton` (ink 1px 테두리)
///
/// 스펙: `docs/specs/design/notebook/README.md` §5.1 · §6
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// If true, wraps content in a scrollable ListView
  /// (useful when the empty state replaces a list).
  final bool scrollable;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.inkTertiary),
            const SizedBox(height: AppSpacing.space4),
            Text(
              title,
              style: NotebookTypography.pieceTitle.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                subtitle!,
                // 빈 상태 부연 = 시스템 일반 안내 → Tier 3 Pretendard bodyMedium
                // (README §1.1.1 결정 가이드, §7.128 자필 회피).
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.space6),
              OutlinedButton.icon(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.ink, width: 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space3,
                  ),
                ),
                icon:
                    actionIcon != null
                        ? Icon(actionIcon, size: 16)
                        : const SizedBox.shrink(),
                label: Text(
                  actionLabel!,
                  style: NotebookTypography.sectionLabel.copyWith(
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (scrollable) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [const SizedBox(height: 60), content],
      );
    }

    return content;
  }
}
