import 'package:flutter/material.dart';

/// App typography styles based on design system
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Pretendard';

  // Display
  static const displayLarge = TextStyle(
    fontSize: 32,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  static const displayMedium = TextStyle(
    fontSize: 28,
    height: 1.29,
    fontWeight: FontWeight.w700,
  );

  // Heading
  static const headingLarge = TextStyle(
    fontSize: 24,
    height: 1.33,
    fontWeight: FontWeight.w600,
  );

  static const headingMedium = TextStyle(
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  static const headingSmall = TextStyle(
    fontSize: 18,
    height: 1.33,
    fontWeight: FontWeight.w600,
  );

  // Body
  static const bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
  );

  // Caption
  static const caption = TextStyle(
    fontSize: 11,
    height: 1.27,
    fontWeight: FontWeight.w400,
  );

  static const captionSmall = TextStyle(
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w400,
  );

  /// Ultra-small caption for dense grids (e.g., weekly schedule cells).
  /// Use sparingly — legibility degrades below this size.
  static const captionXSmall = TextStyle(
    fontSize: 9,
    height: 1.2,
    fontWeight: FontWeight.w400,
  );

  // Button
  static const button = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );

  static const buttonSmall = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
  );

  // ─────────────────────────────────────────────────────────────
  // Weight variants (#1221)
  //
  // These combinations already existed across the app as
  // `base.copyWith(fontWeight: ...)`. Naming them makes the scale
  // traceable and lets the Figma mirror bind every text node to a
  // named style. Values are identical to the expressions they
  // replace — see app_typography_weight_tokens_test.dart.
  //
  // Suffix encodes the FontWeight literally (W500/W600/W700) because
  // the base names already use Large/Medium/Small for *size*.
  // ─────────────────────────────────────────────────────────────

  static const bodyLargeW600 = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );

  static const bodyLargeW700 = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w700,
  );

  static const bodyMediumW500 = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
  );

  static const bodyMediumW600 = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w600,
  );

  static const bodyMediumW700 = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w700,
  );

  static const bodySmallW500 = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
  );

  static const bodySmallW600 = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w600,
  );

  static const captionW500 = TextStyle(
    fontSize: 11,
    height: 1.27,
    fontWeight: FontWeight.w500,
  );

  static const captionW600 = TextStyle(
    fontSize: 11,
    height: 1.27,
    fontWeight: FontWeight.w600,
  );

  static const captionSmallW600 = TextStyle(
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  static const headingSmallW700 = TextStyle(
    fontSize: 18,
    height: 1.33,
    fontWeight: FontWeight.w700,
  );
}
