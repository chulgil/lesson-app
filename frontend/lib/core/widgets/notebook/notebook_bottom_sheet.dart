import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../bottom_sheet_handle.dart';

/// Notebook x Score styled BottomSheet content shell.
///
/// - backgroundColor: [AppColors.paper]
/// - shape: square corners (BorderRadius.zero)
/// - Includes [BottomSheetHandle] at the top by default
///
/// Callers should keep the route background transparent and
/// wrap content with this shell.
///
/// Spec: `docs/specs/design/notebook/README.md` section 3
@immutable
class NotebookBottomSheet extends StatelessWidget {
  const NotebookBottomSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.screenPadding),
    this.showHandle = true,
  });

  /// Key for the drag handle widget, useful for testing.
  static const handleKey = Key('notebook_bottom_sheet_handle');

  /// The sheet body content.
  final Widget child;

  /// Padding around the content area.
  final EdgeInsets padding;

  /// Whether to show the drag handle at the top.
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHandle) ...[
                const Center(
                  child: BottomSheetHandle(
                    key: handleKey,
                    margin: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience helper to show a Notebook-styled modal bottom sheet.
///
/// Wraps content in [NotebookBottomSheet] with transparent route background.
Future<T?> showNotebookBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showHandle = true,
  EdgeInsets padding = const EdgeInsets.all(AppSpacing.screenPadding),
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.45),
    isScrollControlled: isScrollControlled,
    builder:
        (ctx) => NotebookBottomSheet(
          showHandle: showHandle,
          padding: padding,
          child: builder(ctx),
        ),
  );
}

/// Shows a Notebook-styled modal route for custom bottom-sheet bodies.
///
/// Use this when the child already owns its surface, padding, or a
/// [DraggableScrollableSheet] layout. For ordinary sheets, prefer
/// [showNotebookBottomSheet].
Future<T?> showNotebookModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    shape: const RoundedRectangleBorder(),
    barrierColor: AppColors.ink.withValues(alpha: 0.45),
    builder: (ctx) {
      final child = builder(ctx);
      return Material(color: AppColors.paper, child: child);
    },
  );
}
