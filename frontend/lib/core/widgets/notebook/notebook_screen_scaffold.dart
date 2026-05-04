import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/notebook_typography.dart';

/// Notebook x Score default screen scaffold.
///
/// Provides a paper-colored [Scaffold] with an auto-styled AppBar
/// (paper background, ink text, Playfair title).
///
/// For detail screens with masthead + sliver body, use
/// [NotebookDetailScaffold] instead.
///
/// Spec: `docs/specs/design/notebook/README.md` section 3
@immutable
class NotebookScreenScaffold extends StatelessWidget {
  const NotebookScreenScaffold({
    super.key,
    required this.body,
    this.appBarTitle,
    this.appBar,
    this.actions,
    this.backgroundColor = AppColors.paper,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  }) : assert(
         appBarTitle == null || appBar == null,
         'Provide either appBarTitle or appBar, not both.',
       );

  /// Simple string title for the AppBar. Rendered with
  /// [NotebookTypography.appBarTitle]. Ignored when [appBar] is provided.
  final String? appBarTitle;

  /// Custom AppBar. When provided, [appBarTitle] and [actions] are ignored.
  final PreferredSizeWidget? appBar;

  /// Trailing actions for the auto-generated AppBar.
  final List<Widget>? actions;

  /// Main body widget.
  final Widget body;

  /// Screen background color. Defaults to Notebook paper.
  final Color backgroundColor;

  /// Optional FAB.
  final Widget? floatingActionButton;

  /// Optional bottom navigation or bar widget.
  final Widget? bottomNavigationBar;

  /// Whether the body should resize when the keyboard appears.
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final effectiveAppBar =
        appBar ??
        (appBarTitle != null
            ? AppBar(
              titleSpacing: 0,
              title: Text(appBarTitle!, style: NotebookTypography.appBarTitle),
              actions: actions,
            )
            : null);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: effectiveAppBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
