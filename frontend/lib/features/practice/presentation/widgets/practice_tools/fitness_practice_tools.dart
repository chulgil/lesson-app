import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/widgets/empty_state_widget.dart';
import 'practice_tool.dart';

/// Stable [PracticeTool.id]s for the fitness discipline's practice tools (#979-B).
abstract final class FitnessPracticeToolIds {
  static const repCounter = 'rep_counter';
  static const intervalTimer = 'interval_timer';
  static const guideMedia = 'guide_media';
}

/// Fitness (헬스 / GX) discipline practice tools — Phase 4 (#979-B), skeleton stage.
///
/// The second registered discipline after music. #979-A wired the practice tools
/// modal to a discipline-keyed [PracticeToolRegistry]; this registers fitness's
/// tool set as a single data entry, so the fitness shell renders with **zero**
/// modal-shell change and music stays byte-identical.
///
/// The tools are **skeletons**: each renders its identity (via [EmptyStateWidget])
/// so the fitness shell is navigable, but carries no sensor / camera / IMU / BPM
/// logic — the fitness domain interview (real rep detection, interval pacing, form
/// analysis) is a deliberate follow-up. None has id `tuner`, so the modal's
/// microphone lifecycle stays inert for fitness (its `_tunerIndex` resolves to -1).
final List<PracticeTool> fitnessPracticeTools = <PracticeTool>[
  PracticeTool(
    id: FitnessPracticeToolIds.repCounter,
    displayLabel: AppStrings.practiceToolRepCounter,
    panelBuilder:
        (context, studentId, sectionId) => const EmptyStateWidget(
          icon: Icons.repeat_rounded,
          title: AppStrings.practiceToolRepCounter,
          subtitle: AppStrings.practiceToolSkeletonSubtitle,
        ),
  ),
  PracticeTool(
    id: FitnessPracticeToolIds.intervalTimer,
    displayLabel: AppStrings.practiceToolIntervalTimer,
    panelBuilder:
        (context, studentId, sectionId) => const EmptyStateWidget(
          icon: Icons.timer_outlined,
          title: AppStrings.practiceToolIntervalTimer,
          subtitle: AppStrings.practiceToolSkeletonSubtitle,
        ),
  ),
  PracticeTool(
    id: FitnessPracticeToolIds.guideMedia,
    displayLabel: AppStrings.practiceToolGuideMedia,
    panelBuilder:
        (context, studentId, sectionId) => const EmptyStateWidget(
          icon: Icons.ondemand_video_outlined,
          title: AppStrings.practiceToolGuideMedia,
          subtitle: AppStrings.practiceToolSkeletonSubtitle,
        ),
  ),
];
