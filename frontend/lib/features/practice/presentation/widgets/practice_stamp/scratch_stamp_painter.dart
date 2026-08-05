import 'package:flutter/material.dart';

import 'stamp_template.dart';

/// Bottom layer of `ScratchStampSheet`: the stamp fully filled in ink color.
/// Always painted underneath the scratch mask; revealed wherever the mask
/// above it has been erased.
class StampFillPainter extends CustomPainter {
  final StampTemplate template;
  final Color color;

  StampFillPainter({required this.template, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = template.buildPath(size);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final outline = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, outline);
  }

  @override
  bool shouldRepaint(covariant StampFillPainter oldDelegate) =>
      oldDelegate.template != template || oldDelegate.color != color;
}

/// Top layer of `ScratchStampSheet`: a neutral mask covering the stamp
/// shape, erased wherever the accumulated scratch [strokePath] has been
/// dragged (`BlendMode.clear` inside a `saveLayer`), revealing the filled
/// stamp beneath.
///
/// [strokePath] is mutated in place by the caller as the student drags, so
/// `shouldRepaint` always returns true rather than comparing the (identical)
/// `Path` reference across frames.
class ScratchMaskPainter extends CustomPainter {
  final StampTemplate template;
  final Path strokePath;
  final Color maskColor;

  ScratchMaskPainter({
    required this.template,
    required this.strokePath,
    required this.maskColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final templatePath = template.buildPath(size);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawPath(templatePath, Paint()..color = maskColor);
    canvas.drawPath(strokePath, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScratchMaskPainter oldDelegate) => true;
}
