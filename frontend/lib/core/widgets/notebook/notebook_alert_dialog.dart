import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/notebook_typography.dart';

/// Notebook x Score styled AlertDialog wrapper.
///
/// - backgroundColor: [AppColors.paper]
/// - shape: square corners (BorderRadius.zero) with ink quaternary border
/// - titleStyle: [NotebookTypography.pieceTitle]
/// - buttons: ink foreground, [AppColors.paperAccent] for destructive actions
///
/// Spec: `docs/specs/design/notebook/README.md` section 3
@immutable
class NotebookAlertDialog extends StatelessWidget {
  const NotebookAlertDialog({
    super.key,
    required this.content,
    this.title,
    this.titleWidget,
    this.onConfirm,
    this.confirmLabel = AppStrings.confirm,
    this.cancelLabel,
    this.onCancel,
    this.isDestructive = false,
    this.confirmColor,
    this.actions,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.space6,
      vertical: AppSpacing.space6,
    ),
    this.icon,
    this.iconPadding,
    this.iconColor,
    this.titlePadding,
    this.contentPadding,
    this.actionsPadding,
    this.actionsAlignment,
    this.buttonPadding,
    this.scrollable = false,
    this.semanticLabel,
    this.clipBehavior = Clip.none,
    this.alignment,
    Color? backgroundColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    TextStyle? titleTextStyle,
    TextStyle? contentTextStyle,
  });

  /// Dialog title. Prefer a plain string; existing form dialogs may pass a
  /// custom title widget while migrating to the Notebook wrapper.
  final Object? title;

  /// Custom title widget for dialogs with non-text or internally styled title.
  final Widget? titleWidget;

  /// Dialog body content widget.
  final Widget content;

  /// Label for the confirm action button.
  final String confirmLabel;

  /// Label for the cancel button. When null, no cancel button is shown.
  final String? cancelLabel;

  /// Called when the confirm button is tapped.
  final VoidCallback? onConfirm;

  /// Called when the cancel button is tapped.
  /// Falls back to [Navigator.pop] if null.
  final VoidCallback? onCancel;

  /// When true the confirm button uses [AppColors.paperAccent] foreground.
  final bool isDestructive;

  /// Optional explicit confirm foreground color for semantic actions.
  final Color? confirmColor;

  /// Optional explicit action widgets for form or multi-action dialogs.
  final List<Widget>? actions;

  /// Outer inset padding around the dialog.
  final EdgeInsets insetPadding;

  /// Optional icon shown above the title.
  final Widget? icon;

  /// Optional icon padding override.
  final EdgeInsetsGeometry? iconPadding;

  /// Optional icon color override.
  final Color? iconColor;

  /// Optional title padding override.
  final EdgeInsetsGeometry? titlePadding;

  /// Optional content padding override.
  final EdgeInsetsGeometry? contentPadding;

  /// Optional actions padding override.
  final EdgeInsetsGeometry? actionsPadding;

  /// Optional action alignment override.
  final MainAxisAlignment? actionsAlignment;

  /// Optional button padding override.
  final EdgeInsetsGeometry? buttonPadding;

  /// Whether the title and content should scroll together.
  final bool scrollable;

  /// Optional semantic label.
  final String? semanticLabel;

  /// Optional clipping behavior.
  final Clip clipBehavior;

  /// Optional dialog alignment.
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.inkQuaternary),
      ),
      insetPadding: insetPadding,
      icon: icon,
      iconPadding: iconPadding,
      iconColor: iconColor,
      titlePadding: titlePadding,
      title:
          titleWidget ??
          (title != null
              ? title is Widget
                  ? title as Widget
                  : Text(title.toString(), style: NotebookTypography.pieceTitle)
              : null),
      content: content,
      contentPadding: contentPadding,
      actionsPadding: actionsPadding,
      actionsAlignment: actionsAlignment,
      buttonPadding: buttonPadding,
      scrollable: scrollable,
      semanticLabel: semanticLabel,
      clipBehavior: clipBehavior,
      alignment: alignment,
      actions:
          actions ??
          [
            if (cancelLabel != null)
              TextButton(
                onPressed: onCancel ?? () => Navigator.of(context).pop(),
                child: Text(
                  cancelLabel!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            TextButton(
              onPressed: onConfirm,
              child: Text(
                confirmLabel,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      confirmColor ??
                      (isDestructive ? AppColors.paperAccent : AppColors.ink),
                ),
              ),
            ),
          ],
    );
  }
}

/// Convenience helper to show a [NotebookAlertDialog].
///
/// Returns the dialog result (null if dismissed).
Future<T?> showNotebookDialog<T>({
  required BuildContext context,
  required String title,
  Widget? content,
  String? message,
  VoidCallback? onConfirm,
  String confirmLabel = AppStrings.confirm,
  String? cancelLabel,
  VoidCallback? onCancel,
  bool isDestructive = false,
  Color? confirmColor,
  bool barrierDismissible = true,
}) {
  assert(
    content != null || message != null,
    'Either content or message must be provided.',
  );

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder:
        (_) => NotebookAlertDialog(
          title: title,
          content: content ?? Text(message!),
          onConfirm: onConfirm ?? () => Navigator.of(context).pop(true),
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          onCancel: onCancel,
          isDestructive: isDestructive,
          confirmColor: confirmColor,
        ),
  );
}
