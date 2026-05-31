import 'package:flutter/material.dart';

import 'coach_mark_controller.dart';
import 'coach_mark_overlay.dart';

/// Wraps a widget tree and injects the [CoachMarkOverlay] when the
/// controller has an active step.
///
/// Place this widget above the subtree that contains the target widgets.
///
/// Example:
/// ```dart
/// CoachMarkScope(
///   controller: _controller,
///   child: MyScreen(),
/// )
/// ```
class CoachMarkScope extends StatelessWidget {
  final Widget child;
  final CoachMarkController controller;

  const CoachMarkScope({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final step = controller.currentStep;
        return Stack(
          children: [
            child,
            if (step != null)
              CoachMarkOverlay(
                targetKey: step.targetKey,
                title: step.title,
                description: step.description,
                actionLabel: step.actionLabel,
                position: step.position,
                onAction: () {
                  step.onAction?.call();
                  controller.next();
                },
                onDismiss: controller.dismiss,
              ),
          ],
        );
      },
    );
  }
}
