import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/tuner_types.dart';
import '../../providers/tuner_combo_provider.dart';
import '../../providers/tuner_provider.dart';

/// Cat indicator for tuner with expressions and speech bubbles.
class TunerCatIndicator extends ConsumerStatefulWidget {
  const TunerCatIndicator({
    super.key,
    this.size = 120,
  });

  final double size;

  @override
  ConsumerState<TunerCatIndicator> createState() => _TunerCatIndicatorState();
}

class _TunerCatIndicatorState extends ConsumerState<TunerCatIndicator>
    with TickerProviderStateMixin {
  late AnimationController _jumpController;
  late AnimationController _pulseController;
  late Animation<double> _jumpAnimation;
  late Animation<double> _pulseAnimation;

  ComboTier _lastTier = ComboTier.none;

  @override
  void initState() {
    super.initState();

    _jumpController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _jumpAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _jumpController, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _jumpController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onComboChanged(ComboState comboState) {
    final newTier = comboState.tier;
    final judgement = comboState.lastJudgement;

    // Trigger jump animation on Perfect with combo milestone
    if (judgement == JudgementResult.perfect && newTier != _lastTier) {
      _jumpController.forward().then((_) => _jumpController.reverse());
    }

    _lastTier = newTier;
  }

  @override
  Widget build(BuildContext context) {
    final tunerState = ref.watch(tunerProvider);
    final comboState = ref.watch(tunerComboProvider);

    // Listen for combo changes
    ref.listen(tunerComboProvider, (_, next) => _onComboChanged(next));

    final status = tunerState.status;
    final isPerfect = tunerState.isPerfect;
    final tier = comboState.tier;

    // Calculate sizes based on widget.size
    final catSize = widget.size * 0.6; // Cat takes 60% of space
    final showExtras = widget.size >= 100; // Only show extras if enough space

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cat face with animations
          AnimatedBuilder(
            animation: Listenable.merge([_jumpAnimation, _pulseAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _jumpAnimation.value),
                child: Transform.scale(
                  scale: isPerfect ? _pulseAnimation.value : 1.0,
                  child: child,
                ),
              );
            },
            child: _CatFace(
              size: catSize,
              status: status,
              isPerfect: isPerfect,
              comboTier: tier,
            ),
          ),

          // Cent display - only if enough space
          if (tunerState.currentNote != null && showExtras) ...[
            const SizedBox(height: 4),
            _CentDisplay(
              centDeviation: tunerState.centDeviation,
              isPerfect: isPerfect,
            ),
          ],
        ],
      ),
    );
  }
}

/// Cat face with expression based on tuning status.
class _CatFace extends StatelessWidget {
  const _CatFace({
    required this.size,
    required this.status,
    required this.isPerfect,
    required this.comboTier,
  });

  final double size;
  final TuningStatus status;
  final bool isPerfect;
  final ComboTier comboTier;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CatFacePainter(
        status: status,
        isPerfect: isPerfect,
        comboTier: comboTier,
      ),
    );
  }
}

class _CatFacePainter extends CustomPainter {
  _CatFacePainter({
    required this.status,
    required this.isPerfect,
    required this.comboTier,
  });

  final TuningStatus status;
  final bool isPerfect;
  final ComboTier comboTier;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final faceRadius = size.width * 0.4;

    // Face color based on status
    final faceColor = _getFaceColor();
    final featureColor = Colors.grey[800]!;

    // Draw face
    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, faceRadius, facePaint);

    // Draw ears
    _drawEars(canvas, center, faceRadius, faceColor, featureColor);

    // Draw eyes based on expression
    _drawEyes(canvas, center, faceRadius, featureColor);

    // Draw nose
    _drawNose(canvas, center, faceRadius, featureColor);

    // Draw mouth based on expression
    _drawMouth(canvas, center, faceRadius, featureColor);

    // Draw whiskers
    _drawWhiskers(canvas, center, faceRadius, featureColor);
  }

  Color _getFaceColor() {
    if (isPerfect) return AppColors.catAccent;
    return switch (status) {
      TuningStatus.idle => Colors.grey[300]!,
      TuningStatus.listening => AppColors.catAccent.withValues(alpha: 0.7),
      TuningStatus.tuned => AppColors.catAccent,
      TuningStatus.flat => Colors.orange[200]!,
      TuningStatus.sharp => Colors.orange[200]!,
    };
  }

  void _drawEars(Canvas canvas, Offset center, double radius, Color faceColor,
      Color featureColor) {
    final earPaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;

    final innerEarPaint = Paint()
      ..color = Colors.pink[100]!
      ..style = PaintingStyle.fill;

    // Left ear
    final leftEarPath = Path()
      ..moveTo(center.dx - radius * 0.7, center.dy - radius * 0.3)
      ..lineTo(center.dx - radius * 0.9, center.dy - radius * 1.1)
      ..lineTo(center.dx - radius * 0.3, center.dy - radius * 0.7)
      ..close();

    canvas.drawPath(leftEarPath, earPaint);

    // Right ear
    final rightEarPath = Path()
      ..moveTo(center.dx + radius * 0.7, center.dy - radius * 0.3)
      ..lineTo(center.dx + radius * 0.9, center.dy - radius * 1.1)
      ..lineTo(center.dx + radius * 0.3, center.dy - radius * 0.7)
      ..close();

    canvas.drawPath(rightEarPath, earPaint);

    // Inner ears
    final leftInnerPath = Path()
      ..moveTo(center.dx - radius * 0.6, center.dy - radius * 0.4)
      ..lineTo(center.dx - radius * 0.75, center.dy - radius * 0.9)
      ..lineTo(center.dx - radius * 0.4, center.dy - radius * 0.6)
      ..close();

    canvas.drawPath(leftInnerPath, innerEarPaint);

    final rightInnerPath = Path()
      ..moveTo(center.dx + radius * 0.6, center.dy - radius * 0.4)
      ..lineTo(center.dx + radius * 0.75, center.dy - radius * 0.9)
      ..lineTo(center.dx + radius * 0.4, center.dy - radius * 0.6)
      ..close();

    canvas.drawPath(rightInnerPath, innerEarPaint);
  }

  void _drawEyes(Canvas canvas, Offset center, double radius, Color color) {
    final eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final eyeOffsetX = radius * 0.35;
    final eyeOffsetY = radius * 0.1;
    final eyeRadius = radius * 0.12;

    // Expression-based eyes
    if (isPerfect || status == TuningStatus.tuned) {
      // Happy closed eyes (^_^)
      _drawHappyEye(canvas, Offset(center.dx - eyeOffsetX, center.dy - eyeOffsetY),
          eyeRadius, color);
      _drawHappyEye(canvas, Offset(center.dx + eyeOffsetX, center.dy - eyeOffsetY),
          eyeRadius, color);
    } else if (status == TuningStatus.flat) {
      // Sad eyes (looking down)
      canvas.drawCircle(
          Offset(center.dx - eyeOffsetX, center.dy - eyeOffsetY + 3),
          eyeRadius,
          eyePaint);
      canvas.drawCircle(
          Offset(center.dx + eyeOffsetX, center.dy - eyeOffsetY + 3),
          eyeRadius,
          eyePaint);
    } else if (status == TuningStatus.sharp) {
      // Surprised eyes (wide)
      canvas.drawCircle(
          Offset(center.dx - eyeOffsetX, center.dy - eyeOffsetY),
          eyeRadius * 1.3,
          eyePaint);
      canvas.drawCircle(
          Offset(center.dx + eyeOffsetX, center.dy - eyeOffsetY),
          eyeRadius * 1.3,
          eyePaint);
    } else {
      // Normal eyes
      canvas.drawCircle(
          Offset(center.dx - eyeOffsetX, center.dy - eyeOffsetY),
          eyeRadius,
          eyePaint);
      canvas.drawCircle(
          Offset(center.dx + eyeOffsetX, center.dy - eyeOffsetY),
          eyeRadius,
          eyePaint);
    }
  }

  void _drawHappyEye(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy - radius * 1.5,
          center.dx + radius, center.dy);

    canvas.drawPath(path, paint);
  }

  void _drawNose(Canvas canvas, Offset center, double radius, Color color) {
    final nosePaint = Paint()
      ..color = Colors.pink[300]!
      ..style = PaintingStyle.fill;

    final noseCenter = Offset(center.dx, center.dy + radius * 0.15);
    final noseSize = radius * 0.12;

    final nosePath = Path()
      ..moveTo(noseCenter.dx, noseCenter.dy - noseSize)
      ..lineTo(noseCenter.dx - noseSize, noseCenter.dy + noseSize * 0.5)
      ..lineTo(noseCenter.dx + noseSize, noseCenter.dy + noseSize * 0.5)
      ..close();

    canvas.drawPath(nosePath, nosePaint);
  }

  void _drawMouth(Canvas canvas, Offset center, double radius, Color color) {
    final mouthPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final mouthY = center.dy + radius * 0.35;

    if (isPerfect || status == TuningStatus.tuned) {
      // Big smile
      final path = Path()
        ..moveTo(center.dx - radius * 0.25, mouthY)
        ..quadraticBezierTo(center.dx, mouthY + radius * 0.2,
            center.dx + radius * 0.25, mouthY);
      canvas.drawPath(path, mouthPaint);
    } else if (status == TuningStatus.flat) {
      // Slight frown
      final path = Path()
        ..moveTo(center.dx - radius * 0.15, mouthY + radius * 0.1)
        ..quadraticBezierTo(center.dx, mouthY - radius * 0.05,
            center.dx + radius * 0.15, mouthY + radius * 0.1);
      canvas.drawPath(path, mouthPaint);
    } else {
      // Neutral "w" mouth
      final path = Path()
        ..moveTo(center.dx - radius * 0.15, mouthY)
        ..lineTo(center.dx - radius * 0.05, mouthY + radius * 0.08)
        ..lineTo(center.dx, mouthY)
        ..lineTo(center.dx + radius * 0.05, mouthY + radius * 0.08)
        ..lineTo(center.dx + radius * 0.15, mouthY);
      canvas.drawPath(path, mouthPaint);
    }
  }

  void _drawWhiskers(Canvas canvas, Offset center, double radius, Color color) {
    final whiskerPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final whiskerStartY = center.dy + radius * 0.2;
    final whiskerLength = radius * 0.5;

    // Left whiskers
    for (var i = 0; i < 3; i++) {
      final angle = -0.2 + (i * 0.2);
      canvas.drawLine(
        Offset(center.dx - radius * 0.3, whiskerStartY + (i - 1) * 5),
        Offset(center.dx - radius * 0.3 - whiskerLength * math.cos(angle),
            whiskerStartY + (i - 1) * 5 - whiskerLength * math.sin(angle)),
        whiskerPaint,
      );
    }

    // Right whiskers
    for (var i = 0; i < 3; i++) {
      final angle = 0.2 - (i * 0.2);
      canvas.drawLine(
        Offset(center.dx + radius * 0.3, whiskerStartY + (i - 1) * 5),
        Offset(center.dx + radius * 0.3 + whiskerLength * math.cos(angle),
            whiskerStartY + (i - 1) * 5 - whiskerLength * math.sin(angle)),
        whiskerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CatFacePainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.isPerfect != isPerfect ||
        oldDelegate.comboTier != comboTier;
  }
}

/// Speech bubble for cat feedback.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    required this.judgement,
    required this.comboTier,
  });

  final JudgementResult judgement;
  final ComboTier comboTier;

  @override
  Widget build(BuildContext context) {
    // Use combo message if available, otherwise judgement message
    final message =
        comboTier != ComboTier.none ? comboTier.message : judgement.message;

    final color = switch (judgement) {
      JudgementResult.perfect => Colors.green[100],
      JudgementResult.good => Colors.yellow[100],
      JudgementResult.miss => Colors.grey[200],
    };

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Cent deviation display.
class _CentDisplay extends StatelessWidget {
  const _CentDisplay({
    required this.centDeviation,
    required this.isPerfect,
  });

  final double centDeviation;
  final bool isPerfect;

  @override
  Widget build(BuildContext context) {
    final color = isPerfect
        ? Colors.green
        : (centDeviation < 0 ? Colors.red : Colors.orange);

    final arrow = centDeviation > 3
        ? '↓'
        : (centDeviation < -3 ? '↑' : '');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (arrow.isNotEmpty)
          Text(
            arrow,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        Text(
          '${centDeviation >= 0 ? '+' : ''}${centDeviation.toStringAsFixed(1)}¢',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Combo counter display.
class _ComboCounter extends StatelessWidget {
  const _ComboCounter({
    required this.count,
    required this.tier,
  });

  final int count;
  final ComboTier tier;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars based on tier
        for (var i = 0; i < tier.stars; i++)
          Icon(
            Icons.star,
            size: 16,
            color: tier.isGolden ? Colors.amber : Colors.yellow[700],
          ),

        const SizedBox(width: 4),

        Text(
          'COMBO $count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: tier.isGolden ? Colors.amber[800] : AppColors.primary,
          ),
        ),
      ],
    );
  }
}
