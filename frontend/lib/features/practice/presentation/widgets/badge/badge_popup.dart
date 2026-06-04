// Badge popup — one-shot notification when a new badge is awarded.
//
// Visual: paper-card dialog with badge icon, name, description, and a
// single confirm action. Wrap it in a [BadgePopupListener] to auto-show
// the popup whenever the recently-awarded queue changes.

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/badge.dart';
import '../../extensions/badge_visuals.dart';
import '../../providers/badge_provider.dart';

/// Modal popup announcing a newly awarded badge.
class BadgePopup extends StatelessWidget {
  final Badge badge;
  final VoidCallback? onDismiss;

  const BadgePopup({super.key, required this.badge, this.onDismiss});

  static Future<void> show(BuildContext context, Badge badge) {
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.inkScrim,
      builder:
          (ctx) => BadgePopup(
            badge: badge,
            onDismiss: () => Navigator.of(ctx).pop(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visual = badge.type.visual;
    return Dialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space5,
        vertical: AppSpacing.space5,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space5),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.practiceBadgePopupTitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: visual.accent.withValues(alpha: 0.12),
                border: Border.all(color: visual.accent.withValues(alpha: 0.4)),
              ),
              child: Icon(
                visual.icon,
                size: AppSpacing.iconLG,
                color: visual.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              visual.name,
              style: AppTypography.headingMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              visual.description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space5),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.paper,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                child: const Text(AppStrings.practiceBadgePopupConfirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Listens to the recently-awarded queue and shows [BadgePopup] one by one.
///
/// Place this near the top of the student tree (e.g. wrapping the student
/// home scaffold). It does not paint anything itself.
class BadgePopupListener extends ConsumerStatefulWidget {
  final String studentId;
  final Widget child;

  const BadgePopupListener({
    super.key,
    required this.studentId,
    required this.child,
  });

  @override
  ConsumerState<BadgePopupListener> createState() => _BadgePopupListenerState();
}

class _BadgePopupListenerState extends ConsumerState<BadgePopupListener> {
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<PracticeBadgeState>(
      practiceBadgeStateNotifierProvider(widget.studentId),
      (prev, next) {
        if (_showing) return;
        if (next.recentlyAwarded.isEmpty) return;
        _showQueue(next.recentlyAwarded);
      },
    );
    return widget.child;
  }

  Future<void> _showQueue(List<Badge> queue) async {
    if (_showing) return;
    _showing = true;
    try {
      for (final badge in queue) {
        if (!mounted) return;
        await BadgePopup.show(context, badge);
      }
    } finally {
      _showing = false;
      if (mounted) {
        ref
            .read(practiceBadgeStateNotifierProvider(widget.studentId).notifier)
            .consumeRecentlyAwarded();
      }
    }
  }
}
