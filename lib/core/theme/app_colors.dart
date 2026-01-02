import 'package:flutter/material.dart';

/// App color palette based on design system
class AppColors {
  AppColors._();

  // Primary - Classic purple for music feel
  static const primary = Color(0xFF6B5B95);
  static const primaryLight = Color(0xFF9A8BC4);
  static const primaryDark = Color(0xFF4A3D6E);

  // Secondary - Sandy brown for instrument wood feel
  static const secondary = Color(0xFFF4A460);
  static const secondaryLight = Color(0xFFF7C490);

  // Semantic
  static const success = Color(0xFF2E8B57);
  static const successLight = Color(0xFFE8F5E9);
  static const warning = Color(0xFFF4A460);
  static const warningLight = Color(0xFFFFF3E0);
  static const error = Color(0xFFDC143C);
  static const errorLight = Color(0xFFFFEBEE);
  static const info = Color(0xFF4A90D9);
  static const infoLight = Color(0xFFE3F2FD);

  // Practice status
  static const practiceGood = Color(0xFF2E8B57);
  static const practiceNormal = Color(0xFFF4A460);
  static const practicePoor = Color(0xFFDC143C);
  static const practicePaused = Color(0xFF9E9E9E);

  // Cat UI accent (metronome cat paw)
  static const catAccent = Color(0xFFB8A9C9);

  // Light mode
  static const backgroundLight = Color(0xFFFFFAF5);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceSecondaryLight = Color(0xFFF5F0EB);
  static const borderLight = Color(0xFFE5E0DB);
  static const textPrimaryLight = Color(0xFF1A1A1A);
  static const textSecondaryLight = Color(0xFF666666);
  static const textTertiaryLight = Color(0xFF999999);
  static const textDisabledLight = Color(0xFFCCCCCC);

  // Dark mode
  static const backgroundDark = Color(0xFF1A1A2E);
  static const surfaceDark = Color(0xFF252540);
  static const surfaceSecondaryDark = Color(0xFF303050);
  static const borderDark = Color(0xFF404060);
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFB0B0B0);
  static const textTertiaryDark = Color(0xFF808080);
  static const textDisabledDark = Color(0xFF505050);

  // Social login
  static const googleBackground = Color(0xFFFFFFFF);
  static const kakaoBackground = Color(0xFFFEE500);
  static const appleBackground = Color(0xFF000000);
}
