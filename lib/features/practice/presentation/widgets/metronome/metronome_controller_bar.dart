import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../providers/metronome/metronome_provider.dart';
import 'cat_beat_indicator.dart';

/// Compact metronome controller bar for bottom of screen.
///
/// Shows: BPM display, play/pause button, cat indicator, expand button.
class MetronomeControllerBar extends ConsumerWidget {
  const MetronomeControllerBar({
    super.key,
    this.onExpand,
  });

  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metronomeProvider);

    return GestureDetector(
      onTap: onExpand,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: Row(
            children: [
              // Cat indicator - large for visibility
              CatBeatIndicator(
                currentBeat: state.currentBeat,
                timeSignature: state.settings.timeSignature,
                isPlaying: state.isPlaying,
                size: 64,
                compact: true,
              ),
              const SizedBox(width: AppSpacing.space4),

              // BPM display and controls
              Expanded(
                child: _BpmControls(
                  bpm: state.settings.bpm,
                  timeSignature: state.settings.timeSignature.label,
                  onDecrement: () =>
                      ref.read(metronomeProvider.notifier).incrementBpm(-5),
                  onIncrement: () =>
                      ref.read(metronomeProvider.notifier).incrementBpm(5),
                ),
              ),
              const SizedBox(width: AppSpacing.space4),

              // Play/Pause button
              _PlayPauseButton(
                isPlaying: state.isPlaying,
                onPressed: () =>
                    ref.read(metronomeProvider.notifier).toggle(),
              ),
              const SizedBox(width: AppSpacing.space2),

              // Expand button - same size as play button
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton.outlined(
                  icon: const Icon(Icons.fullscreen, size: 28),
                  onPressed: onExpand,
                  tooltip: '전체 화면',
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _BpmControls extends StatelessWidget {
  const _BpmControls({
    required this.bpm,
    required this.timeSignature,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int bpm;
  final String timeSignature;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrement button
        _SmallButton(
          icon: Icons.remove,
          onPressed: onDecrement,
        ),
        const SizedBox(width: AppSpacing.space2),

        // BPM display
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$bpm',
              style: AppTypography.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'BPM',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.space2),

        // Increment button
        _SmallButton(
          icon: Icons.add,
          onPressed: onIncrement,
        ),
        const SizedBox(width: AppSpacing.space3),

        // Time signature display (same size as BPM)
        Text(
          timeSignature,
          style: AppTypography.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton.filled(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton.filled(
        icon: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          size: 28,
        ),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
