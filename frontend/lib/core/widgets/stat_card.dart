import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/notebook_typography.dart';

/// Reusable statistic card — **Notebook × Score 스타일**.
///
/// 종이 위의 "수치 카드" 메타포:
/// - 배경: `paperDark` (크림색 종이의 한 톤 짙은 영역)
/// - 왼쪽 3px `ink` 세로선 (악보 소절선 메타포)
/// - 제목: `NotebookTypography.sectionLabel` (대문자 + letterSpacing)
/// - 값: Playfair Display serif, 큰 크기
/// - 부제: `caption` + `inkTertiary`
///
/// Used in:
/// - PaymentManagementScreen · ParentDashboardTab · HomeScreen · StudentStatsCards
///
/// 호환성: 기존 `color` 파라미터는 API 보존을 위해 유지하되 내부에서 무시.
/// 전 화면이 Notebook × Score 컨셉으로 전환 중 — 중간 단계에서 단일 룩 강제.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    this.icon,
    this.onTap,
  });

  /// Title label (e.g., "수납 완료", "미납")
  final String title;

  /// Main value to display (e.g., "200,000원", "3명")
  final String value;

  /// Optional subtitle (e.g., "3명", "이번 주")
  final String? subtitle;

  /// Theme color — **무시됨**. API 호환성을 위해 유지. 전면 전환 후 제거 예정.
  // ignore: unused_element, unused_field
  final Color color;

  /// Optional leading icon
  final IconData? icon;

  /// Optional tap callback
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.paperDark,
        border: Border(left: BorderSide(color: AppColors.ink, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space3,
          AppSpacing.space3,
          AppSpacing.space3,
          AppSpacing.space3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.ink, size: 16),
                  const SizedBox(width: AppSpacing.space2),
                ],
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: NotebookTypography.sectionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              value,
              style: NotebookTypography.pieceTitle.copyWith(
                fontSize: 24,
                color: AppColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: card),
      );
    }

    return card;
  }
}

/// Horizontal row of stat cards with equal spacing.
class StatCardRow extends StatelessWidget {
  const StatCardRow({
    super.key,
    required this.cards,
    this.spacing = AppSpacing.space3,
  });

  final List<Widget> cards;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}
