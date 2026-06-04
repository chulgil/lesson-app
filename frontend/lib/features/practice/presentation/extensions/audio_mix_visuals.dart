import '../../../../core/l10n/app_strings.dart';
import '../../domain/value_objects/audio_mix_mode.dart';

/// Presentation-layer label/description mapping for [AudioMixMode].
///
/// Lives in `presentation/extensions/` per the flutter-architecture rule —
/// domain/data must not depend on `AppStrings`.
extension AudioMixVisuals on AudioMixMode {
  /// Short title used in pickers and dialog options.
  String get title {
    switch (this) {
      case AudioMixMode.videoOnly:
        return AppStrings.audioMixModeVideoOnlyTitle;
      case AudioMixMode.recordOnly:
        return AppStrings.audioMixModeRecordOnlyTitle;
      case AudioMixMode.mixed:
        return AppStrings.audioMixModeMixedTitle;
      case AudioMixMode.videoMuted:
        return AppStrings.audioMixModeVideoMutedTitle;
      case AudioMixMode.headphoneOnly:
        return AppStrings.audioMixModeHeadphoneOnlyTitle;
      case AudioMixMode.metronomeMixed:
        return AppStrings.audioMixModeMetronomeMixedTitle;
    }
  }

  /// One-line description for the picker / dialog.
  String get description {
    switch (this) {
      case AudioMixMode.videoOnly:
        return AppStrings.audioMixModeVideoOnlyDescription;
      case AudioMixMode.recordOnly:
        return AppStrings.audioMixModeRecordOnlyDescription;
      case AudioMixMode.mixed:
        return AppStrings.audioMixModeMixedDescription;
      case AudioMixMode.videoMuted:
        return AppStrings.audioMixModeVideoMutedDescription;
      case AudioMixMode.headphoneOnly:
        return AppStrings.audioMixModeHeadphoneOnlyDescription;
      case AudioMixMode.metronomeMixed:
        return AppStrings.audioMixModeMetronomeMixedDescription;
    }
  }
}

/// Format seconds as `m:ss` ("0:42") for `tempoMono` labels.
String formatLoopSeconds(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
