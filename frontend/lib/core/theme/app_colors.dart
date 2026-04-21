import 'package:flutter/material.dart';

/// App color palette based on design system
class AppColors {
  AppColors._();

  // Primary - Notebook × Score: ink (was classic purple 0xFF6B5B95)
  static const primary = Color(0xFF14161C);
  static const primaryLight = Color(0xFF3F5D2F); // paperOk
  static const primaryDark = Color(0xFF14161C);

  // Secondary - Notebook × Score: paperAccent (was sandy brown 0xFFF4A460)
  static const secondary = Color(0xFF9B1B12);
  static const secondaryLight = Color(0xFFE8DFC7); // paperDark

  // Semantic - mapped to Notebook × Score palette
  static const success = Color(0xFF3F5D2F); // paperOk
  static const successDark = Color(0xFF2A4020);
  static const successLight = Color(0xFFE8DFC7); // paperDark
  static const warning = Color(0xFF9B1B12); // paperAccent
  static const warningLight = Color(0xFFE8DFC7); // paperDark
  static const error = Color(0xFF9B1B12); // paperAccent
  static const errorLight = Color(0xFFE8DFC7); // paperDark
  static const info = Color(0xFF14161C); // ink
  static const infoLight = Color(0xFFE8DFC7); // paperDark

  // Practice status - mapped to Notebook × Score palette
  static const practiceGood = Color(0xFF3F5D2F); // paperOk
  static const practiceNormal = Color(0x8C14161C); // inkTertiary
  static const practicePoor = Color(0xFF9B1B12); // paperAccent
  static const practicePaused = Color(0x4014161C); // inkQuaternary

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

  // Schedule: travel time block colors
  static const scheduleTravelBackground = Color(0xFFE8E0F0);
  static const scheduleTravelAccent = Color(0xFF9E8BB8);

  // Schedule: rest day (no lessons scheduled) background
  static const scheduleRestDayBackground = Color(0xFFE8E8E8);

  // Schedule: now indicator (red line/dot for current time)
  static const scheduleNowIndicator = Color(0xFFE53935);

  // Schedule: grid line color
  static const scheduleGridLine = Color(0xFFE8E8E8);

  // Schedule: booking slot colors (design_master.md 5.3)
  static const slotAvailable = Color(0xFF4CAF50);
  static const slotMyBooking = Color(0xFF2196F3);
  static const slotAlmostFull = Color(0xFFFFC107);
  static const slotUnavailable = Color(0xFF9E9E9E);
  static const slotRecommended = Color(0xFFF4A460);

  // Schedule: availability block (empty/available)
  static const availabilityEmpty = Color(0xFFFAFAFA);
  static const availabilityBorder = Color(0xFFE0E0E0);
  static const availabilityText = Color(0xFFBDBDBD);

  // Light mode - Notebook × Score palette
  static const backgroundLight = Color(0xFFE8DFC7); // paperDark
  static const surfaceLight = Color(0xFFF2ECDD); // paper
  static const surfaceSecondaryLight = Color(0xFFE8DFC7); // paperDark
  static const borderLight = Color(0x4014161C); // inkQuaternary
  static const textPrimaryLight = Color(0xFF14161C); // ink
  static const textSecondaryLight = Color(0xBF14161C); // inkSecondary
  static const textTertiaryLight = Color(0x8C14161C); // inkTertiary
  static const textDisabledLight = Color(0x4014161C); // inkQuaternary

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

  // Brand colors
  static const youtubeRed = Color(0xFFFF0000);

  // Gamification level gradients
  static const levelBronzeStart = Color(0xFF8B4513);
  static const levelBronzeEnd = Color(0xFFCD853F);
  static const levelSilverStart = Color(0xFF5B8C5A);
  static const levelSilverEnd = Color(0xFF78AB78);
  static const levelGoldStart = Color(0xFFB8860B);
  static const levelGoldEnd = Color(0xFFDAA520);
  static const levelPlatinumStart = Color(0xFF4A7FB5);
  static const levelPlatinumEnd = Color(0xFF6BA3D6);
  static const levelDiamondStart = Color(0xFF6B21A8);
  static const levelDiamondEnd = Color(0xFF9333EA);

  // Tuner
  static const tunerGlowPerfect = Color(0x6690EE90);
  static const tunerCircleStroke = Color(0x33808080);

  // ─────────────────────────────────────────────────────────────
  // Notebook × Score 팔레트 (docs/specs/design/notebook/README.md)
  // 음악 악보 + 노트 필기 컨셉. Phase 1: 선생님 홈화면부터 적용.
  // ─────────────────────────────────────────────────────────────
  static const paper = Color(0xFFF2ECDD); // 크림색 종이 배경
  static const paperDark = Color(0xFFE8DFC7); // 강조 영역
  static const ink = Color(0xFF14161C); // 본문 (딥 블루-블랙)
  static const inkSecondary = Color(0xBF14161C); // 75% alpha
  static const inkTertiary = Color(0x8C14161C); // 55% alpha
  static const inkQuaternary = Color(0x4014161C); // 25% alpha
  static const paperPencil = Color(0x9914161C); // 60% alpha (손글씨)
  static const paperMargin = Color(0xFFA83E3A); // 왼쪽 붉은 여백선 (3px 고정)
  static const paperAccent = Color(0xFF9B1B12); // 핵심 액션
  static const paperAccentSoft = Color(0x1F9B1B12); // 12% alpha
  static const paperOk = Color(0xFF3F5D2F); // 완료 (녹색 펜)
  static const paperHighlight = Color(0xFFF7D755); // 형광펜
}
