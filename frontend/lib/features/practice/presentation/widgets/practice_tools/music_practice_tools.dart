import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/empty_state_widget.dart';
import '../tuner/tuner_settings_sheet.dart';
import 'metronome_panel.dart';
import 'practice_tool.dart';
import 'tuner_panel.dart';

/// Stable [PracticeTool.id]s for the music discipline's practice tools.
abstract final class PracticeToolIds {
  static const metronome = 'metronome';
  static const tuner = 'tuner';
  static const recording = 'recording';
}

/// Music discipline practice tools, in tab order: metronome, tuner, recording.
///
/// The only registered tool set in Phase 3 (#973). The practice tools modal
/// renders from this list, so the tab structure is byte-identical to the
/// previously hardcoded `[메트로놈, 튜너]` tabs, plus a 녹음 launch tab wired to
/// [PracticeRecordingScreen] via the quick-record route (dead-code entry point
/// audit — recording had no reachable UI entry point). Phase 4 (#979)
/// introduces a discipline-keyed registry; until then the modal defaults to
/// this list.
///
/// Tab labels stay hardcoded Korean here (relocated verbatim from the modal) —
/// StringOverlay-ization (#968) of the tool labels is a follow-up, not part of
/// this byte-identical slice. The 녹음 tab is new, so its label/panel copy use
/// [AppStrings] from the start.
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
  PracticeTool(
    id: PracticeToolIds.recording,
    displayLabel: AppStrings.practiceRecordingTitle,
    panelBuilder:
        (context, studentId, sectionId) => EmptyStateWidget(
          icon: Icons.mic,
          title: AppStrings.quickRecordSectionTitle,
          subtitle: AppStrings.quickRecordHint,
          actionLabel: studentId == null ? null : AppStrings.quickRecordButton,
          actionIcon: Icons.mic,
          onAction:
              studentId == null
                  ? null
                  : () => _startQuickRecording(context, studentId),
        ),
  ),
];

/// Closes the practice tools modal and pushes the quick-record route.
///
/// `quick=true` makes [PracticeRecordingScreen] resolve the student's default
/// "무제 > 바로 녹음" repertoire/section automatically via
/// [QuickRecordingService] — no repertoire/section picker needed
/// (practice_master §4.3.4). The `:repertoireId` path segment is a
/// placeholder ('quick'); the screen ignores it once quick mode resolves the
/// real id.
void _startQuickRecording(BuildContext context, String studentId) {
  Navigator.of(context).pop();
  context.push(
    '${AppRoutes.practiceRecording.replaceFirst(':repertoireId', 'quick')}'
    '?quick=true&studentId=$studentId',
  );
}
