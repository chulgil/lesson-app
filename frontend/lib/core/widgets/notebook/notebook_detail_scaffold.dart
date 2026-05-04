import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/notebook_typography.dart';
import 'notebook_masthead.dart';
import 'paper_scaffold.dart';

/// Notebook x Score detail screen scaffold.
///
/// Combines [NotebookMasthead] (eyebrow + meta) with a sliver-based body
/// on a paper background, and optionally appends a "Fine." footer.
///
/// Use this for subscription details, request details, and other
/// deep-linked content screens.
///
/// Spec: `docs/specs/design/notebook/README.md` section 6
@immutable
class NotebookDetailScaffold extends StatelessWidget {
  const NotebookDetailScaffold({
    super.key,
    required this.eyebrow,
    required this.slivers,
    this.meta,
    this.trailing,
    this.bottomBar,
    this.showFine = true,
  });

  /// Left-side brand/label for the masthead (e.g. "LESSONAZA").
  final String eyebrow;

  /// Right-side meta text for the masthead (e.g. "VOL. IV . NO. 18").
  /// Ignored when [trailing] is provided.
  final String? meta;

  /// Custom trailing widget in the masthead (replaces [meta]).
  final Widget? trailing;

  /// Sliver children for the scrollable body area.
  final List<Widget> slivers;

  /// Optional bottom bar (e.g. action bar, input bar).
  final Widget? bottomBar;

  /// Whether to append a "Fine." footer at the end of the scroll area.
  final bool showFine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: PaperScaffold(
        child: SafeArea(
          bottom: bottomBar != null,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: NotebookMasthead(
                    eyebrow: eyebrow,
                    meta: meta ?? '',
                    trailing: trailing,
                  ),
                ),
              ),
              ...slivers,
              if (showFine)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space6,
                    ),
                    child: Center(
                      child: Text('Fine.', style: NotebookTypography.fine),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
