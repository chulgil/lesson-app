import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class MetronomeStep extends StatefulWidget {
  final bool completed;
  final VoidCallback onComplete;

  const MetronomeStep({
    super.key,
    required this.completed,
    required this.onComplete,
  });

  @override
  State<MetronomeStep> createState() => _MetronomeStepState();
}

class _MetronomeStepState extends State<MetronomeStep> {
  late int _bpm;
  late bool _isPlaying;
  late int _countdownRemaining;
  late Timer? _timer;

  @override
  void initState() {
    super.initState();
    _bpm = 100;
    _isPlaying = false;
    _countdownRemaining = 3;
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (widget.completed) return;

    setState(() {
      _isPlaying = true;
      _countdownRemaining = 3;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _countdownRemaining--;
      });

      if (_countdownRemaining <= 0) {
        _timer?.cancel();
        _timer = null;

        if (!mounted) return;

        setState(() {
          _isPlaying = false;
        });

        // Notify parent that metronome simulation is complete
        widget.onComplete();
      }
    });
  }

  int _getActiveBeat() {
    // 3 - countdownRemaining gives: 1 (beat 1), 2 (beat 2), 3 (beat 3)
    return 3 - _countdownRemaining;
  }

  @override
  Widget build(BuildContext context) {
    final isBeatActive = _isPlaying;
    final activeBeat = _getActiveBeat();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // BPM Slider Label
          Text(
            '메트로놈 박자 연습',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // BPM Display
          Text(
            '$_bpm BPM',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // BPM Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
            child: Slider(
              value: _bpm.toDouble(),
              min: 60,
              max: 180,
              divisions: 24,
              onChanged: widget.completed
                  ? null
                  : (value) {
                      setState(() => _bpm = value.toInt());
                    },
              activeColor: AppColors.paperAccent,
              inactiveColor: AppColors.inkQuaternary,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),

          // Beat Visualization (3 dots)
          if (isBeatActive)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = index < activeBeat;
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.paperAccent
                        : AppColors.inkQuaternary,
                    borderRadius: BorderRadius.zero,
                  ),
                );
              }),
            ),

          const SizedBox(height: AppSpacing.space6),

          // Play Button or Completion Message
          if (!isBeatActive && !widget.completed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('student_tutorial_metronome_play'),
                onPressed: _startCountdown,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                  foregroundColor: AppColors.paper,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                ),
                child: Text('재생', style: AppTypography.button),
              ),
            ),

          // Playing Countdown
          if (isBeatActive && _countdownRemaining > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null, // Disabled during playback
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.paperAccent.withOpacity(0.5),
                  foregroundColor: AppColors.paper,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  disabledBackgroundColor: AppColors.paperAccent.withOpacity(
                    0.5,
                  ),
                ),
                child: Text(
                  '재생중... ($_countdownRemaining)',
                  style: AppTypography.button.copyWith(color: AppColors.paper),
                ),
              ),
            ),

          // Completion State
          if (widget.completed)
            Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: AppColors.paperOk,
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  '메트로놈 박자를 익혔어요!',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.paperOk,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
