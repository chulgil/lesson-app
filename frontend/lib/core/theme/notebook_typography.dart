import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Notebook × Score 전용 타이포그래피.
///
/// 4대 시그니처:
/// - Playfair Display: 매스트헤드, 타이틀, 로마숫자
/// - Noto Serif KR: 한글 대형 제목 (선택)
/// - Gaegu: 손글씨 주석 / 마지널리아
/// - IBM Plex Mono: 날짜 / VOL·NO 라벨 / 템포
///
/// 본문(Sans)은 기존 Pretendard 유지 — `AppTypography.bodyMedium` 등 사용.
///
/// 스펙: docs/specs/design/notebook/README.md §4
class NotebookTypography {
  NotebookTypography._();

  /// 매스트헤드 메인 타이틀 — 페이지 상단 큰 제목.
  /// 예: "오늘의 레슨"
  static TextStyle get masthead => GoogleFonts.playfairDisplay(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.8,
    height: 1.0,
  );

  /// 매스트헤드 부제 — italic.
  /// 예: "Programme for Thursday"
  static TextStyle get mastheadLabel => GoogleFonts.playfairDisplay(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    color: AppColors.inkSecondary,
    letterSpacing: 2,
  );

  /// 매스트헤드 하단 날짜줄 — italic serif.
  /// 예: "4月 18日 · 다섯 편의 수업"
  static TextStyle get mastheadDate => GoogleFonts.playfairDisplay(
    fontSize: 13,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
    color: AppColors.inkSecondary,
  );

  /// 브랜드 로고 라벨 — 상단 매스트헤드 좌측.
  /// 예: "LESSONAZA"
  static TextStyle get eyebrow => GoogleFonts.playfairDisplay(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    letterSpacing: 5,
  );

  /// VOL·NO·DATE 메타 — 매스트헤드 우측.
  /// 예: "VOL. IV · NO. 18 · APR MMXXVI"
  static TextStyle get metaMono => GoogleFonts.ibmPlexMono(
    fontSize: 9,
    fontWeight: FontWeight.w400,
    color: AppColors.inkSecondary,
    letterSpacing: 1,
  );

  /// 로마숫자 번호 — 레슨 인덱스 (I, II, III…).
  static TextStyle get roman => GoogleFonts.playfairDisplay(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    color: AppColors.inkSecondary,
  );

  /// 로마숫자 — 활성 상태 (현재 진행 중 레슨).
  static TextStyle get romanActive =>
      roman.copyWith(color: AppColors.paperAccent);

  /// 곡명·레슨 제목.
  static TextStyle get pieceTitle => GoogleFonts.playfairDisplay(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    letterSpacing: -0.2,
    height: 1.3,
  );

  /// 섹션 제목 — 화면 내부 영역 헤더 (레슨 상세의 "선생님 피드백" / "주요 포인트" 등).
  /// Playfair 17 / w600. `appBarTitle`(18)과 `pieceTitle`(16) 사이의 중간 위계.
  static TextStyle get sectionTitle => GoogleFonts.playfairDisplay(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    letterSpacing: -0.2,
    height: 1.3,
  );

  /// AppBar 타이틀 — Playfair Display 18 / w700.
  /// 전역 `appBarTheme.titleTextStyle` 에 적용되어 하위 화면 전체의 상단 타이틀을 통일.
  static TextStyle get appBarTitle => GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: 0,
    height: 1.2,
  );

  /// 다이얼로그 타이틀 — Playfair Display 19 / w700.
  /// 전역 `dialogTheme.titleTextStyle` 에 적용되어 AlertDialog 제목 전체를 통일.
  /// AppBar 타이틀과 시각 위계를 맞추기 위해 약간 큰 19pt + 조금 타이트한 height.
  static TextStyle get dialogTitle => GoogleFonts.playfairDisplay(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: 0,
    height: 1.25,
  );

  /// "Fine." 푸터 라벨 — italic serif.
  static TextStyle get fine => GoogleFonts.playfairDisplay(
    fontSize: 15,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  /// 섹션 라벨 — 업퍼케이스 sans.
  /// 예: "레슨요청 · 14", "스케줄변경요청 · 5"
  static TextStyle get sectionLabel => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.inkSecondary,
    letterSpacing: 1.0,
  );

  /// 손글씨 본문 — Gaegu.
  static TextStyle get hand => GoogleFonts.gaegu(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.paperPencil,
    height: 1.5,
  );

  /// 손글씨 강조 — "지금", "발표회!" 등.
  static TextStyle get handEmphasis => GoogleFonts.gaegu(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.paperAccent,
  );

  /// 손글씨 완료 메모 — "✓ 보잉 좋음".
  static TextStyle get handOk => GoogleFonts.gaegu(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.paperOk,
  );

  /// 시스템 자동 인디케이터 — Pretendard italic small caps.
  ///
  /// 사용 대상: 앱이 자동 생성한 메타 라벨 — "오늘", "D-N", "미수금", "필수",
  /// "진행 중" 등. README §1.1 Tier 4 (사람 자필 아님) → Gaegu 회피.
  ///
  /// 색상 override: paperOk 등 의미별 변형은 `copyWith(color: ...)` 사용.
  static TextStyle get indicatorLabel => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: AppColors.paperAccent,
    letterSpacing: 0.8,
    height: 1.2,
  );

  /// 템포 표기 — "♩ = 92".
  static TextStyle get tempoMono => GoogleFonts.ibmPlexMono(
    fontSize: 9,
    fontWeight: FontWeight.w500,
    color: AppColors.inkSecondary,
    letterSpacing: 1,
  );
}

/// 로마숫자 변환 헬퍼 (0-based index).
///
/// [index]가 12 이상이면 아라비아 숫자로 폴백.
String romanOf(int index) {
  const table = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII',
  ];
  if (index < 0) return '';
  if (index < table.length) return table[index];
  return (index + 1).toString();
}
