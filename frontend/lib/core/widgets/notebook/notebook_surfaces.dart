/// Barrel file for Notebook x Score surface widgets.
///
/// Each primary widget now lives in its own file. This barrel re-exports
/// them and retains backward-compatible widgets.
library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../bottom_sheet_handle.dart';

export 'notebook_alert_dialog.dart';
export 'notebook_bottom_sheet.dart';
export 'notebook_detail_scaffold.dart';
export 'notebook_screen_scaffold.dart';

/// Backward-compatible bottom-sheet shell.
///
/// New code should use [NotebookBottomSheet] from `notebook_bottom_sheet.dart`.
@Deprecated('Use NotebookBottomSheet instead')
class NotebookBottomSheetShell extends StatelessWidget {
  const NotebookBottomSheetShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.screenPadding),
    this.showHandle = true,
  });

  static const handleKey = Key('notebook_bottom_sheet_handle');

  final Widget child;
  final EdgeInsets padding;
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

/// Notebook x Score angular flat card.
///
/// Wraps a [Card] with paper background, zero elevation, zero border-radius.
@immutable
class NotebookCard extends StatelessWidget {
  const NotebookCard({
    super.key,
    required this.child,
    this.color = AppColors.paper,
    this.margin = EdgeInsets.zero,
    this.elevation = 0,
    this.shape = const RoundedRectangleBorder(),
    this.clipBehavior,
    this.semanticContainer = true,
    this.borderOnForeground = true,
    this.shadowColor,
    this.surfaceTintColor = Colors.transparent,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final bool semanticContainer;
  final bool borderOnForeground;
  final Color? shadowColor;
  final Color? surfaceTintColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: elevation,
      surfaceTintColor: surfaceTintColor,
      shape: shape,
      margin: margin,
      clipBehavior: clipBehavior,
      semanticContainer: semanticContainer,
      borderOnForeground: borderOnForeground,
      shadowColor: shadowColor,
      child: child,
    );
  }
}
