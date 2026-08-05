import 'package:flutter/material.dart';

/// Visual stamp shapes available for the scratch-stamp practice interaction
/// (`ScratchStampSheet`, P1 daily-satisfaction gamification spec).
///
/// Presentation-only concept — kept out of `domain/` per
/// `flutter-architecture.md` (no display concepts on `PracticeSection`).
enum StampTemplate {
  /// 고양이 발바닥 (기본).
  catPaw,

  /// 8분음표.
  eighthNote;

  /// Builds the outline/fill path for this template, scaled to [size].
  Path buildPath(Size size) {
    switch (this) {
      case StampTemplate.catPaw:
        return _buildCatPawPath(size);
      case StampTemplate.eighthNote:
        return _buildEighthNotePath(size);
    }
  }
}

Path _buildCatPawPath(Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();

  // Main pad (bottom, wide oval).
  path.addOval(
    Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.62),
      width: w * 0.62,
      height: h * 0.46,
    ),
  );

  // Four toes around the top.
  final toeCenters = [
    Offset(w * 0.24, h * 0.28),
    Offset(w * 0.40, h * 0.14),
    Offset(w * 0.60, h * 0.14),
    Offset(w * 0.76, h * 0.28),
  ];
  for (final center in toeCenters) {
    path.addOval(
      Rect.fromCenter(center: center, width: w * 0.20, height: h * 0.22),
    );
  }

  return path;
}

Path _buildEighthNotePath(Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();

  // Note head.
  path.addOval(
    Rect.fromCenter(
      center: Offset(w * 0.32, h * 0.78),
      width: w * 0.34,
      height: h * 0.26,
    ),
  );

  // Stem.
  path.moveTo(w * 0.47, h * 0.78);
  path.lineTo(w * 0.47, h * 0.16);
  path.lineTo(w * 0.55, h * 0.16);
  path.lineTo(w * 0.55, h * 0.78);
  path.close();

  // Flag.
  path.moveTo(w * 0.55, h * 0.16);
  path.quadraticBezierTo(w * 0.86, h * 0.24, w * 0.80, h * 0.46);
  path.quadraticBezierTo(w * 0.68, h * 0.34, w * 0.55, h * 0.40);
  path.close();

  return path;
}
