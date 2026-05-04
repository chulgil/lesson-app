import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/tuner_types.dart';
import '../../providers/tuner_provider.dart';

/// Fish indicator that follows around the circular tuner.
/// Uses polar coordinates and cents-based accuracy visualization.
class TunerFishIndicator extends ConsumerStatefulWidget {
  const TunerFishIndicator({super.key, required this.circleSize});

  final double circleSize;

  @override
  ConsumerState<TunerFishIndicator> createState() => _TunerFishIndicatorState();
}

class _TunerFishIndicatorState extends ConsumerState<TunerFishIndicator>
    with TickerProviderStateMixin {
  // Angle animation for smooth movement
  late AnimationController _angleController;
  late Animation<double> _angleAnimation;
  double _currentAngle = 0;
  double _targetAngle = 0;

  // Tail wiggle animation
  late AnimationController _tailController;

  // Bubble animation
  late AnimationController _bubbleController;

  // Track isPerfect state for animation speed
  bool _isPerfect = false;

  // Animation durations
  static const _tailSlowDuration = Duration(milliseconds: 600);
  static const _tailFastDuration = Duration(
    milliseconds: 100,
  ); // Faster tail when hit
  static const _bubbleSlowDuration = Duration(milliseconds: 3000);
  static const _bubbleFastDuration = Duration(
    milliseconds: 800,
  ); // Faster bubbles when hit

  @override
  void initState() {
    super.initState();

    // Angle movement (smooth transition between notes)
    _angleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _angleAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _angleController, curve: Curves.easeOutCubic),
    );

    // Tail wiggle (continuous, starts slow)
    _tailController = AnimationController(
      duration: _tailSlowDuration,
      vsync: this,
    )..repeat(reverse: true);

    // Bubble effect (repeating, starts slow)
    _bubbleController = AnimationController(
      duration: _bubbleSlowDuration,
      vsync: this,
    )..repeat();
  }

  void _updateAnimationSpeed(bool isPerfect) {
    if (_isPerfect == isPerfect) return;
    _isPerfect = isPerfect;

    // Update tail speed - stop, change duration, restart
    _tailController.stop();
    _tailController.duration =
        isPerfect ? _tailFastDuration : _tailSlowDuration;
    _tailController.repeat(reverse: true);

    // Update bubble speed - stop, change duration, restart
    _bubbleController.stop();
    _bubbleController.duration =
        isPerfect ? _bubbleFastDuration : _bubbleSlowDuration;
    _bubbleController.repeat();
  }

  @override
  void dispose() {
    _angleController.dispose();
    _tailController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  /// Convert note index to angle in radians (12 o'clock = C)
  double _indexToAngleRad(int index) {
    const startAtTopRad = -math.pi / 2; // Start at 12 o'clock
    const step = (2 * math.pi) / 12.0;
    return startAtTopRad + (index * step);
  }

  /// Calculate angle including cent deviation
  double _calculateAngle(NoteName note, double centDeviation) {
    final baseAngle = _indexToAngleRad(note.index);
    // Cent offset: ±50¢ = ±15° (half of 30° segment)
    final centOffset =
        (centDeviation.clamp(-50.0, 50.0) / 50.0) * (math.pi / 12);
    return baseAngle + centOffset;
  }

  /// Shortest angle delta for smooth rotation
  double _shortestAngleDelta(double from, double to) {
    var delta = (to - from) % (2 * math.pi);
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    return delta;
  }

  /// Polar to Cartesian conversion
  Offset _polarToCartesian(Offset center, double radius, double angleRad) {
    return Offset(
      center.dx + radius * math.cos(angleRad),
      center.dy + radius * math.sin(angleRad),
    );
  }

  void _updateAngle(double newTargetAngle) {
    if ((_targetAngle - newTargetAngle).abs() > 0.01) {
      final delta = _shortestAngleDelta(_currentAngle, newTargetAngle);
      final endAngle = _currentAngle + delta;
      _angleAnimation = Tween<double>(
        begin: _currentAngle,
        end: endAngle,
      ).animate(
        CurvedAnimation(parent: _angleController, curve: Curves.easeOutCubic),
      );
      _targetAngle = newTargetAngle;
      // Update current angle to end value after animation completes
      _angleController.forward(from: 0).then((_) {
        _currentAngle = endAngle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tunerState = ref.watch(tunerProvider);
    final currentNote = tunerState.currentNote;
    final isListening = tunerState.isListening;
    final isPerfect = tunerState.isPerfect;

    // Update animation speed based on isPerfect
    _updateAnimationSpeed(isPerfect);

    // Update angle animation
    if (currentNote != null) {
      // If perfect, snap to note center (centDeviation = 0)
      // Otherwise, use actual centDeviation for smooth movement
      final effectiveCentDeviation =
          isPerfect ? 0.0 : currentNote.centDeviation;
      final newTarget = _calculateAngle(
        currentNote.name,
        effectiveCentDeviation,
      );
      _updateAngle(newTarget);
    }

    // Fish size (1.5x larger)
    final fishSize = widget.circleSize * 0.15;
    final radius =
        widget.circleSize / 2 -
        fishSize * 0.3; // Fish close to outer circle edge
    final center = Offset(widget.circleSize / 2, widget.circleSize / 2);

    final isVisible = isListening && currentNote != null;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _angleAnimation,
        _tailController,
        _bubbleController,
      ]),
      builder: (context, child) {
        // Always use animation value when available (covers both animating and completed states)
        final displayAngle = _angleAnimation.value;

        // Calculate position on circle
        final position = _polarToCartesian(center, radius, displayAngle);

        // Fish rotation (face direction of movement)
        final fishRotation = displayAngle + (math.pi / 2);

        // Simple constant tail wiggle
        const tailAmplitude = 0.1;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Bubbles
            if (isVisible)
              ..._buildBubbles(position, fishSize, _bubbleController.value),

            // Fish shadow (always below, centered)
            if (isVisible)
              Positioned(
                left: position.dx - fishSize * 0.5,
                top: position.dy - fishSize * 0.5 + 1, // 1px down
                child: Opacity(
                  opacity: 0.3,
                  child: Transform.rotate(
                    angle: fishRotation,
                    child: _CuteFishShadow(
                      size: fishSize,
                      tailPhase: _tailController.value,
                      tailAmplitude: tailAmplitude,
                    ),
                  ),
                ),
              ),

            // Fish (95% opacity, centered with glow)
            Positioned(
              left: position.dx - fishSize * 0.5,
              top: position.dy - fishSize * 0.5,
              child: Opacity(
                opacity: 0.95,
                child: Transform.rotate(
                  angle: fishRotation,
                  child: _CuteFish(
                    size: fishSize,
                    tailPhase: _tailController.value,
                    tailAmplitude: tailAmplitude,
                    isVisible: isVisible,
                    isPerfect: isPerfect,
                    drawShadow: false, // Shadow drawn separately
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildBubbles(Offset fishPos, double fishSize, double phase) {
    final bubbles = <Widget>[];

    // Use cat face color for bubbles
    final bubbleColor =
        Color.lerp(AppColors.paper, AppColors.paperAccent, 0.3)!;

    // Bubble 1 (larger, slower)
    final bubble1Phase = phase;
    final bubble1Opacity = (1 - bubble1Phase).clamp(0.0, 0.8);
    bubbles.add(
      Positioned(
        left: fishPos.dx - fishSize * 0.2 - bubble1Phase * 20,
        top: fishPos.dy - fishSize * 0.3 - bubble1Phase * 30,
        child: Opacity(
          opacity: bubble1Opacity,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bubbleColor,
            ),
          ),
        ),
      ),
    );

    // Bubble 2 (smaller, offset phase)
    final bubble2Phase = (phase + 0.4) % 1.0;
    final bubble2Opacity = (1 - bubble2Phase).clamp(0.0, 0.6);
    bubbles.add(
      Positioned(
        left: fishPos.dx + fishSize * 0.1 - bubble2Phase * 15,
        top: fishPos.dy - fishSize * 0.4 - bubble2Phase * 25,
        child: Opacity(
          opacity: bubble2Opacity,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bubbleColor,
            ),
          ),
        ),
      ),
    );

    // Bubble 3 (tiny, different offset)
    final bubble3Phase = (phase + 0.7) % 1.0;
    final bubble3Opacity = (1 - bubble3Phase).clamp(0.0, 0.5);
    bubbles.add(
      Positioned(
        left: fishPos.dx - fishSize * 0.1 - bubble3Phase * 12,
        top: fishPos.dy - fishSize * 0.2 - bubble3Phase * 35,
        child: Opacity(
          opacity: bubble3Opacity,
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bubbleColor,
            ),
          ),
        ),
      ),
    );

    return bubbles;
  }
}

/// Shadow-only fish widget for separate positioning.
class _CuteFishShadow extends StatelessWidget {
  const _CuteFishShadow({
    required this.size,
    required this.tailPhase,
    required this.tailAmplitude,
  });

  final double size;
  final double tailPhase;
  final double tailAmplitude;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _CuteFishShadowPainter(
          tailPhase: tailPhase,
          tailAmplitude: tailAmplitude,
        ),
      ),
    );
  }
}

/// Simple fish widget based on SVG design (64x64 viewBox).
class _CuteFish extends StatelessWidget {
  const _CuteFish({
    required this.size,
    required this.tailPhase,
    required this.tailAmplitude,
    required this.isVisible,
    this.isPerfect = false,
    this.drawShadow = true,
  });

  final double size;
  final double tailPhase;
  final double tailAmplitude;
  final bool isVisible;
  final bool isPerfect;
  final bool drawShadow;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return SizedBox(width: size, height: size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _CuteFishPainter(
          tailPhase: tailPhase,
          tailAmplitude: tailAmplitude,
          isPerfect: isPerfect,
        ),
      ),
    );
  }
}

/// Painter for simple fish (ellipse body + V-tail + eye).
/// Uses cat colors: face color for body, primary for eye.
/// When isPerfect, changes to green color.
class _CuteFishPainter extends CustomPainter {
  _CuteFishPainter({
    required this.tailPhase,
    required this.tailAmplitude,
    this.isPerfect = false,
  });

  final double tailPhase;
  final double tailAmplitude;
  final bool isPerfect;

  @override
  void paint(Canvas canvas, Size size) {
    // Use cat colors (same as cat face and eye)
    final faceColor = Color.lerp(AppColors.paper, AppColors.paperAccent, 0.2)!;
    final eyeColor = AppColors.paperAccent;

    // Scale factors based on SVG viewBox 64x64
    final sx = size.width / 64;
    final sy = size.height / 64;

    // Center offset: move fish left by 8 units to center it in canvas
    // Original center was ~40, canvas center is 32, so shift left by 8
    const centerOffsetX = -8.0;

    // Tail wiggle offset
    final wiggle = (tailPhase - 0.5) * size.height * tailAmplitude;

    final tailBaseX = (52 + centerOffsetX) * sx;
    final tailTipX = (62 + centerOffsetX) * sx;
    final tailY = 32 * sy + wiggle;

    // === BODY (ellipse - fill only, no stroke) ===
    final fillPaint =
        Paint()
          ..color = faceColor
          ..style = PaintingStyle.fill;

    final bodyPath = Path();
    bodyPath.addOval(
      Rect.fromCenter(
        center: Offset((36 + centerOffsetX) * sx, 32 * sy),
        width: 36 * sx, // horizontal diameter
        height: 28 * sy, // vertical diameter
      ),
    );
    canvas.drawPath(bodyPath, fillPaint);

    // === TAIL (V-shape pointing right with wiggle - filled) ===
    final tailPath = Path();
    tailPath.moveTo(tailBaseX, tailY);
    tailPath.lineTo(tailTipX, tailY - 8 * sy + wiggle * 0.3);
    tailPath.lineTo(tailTipX, tailY + 8 * sy + wiggle * 0.3);
    tailPath.close();

    canvas.drawPath(tailPath, fillPaint);

    // === EYE (filled circle - cat eye color) ===
    final eyePaint =
        Paint()
          ..color = eyeColor
          ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset((28 + centerOffsetX) * sx, 30 * sy),
      2.4 * sx,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CuteFishPainter oldDelegate) {
    return oldDelegate.tailPhase != tailPhase ||
        oldDelegate.tailAmplitude != tailAmplitude ||
        oldDelegate.isPerfect != isPerfect;
  }
}

/// Painter for fish shadow only (cat eye color).
class _CuteFishShadowPainter extends CustomPainter {
  _CuteFishShadowPainter({
    required this.tailPhase,
    required this.tailAmplitude,
  });

  final double tailPhase;
  final double tailAmplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final shadowColor = AppColors.paperAccent;

    // Scale factors based on SVG viewBox 64x64
    final sx = size.width / 64;
    final sy = size.height / 64;

    // Center offset: same as fish to keep shadow aligned
    const centerOffsetX = -8.0;

    // Tail wiggle offset
    final wiggle = (tailPhase - 0.5) * size.height * tailAmplitude;

    final tailBaseX = (52 + centerOffsetX) * sx;
    final tailTipX = (62 + centerOffsetX) * sx;
    final tailY = 32 * sy + wiggle;

    final shadowPaint =
        Paint()
          ..color = shadowColor
          ..style = PaintingStyle.fill;

    // Shadow body (same shape as fish body)
    final bodyPath = Path();
    bodyPath.addOval(
      Rect.fromCenter(
        center: Offset((36 + centerOffsetX) * sx, 32 * sy),
        width: 36 * sx,
        height: 28 * sy,
      ),
    );
    canvas.drawPath(bodyPath, shadowPaint);

    // Shadow tail (same shape as fish tail)
    final tailPath = Path();
    tailPath.moveTo(tailBaseX, tailY);
    tailPath.lineTo(tailTipX, tailY - 8 * sy + wiggle * 0.3);
    tailPath.lineTo(tailTipX, tailY + 8 * sy + wiggle * 0.3);
    tailPath.close();
    canvas.drawPath(tailPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _CuteFishShadowPainter oldDelegate) {
    return oldDelegate.tailPhase != tailPhase ||
        oldDelegate.tailAmplitude != tailAmplitude;
  }
}
