import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../l10n/generated/app_localizations.dart';

/// Position of the speech-bubble relative to the highlighted target.
enum CoachMarkPosition { above, below }

/// Highlights a target widget and shows a contextual speech-bubble.
///
/// Renders a semi-transparent scrim with a spotlight "hole" cut out
/// around [targetKey], then overlays a balloon card at [position].
///
/// The consumer is responsible for removing this widget from the tree
/// (typically via [CoachMarkScope]).
///
// ignore: widget-smoke-test — smoke test is in test/core/widgets/coach_mark/
class CoachMarkOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onDismiss;
  final CoachMarkPosition position;

  const CoachMarkOverlay({
    super.key,
    required this.targetKey,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    this.onDismiss,
    this.position = CoachMarkPosition.below,
  });

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  // Measured target rect (null until post-frame callback fires)
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    // Measure after the first frame so the target widget is laid out
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rect = _measureTarget();
      if (rect != _targetRect) {
        setState(() => _targetRect = rect);
      }
    });
  }

  @override
  void didUpdateWidget(CoachMarkOverlay old) {
    super.didUpdateWidget(old);
    // Re-measure when the target key changes
    if (old.targetKey != widget.targetKey) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _targetRect = _measureTarget());
      });
    }
  }

  Rect? _measureTarget() {
    final renderBox =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final targetRect = _targetRect;

    return Stack(
      children: [
        // Scrim layer fills the available space — tapping it dismisses
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: CustomPaint(
              painter: _SpotlightPainter(
                targetRect: targetRect,
                scrimColor: AppColors.ink.withValues(alpha: 0.7),
                spotlightPadding: AppSpacing.space2,
                spotlightRadius: AppSpacing.radiusMedium,
              ),
            ),
          ),
        ),
        // Balloon card (only when target is measured)
        if (targetRect != null)
          _PositionedBalloon(
            targetRect: targetRect,
            position: widget.position,
            title: widget.title,
            description: widget.description,
            actionLabel: widget.actionLabel,
            onAction: widget.onAction,
            onDismiss: widget.onDismiss,
          ),
      ],
    );
  }
}

/// Paints the full-screen scrim with a rounded-rectangle spotlight hole.
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color scrimColor;
  final double spotlightPadding;
  final double spotlightRadius;

  const _SpotlightPainter({
    required this.targetRect,
    required this.scrimColor,
    required this.spotlightPadding,
    required this.spotlightRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scrimPaint = Paint()..color = scrimColor;
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (targetRect == null) {
      canvas.drawRect(fullRect, scrimPaint);
      return;
    }

    final spotlight = targetRect!.inflate(spotlightPadding);
    final spotlightRRect = RRect.fromRectAndRadius(
      spotlight,
      Radius.circular(spotlightRadius),
    );

    // Scrim with hole using Even-Odd fill rule
    final path =
        Path()
          ..addRect(fullRect)
          ..addRRect(spotlightRRect)
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, scrimPaint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.targetRect != targetRect || old.scrimColor != scrimColor;
}

/// Places the balloon card above or below the target.
class _PositionedBalloon extends StatelessWidget {
  final Rect targetRect;
  final CoachMarkPosition position;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onDismiss;

  const _PositionedBalloon({
    required this.targetRect,
    required this.position,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const horizontalPadding = AppSpacing.screenPadding;

    // Arrow horizontal center (clamped to card bounds)
    final double arrowCenterX = targetRect.center.dx.clamp(
      horizontalPadding + _arrowSize * 2,
      screenSize.width - horizontalPadding - _arrowSize * 2,
    );

    // Use only top OR bottom, never both, to avoid Positioned conflicts
    final double? posTop =
        position == CoachMarkPosition.below
            ? targetRect.bottom + AppSpacing.space3
            : null;
    final double? posBottom =
        position == CoachMarkPosition.above
            ? screenSize.height - targetRect.top + AppSpacing.space3
            : null;

    return Positioned(
      left: horizontalPadding,
      right: horizontalPadding,
      top: posTop,
      bottom: posBottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (position == CoachMarkPosition.below)
            _Arrow(
              centerX: arrowCenterX - horizontalPadding,
              pointing: _ArrowDirection.up,
            ),
          _BalloonCard(
            title: title,
            description: description,
            actionLabel: actionLabel,
            onAction: onAction,
            onDismiss: onDismiss,
          ),
          if (position == CoachMarkPosition.above)
            _Arrow(
              centerX: arrowCenterX - horizontalPadding,
              pointing: _ArrowDirection.down,
            ),
        ],
      ),
    );
  }
}

const double _arrowSize = 8.0;

enum _ArrowDirection { up, down }

class _Arrow extends StatelessWidget {
  final double centerX;
  final _ArrowDirection pointing;

  const _Arrow({required this.centerX, required this.pointing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _arrowSize,
      child: CustomPaint(
        painter: _ArrowPainter(centerX: centerX, pointing: pointing),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final double centerX;
  final _ArrowDirection pointing;

  const _ArrowPainter({required this.centerX, required this.pointing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.paper
          ..style = PaintingStyle.fill;

    final path = Path();
    if (pointing == _ArrowDirection.up) {
      path
        ..moveTo(centerX, 0)
        ..lineTo(centerX - _arrowSize, size.height)
        ..lineTo(centerX + _arrowSize, size.height)
        ..close();
    } else {
      path
        ..moveTo(centerX, size.height)
        ..lineTo(centerX - _arrowSize, 0)
        ..lineTo(centerX + _arrowSize, 0)
        ..close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.centerX != centerX || old.pointing != pointing;
}

class _BalloonCard extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onDismiss;

  const _BalloonCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onDismiss != null)
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink.withValues(alpha: 0.5),
                    minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).coachMarkSkip),
                )
              else
                const SizedBox.shrink(),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.paper,
                  minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
