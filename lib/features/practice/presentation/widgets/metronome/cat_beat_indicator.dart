import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../models/metronome_settings.dart';

/// Cat eye blinking animation for metronome beats.
///
/// Visual patterns by time signature:
/// - 2/4: One cat (2 eyes)
/// - 3/4: Two cats (4 eyes)
/// - 4/4: Two cats (4 eyes)
/// - 6/8: Three cats (6 eyes)
class CatBeatIndicator extends StatelessWidget {
  const CatBeatIndicator({
    super.key,
    required this.currentBeat,
    required this.timeSignature,
    required this.isPlaying,
    this.size = 80.0,
    this.compact = false,
  });

  final int currentBeat;
  final TimeSignature timeSignature;
  final bool isPlaying;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactIndicator();
    }

    return switch (timeSignature) {
      TimeSignature.twoFour => _buildOneCat2_4(),
      TimeSignature.threeFour => _buildTwoCats3_4(),
      TimeSignature.fourFour => _buildTwoCats4_4(),
      TimeSignature.sixEight => _buildThreeCats6_8(),
    };
  }

  /// Compact indicator for controller bar (single small cat).
  /// Both eyes blink together (close on odd beats, open on even beats).
  Widget _buildCompactIndicator() {
    final bothClosed = isPlaying && currentBeat % 2 == 1;

    return _CatFace(
      size: size,
      leftEyeClosed: bothClosed,
      rightEyeClosed: bothClosed,
    );
  }

  /// 2/4: One cat with 2 eyes (blink together)
  /// Beat 1: Both eyes closed
  /// Beat 2: Both eyes open
  Widget _buildOneCat2_4() {
    final bothClosed = isPlaying && currentBeat == 1;

    return _CatFace(
      size: size * 1.2,
      leftEyeClosed: bothClosed,
      rightEyeClosed: bothClosed,
    );
  }

  /// 3/4: Two cats with 4 eyes (cumulative)
  /// Beat 1: 1st eye closed
  /// Beat 2: 1st+2nd eyes closed
  /// Beat 3: 1st+2nd+3rd eyes closed, then reset on new measure
  Widget _buildTwoCats3_4() {
    final leftCatLeft = isPlaying && currentBeat >= 1;
    final leftCatRight = isPlaying && currentBeat >= 2;
    final rightCatLeft = isPlaying && currentBeat >= 3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CatFace(
          size: size,
          leftEyeClosed: leftCatLeft,
          rightEyeClosed: leftCatRight,
        ),
        SizedBox(width: size * 0.3),
        _CatFace(
          size: size,
          leftEyeClosed: rightCatLeft,
          rightEyeClosed: false,
        ),
      ],
    );
  }

  /// 4/4: Two cats with 4 eyes (cumulative)
  /// Beat 1: 1st eye closed
  /// Beat 2: 1st+2nd eyes closed
  /// Beat 3: 1st+2nd+3rd eyes closed
  /// Beat 4: All 4 eyes closed, then reset on new measure
  Widget _buildTwoCats4_4() {
    final leftCatLeft = isPlaying && currentBeat >= 1;
    final leftCatRight = isPlaying && currentBeat >= 2;
    final rightCatLeft = isPlaying && currentBeat >= 3;
    final rightCatRight = isPlaying && currentBeat >= 4;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CatFace(
          size: size,
          leftEyeClosed: leftCatLeft,
          rightEyeClosed: leftCatRight,
        ),
        SizedBox(width: size * 0.3),
        _CatFace(
          size: size,
          leftEyeClosed: rightCatLeft,
          rightEyeClosed: rightCatRight,
        ),
      ],
    );
  }

  /// 6/8: Three cats with 6 eyes (cumulative)
  /// Beats 1-6: Eyes close progressively
  /// New measure: All reset, then start again
  Widget _buildThreeCats6_8() {
    final leftCatLeft = isPlaying && currentBeat >= 1;
    final leftCatRight = isPlaying && currentBeat >= 2;
    final midCatLeft = isPlaying && currentBeat >= 3;
    final midCatRight = isPlaying && currentBeat >= 4;
    final rightCatLeft = isPlaying && currentBeat >= 5;
    final rightCatRight = isPlaying && currentBeat >= 6;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CatFace(
          size: size * 0.9,
          leftEyeClosed: leftCatLeft,
          rightEyeClosed: leftCatRight,
        ),
        SizedBox(width: size * 0.2),
        _CatFace(
          size: size * 0.9,
          leftEyeClosed: midCatLeft,
          rightEyeClosed: midCatRight,
        ),
        SizedBox(width: size * 0.2),
        _CatFace(
          size: size * 0.9,
          leftEyeClosed: rightCatLeft,
          rightEyeClosed: rightCatRight,
        ),
      ],
    );
  }
}

/// Single cat face with controllable eye states.
class _CatFace extends StatelessWidget {
  const _CatFace({
    required this.size,
    required this.leftEyeClosed,
    required this.rightEyeClosed,
  });

  final double size;
  final bool leftEyeClosed;
  final bool rightEyeClosed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CatFacePainter(
          leftEyeClosed: leftEyeClosed,
          rightEyeClosed: rightEyeClosed,
          faceColor: AppColors.primary.withValues(alpha: 0.2),
          featureColor: AppColors.primary,
        ),
      ),
    );
  }
}

/// Custom painter for cat face.
class _CatFacePainter extends CustomPainter {
  _CatFacePainter({
    required this.leftEyeClosed,
    required this.rightEyeClosed,
    required this.faceColor,
    required this.featureColor,
  });

  final bool leftEyeClosed;
  final bool rightEyeClosed;
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

    // Face circle
    canvas.drawCircle(center, radius, facePaint);

    // Ears
    final earPath = Path();
    // Left ear
    earPath.moveTo(center.dx - radius * 0.7, center.dy - radius * 0.5);
    earPath.lineTo(center.dx - radius * 0.9, center.dy - radius * 1.1);
    earPath.lineTo(center.dx - radius * 0.3, center.dy - radius * 0.7);
    earPath.close();
    // Right ear
    earPath.moveTo(center.dx + radius * 0.7, center.dy - radius * 0.5);
    earPath.lineTo(center.dx + radius * 0.9, center.dy - radius * 1.1);
    earPath.lineTo(center.dx + radius * 0.3, center.dy - radius * 0.7);
    earPath.close();
    canvas.drawPath(earPath, facePaint);
    canvas.drawPath(earPath, linePaint);

    // Eyes (1.2x size, circle)
    final eyeY = center.dy - radius * 0.1;
    final eyeRadius = radius * 0.24;
    final leftEyeX = center.dx - radius * 0.35;
    final rightEyeX = center.dx + radius * 0.35;

    if (leftEyeClosed) {
      // Closed eye (curved line)
      _drawClosedEye(canvas, Offset(leftEyeX, eyeY), eyeRadius, linePaint);
    } else {
      // Open eye (circle)
      canvas.drawCircle(Offset(leftEyeX, eyeY), eyeRadius, featurePaint);
    }

    if (rightEyeClosed) {
      _drawClosedEye(canvas, Offset(rightEyeX, eyeY), eyeRadius, linePaint);
    } else {
      canvas.drawCircle(Offset(rightEyeX, eyeY), eyeRadius, featurePaint);
    }

    // Nose
    final nosePath = Path();
    nosePath.moveTo(center.dx, center.dy + radius * 0.1);
    nosePath.lineTo(center.dx - radius * 0.1, center.dy + radius * 0.25);
    nosePath.lineTo(center.dx + radius * 0.1, center.dy + radius * 0.25);
    nosePath.close();
    canvas.drawPath(nosePath, featurePaint);

    // Mouth
    final mouthPath = Path();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.25);
    mouthPath.lineTo(center.dx, center.dy + radius * 0.4);
    canvas.drawPath(mouthPath, linePaint);

    mouthPath.reset();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.4);
    mouthPath.quadraticBezierTo(center.dx - radius * 0.15,
        center.dy + radius * 0.5, center.dx - radius * 0.25, center.dy + radius * 0.4);
    canvas.drawPath(mouthPath, linePaint);

    mouthPath.reset();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.4);
    mouthPath.quadraticBezierTo(center.dx + radius * 0.15,
        center.dy + radius * 0.5, center.dx + radius * 0.25, center.dy + radius * 0.4);
    canvas.drawPath(mouthPath, linePaint);

    // Whiskers
    _drawWhiskers(canvas, center, radius, linePaint);
  }

  void _drawClosedEye(
      Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx - radius, center.dy);
    path.quadraticBezierTo(
        center.dx, center.dy + radius * 0.5, center.dx + radius, center.dy);
    canvas.drawPath(path, paint);
  }

  void _drawOvalEye(Canvas canvas, Offset center, double radiusX,
      double radiusY, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      paint,
    );
  }

  void _drawWhiskers(
      Canvas canvas, Offset center, double radius, Paint paint) {
    final whiskerPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Left whiskers
    canvas.drawLine(
      Offset(center.dx - radius * 0.3, center.dy + radius * 0.3),
      Offset(center.dx - radius * 0.8, center.dy + radius * 0.2),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.3, center.dy + radius * 0.35),
      Offset(center.dx - radius * 0.8, center.dy + radius * 0.4),
      whiskerPaint,
    );

    // Right whiskers
    canvas.drawLine(
      Offset(center.dx + radius * 0.3, center.dy + radius * 0.3),
      Offset(center.dx + radius * 0.8, center.dy + radius * 0.2),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.3, center.dy + radius * 0.35),
      Offset(center.dx + radius * 0.8, center.dy + radius * 0.4),
      whiskerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CatFacePainter oldDelegate) {
    return leftEyeClosed != oldDelegate.leftEyeClosed ||
        rightEyeClosed != oldDelegate.rightEyeClosed;
  }
}
