import '../tuner/tuner_settings_sheet.dart';
import 'metronome_panel.dart';
import 'practice_tool.dart';
import 'tuner_panel.dart';

/// Stable [PracticeTool.id]s for the music discipline's practice tools.
abstract final class PracticeToolIds {
  static const metronome = 'metronome';
  static const tuner = 'tuner';
}

/// Music discipline practice tools, in tab order: metronome then tuner.
///
/// The only registered tool set in Phase 3 (#973). The practice tools modal
/// renders from this list, so the tab structure is byte-identical to the
/// previously hardcoded `[메트로놈, 튜너]` tabs. Phase 4 (#979) introduces a
/// discipline-keyed registry; until then the modal defaults to this list.
///
/// Tab labels stay hardcoded Korean here (relocated verbatim from the modal) —
/// StringOverlay-ization (#968) of the tool labels is a follow-up, not part of
/// this byte-identical slice.
final List<PracticeTool> musicPracticeTools = <PracticeTool>[
  PracticeTool(
    id: PracticeToolIds.metronome,
    displayLabel: '메트로놈',
    panelBuilder:
        (context, studentId, sectionId) =>
            MetronomePanel(studentId: studentId, sectionId: sectionId),
  ),
  PracticeTool(
    id: PracticeToolIds.tuner,
    displayLabel: '튜너',
    panelBuilder: (context, studentId, sectionId) => const TunerPanel(),
    onShowSettings: (context) => TunerSettingsSheet.show(context),
  ),
];
