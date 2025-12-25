import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Animated waveform visualization for recording.
///
/// Shows flowing sine wave animation that moves from right to left.
/// When paused, the animation stops.
class RecordingWaveform extends StatefulWidget {
  const RecordingWaveform({
    super.key,
    this.isActive = true,
    this.height = 60,
    this.waveColor,
    this.waveCount = 3,
  });

  /// Whether the waveform animation is active
  final bool isActive;

  /// Height of the waveform container
  final double height;

  /// Color of the wave (defaults to white)
  final Color? waveColor;

  /// Number of overlapping waves
  final int waveCount;

  @override
  State<RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RecordingWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waveColor = widget.waveColor ?? Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: WaveformPainter(
            animationValue: _controller.value,
            waveColor: waveColor,
            waveCount: widget.waveCount,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }
}

/// Custom painter for flowing wave animation
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.animationValue,
    required this.waveColor,
    required this.waveCount,
    required this.isActive,
  });

  final double animationValue;
  final Color waveColor;
  final int waveCount;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    for (int i = 0; i < waveCount; i++) {
      final paint = Paint()
        ..color = waveColor.withValues(alpha: isActive ? (0.3 - i * 0.08) : 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 - i * 0.3
        ..strokeCap = StrokeCap.round;

      final path = Path();

      // Wave parameters - each wave has different properties
      final frequency = 2.0 + i * 0.5; // waves per width
      final amplitude = (size.height * 0.35) - i * 8; // height of wave
      final phaseShift = animationValue * 2 * pi + (i * pi / 3); // offset for each wave
      final speed = 1.0 + i * 0.3; // different speeds

      path.moveTo(0, centerY);

      for (double x = 0; x <= size.width; x += 2) {
        // Calculate y using sine wave
        // Moving right to left by adding phase (wave appears to flow leftward)
        final normalizedX = x / size.width;
        final y = centerY +
            sin((normalizedX * frequency * 2 * pi) + (phaseShift * speed)) *
                amplitude;

        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isActive != isActive;
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
    final color = barColor ?? AppColors.primary;
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
