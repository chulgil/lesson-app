import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../features/practice/practice_facade.dart'
    show metronomeProvider;
import 'cat_beat_indicator.dart';

/// Compact metronome controller bar for bottom of screen.
///
/// Shows: BPM display, play/pause button, cat indicator, expand button.
/// Pre-warms the metronome engine on mount to reduce first-play latency.
class MetronomeControllerBar extends ConsumerStatefulWidget {
  const MetronomeControllerBar({super.key, this.onExpand});

  final VoidCallback? onExpand;

  @override
  ConsumerState<MetronomeControllerBar> createState() =>
      _MetronomeControllerBarState();
}

class _MetronomeControllerBarState
    extends ConsumerState<MetronomeControllerBar> {
  @override
  void initState() {
    super.initState();
    // Pre-warm engine as soon as controller bar is shown
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metronomeProvider);

    return GestureDetector(
      onTap: widget.onExpand,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 106,
        decoration: const BoxDecoration(color: AppColors.paper),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cat indicator - compact size
                CatBeatIndicator(
                  currentBeat: state.currentBeat,
                  timeSignature: state.settings.timeSignature,
                  isPlaying: state.isPlaying,
                  bpm: state.settings.bpm,
                  size: 48,
                  compact: true,
                ),
                const SizedBox(width: AppSpacing.space4),

                // BPM display and controls
                Expanded(
                  child: Semantics(
                    label: '현재 템포 ${state.settings.bpm} BPM, 박자 ${state.settings.timeSignature.label}',
                    child: _BpmControls(
                      bpm: state.settings.bpm,
                      timeSignature: state.settings.timeSignature.label,
                      onDecrement:
                          () => ref
                              .read(metronomeProvider.notifier)
                              .incrementBpm(-5),
                      onIncrement:
                          () => ref
                              .read(metronomeProvider.notifier)
                              .incrementBpm(5),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space4),

                // Play/Pause button
                Semantics(
                  label: state.isPlaying ? '메트로놈 정지' : '메트로놈 재생',
                  button: true,
                  onTap: () => ref.read(metronomeProvider.notifier).toggle(),
                  child: _PlayPauseButton(
                    isPlaying: state.isPlaying,
                    onPressed:
                        () => ref.read(metronomeProvider.notifier).toggle(),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),

                // Expand button - same size as play button
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton.outlined(
                    icon: const Icon(Icons.fullscreen, size: 28),
                    onPressed: widget.onExpand,
                    tooltip: '전체 화면',
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.paperAccent,
                      side: BorderSide(color: AppColors.paperAccent, width: 2),
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decrement button
          _SmallButton(icon: Icons.remove, onPressed: onDecrement),
          const SizedBox(width: AppSpacing.space2),

          // BPM display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$bpm',
                style: AppTypography.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.paperAccent,
                ),
              ),
              Text(
                'BPM',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.space2),

          // Increment button
          _SmallButton(icon: Icons.add, onPressed: onIncrement),
          const SizedBox(width: AppSpacing.space3),

          // Time signature display (same size as BPM)
          Text(
            timeSignature,
            style: AppTypography.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.paperAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.icon, required this.onPressed});

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
          backgroundColor: AppColors.paperAccentSoft,
          foregroundColor: AppColors.paperAccent,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.isPlaying, required this.onPressed});

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton.filled(
        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 28),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.paperAccent,
          foregroundColor: AppColors.paper,
        ),
      ),
    );
  }
}
