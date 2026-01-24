import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Heart particle for perfect tuning celebration.
/// Starts from cat edge and expands outward radially to the circle.
class HeartParticle {
  HeartParticle({
    required this.center,
    required this.angle,
    required this.baseSize,
    required this.startRadius,
    required this.maxRadius,
    required this.rotation,
    this.progress = 0.0,
    this.speed = 1.0,
  });

  final Offset center; // Cat center position
  final double angle; // Direction angle (radians)
  final double baseSize; // Base size of heart
  final double startRadius; // Start from cat edge
  final double maxRadius; // End at circle edge
  double rotation; // Current rotation
  double progress; // 0.0 = at cat edge, 1.0 = at circle edge
  double speed; // Speed multiplier

  /// Current position based on progress
  Offset get position {
    final currentRadius = startRadius + progress * (maxRadius - startRadius);
    return Offset(
      center.dx + math.cos(angle) * currentRadius,
      center.dy + math.sin(angle) * currentRadius,
    );
  }

  /// Size grows as particle moves outward
  double get size {
    // Start small, grow to full size
    return baseSize * (0.5 + progress * 0.5);
  }

  /// Opacity: fade in quickly, stay visible until the very end
  double get opacity {
    if (progress < 0.1) {
      // Quick fade in
      return progress / 0.1;
    } else if (progress > 0.9) {
      // Very late fade out
      return (1.0 - progress) / 0.1;
    }
    return 1.0;
  }

  bool get isDead => progress >= 1.0;
}
