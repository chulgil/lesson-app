import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'waveform/waveform_style.dart';
import 'waveform/wave_waveform.dart';
import 'waveform/amplitude_waveform.dart';

export 'waveform/waveform_style.dart';
export 'waveform/wave_waveform.dart';
export 'waveform/amplitude_waveform.dart';
export 'waveform/zoomable_waveform.dart';
export 'waveform/ab_loop.dart';

/// Animated waveform visualization for recording.
///
/// Factory widget that renders either [WaveWaveform] or [AmplitudeWaveform]
/// based on the selected [style].
class RecordingWaveform extends StatelessWidget {
  const RecordingWaveform({
    super.key,
    this.style = WaveformStyle.wave,
    this.isActive = true,
    this.height = 60,
    this.waveColor,
    this.waveCount = 3,
    this.amplitudeStream,
    this.barWidth = 3.0,
    this.barSpacing = 2.0,
  });

  /// Waveform visualization style
  final WaveformStyle style;

  /// Whether the waveform animation is active
  final bool isActive;

  /// Height of the waveform container
  final double height;

  /// Color of the wave/bars (defaults to white)
  final Color? waveColor;

  /// Number of overlapping waves (for wave style)
  final int waveCount;

  /// Stream of normalized amplitude values (for amplitude style)
  final Stream<double>? amplitudeStream;

  /// Width of each bar (for amplitude style)
  final double barWidth;

  /// Spacing between bars (for amplitude style)
  final double barSpacing;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case WaveformStyle.wave:
        return WaveWaveform(
          isActive: isActive,
          height: height,
          waveColor: waveColor,
          waveCount: waveCount,
        );

      case WaveformStyle.amplitude:
        if (amplitudeStream == null) {
          // Fallback to wave if no stream provided
          return WaveWaveform(
            isActive: isActive,
            height: height,
            waveColor: waveColor,
            waveCount: waveCount,
          );
        }
        return AmplitudeWaveform(
          amplitudeStream: amplitudeStream!,
          isActive: isActive,
          height: height,
          barColor: waveColor,
          barWidth: barWidth,
          barSpacing: barSpacing,
        );
    }
  }
}

/// Simple static waveform for display purposes
class StaticWaveform extends StatelessWidget {
  const StaticWaveform({
    super.key,
    this.barCount = 30,
    this.height = 40,
    this.barColor,
  });

  final int barCount;
  final double height;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final color = barColor ?? AppColors.paperAccent;
    final random = Random(42); // Fixed seed for consistent appearance

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          final barHeight = (0.2 + random.nextDouble() * 0.8) * height * 0.8;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 2,
              height: max(4, barHeight),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }),
      ),
    );
  }
}
