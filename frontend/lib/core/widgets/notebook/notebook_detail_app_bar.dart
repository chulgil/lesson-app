import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/notebook_typography.dart';

/// Standard action types available in detail screen AppBars.
///
/// Each screen shows only the actions it needs by passing them
/// in the [actions] list. Icons and semantics are centralized here
/// to enforce consistency across all detail screens.
enum DetailAppBarAction {
  add(Icons.add, 'add'),
  edit(Icons.edit_outlined, 'edit'),
  delete(Icons.delete_outline, 'delete'),
  share(Icons.share_outlined, 'share'),
  more(Icons.more_vert, 'more'), // always vertical dots
  settings(Icons.settings_outlined, 'settings'),
  filter(Icons.filter_list, 'filter'),
  search(Icons.search, 'search'),
  copy(Icons.copy_outlined, 'copy'),
  history(Icons.history, 'history'),
  ;

  const DetailAppBarAction(this.icon, this.semanticLabel);
  final IconData icon;
  final String semanticLabel;
}

/// Leading button type for detail screen AppBars.
enum DetailAppBarLeading {
  /// Standard back arrow for drill-down navigation.
  back,

  /// Close (×) for modal/edit screens that discard on close.
  close,
}

/// Unified AppBar for all detail screens with back navigation.
///
/// Design spec:
/// ```
/// ──────────────────────────────────────
///  [←] Title                    [+] [⋮]
/// ──────────────────────────────────────  ← bottom border
/// ```
///
/// Usage:
/// ```dart
/// NotebookScreenScaffold(
///   appBar: NotebookDetailAppBar(
///     title: AppStrings.studentDetailTitle,
///     actions: [DetailAppBarAction.more],
///     onAction: (action) { ... },
///   ),
///   body: ...,
/// )
/// ```
class NotebookDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final DetailAppBarLeading leading;
  final VoidCallback? onLeadingTap;
  final List<DetailAppBarAction> actions;
  final ValueChanged<DetailAppBarAction>? onAction;

  /// For actions that need custom widgets (e.g., PopupMenuButton, TextButton).
  /// These are appended AFTER enum-based action icons.
  final List<Widget>? customActions;

  /// Optional bottom widget (e.g., TabBar). The border line is always shown
  /// below this widget.
  final PreferredSizeWidget? bottom;

  const NotebookDetailAppBar({
    super.key,
    required this.title,
    this.leading = DetailAppBarLeading.back,
    this.onLeadingTap,
    this.actions = const [],
    this.onAction,
    this.customActions,
    this.bottom,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    // AppBar height (kToolbarHeight) + bottom widget + border (1px)
    return Size.fromHeight(kToolbarHeight + bottomHeight + 1);
  }

  @override
  Widget build(BuildContext context) {
    final leadingIcon =
        leading == DetailAppBarLeading.close ? Icons.close : Icons.arrow_back;

    final actionWidgets = <Widget>[
      for (final action in actions)
        IconButton(
          icon: Icon(action.icon),
          onPressed: onAction != null ? () => onAction!(action) : null,
          tooltip: action.semanticLabel,
        ),
      if (customActions != null) ...customActions!,
    ];

    // Bottom border — matches ThinRule (1px inkQuaternary), same as home screen
    final borderLine = PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
        height: 1,
        color: AppColors.inkQuaternary,
      ),
    );

    final PreferredSizeWidget effectiveBottom;
    if (bottom != null) {
      effectiveBottom = PreferredSize(
        preferredSize: Size.fromHeight(
          bottom!.preferredSize.height + 1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [bottom!, borderLine],
        ),
      );
    } else {
      effectiveBottom = borderLine;
    }

    return AppBar(
      leading: IconButton(
        icon: Icon(leadingIcon),
        onPressed: onLeadingTap ?? () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        title,
        style: NotebookTypography.appBarTitle,
      ),
      centerTitle: false,
      titleSpacing: 0,
      actions: actionWidgets.isEmpty ? null : actionWidgets,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: effectiveBottom,
    );
  }
}
