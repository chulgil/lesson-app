import 'package:flutter/widgets.dart';

/// Discipline-neutral injection slot for an optional center action inside a
/// bottom navigation row.
///
/// Renders [centerAction] verbatim when provided, or [SizedBox.shrink] when
/// null — a shell with no center action contributes no width and no layout, so
/// "null = not shown, no regression" holds for shells that do not inject one.
///
/// Music (discipline 0) injects the practice center button here; teacher and
/// parent shells pass null today and adopt this slot only once they gain a
/// center action (Phase 4, #979). Adding an empty slot to a `spaceAround` row
/// that has none would shift the existing items, so non-music shells stay
/// unwrapped until they actually have an action to show.
class CenterActionSlot extends StatelessWidget {
  const CenterActionSlot({super.key, this.centerAction});

  /// Widget rendered at the center slot, or null for no action.
  final Widget? centerAction;

  @override
  Widget build(BuildContext context) {
    return centerAction ?? const SizedBox.shrink();
  }
}
