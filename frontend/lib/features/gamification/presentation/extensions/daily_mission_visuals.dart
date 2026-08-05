import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/daily_mission_kind.dart';

/// [DailyMissionKind] → 표시 라벨/아이콘 변환 (C2/C3: domain 에 표시 getter
/// 금지, presentation/extensions 1곳 SSOT).
extension DailyMissionKindVisuals on DailyMissionKind {
  String get title => switch (this) {
    DailyMissionKind.practice15m => AppStrings.dailyMissionPracticeTitle,
    DailyMissionKind.metronome1 => AppStrings.dailyMissionMetronomeTitle,
    DailyMissionKind.tuner1 => AppStrings.dailyMissionTunerTitle,
    DailyMissionKind.recording1 => AppStrings.dailyMissionRecordingTitle,
  };

  IconData get icon => switch (this) {
    DailyMissionKind.practice15m => Icons.flag_outlined,
    DailyMissionKind.metronome1 => Icons.speed_outlined,
    DailyMissionKind.tuner1 => Icons.graphic_eq,
    DailyMissionKind.recording1 => Icons.mic_none_outlined,
  };
}
