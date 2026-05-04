import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Circle button for BPM increment/decrement.
class CircleButton extends StatelessWidget {
  const CircleButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(color: AppColors.paperAccent),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.paperDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hybrid BPM slider: 10-200 linear (75%), 200-400 compressed (25%).
/// Includes +1/-1 buttons for fine-tuning.
class LogarithmicBpmSlider extends StatelessWidget {
  const LogarithmicBpmSlider({
    super.key,
    required this.bpm,
    required this.onChanged,
    required this.onIncrement,
  });

  final int bpm;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onIncrement;

  static const double _minBpm = 30;
  static const double _midBpm = 120; // Transition point
  static const double _maxBpm = 208;
  static const double _midPosition = 0.6; // 120 BPM at 60% of slider

  /// Convert BPM to slider position (0-1) using hybrid scale.
  /// 10-200: linear in 0-0.75 range
  /// 200-400: compressed in 0.75-1.0 range
  double _bpmToSlider(int bpm) {
    final clampedBpm = bpm.clamp(_minBpm.toInt(), _maxBpm.toInt()).toDouble();

    if (clampedBpm <= _midBpm) {
      // Linear: 10-200 maps to 0-0.75
      return ((clampedBpm - _minBpm) / (_midBpm - _minBpm) * _midPosition)
          .clamp(0.0, _midPosition);
    } else {
      // Compressed: 200-400 maps to 0.75-1.0
      return (_midPosition +
              (clampedBpm - _midBpm) /
                  (_maxBpm - _midBpm) *
                  (1.0 - _midPosition))
          .clamp(_midPosition, 1.0);
    }
  }

  /// Convert slider position (0-1) to BPM using hybrid scale.
  int _sliderToBpm(double position) {
    if (position <= _midPosition) {
      // Linear: 0-0.75 maps to 10-200
      final bpm = _minBpm + (position / _midPosition) * (_midBpm - _minBpm);
      return bpm.round().clamp(_minBpm.toInt(), _midBpm.toInt());
    } else {
      // Compressed: 0.75-1.0 maps to 200-400
      final bpm =
          _midBpm +
          ((position - _midPosition) / (1.0 - _midPosition)) *
              (_maxBpm - _midBpm);
      return bpm.round().clamp(_midBpm.toInt(), _maxBpm.toInt());
    }
  }

  /// Get color based on BPM intensity (darker = faster).
  Color _getSliderColor(int bpm) {
    final intensity = ((bpm - _minBpm) / (_maxBpm - _minBpm)).clamp(0.0, 1.0);
    return Color.lerp(
      AppColors.paperAccentSoft,
      AppColors.paperAccent,
      intensity,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final sliderColor = _getSliderColor(bpm);

    return Column(
      children: [
        // Main slider with +5/-5 buttons
        Row(
          children: [
            CircleButton(label: '-5', onPressed: () => onIncrement(-5)),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: sliderColor,
                  inactiveTrackColor: AppColors.paperAccentSoft.withValues(
                    alpha: 0.3,
                  ),
                  thumbColor: sliderColor,
                  overlayColor: sliderColor.withValues(alpha: 0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _bpmToSlider(bpm),
                  min: 0,
                  max: 1,
                  onChanged: (value) => onChanged(_sliderToBpm(value)),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            CircleButton(label: '+5', onPressed: () => onIncrement(5)),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        // Fine-tuning +1/-1 buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SmallButton(label: '-1', onPressed: () => onIncrement(-1)),
            const SizedBox(width: AppSpacing.space4),
            SmallButton(label: '+1', onPressed: () => onIncrement(1)),
          ],
        ),
      ],
    );
  }
}

/// Small button for fine BPM adjustment.
class SmallButton extends StatelessWidget {
  const SmallButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 32,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.paperAccent,
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppColors.inkQuaternary),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
