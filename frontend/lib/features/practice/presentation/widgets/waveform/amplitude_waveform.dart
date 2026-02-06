import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';

/// Real-time amplitude bar graph visualization for recording.
///
/// Shows vertical bars that respond to actual audio input levels.
/// Bars scroll from right to left as new amplitude data arrives.
class AmplitudeWaveform extends StatefulWidget {
  const AmplitudeWaveform({
    super.key,
    required this.amplitudeStream,
    this.isActive = true,
    this.height = 60,
    this.barColor,
    this.barWidth = 3.0,
    this.barSpacing = 2.0,
  });

  /// Stream of normalized amplitude values (0.0 to 1.0)
  final Stream<double> amplitudeStream;

  /// Whether the waveform is actively receiving data
  final bool isActive;

  /// Height of the waveform container
  final double height;

  /// Color of the bars (defaults to white)
  final Color? barColor;

  /// Width of each bar
  final double barWidth;

  /// Spacing between bars
  final double barSpacing;

  @override
  State<AmplitudeWaveform> createState() => _AmplitudeWaveformState();
}

class _AmplitudeWaveformState extends State<AmplitudeWaveform> {
  final Queue<double> _amplitudes = Queue<double>();
  StreamSubscription<double>? _subscription;
  int _maxBars = 50;

  @override
  void initState() {
    super.initState();
    _subscribeToStream();
  }

  @override
  void didUpdateWidget(AmplitudeWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.amplitudeStream != oldWidget.amplitudeStream) {
      _unsubscribe();
      _subscribeToStream();
    }
    if (widget.isActive != oldWidget.isActive) {
      if (!widget.isActive) {
        _unsubscribe();
      } else {
        _subscribeToStream();
      }
    }
  }

  void _subscribeToStream() {
    if (!widget.isActive) {
      return;
    }

    _subscription = widget.amplitudeStream.listen(
      (amplitude) {
        if (mounted) {
          setState(() {
            _amplitudes.addLast(amplitude);
            while (_amplitudes.length > _maxBars) {
              _amplitudes.removeFirst();
            }
          });
        }
      },
      onError: (error) {
        // Stream error, ignore
      },
      onDone: () {
        // Stream done
      },
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate max bars based on available width
        _maxBars = (constraints.maxWidth / (widget.barWidth + widget.barSpacing))
            .floor();

        return CustomPaint(
          size: Size(constraints.maxWidth, widget.height),
          painter: _AmplitudeBarPainter(
            amplitudes: _amplitudes.toList(),
            barColor: widget.barColor ?? Colors.white,
            barWidth: widget.barWidth,
            barSpacing: widget.barSpacing,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }
}

/// Custom painter for amplitude bar visualization
class _AmplitudeBarPainter extends CustomPainter {
  _AmplitudeBarPainter({
    required this.amplitudes,
    required this.barColor,
    required this.barWidth,
    required this.barSpacing,
    required this.isActive,
  });

  final List<double> amplitudes;
  final Color barColor;
  final double barWidth;
  final double barSpacing;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) {
      _drawIdleBars(canvas, size);
      return;
    }

    final paint = Paint()
      ..color = barColor.withValues(alpha: isActive ? 0.8 : 0.4)
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final stepWidth = barWidth + barSpacing;

    // Draw bars from right to left (newest on right)
    for (int i = 0; i < amplitudes.length; i++) {
      final index = amplitudes.length - 1 - i;
      final x = size.width - (i * stepWidth) - barWidth;

      if (x < 0) break;

      // Scale amplitude to bar height (minimum 4px)
      final amplitude = amplitudes[index].clamp(0.0, 1.0);
      final barHeight = (amplitude * size.height * 0.8).clamp(4.0, size.height);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight,
        ),
        const Radius.circular(1.5),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  void _drawIdleBars(Canvas canvas, Size size) {
    // Draw faint idle bars when no data
    final paint = Paint()
      ..color = barColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final stepWidth = barWidth + barSpacing;
    final barCount = (size.width / stepWidth).floor();

    for (int i = 0; i < barCount; i++) {
      final x = size.width - (i * stepWidth) - barWidth;
      if (x < 0) break;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: 4,
        ),
        const Radius.circular(1.5),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmplitudeBarPainter oldDelegate) {
    return oldDelegate.amplitudes.length != amplitudes.length ||
        oldDelegate.isActive != isActive ||
        (amplitudes.isNotEmpty &&
            oldDelegate.amplitudes.isNotEmpty &&
            oldDelegate.amplitudes.last != amplitudes.last);
  }
}
