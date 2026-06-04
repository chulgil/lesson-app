// Badge collection — gallery view of all §2.7 badges grouped by category.
//
// Shows earned badges with full color/icon, locked badges greyed out.

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/badge.dart';
import '../../extensions/badge_visuals.dart';
import '../../providers/badge_provider.dart';

/// Read-only badge gallery — earned + locked entries grouped by category.
class BadgeCollection extends ConsumerWidget {
  final String studentId;

  const BadgeCollection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(practiceBadgeCollectionProvider(studentId));
    final earnedCount = badges.where((b) => b.isEarned).length;

    final grouped = <BadgeCategory, List<Badge>>{};
    for (final b in badges) {
      grouped.putIfAbsent(b.type.category, () => []).add(b);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(earned: earnedCount, total: badges.length),
        const SizedBox(height: AppSpacing.space4),
        for (final category in BadgeCategory.values) ...[
          if ((grouped[category] ?? const []).isNotEmpty) ...[
            _CategoryLabel(category: category),
            const SizedBox(height: AppSpacing.space2),
            _BadgeGrid(badges: grouped[category]!),
            const SizedBox(height: AppSpacing.space4),
          ],
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int earned;
  final int total;

  const _Header({required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          AppStrings.practiceBadgeCollectionTitle,
          style: AppTypography.headingMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          '$earned / $total',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  final BadgeCategory category;

  const _CategoryLabel({required this.category});

  @override
  Widget build(BuildContext context) {
    return Text(
      category.label,
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.inkSecondary,
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final List<Badge> badges;

  const _BadgeGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute column count; min tile width ~96.
        final width = constraints.maxWidth;
        final columns = width < 280 ? 2 : (width < 420 ? 3 : 4);
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.space3,
          crossAxisSpacing: AppSpacing.space3,
          childAspectRatio: 0.78,
          children: [for (final b in badges) _BadgeTile(badge: b)],
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Badge badge;

  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final visual = badge.type.visual;
    final isEarned = badge.isEarned;
    final accent = isEarned ? visual.accent : AppColors.inkTertiary;
    final bg =
        isEarned ? visual.accent.withValues(alpha: 0.1) : AppColors.paperDark;
    final borderColor =
        isEarned
            ? visual.accent.withValues(alpha: 0.35)
            : AppColors.inkQuaternary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg),
            child: Icon(visual.icon, size: AppSpacing.iconSM, color: accent),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            visual.name,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: isEarned ? AppColors.ink : AppColors.inkTertiary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            visual.description,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.inkTertiary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
