import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../models/metronome_settings.dart';

/// Pastel purple color for paw (per spec).
const _pawColor = Color(0xFFB8A9C9);

/// Easing curve per spec: cubic-bezier(0.22, 0.61, 0.36, 1).
const _dropCurve = Cubic(0.22, 0.61, 0.36, 1);

/// Cat beat indicator with animated paw design.
///
/// Visual components:
/// - Cat face with ears at top
/// - Animated paws: "툭 올려놓기" motion per spec
class CatBeatIndicator extends StatelessWidget {
  const CatBeatIndicator({
    super.key,
    required this.currentBeat,
    required this.timeSignature,
    required this.isPlaying,
    this.accentPattern = AccentPattern.strongMediumWeak,
    this.bpm = 100,
    this.size = 80.0,
    this.compact = false,
  });

  final int currentBeat;
  final TimeSignature timeSignature;
  final bool isPlaying;
  final AccentPattern accentPattern;
  final int bpm;
  final double size;
  final bool compact;

  int get _beatCount => switch (timeSignature) {
        TimeSignature.twoFour => 2,
        TimeSignature.threeFour => 3,
        TimeSignature.fourFour => 4,
        TimeSignature.sixEight => 6,
      };

  /// Determine if eyes should be open based on accent pattern.
  bool get _shouldEyesOpen {
    if (!isPlaying) return false;

    return switch (accentPattern) {
      AccentPattern.uniform => false,
      AccentPattern.firstBeatOnly => currentBeat == 1,
      AccentPattern.strongMediumWeak => currentBeat == 1 || currentBeat == 3,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactIndicator();
    }
    return _buildFullIndicator();
  }

  /// Compact indicator for controller bar.
  /// Pulses (blinks) on each beat when playing.
  Widget _buildCompactIndicator() {
    final eyesOpen = isPlaying && currentBeat == 1;

    return _CompactCatWithPulse(
      size: size,
      eyesOpen: eyesOpen,
      currentBeat: isPlaying ? currentBeat : 0,
      isPlaying: isPlaying,
    );
  }

  /// Full indicator with cat face and animated paws.
  Widget _buildFullIndicator() {
    // Cat face height based on size parameter
    final catFaceHeight = size * 1.3;
    final containerWidth = size * 2.5;

    return SizedBox(
      width: containerWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cat face section - fixed size based on size parameter
          SizedBox(
            height: catFaceHeight,
            child: CustomPaint(
              painter: _CatFacePainter(
                eyesOpen: _shouldEyesOpen,
                faceColor: AppColors.primary.withValues(alpha: 0.2),
                featureColor: AppColors.primary,
              ),
              size: Size.infinite,
            ),
          ),
          // Animated paws section
          _AnimatedPawsRow(
            beatCount: _beatCount,
            currentBeat: isPlaying ? currentBeat : 0,
            bpm: bpm,
            accentPattern: accentPattern,
            parentWidth: containerWidth,
          ),
        ],
      ),
    );
  }
}

/// Animated paws row with drop animation.
class _AnimatedPawsRow extends StatelessWidget {
  const _AnimatedPawsRow({
    required this.beatCount,
    required this.currentBeat,
    required this.bpm,
    required this.accentPattern,
    required this.parentWidth,
  });

  final int beatCount;
  final int currentBeat;
  final int bpm;
  final AccentPattern accentPattern;
  final double parentWidth;

  @override
  Widget build(BuildContext context) {
    // Calculate paw size based on available width
    final pawWidth = (parentWidth / beatCount).clamp(40.0, 100.0);
    final pawHeight = pawWidth * 0.6;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(beatCount, (index) {
        final beatNumber = index + 1;
        final isActive = currentBeat > 0 && index < currentBeat;
        final isCurrentBeat = currentBeat == beatNumber;

        return Expanded(
          child: Center(
            child: _AnimatedPaw(
              key: ValueKey('paw_$beatNumber'),
              beatNumber: beatNumber,
              isActive: isActive,
              isCurrentBeat: isCurrentBeat,
              bpm: bpm,
              accentPattern: accentPattern,
              beatCount: beatCount,
              pawSize: Size(pawWidth, pawHeight),
            ),
          ),
        );
      }),
    );
  }
}

/// Single animated paw with drop + scale animation.
class _AnimatedPaw extends StatefulWidget {
  const _AnimatedPaw({
    super.key,
    required this.beatNumber,
    required this.isActive,
    required this.isCurrentBeat,
    required this.bpm,
    required this.accentPattern,
    required this.beatCount,
    required this.pawSize,
  });

  final int beatNumber;
  final bool isActive;
  final bool isCurrentBeat;
  final int bpm;
  final AccentPattern accentPattern;
  final int beatCount;
  final Size pawSize;

  @override
  State<_AnimatedPaw> createState() => _AnimatedPawState();
}

class _AnimatedPawState extends State<_AnimatedPaw>
    with TickerProviderStateMixin {
  late AnimationController _dropController;
  late AnimationController _scaleController;
  late Animation<double> _dropAnimation;
  late Animation<double> _scaleAnimation;

  /// Get base drop distance based on BPM (per spec).
  double get _baseDropDistance {
    if (widget.bpm < 90) return 12.0;
    if (widget.bpm < 120) return 8.0;
    return 5.0;
  }

  /// Get drop distance with beat-type multiplier.
  /// 강박 has larger movement, 약박 has smaller.
  double get _dropDistance {
    final base = _baseDropDistance;

    // 강박 (1박): 3.0x movement
    if (widget.beatNumber == 1) return base * 3.0;

    // 중간박 (3박 in 4/4): 2.0x movement
    if (widget.beatNumber == 3 && widget.beatCount >= 4) return base * 2.0;

    // 약박: 1.4x movement
    return base * 1.4;
  }

  /// Get scale peak based on beat type (per spec).
  double get _scalePeak {
    // No scale animation for high BPM (per spec: 120+ removes scale)
    if (widget.bpm >= 120) return 1.0;

    // 강박 (1박): scale 1.06
    if (widget.beatNumber == 1) return 1.06;

    // 중간박 (3박 in 4/4): scale 1.03
    if (widget.beatNumber == 3 && widget.beatCount >= 4) return 1.03;

    // 약박: no scale
    return 1.0;
  }

  /// Get opacity based on beat type (per spec).
  double get _beatOpacity {
    if (!widget.isActive) return 0.4;

    // 약박 (2·4박): opacity 85%
    if (widget.beatNumber == 2 || widget.beatNumber == 4) {
      if (widget.accentPattern == AccentPattern.strongMediumWeak) {
        return 0.85;
      }
    }

    return 1.0;
  }

  @override
  void initState() {
    super.initState();

    // Drop animation: reduced from 140ms to 80ms for snappier response
    _dropController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );

    // Scale animation: reduced from 120ms to 60ms for snappier response
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 60),
      vsync: this,
    );

    _setupAnimations();
  }

  void _setupAnimations() {
    // Drop animation with spec easing
    _dropAnimation = Tween<double>(
      begin: -_dropDistance,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _dropController,
      curve: _dropCurve,
    ));

    // Scale animation: 1.0 → peak → 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: _scalePeak),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: _scalePeak, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(_AnimatedPaw oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation when this beat becomes current
    if (widget.isCurrentBeat && !oldWidget.isCurrentBeat) {
      _triggerAnimation();
    }

    // Update animations if BPM changed
    if (widget.bpm != oldWidget.bpm) {
      _setupAnimations();
    }
  }

  void _triggerAnimation() {
    // Reset and play drop animation
    _dropController.forward(from: 0);

    // Play scale animation if applicable
    if (_scalePeak > 1.0) {
      _scaleController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _dropController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_dropController, _scaleController]),
      builder: (context, child) {
        // Only apply animation offset when animation is running
        // Use 0.0 as stable position to prevent position jumping on screen open
        final dropOffset = _dropController.isAnimating ? _dropAnimation.value : 0.0;
        final scale = _scaleController.isAnimating ? _scaleAnimation.value : 1.0;

        return Transform.translate(
          offset: Offset(0, dropOffset),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: widget.pawSize,
              painter: _PawPainter(
                opacity: _beatOpacity,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paw shape painter (fill only, no stroke per spec).
class _PawPainter extends CustomPainter {
  _PawPainter({
    required this.opacity,
  });

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final pawPaint = Paint()
      ..color = _pawColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Scale factor to fit paw in given size (SVG viewBox is 24x24)
    final scale = size.width / 24.0;

    // Draw 3 small circles (jelly pads)
    canvas.drawCircle(
      Offset(7.6 * scale, 8.3 * scale),
      1.65 * scale,
      pawPaint,
    );
    canvas.drawCircle(
      Offset(12.0 * scale, 7.3 * scale),
      1.75 * scale,
      pawPaint,
    );
    canvas.drawCircle(
      Offset(16.4 * scale, 8.3 * scale),
      1.65 * scale,
      pawPaint,
    );

    // Draw main pad (bean shape)
    final mainPadPath = Path();
    mainPadPath.addOval(
      Rect.fromCenter(
        center: Offset(12.0 * scale, 14.5 * scale),
        width: 10.5 * scale,
        height: 7.5 * scale,
      ),
    );
    canvas.drawPath(mainPadPath, pawPaint);
  }

  @override
  bool shouldRepaint(covariant _PawPainter oldDelegate) {
    return opacity != oldDelegate.opacity;
  }
}

/// Cat face painter (separated from paws for animation).
class _CatFacePainter extends CustomPainter {
  _CatFacePainter({
    required this.eyesOpen,
    required this.faceColor,
    required this.featureColor,
  });

  final bool eyesOpen;
  final Color faceColor;
  final Color featureColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final radius = size.height * 0.4;

    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;

    final featurePaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Face circle
    canvas.drawCircle(center, radius, facePaint);

    // Ears
    _drawEars(canvas, center, radius, facePaint, linePaint);

    // Eyes
    final eyeY = center.dy - radius * 0.1;
    final eyeRadius = radius * 0.22;
    final leftEyeX = center.dx - radius * 0.38;
    final rightEyeX = center.dx + radius * 0.38;

    if (eyesOpen) {
      canvas.drawCircle(Offset(leftEyeX, eyeY), eyeRadius, featurePaint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), eyeRadius, featurePaint);
    } else {
      _drawSmilingEye(canvas, Offset(leftEyeX, eyeY), eyeRadius, linePaint);
      _drawSmilingEye(canvas, Offset(rightEyeX, eyeY), eyeRadius, linePaint);
    }

    // Nose
    final nosePath = Path();
    nosePath.moveTo(center.dx, center.dy + radius * 0.15);
    nosePath.lineTo(center.dx - radius * 0.1, center.dy + radius * 0.28);
    nosePath.lineTo(center.dx + radius * 0.1, center.dy + radius * 0.28);
    nosePath.close();
    canvas.drawPath(nosePath, featurePaint);

    // Mouth
    final mouthPath = Path();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.28);
    mouthPath.lineTo(center.dx, center.dy + radius * 0.4);
    canvas.drawPath(mouthPath, linePaint);

    mouthPath.reset();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.4);
    mouthPath.quadraticBezierTo(center.dx - radius * 0.15,
        center.dy + radius * 0.5, center.dx - radius * 0.22, center.dy + radius * 0.4);
    canvas.drawPath(mouthPath, linePaint);

    mouthPath.reset();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.4);
    mouthPath.quadraticBezierTo(center.dx + radius * 0.15,
        center.dy + radius * 0.5, center.dx + radius * 0.22, center.dy + radius * 0.4);
    canvas.drawPath(mouthPath, linePaint);

    // Whiskers
    _drawWhiskers(canvas, center, radius, linePaint);
  }

  void _drawEars(Canvas canvas, Offset center, double radius, Paint facePaint,
      Paint linePaint) {
    final earPath = Path();
    earPath.moveTo(center.dx - radius * 0.7, center.dy - radius * 0.5);
    earPath.lineTo(center.dx - radius * 0.9, center.dy - radius * 1.1);
    earPath.lineTo(center.dx - radius * 0.3, center.dy - radius * 0.7);
    earPath.close();
    earPath.moveTo(center.dx + radius * 0.7, center.dy - radius * 0.5);
    earPath.lineTo(center.dx + radius * 0.9, center.dy - radius * 1.1);
    earPath.lineTo(center.dx + radius * 0.3, center.dy - radius * 0.7);
    earPath.close();
    canvas.drawPath(earPath, facePaint);
    canvas.drawPath(earPath, linePaint);
  }

  void _drawSmilingEye(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx - radius, center.dy);
    path.quadraticBezierTo(
        center.dx, center.dy - radius * 0.8, center.dx + radius, center.dy);
    canvas.drawPath(path, paint);
  }

  void _drawWhiskers(Canvas canvas, Offset center, double radius, Paint paint) {
    final whiskerPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - radius * 0.35, center.dy + radius * 0.35),
      Offset(center.dx - radius * 0.85, center.dy + radius * 0.25),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.35, center.dy + radius * 0.4),
      Offset(center.dx - radius * 0.85, center.dy + radius * 0.45),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.35, center.dy + radius * 0.35),
      Offset(center.dx + radius * 0.85, center.dy + radius * 0.25),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.35, center.dy + radius * 0.4),
      Offset(center.dx + radius * 0.85, center.dy + radius * 0.45),
      whiskerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CatFacePainter oldDelegate) {
    return eyesOpen != oldDelegate.eyesOpen;
  }
}

/// Compact cat face painter for controller bar.
class _CompactCatPainter extends CustomPainter {
  _CompactCatPainter({
    required this.eyesOpen,
    required this.currentBeat,
    required this.faceColor,
    required this.featureColor,
  });

  final bool eyesOpen;
  final int currentBeat;
  final Color faceColor;
  final Color featureColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;

    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;

    final featurePaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, facePaint);
    _drawEars(canvas, center, radius, facePaint, linePaint);

    final eyeY = center.dy - radius * 0.1;
    final eyeRadius = radius * 0.2;
    final leftEyeX = center.dx - radius * 0.35;
    final rightEyeX = center.dx + radius * 0.35;

    if (eyesOpen) {
      canvas.drawCircle(Offset(leftEyeX, eyeY), eyeRadius, featurePaint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), eyeRadius, featurePaint);
    } else {
      _drawSmilingEye(canvas, Offset(leftEyeX, eyeY), eyeRadius, linePaint);
      _drawSmilingEye(canvas, Offset(rightEyeX, eyeY), eyeRadius, linePaint);
    }

    _drawNose(canvas, center, radius, featurePaint);
    _drawMouth(canvas, center, radius, linePaint);
  }

  void _drawEars(Canvas canvas, Offset center, double radius, Paint facePaint,
      Paint linePaint) {
    final earPath = Path();
    earPath.moveTo(center.dx - radius * 0.7, center.dy - radius * 0.5);
    earPath.lineTo(center.dx - radius * 0.9, center.dy - radius * 1.1);
    earPath.lineTo(center.dx - radius * 0.3, center.dy - radius * 0.7);
    earPath.close();
    earPath.moveTo(center.dx + radius * 0.7, center.dy - radius * 0.5);
    earPath.lineTo(center.dx + radius * 0.9, center.dy - radius * 1.1);
    earPath.lineTo(center.dx + radius * 0.3, center.dy - radius * 0.7);
    earPath.close();
    canvas.drawPath(earPath, facePaint);
    canvas.drawPath(earPath, linePaint);
  }

  void _drawSmilingEye(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx - radius, center.dy);
    path.quadraticBezierTo(
        center.dx, center.dy - radius * 0.8, center.dx + radius, center.dy);
    canvas.drawPath(path, paint);
  }

  void _drawNose(Canvas canvas, Offset center, double radius, Paint featurePaint) {
    final nosePath = Path();
    nosePath.moveTo(center.dx, center.dy + radius * 0.1);
    nosePath.lineTo(center.dx - radius * 0.1, center.dy + radius * 0.25);
    nosePath.lineTo(center.dx + radius * 0.1, center.dy + radius * 0.25);
    nosePath.close();
    canvas.drawPath(nosePath, featurePaint);
  }

  void _drawMouth(Canvas canvas, Offset center, double radius, Paint linePaint) {
    final mouthPath = Path();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.25);
    mouthPath.lineTo(center.dx, center.dy + radius * 0.35);
    canvas.drawPath(mouthPath, linePaint);

    mouthPath.reset();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.35);
    mouthPath.quadraticBezierTo(center.dx - radius * 0.15,
        center.dy + radius * 0.45, center.dx - radius * 0.2, center.dy + radius * 0.35);
    canvas.drawPath(mouthPath, linePaint);

    mouthPath.reset();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.35);
    mouthPath.quadraticBezierTo(center.dx + radius * 0.15,
        center.dy + radius * 0.45, center.dx + radius * 0.2, center.dy + radius * 0.35);
    canvas.drawPath(mouthPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _CompactCatPainter oldDelegate) {
    return eyesOpen != oldDelegate.eyesOpen ||
        currentBeat != oldDelegate.currentBeat;
  }
}

/// Compact cat with pulse animation on each beat.
class _CompactCatWithPulse extends StatefulWidget {
  const _CompactCatWithPulse({
    required this.size,
    required this.eyesOpen,
    required this.currentBeat,
    required this.isPlaying,
  });

  final double size;
  final bool eyesOpen;
  final int currentBeat;
  final bool isPlaying;

  @override
  State<_CompactCatWithPulse> createState() => _CompactCatWithPulseState();
}

class _CompactCatWithPulseState extends State<_CompactCatWithPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Reduced from 100ms to 60ms for snappier response
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 60),
      vsync: this,
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(_CompactCatWithPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger pulse on each beat change
    if (widget.currentBeat != oldWidget.currentBeat && widget.currentBeat > 0) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = _pulseController.isAnimating ? _pulseAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _CompactCatPainter(
                eyesOpen: widget.eyesOpen,
                currentBeat: widget.currentBeat,
                faceColor: AppColors.primary.withValues(alpha: 0.2),
                featureColor: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
