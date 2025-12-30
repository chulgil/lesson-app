import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import 'ab_loop.dart';

/// Zoomable waveform progress bar with pinch-to-zoom support.
///
/// Allows users to zoom in on long recordings for precise seek and A-B loop setting.
class ZoomableWaveformProgressBar extends StatefulWidget {
  const ZoomableWaveformProgressBar({
    super.key,
    required this.progress,
    required this.duration,
    required this.onSeek,
    this.abLoop = const ABLoop(),
    this.onABMarkerDrag,
    this.height = 80,
    this.minScale = 1.0,
    this.maxScale = 10.0,
  });

  /// Current playback progress (0.0 to 1.0)
  final double progress;

  /// Total duration of the recording
  final Duration duration;

  /// Callback when user seeks to a new position
  final ValueChanged<double> onSeek;

  /// A-B loop state
  final ABLoop abLoop;

  /// Callback when A or B marker is dragged (isA, newProgress)
  final void Function(bool isA, double newProgress)? onABMarkerDrag;

  /// Height of the waveform container
  final double height;

  /// Minimum zoom scale (1.0 = no zoom)
  final double minScale;

  /// Maximum zoom scale
  final double maxScale;

  @override
  State<ZoomableWaveformProgressBar> createState() =>
      _ZoomableWaveformProgressBarState();
}

class _ZoomableWaveformProgressBarState
    extends State<ZoomableWaveformProgressBar> {
  double _scale = 1.0;
  double _baseScale = 1.0;
  double _offset = 0.0; // Normalized offset (0.0 to 1.0 - 1/_scale)
  Offset? _lastFocalPoint;

  // For marker dragging
  bool _isDraggingMarkerA = false;
  bool _isDraggingMarkerB = false;

  /// Convert local x position to progress value considering zoom
  double _localXToProgress(double localX, double width) {
    // Visible portion of the waveform
    final visibleWidth = 1.0 / _scale;
    final progressAtX = _offset + (localX / width) * visibleWidth;
    return progressAtX.clamp(0.0, 1.0);
  }

  /// Convert progress value to local x position considering zoom
  double _progressToLocalX(double progress, double width) {
    final visibleWidth = 1.0 / _scale;
    final localProgress = (progress - _offset) / visibleWidth;
    return localProgress * width;
  }

  /// Check if a marker is near the touch point
  bool _isNearMarker(double touchX, double markerProgress, double width) {
    final markerX = _progressToLocalX(markerProgress, width);
    return (touchX - markerX).abs() < 20; // 20px touch target
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
    _lastFocalPoint = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, double width) {
    setState(() {
      // Handle pinch zoom
      if (details.scale != 1.0) {
        final newScale =
            (_baseScale * details.scale).clamp(widget.minScale, widget.maxScale);

        // Zoom centered on focal point
        if (_lastFocalPoint != null) {
          final focalProgress = _localXToProgress(_lastFocalPoint!.dx, width);
          final newVisibleWidth = 1.0 / newScale;

          // Adjust offset to keep focal point in same screen position
          final focalRatio = _lastFocalPoint!.dx / width;
          _offset = focalProgress - focalRatio * newVisibleWidth;
        }

        _scale = newScale;
      }

      // Handle pan when zoomed
      if (_scale > 1.0 && details.scale == 1.0) {
        final delta = details.focalPoint.dx - (_lastFocalPoint?.dx ?? 0);
        final visibleWidth = 1.0 / _scale;
        final progressDelta = -delta / width * visibleWidth;
        _offset = (_offset + progressDelta).clamp(0.0, 1.0 - visibleWidth);
      }

      _lastFocalPoint = details.localFocalPoint;

      // Clamp offset to valid range
      final maxOffset = 1.0 - (1.0 / _scale);
      _offset = _offset.clamp(0.0, maxOffset.clamp(0.0, 1.0));
    });
  }

  void _handleTapDown(TapDownDetails details, double width) {
    final localX = details.localPosition.dx;

    // Check if tapping on A or B marker for dragging
    if (widget.abLoop.hasA) {
      final aProgress =
          widget.abLoop.pointA!.inMilliseconds / widget.duration.inMilliseconds;
      if (_isNearMarker(localX, aProgress, width)) {
        _isDraggingMarkerA = true;
        return;
      }
    }

    if (widget.abLoop.hasB) {
      final bProgress =
          widget.abLoop.pointB!.inMilliseconds / widget.duration.inMilliseconds;
      if (_isNearMarker(localX, bProgress, width)) {
        _isDraggingMarkerB = true;
        return;
      }
    }

    // Regular seek
    final newProgress = _localXToProgress(localX, width);
    widget.onSeek(newProgress);
  }

  void _handlePanUpdate(DragUpdateDetails details, double width) {
    final localX = details.localPosition.dx;
    final newProgress = _localXToProgress(localX, width);

    if (_isDraggingMarkerA && widget.onABMarkerDrag != null) {
      widget.onABMarkerDrag!(true, newProgress);
    } else if (_isDraggingMarkerB && widget.onABMarkerDrag != null) {
      widget.onABMarkerDrag!(false, newProgress);
    } else if (!_isDraggingMarkerA && !_isDraggingMarkerB) {
      // Regular seek while dragging
      widget.onSeek(newProgress);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _isDraggingMarkerA = false;
    _isDraggingMarkerB = false;
  }

  /// Reset zoom to default
  void resetZoom() {
    setState(() {
      _scale = 1.0;
      _offset = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zoom indicator (only show when zoomed)
            if (_scale > 1.0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_scale.toStringAsFixed(1)}x zoom',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                    GestureDetector(
                      onTap: resetZoom,
                      child: Text(
                        '초기화',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Waveform
            GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: (details) => _handleScaleUpdate(details, width),
              onTapDown: (details) => _handleTapDown(details, width),
              onHorizontalDragUpdate: (details) =>
                  _handlePanUpdate(details, width),
              onHorizontalDragEnd: _handlePanEnd,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: _ZoomableWaveformPainter(
                      progress: widget.progress.clamp(0.0, 1.0),
                      abLoop: widget.abLoop,
                      duration: widget.duration,
                      scale: _scale,
                      offset: _offset,
                    ),
                    size: Size(width, widget.height),
                  ),
                ),
              ),
            ),

            // Mini map (overview) when zoomed
            if (_scale > 1.5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _MiniMap(
                  progress: widget.progress,
                  scale: _scale,
                  offset: _offset,
                  abLoop: widget.abLoop,
                  duration: widget.duration,
                  onTap: (newOffset) {
                    setState(() {
                      final maxOffset = 1.0 - (1.0 / _scale);
                      _offset = newOffset.clamp(0.0, maxOffset.clamp(0.0, 1.0));
                    });
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Custom painter for zoomable waveform.
class _ZoomableWaveformPainter extends CustomPainter {
  _ZoomableWaveformPainter({
    required this.progress,
    required this.abLoop,
    required this.duration,
    required this.scale,
    required this.offset,
  });

  final double progress;
  final ABLoop abLoop;
  final Duration duration;
  final double scale;
  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final playedPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final unplayedPaint = Paint()
      ..color = const Color(0xFF636366)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final loopPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3);

    final markerPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3;

    // Calculate visible range
    final visibleWidth = 1.0 / scale;
    final visibleStart = offset;
    final visibleEnd = offset + visibleWidth;

    // Convert progress to local x
    double progressToX(double p) {
      return ((p - visibleStart) / visibleWidth) * size.width;
    }

    // Draw A-B loop highlight
    if (abLoop.isActive && duration.inMilliseconds > 0) {
      final aProgress =
          abLoop.pointA!.inMilliseconds / duration.inMilliseconds;
      final bProgress =
          abLoop.pointB!.inMilliseconds / duration.inMilliseconds;

      // Only draw if visible
      if (bProgress >= visibleStart && aProgress <= visibleEnd) {
        final aX = progressToX(aProgress).clamp(0.0, size.width);
        final bX = progressToX(bProgress).clamp(0.0, size.width);
        canvas.drawRect(
          Rect.fromLTRB(aX, 0, bX, size.height),
          loopPaint,
        );
      }
    }

    // Draw waveform bars (scaled)
    final barsPerUnit = 50; // bars per full waveform (unzoomed)
    final totalBars = (barsPerUnit * scale).round();
    final visibleBars = totalBars;
    final barWidth = size.width / visibleBars;
    final centerY = size.height / 2;

    for (int i = 0; i < visibleBars; i++) {
      final barProgress = visibleStart + (i / visibleBars) * visibleWidth;
      if (barProgress < 0 || barProgress > 1) continue;

      final x = i * barWidth + barWidth / 2;

      // Simulated waveform heights (consistent pattern based on progress)
      final patternIndex = (barProgress * 1000).round();
      final height = (20 + (patternIndex % 7) * 5 + (patternIndex % 3) * 3)
          .toDouble();
      final halfHeight = height / 2;

      final paint = barProgress <= progress ? playedPaint : unplayedPaint;

      canvas.drawLine(
        Offset(x, centerY - halfHeight),
        Offset(x, centerY + halfHeight),
        paint,
      );
    }

    // Draw A marker
    if (abLoop.hasA && duration.inMilliseconds > 0) {
      final aProgress =
          abLoop.pointA!.inMilliseconds / duration.inMilliseconds;
      if (aProgress >= visibleStart && aProgress <= visibleEnd) {
        final aX = progressToX(aProgress);
        _drawMarker(canvas, size, aX, 'A', markerPaint);
      }
    }

    // Draw B marker
    if (abLoop.hasB && duration.inMilliseconds > 0) {
      final bProgress =
          abLoop.pointB!.inMilliseconds / duration.inMilliseconds;
      if (bProgress >= visibleStart && bProgress <= visibleEnd) {
        final bX = progressToX(bProgress);
        _drawMarker(canvas, size, bX, 'B', markerPaint);
      }
    }

    // Draw playhead
    if (progress >= visibleStart && progress <= visibleEnd) {
      final playheadX = progressToX(progress).clamp(0.0, size.width);
      final playheadPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(playheadX, 4),
        Offset(playheadX, size.height - 4),
        playheadPaint,
      );

      // Playhead knob
      final knobX = playheadX.clamp(6.0, size.width - 6.0);
      canvas.drawCircle(
        Offset(knobX, centerY),
        6,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawMarker(
      Canvas canvas, Size size, double x, String label, Paint paint) {
    // Marker line
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      paint,
    );

    // Label background
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, 12), width: 22, height: 20),
      const Radius.circular(4),
    );
    canvas.drawRRect(labelRect, Paint()..color = AppColors.primary);

    // Label text
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(x - 5, 5));

    // Draw drag handle (circle at bottom)
    canvas.drawCircle(
      Offset(x, size.height - 10),
      8,
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(
      Offset(x, size.height - 10),
      6,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _ZoomableWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.abLoop.pointA != abLoop.pointA ||
        oldDelegate.abLoop.pointB != abLoop.pointB;
  }
}

/// Mini map showing the full waveform with viewport indicator.
class _MiniMap extends StatelessWidget {
  const _MiniMap({
    required this.progress,
    required this.scale,
    required this.offset,
    required this.abLoop,
    required this.duration,
    required this.onTap,
  });

  final double progress;
  final double scale;
  final double offset;
  final ABLoop abLoop;
  final Duration duration;
  final ValueChanged<double> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localX = details.localPosition.dx;
        final progress = localX / box.size.width;
        // Center the viewport on tap position
        final visibleWidth = 1.0 / scale;
        final newOffset = progress - visibleWidth / 2;
        onTap(newOffset);
      },
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomPaint(
          painter: _MiniMapPainter(
            progress: progress,
            scale: scale,
            offset: offset,
            abLoop: abLoop,
            duration: duration,
          ),
          size: const Size(double.infinity, 20),
        ),
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  _MiniMapPainter({
    required this.progress,
    required this.scale,
    required this.offset,
    required this.abLoop,
    required this.duration,
  });

  final double progress;
  final double scale;
  final double offset;
  final ABLoop abLoop;
  final Duration duration;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw simplified waveform
    final barPaint = Paint()
      ..color = const Color(0xFF636366)
      ..strokeWidth = 1;

    const barCount = 30;
    final barWidth = size.width / barCount;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final height = (4 + (i % 5) * 2).toDouble();
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        barPaint,
      );
    }

    // Draw A-B loop region
    if (abLoop.isActive && duration.inMilliseconds > 0) {
      final aProgress =
          abLoop.pointA!.inMilliseconds / duration.inMilliseconds;
      final bProgress =
          abLoop.pointB!.inMilliseconds / duration.inMilliseconds;
      canvas.drawRect(
        Rect.fromLTRB(
          size.width * aProgress,
          0,
          size.width * bProgress,
          size.height,
        ),
        Paint()..color = AppColors.primary.withValues(alpha: 0.3),
      );
    }

    // Draw playhead
    final playheadX = size.width * progress;
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 1,
    );

    // Draw viewport indicator
    final visibleWidth = 1.0 / scale;
    final viewportRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * offset,
        0,
        size.width * visibleWidth,
        size.height,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      viewportRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      viewportRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }
}
