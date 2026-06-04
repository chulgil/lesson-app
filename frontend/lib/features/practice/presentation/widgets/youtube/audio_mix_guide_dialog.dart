import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/value_objects/audio_mix_mode.dart';

/// Action chosen by the student in [showAudioMixGuide].
enum AudioMixGuideResult {
  continueAnyway,
  muteVideo,
  openHeadphoneSettings,
  dismissed,
}

/// Returns the AudioMixMode implied by the user choice, given the current
/// metronome state.
AudioMixMode mapGuideResultToMode(
  AudioMixGuideResult result, {
  required bool metronomeActive,
  required bool headphoneConnected,
}) {
  switch (result) {
    case AudioMixGuideResult.muteVideo:
      return AudioMixMode.videoMuted;
    case AudioMixGuideResult.openHeadphoneSettings:
    case AudioMixGuideResult.continueAnyway:
      if (headphoneConnected) {
        return metronomeActive
            ? AudioMixMode.metronomeMixed
            : AudioMixMode.headphoneOnly;
      }
      return metronomeActive ? AudioMixMode.metronomeMixed : AudioMixMode.mixed;
    case AudioMixGuideResult.dismissed:
      return AudioMixMode.recordOnly;
  }
}

/// Shows an audio-mix guide. Spec §5.4.
///
/// [headphoneConnected] controls the displayed message; the action list is
/// the same in both cases (so the student can opt in to any path).
Future<AudioMixGuideResult> showAudioMixGuide(
  BuildContext context, {
  required bool headphoneConnected,
}) async {
  final result = await showDialog<AudioMixGuideResult>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AudioMixGuideDialog(headphoneConnected: headphoneConnected);
    },
  );
  return result ?? AudioMixGuideResult.dismissed;
}

class AudioMixGuideDialog extends StatelessWidget {
  final bool headphoneConnected;

  const AudioMixGuideDialog({super.key, required this.headphoneConnected});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.audioMixGuideTitle,
              style: AppTypography.headingMedium,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              headphoneConnected
                  ? AppStrings.audioMixGuideMessageWithHeadphone
                  : AppStrings.audioMixGuideMessageNoHeadphone,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            _ChoiceTile(
              label: AppStrings.audioMixGuideContinueAnyway,
              onTap: () =>
                  Navigator.of(context).pop(AudioMixGuideResult.continueAnyway),
            ),
            _ChoiceTile(
              label: AppStrings.audioMixGuideMuteVideo,
              onTap: () =>
                  Navigator.of(context).pop(AudioMixGuideResult.muteVideo),
            ),
            if (!headphoneConnected)
              _ChoiceTile(
                label: AppStrings.audioMixGuideHeadphonePrompt,
                onTap: () => Navigator.of(
                  context,
                ).pop(AudioMixGuideResult.openHeadphoneSettings),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChoiceTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inkQuaternary),
            borderRadius: BorderRadius.zero,
          ),
          child: Text(label, style: AppTypography.bodyMedium),
        ),
      ),
    );
  }
}
