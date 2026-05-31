import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum SwipeActionTone { normal, destructive }

class SwipeAction {
  const SwipeAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tone = SwipeActionTone.normal,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final SwipeActionTone tone;
}

class SwipeActionTile extends StatefulWidget {
  const SwipeActionTile({
    super.key,
    required this.child,
    required this.actions,
    this.actionWidth = 72,
  });

  final Widget child;
  final List<SwipeAction> actions;
  final double actionWidth;

  @override
  State<SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<SwipeActionTile> {
  var _revealed = false;
  var _dragDelta = 0.0;

  double get _revealWidth => widget.actionWidth * widget.actions.length;

  void _settleDrag(double velocity) {
    if (velocity > 0 || _dragDelta > 48) {
      setState(() => _revealed = true);
    } else if (velocity < 0 || _dragDelta < -48) {
      setState(() => _revealed = false);
    }
    _dragDelta = 0;
  }

  bool _isPrimaryMouseDrag(PointerEvent event) {
    return event.kind == PointerDeviceKind.mouse &&
        (event.buttons & kPrimaryMouseButton) != 0;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          if (_revealed)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      widget.actions
                          .map(
                            (action) => _SwipeActionButton(
                              action: action,
                              width: widget.actionWidth,
                              onPressed: () {
                                setState(() => _revealed = false);
                                action.onPressed();
                              },
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              _revealed ? _revealWidth : 0,
              0,
              0,
            ),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerMove: (event) {
                if (_isPrimaryMouseDrag(event)) {
                  _dragDelta += event.delta.dx;
                }
              },
              onPointerUp: (event) {
                if (event.kind == PointerDeviceKind.mouse) {
                  _settleDrag(0);
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  _settleDrag(details.primaryVelocity ?? 0);
                },
                onHorizontalDragUpdate: (details) {
                  _dragDelta += details.primaryDelta ?? 0;
                },
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.action,
    required this.width,
    required this.onPressed,
  });

  final SwipeAction action;
  final double width;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDestructive = action.tone == SwipeActionTone.destructive;
    final color = isDestructive ? AppColors.paperAccent : AppColors.ink;

    return SizedBox(
      width: width,
      child: Material(
        color: color,
        child: InkWell(
          onTap: onPressed,
          child: Semantics(
            button: true,
            label: action.label,
            hint: AppStrings.swipeActionHint,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: AppColors.paper, size: 20),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  action.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
