import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
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
  Offset? _scaleStartPoint;

  // For marker dragging
  bool _isDraggingMarkerA = false;
  bool _isDraggingMarkerB = false;

  // For distinguishing tap from pan
  bool _isPanning = false;
  bool _isZooming = false;

  // For reliable tap detection on iOS
  bool _isInScaleGesture = false;
  double _maxMoveDistance = 0.0;
  static const double _tapThreshold =
      15.0; // Max movement to be considered a tap

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

  void _handleScaleStart(ScaleStartDetails details, double width) {
    _baseScale = _scale;
    _lastFocalPoint = details.localFocalPoint;
    _scaleStartPoint = details.localFocalPoint;
    _isPanning = false;
    _isZooming = false;
    _isInScaleGesture = true;
    _maxMoveDistance = 0.0;

    // Check if starting on a marker
    final localX = details.localFocalPoint.dx;
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
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, double width) {
    // Track max movement distance from start point for tap detection
    if (_scaleStartPoint != null) {
      final distance = (details.localFocalPoint - _scaleStartPoint!).distance;
      if (distance > _maxMoveDistance) {
        _maxMoveDistance = distance;
      }
    }

    // Handle marker dragging
    if (_isDraggingMarkerA || _isDraggingMarkerB) {
      final localX = details.localFocalPoint.dx;
      final newProgress = _localXToProgress(localX, width);
      if (_isDraggingMarkerA && widget.onABMarkerDrag != null) {
        widget.onABMarkerDrag!(true, newProgress);
      } else if (_isDraggingMarkerB && widget.onABMarkerDrag != null) {
        widget.onABMarkerDrag!(false, newProgress);
      }
      return;
    }

    setState(() {
      // Detect if zooming (pinch with scale != 1.0)
      if (details.scale != 1.0) {
        _isZooming = true;
        final newScale = (_baseScale * details.scale).clamp(
          widget.minScale,
          widget.maxScale,
        );

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

      // Handle pan when zoomed (single finger drag)
      if (_scale > 1.0 && details.scale == 1.0 && details.pointerCount == 1) {
        // Use localFocalPoint for consistent coordinate comparison
        final delta = details.localFocalPoint.dx - (_lastFocalPoint?.dx ?? 0);
        // Mark as panning if moved more than threshold
        if (delta.abs() > 5) {
          _isPanning = true;
        }
        if (_isPanning) {
          final visibleWidth = 1.0 / _scale;
          final progressDelta = -delta / width * visibleWidth;
          _offset = (_offset + progressDelta).clamp(0.0, 1.0 - visibleWidth);
        }
      }

      _lastFocalPoint = details.localFocalPoint;

      // Clamp offset to valid range
      final maxOffset = 1.0 - (1.0 / _scale);
      _offset = _offset.clamp(0.0, maxOffset.clamp(0.0, 1.0));
    });
  }

  void _handleScaleEnd(ScaleEndDetails details, double width) {
    // Use distance-based tap detection for reliability on iOS
    // If movement was minimal, treat as a tap (not pan, not zoom, not marker drag)
    final isTap =
        _maxMoveDistance < _tapThreshold &&
        !_isZooming &&
        !_isDraggingMarkerA &&
        !_isDraggingMarkerB;

    if (isTap && _scaleStartPoint != null) {
      final newProgress = _localXToProgress(_scaleStartPoint!.dx, width);
      widget.onSeek(newProgress);
    }

    // Reset states
    _isDraggingMarkerA = false;
    _isDraggingMarkerB = false;
    _isPanning = false;
    _isZooming = false;
    _isInScaleGesture = false;
    _maxMoveDistance = 0.0;
    _scaleStartPoint = null;
  }

  /// Handle tap gesture for reliable seek on iOS
  void _handleTapUp(TapUpDetails details, double width) {
    // This is called when tap is recognized (no scale gesture interference)
    if (!_isInScaleGesture) {
      final newProgress = _localXToProgress(details.localPosition.dx, width);
      widget.onSeek(newProgress);
    }
  }

  /// Handle simple tap for desktop (macOS) - works independently of scale gestures
  void _handleTap(TapDownDetails details, double width) {
    // On desktop, use tap down for immediate response
    // This is especially important for macOS where onScaleStart might fire before onTapUp
    final newProgress = _localXToProgress(details.localPosition.dx, width);
    widget.onSeek(newProgress);
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
                padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_scale.toStringAsFixed(1)}x zoom',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiaryDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: resetZoom,
                      child: Text(
                        '초기화',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Waveform
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Use onTapDown for desktop (macOS) for immediate click response
              onTapDown:
                  (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                      ? (details) => _handleTap(details, width)
                      : null,
              onTapUp: (details) => _handleTapUp(details, width),
              onScaleStart: (details) => _handleScaleStart(details, width),
              onScaleUpdate: (details) => _handleScaleUpdate(details, width),
              onScaleEnd: (details) => _handleScaleEnd(details, width),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondaryDark,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
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
                padding: const EdgeInsets.only(top: AppSpacing.space2),
                child: _MiniMap(
                  progress: widget.progress,
                  scale: _scale,
                  offset: _offset,
                  abLoop: widget.abLoop,
                  duration: widget.duration,
                  onOffsetChanged: (newOffset) {
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
    final playedPaint =
        Paint()
          ..color = AppColors.paperAccent
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

    final unplayedPaint =
        Paint()
          ..color = AppColors.textTertiaryDark
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

    final loopPaint =
        Paint()..color = AppColors.paperAccent.withValues(alpha: 0.3);

    final markerPaint =
        Paint()
          ..color = AppColors.paperAccent
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
      final aProgress = abLoop.pointA!.inMilliseconds / duration.inMilliseconds;
      final bProgress = abLoop.pointB!.inMilliseconds / duration.inMilliseconds;

      // Only draw if visible
      if (bProgress >= visibleStart && aProgress <= visibleEnd) {
        final aX = progressToX(aProgress).clamp(0.0, size.width);
        final bX = progressToX(bProgress).clamp(0.0, size.width);
        canvas.drawRect(Rect.fromLTRB(aX, 0, bX, size.height), loopPaint);
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
      final height =
          (20 + (patternIndex % 7) * 5 + (patternIndex % 3) * 3).toDouble();
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
      final aProgress = abLoop.pointA!.inMilliseconds / duration.inMilliseconds;
      if (aProgress >= visibleStart && aProgress <= visibleEnd) {
        final aX = progressToX(aProgress);
        _drawMarker(canvas, size, aX, 'A', markerPaint);
      }
    }

    // Draw B marker
    if (abLoop.hasB && duration.inMilliseconds > 0) {
      final bProgress = abLoop.pointB!.inMilliseconds / duration.inMilliseconds;
      if (bProgress >= visibleStart && bProgress <= visibleEnd) {
        final bX = progressToX(bProgress);
        _drawMarker(canvas, size, bX, 'B', markerPaint);
      }
    }

    // Draw playhead
    if (progress >= visibleStart && progress <= visibleEnd) {
      final playheadX = progressToX(progress).clamp(0.0, size.width);
      final playheadPaint =
          Paint()
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
    Canvas canvas,
    Size size,
    double x,
    String label,
    Paint paint,
  ) {
    // Marker line
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);

    // Label background
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, 12), width: 22, height: 20),
      const Radius.circular(4),
    );
    canvas.drawRRect(labelRect, Paint()..color = AppColors.paperAccent);

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
      Paint()..color = AppColors.paperAccent,
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
class _MiniMap extends StatefulWidget {
  const _MiniMap({
    required this.progress,
    required this.scale,
    required this.offset,
    required this.abLoop,
    required this.duration,
    required this.onOffsetChanged,
  });

  final double progress;
  final double scale;
  final double offset;
  final ABLoop abLoop;
  final Duration duration;
  final ValueChanged<double> onOffsetChanged;

  @override
  State<_MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<_MiniMap> {
  double? _dragStartOffset;

  void _handleDragStart(DragStartDetails details) {
    _dragStartOffset = widget.offset;
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    if (_dragStartOffset == null) return;
    final delta = details.delta.dx / width;
    final visibleWidth = 1.0 / widget.scale;
    final maxOffset = (1.0 - visibleWidth).clamp(0.0, 1.0);
    final newOffset = (widget.offset + delta).clamp(0.0, maxOffset);
    widget.onOffsetChanged(newOffset);
  }

  void _handleTap(TapDownDetails details, double width) {
    final localX = details.localPosition.dx;
    final tapProgress = localX / width;
    // Center the viewport on tap position
    final visibleWidth = 1.0 / widget.scale;
    final newOffset = tapProgress - visibleWidth / 2;
    widget.onOffsetChanged(newOffset);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onTapDown: (details) => _handleTap(details, width),
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate:
              (details) => _handleDragUpdate(details, width),
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: CustomPaint(
              painter: _MiniMapPainter(
                progress: widget.progress,
                scale: widget.scale,
                offset: widget.offset,
                abLoop: widget.abLoop,
                duration: widget.duration,
              ),
              size: const Size(double.infinity, 20),
            ),
          ),
        );
      },
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
    final barPaint =
        Paint()
          ..color = AppColors.textTertiaryDark
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
      final aProgress = abLoop.pointA!.inMilliseconds / duration.inMilliseconds;
      final bProgress = abLoop.pointB!.inMilliseconds / duration.inMilliseconds;
      canvas.drawRect(
        Rect.fromLTRB(
          size.width * aProgress,
          0,
          size.width * bProgress,
          size.height,
        ),
        Paint()..color = AppColors.paperAccent.withValues(alpha: 0.3),
      );
    }

    // Draw playhead
    final playheadX = size.width * progress;
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      Paint()
        ..color = AppColors.paperAccent
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
        ..color = AppColors.paper.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      viewportRect,
      Paint()
        ..color = AppColors.paper.withValues(alpha: 0.6)
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
