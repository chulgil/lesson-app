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
  static const successDark = Color(0xFF1E5C3A);
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

  // Semantic borders
  static const successBorder = Color(0xFFA5D6A7);
  static const infoBorder = Color(0xFF90CAF9);

  // Amber/gold (goals, stars, achievements)
  static const amber = Color(0xFFFFB800);
  static const amberLight = Color(0xFFFFF8E1);

  // Profile color palette (child profiles, categories)
  static const profileBlue = Color(0xFF4A90D9);
  static const profilePink = Color(0xFFE91E63);
  static const profileGreen = Color(0xFF2E8B57);
  static const profileOrange = Color(0xFFE67E22);
  static const profilePurple = Color(0xFF9B59B6);
  static const profileTeal = Color(0xFF1ABC9C);
  static const profileRed = Color(0xFFE74C3C);
  static const profileIndigo = Color(0xFF3F51B5);

  // Streak gradients
  static const streakGreat1 = Color(0xFFFFB800);
  static const streakGreat2 = Color(0xFFFF8C00);
  static const streakGood1 = Color(0xFFFF6B6B);
  static const streakGood2 = Color(0xFFFF8E53);
  static const streakPaused1 = Color(0xFF9E9E9E);
  static const streakPaused2 = Color(0xFF757575);

  // Cat UI accent (metronome cat paw)
  static const catAccent = Color(0xFFB8A9C9);

  // Tuner-specific colors
  static const tunerNaturalNote = Color(0xFFB8D4E3);
  static const tunerNaturalNoteActive = Color(0xFF6BA3C7);
  static const tunerAccidentalNote = Color(0xFFB8E3C8);
  static const tunerAccidentalNoteActive = Color(0xFF6BC790);
  static const tunerCentPerfect = Color(0xFF90EE90);
  static const tunerCentFlat = Color(0xFFFF6B6B);
  static const tunerCentSharp = Color(0xFFFFB347);

  // Speech bubble colors (shared between metronome and tuner)
  static const bubbleIdleBackground = Color(0xFFB8E3C8);
  static const bubbleIdleText = Color(0xFF757575);
  static const bubbleSuccessBackground = Color(0xFFE8F5E9);
  static const bubbleSuccessText = Color(0xFF2E7D32);
  static const bubbleWarningBackground = Color(0xFFFFF3E0);
  static const bubbleWarningText = Color(0xFFE65100);

  // Schedule: muted colors for non-today lessons
  static const scheduleMutedBackground = Color(0xFFF5F5F5);
  static const scheduleMutedAccent = Color(0xFFBDBDBD);

  // Schedule: rest day (no lessons scheduled) background
  static const scheduleRestDayBackground = Color(0xFFE8E8E8);

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
