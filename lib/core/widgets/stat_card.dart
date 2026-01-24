import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Reusable statistic card widget for displaying summary metrics.
///
/// Used in:
/// - PaymentManagementScreen (수납완료/미납)
/// - ParentDashboardTab (연습 통계)
/// - HomeScreen (학생 현황)
/// - StudentStatsCards (연습 통계)
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

  /// Theme color for the card
  final Color color;

  /// Optional leading icon
  final IconData? icon;

  /// Optional tap callback
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.space2),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTypography.caption.copyWith(
                color: color.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
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
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}
