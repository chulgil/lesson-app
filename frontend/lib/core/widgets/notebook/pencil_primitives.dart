/// Notebook × Score 연필 프리미티브 3종.
///
/// 레퍼런스: `design-plan/hybrid/primitives.jsx`
/// - [PencilUnderline] — 손글씨 느낌 곡선 밑줄
/// - [PencilBox] — 연필 사각 체크박스 (checked 시 Vermillion 체크)
/// - [PencilCircle] — 활성 표시 원 (외곽 링 + 중앙 점)
library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────
// PencilUnderline
// ─────────────────────────────────────────────────────────────────

/// 손글씨 느낌 단순 곡선 밑줄. 강조 텍스트 아래에 배치한다.
class PencilUnderline extends StatelessWidget {
  final double width;
  final Color color;
  final double strokeWidth;

  const PencilUnderline({
    super.key,
    this.width = 80,
    this.color = AppColors.paperAccent,
    this.strokeWidth = 1.8,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, 6),
      painter: _PencilUnderlinePainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _PencilUnderlinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _PencilUnderlinePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final w = size.width;
    final path =
        Path()
          ..moveTo(1, 3.5)
          ..quadraticBezierTo(w * 0.3, 1.5, w * 0.5, 3)
          ..quadraticBezierTo(w * 0.7, 4.5, w - 1, 3.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PencilUnderlinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────────────────────────
// PencilBox
// ─────────────────────────────────────────────────────────────────

/// 연필 사각 체크박스. `checked` 시 Vermillion 체크 표시.
class PencilBox extends StatelessWidget {
  final bool checked;
  final double size;
  final Color borderColor;
  final Color checkColor;

  const PencilBox({
    super.key,
    this.checked = false,
    this.size = 16,
    this.borderColor = AppColors.ink,
    this.checkColor = AppColors.paperAccent,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PencilBoxPainter(
        checked: checked,
        borderColor: borderColor,
        checkColor: checkColor,
      ),
    );
  }
}

class _PencilBoxPainter extends CustomPainter {
  final bool checked;
  final Color borderColor;
  final Color checkColor;

  _PencilBoxPainter({
    required this.checked,
    required this.borderColor,
    required this.checkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // primitives.jsx viewBox 18x18 기준으로 스케일.
    final s = size.width / 18;

    final border =
        Paint()
          ..color = borderColor
          ..strokeWidth = 1.3
          ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(2 * s, 2 * s, 14 * s, 14 * s), border);

    if (checked) {
      final check =
          Paint()
            ..color = checkColor
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;

      final path =
          Path()
            ..moveTo(4.5 * s, 9 * s)
            ..lineTo(8 * s, 13 * s)
            ..lineTo(15 * s, 4 * s);

      canvas.drawPath(path, check);
    }
  }

  @override
  bool shouldRepaint(covariant _PencilBoxPainter oldDelegate) =>
      oldDelegate.checked != checked ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.checkColor != checkColor;
}

// ─────────────────────────────────────────────────────────────────
// PencilCircle
// ─────────────────────────────────────────────────────────────────

/// 활성 표시 원. 외곽 링 + 중앙 채워진 점.
class PencilCircle extends StatelessWidget {
  final double size;
  final Color color;

  const PencilCircle({
    super.key,
    this.size = 18,
    this.color = AppColors.paperAccent,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PencilCirclePainter(color: color),
    );
  }
}

class _PencilCirclePainter extends CustomPainter {
  final Color color;

  _PencilCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // primitives.jsx viewBox 22x22 기준.
    final s = size.width / 22;
    final center = Offset(11 * s, 11 * s);

    final ring =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 8.5 * s, ring);

    final dot =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3 * s, dot);
  }

  @override
  bool shouldRepaint(covariant _PencilCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
