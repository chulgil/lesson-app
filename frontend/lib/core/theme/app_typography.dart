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
}
