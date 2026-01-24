import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/tuner_types.dart';
import '../../providers/tuner_combo_provider.dart';
import 'tuner_cat_particle.dart';

/// Painter for rotating spiral/screw starburst effect.
/// Color progression:
/// Curtain effect with quadrant-based pattern
/// Each quadrant: T25%, W45%, Y30% (40 beams per quadrant, 160 total)
/// Phase 1 (0-0.3): Pattern with transparent
/// Phase 2 (0.3-0.6): Transparent disappears, white + yellow
/// Phase 3 (0.6-0.9): White becomes yellow
/// Phase 4: All yellow (stays while pitch accurate), fade out when inaccurate
class StarburstPainter extends CustomPainter {
  StarburstPainter({
    this.progress = 0.0,
    this.colorProgress = 0.0,
    this.rotation = 0.0,
    this.fadeOut = 0.0,
  });

  // 32 beams total: 8 per quadrant × 4 quadrants (80% reduction)
  // Per quadrant: T=2 (25%), W=4 (50%), Y=2 (25%)
  static const int beamCount = 32;
  static const int beamsPerQuadrant = 8;

  final double progress; // Size growth progress
  final double colorProgress; // Color transition progress (0-0.9, stays at yellow)
  final double rotation; // Rotation angle in radians
  final double fadeOut; // Fade out progress when pitch becomes inaccurate (0-1)

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Radius grows from 10% to 100% based on progress
    final maxRadius = size.width / 2;
    final radius = maxRadius * (0.1 + progress * 0.9);

    // Only fade out when pitch becomes inaccurate
    final overallOpacity = (1.0 - fadeOut).clamp(0.0, 1.0);

    // Per quadrant pattern: T=2 (0-1), W=4 (2-5), Y=2 (6-7)
    // T25%, W50%, Y25% of 8 beams
    Color getPatternColor(int index, double opacity) {
      final i = index % beamsPerQuadrant;
      if (i < 2) {
        return Colors.transparent; // T: 0-1 (2 beams = 25%)
      } else if (i < 6) {
        return Colors.white.withValues(alpha: opacity); // W: 2-5 (4 beams = 50%)
      } else {
        return Colors.yellow.withValues(alpha: opacity); // Y: 6-7 (2 beams = 25%)
      }
    }

    bool isTransparentPosition(int index) => (index % beamsPerQuadrant) < 2;
    bool isWhitePosition(int index) {
      final i = index % beamsPerQuadrant;
      return i >= 2 && i < 6;
    }

    List<Color> colors;

    if (colorProgress < 0.33) {
      // Phase 1 (0-2.7s): Initial pattern T25%, W50%, Y25% per quadrant
      colors = List.generate(beamCount, (i) => getPatternColor(i, overallOpacity));
    } else if (colorProgress < 0.67) {
      // Phase 2 (2.7-5.3s): Transparent disappears, filled with white/yellow
      final t = ((colorProgress - 0.33) / 0.34).clamp(0.0, 1.0);
      colors = List.generate(beamCount, (i) {
        if (isTransparentPosition(i)) {
          // Transparent becomes yellow gradually
          return Colors.yellow.withValues(alpha: overallOpacity * t);
        } else if (isWhitePosition(i)) {
          return Colors.white.withValues(alpha: overallOpacity);
        } else {
          return Colors.yellow.withValues(alpha: overallOpacity);
        }
      });
    } else {
      // Phase 3 (5.3-8s): White becomes yellow - all fills with yellow
      final t = ((colorProgress - 0.67) / 0.33).clamp(0.0, 1.0);
      colors = List.generate(beamCount, (i) {
        if (isWhitePosition(i)) {
          // Blend from white to yellow
          return Color.lerp(Colors.white, Colors.yellow, t)!.withValues(alpha: overallOpacity);
        } else {
          return Colors.yellow.withValues(alpha: overallOpacity);
        }
      });
    }

    // When nearly all yellow (8s+), draw a solid filled circle
    if (colorProgress >= 0.98) {
      final paint = Paint()
        ..color = Colors.yellow.withValues(alpha: overallOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final anglePerBeam = math.pi * 2 / beamCount;

    // Beam width increases as we approach all yellow (0.85 -> 1.0)
    final beamWidthRatio = 0.85 + (colorProgress * 0.15);

    for (var i = 0; i < beamCount; i++) {
      final baseAngle = i * anglePerBeam + rotation;
      final color = colors[i % colors.length];

      // Skip transparent beams
      if (color == Colors.transparent || color.a < 0.01) continue;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Draw straight triangular beam (width increases over time)
      final path = Path();
      path.moveTo(center.dx, center.dy);

      final angle1 = baseAngle;
      final angle2 = baseAngle + anglePerBeam * beamWidthRatio;

      path.lineTo(
        center.dx + math.cos(angle1) * radius,
        center.dy + math.sin(angle1) * radius,
      );
      path.lineTo(
        center.dx + math.cos(angle2) * radius,
        center.dy + math.sin(angle2) * radius,
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarburstPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colorProgress != colorProgress ||
      oldDelegate.rotation != rotation ||
      oldDelegate.fadeOut != fadeOut;
}

/// Painter for heart particles.
class HeartParticlePainter extends CustomPainter {
  HeartParticlePainter({required this.particles});

  final List<HeartParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    // Light purple color like cat face
    final baseColor = AppColors.primary.withValues(alpha: 0.3);

    for (final particle in particles) {
      final opacity = particle.opacity * 0.8; // Max 80% opacity
      if (opacity <= 0.01) continue;

      final paint = Paint()
        ..color = baseColor.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.fill;

      final pos = particle.position;
      final particleSize = particle.size;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(particle.rotation);

      // Draw heart shape
      _drawHeart(canvas, particleSize, paint);

      canvas.restore();
    }
  }

  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final s = size / 2;

    // Heart shape using bezier curves - centered
    path.moveTo(0, s * 0.3);

    // Left half
    path.cubicTo(
      -s * 0.8, -s * 0.5,
      -s * 0.8, s * 0.3,
      0, s,
    );

    // Right half
    path.moveTo(0, s * 0.3);
    path.cubicTo(
      s * 0.8, -s * 0.5,
      s * 0.8, s * 0.3,
      0, s,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeartParticlePainter oldDelegate) => true;
}

/// Cat face painter matching metronome style.
class CatFacePainter extends CustomPainter {
  CatFacePainter({
    required this.status,
    required this.isPerfect,
    required this.comboTier,
    this.isEcstatic = false,
  });

  final TuningStatus status;
  final bool isPerfect;
  final ComboTier comboTier;
  final bool isEcstatic;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final radius = size.height * 0.4;

    // Use metronome style colors
    // Light purple opaque color (same visual as 0.2 alpha on white background)
    final faceColor = Color.lerp(Colors.white, AppColors.primary, 0.2)!;
    final featureColor = AppColors.primary;

    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final featurePaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.fill;

    // Face circle
    canvas.drawCircle(center, radius, facePaint);

    // Ears (metronome style with outline)
    _drawEars(canvas, center, radius, facePaint, linePaint);

    // Eyes based on status
    final eyeY = center.dy - radius * 0.1;
    final eyeRadius = radius * 0.22;
    final leftEyeX = center.dx - radius * 0.38;
    final rightEyeX = center.dx + radius * 0.38;

    final shouldCloseEyes = isPerfect || status == TuningStatus.tuned;

    if (isEcstatic) {
      // Ecstatic expression: extra happy curved eyes with sparkle
      _drawEcstaticEye(canvas, Offset(leftEyeX, eyeY), eyeRadius, linePaint);
      _drawEcstaticEye(canvas, Offset(rightEyeX, eyeY), eyeRadius, linePaint);
      // Draw blush marks on cheeks
      _drawBlush(canvas, center, radius);
    } else if (shouldCloseEyes) {
      _drawSmilingEye(canvas, Offset(leftEyeX, eyeY), eyeRadius, linePaint);
      _drawSmilingEye(canvas, Offset(rightEyeX, eyeY), eyeRadius, linePaint);
    } else {
      canvas.drawCircle(Offset(leftEyeX, eyeY), eyeRadius, featurePaint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), eyeRadius, featurePaint);
    }

    // Nose (metronome style triangle)
    final nosePath = Path();
    nosePath.moveTo(center.dx, center.dy + radius * 0.15);
    nosePath.lineTo(center.dx - radius * 0.1, center.dy + radius * 0.28);
    nosePath.lineTo(center.dx + radius * 0.1, center.dy + radius * 0.28);
    nosePath.close();
    canvas.drawPath(nosePath, featurePaint);

    // Mouth (metronome style ω shape)
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

    // Whiskers (metronome style)
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

  void _drawEcstaticEye(Canvas canvas, Offset center, double radius, Paint paint) {
    // Ecstatic eyes: wave-like shape (~~) for dreamy/ecstatic look
    final wavePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final waveHeight = radius * 0.5;
    final startX = center.dx - radius;
    final endX = center.dx + radius;
    final midX1 = center.dx - radius * 0.5;
    final midX2 = center.dx + radius * 0.5;

    // Wave shape: up-down-up pattern
    path.moveTo(startX, center.dy);
    path.quadraticBezierTo(
        midX1 - radius * 0.25, center.dy - waveHeight, midX1, center.dy);
    path.quadraticBezierTo(
        center.dx, center.dy + waveHeight * 0.6, midX2, center.dy);
    path.quadraticBezierTo(
        midX2 + radius * 0.25, center.dy - waveHeight, endX, center.dy);

    canvas.drawPath(path, wavePaint);
  }

  void _drawBlush(Canvas canvas, Offset center, double radius) {
    // Pink blush circles on both cheeks
    final blushPaint = Paint()
      ..color = Colors.pink.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Left cheek blush
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.55, center.dy + radius * 0.25),
        width: radius * 0.35,
        height: radius * 0.22,
      ),
      blushPaint,
    );

    // Right cheek blush
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.55, center.dy + radius * 0.25),
        width: radius * 0.35,
        height: radius * 0.22,
      ),
      blushPaint,
    );
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
  bool shouldRepaint(covariant CatFacePainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.isPerfect != isPerfect ||
        oldDelegate.comboTier != comboTier ||
        oldDelegate.isEcstatic != isEcstatic;
  }
}
