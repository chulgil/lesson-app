import 'package:flutter/widgets.dart';

/// A practice tool surfaced as one tab in the practice tools modal (#973).
///
/// Presentation-layer injection descriptor: a discipline contributes a list of
/// [PracticeTool]s and the modal renders one tab per tool — its tab count,
/// labels, panels and settings button are driven entirely by the list. Music
/// registers metronome + tuner (see `music_practice_tools.dart`); a future
/// discipline (Phase 4 / #979) registers its own tools without editing the
/// modal shell.
///
/// Carries Flutter [Widget] builders, so it deliberately lives in the
/// presentation layer — it must NOT move to `core/domain/value_objects/`, which
/// forbids Flutter imports (flutter-architecture layer boundary).
@immutable
class PracticeTool {
  const PracticeTool({
    required this.id,
    required this.displayLabel,
    required this.panelBuilder,
    this.onShowSettings,
  });

  /// Stable identifier (e.g. 'metronome', 'tuner'). Not user-facing.
  final String id;

  /// Tab label shown in the modal's [TabBar]. User-facing.
  final String displayLabel;

  /// Builds this tool's tab panel. [studentId] threads the practice student
  /// context (gamification logging) through to the panel; it may be null.
  final Widget Function(BuildContext context, String? studentId) panelBuilder;

  /// Optional settings action. When non-null a settings icon appears in the
  /// modal header while this tool's tab is active and invokes this callback.
  /// null = the tool has no settings affordance.
  final void Function(BuildContext context)? onShowSettings;
}
