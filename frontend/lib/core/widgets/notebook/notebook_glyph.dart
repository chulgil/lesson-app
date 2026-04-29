import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Notebook × Score ASCII/Unicode 글리프 위젯.
///
/// **§9 아이콘 정책 (A2 — 선택적 강제)**:
/// - 시그니처 영역(NotebookMasthead, *Stamp, EmptyState, 손글씨 마지널리아) 에서는
///   Material `Icons.*` 대신 본 위젯의 ASCII/Unicode 글리프 사용.
/// - 일반 navigation/utility (chevron_right, arrow_back, close, more_vert, search)
///   는 Material 허용. 시스템 affordance 컨벤션 우선.
/// - 결정 트리: "이 아이콘이 노트북×스코어 손맛 메타포에 기여하는가?"
///     → YES → NotebookGlyph
///     → NO (시스템 컨벤션) → Material 유지
///
/// 글리프는 Text 로 렌더되며 폰트 fallback 은 Playfair Display(serif). Material
/// `Icon` 과 달리 텍스트 라인 박스 내에서 baseline-aligned 된다.
///
/// 스펙: `docs/specs/design/notebook/README.md` §9
class NotebookGlyph extends StatelessWidget {
  /// 렌더할 글리프 문자. `NotebookGlyph.<name>` 상수 사용 권장.
  final String glyph;

  /// 글리프 크기 (fontSize). 기본 16.
  final double size;

  /// 글리프 색상. 기본 `AppColors.ink`.
  final Color? color;

  /// 폰트 패밀리. null 이면 serif fallback (Playfair Display 또는 시스템 serif).
  final String? fontFamily;

  /// 시맨틱 라벨 (스크린리더). null 이면 데코레이션으로 간주.
  final String? semanticLabel;

  const NotebookGlyph(
    this.glyph, {
    super.key,
    this.size = 16,
    this.color,
    this.fontFamily,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Text(
      glyph,
      style: TextStyle(
        fontSize: size,
        color: color ?? AppColors.ink,
        fontFamily: fontFamily,
        height: 1.0,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      textAlign: TextAlign.center,
    );

    if (semanticLabel == null) return widget;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(child: widget),
    );
  }

  // -- 음악 (Notebook × Score 시그니처 진원지) --

  /// `♩` 4분음표 (U+2669). 템포·음악 마커.
  static const note = '♩';

  /// `♪` 8분음표 (U+266A). 음악 일반.
  static const eighthNote = '♪';

  /// `♫` 8분음표 페어 (U+266B). 음악 그룹.
  static const beamedNotes = '♫';

  /// `♬` 16분음표 (U+266C). 활기·생동.
  static const sixteenthNotes = '♬';

  /// `𝄞` 높은음자리표 (U+1D11E). StaffDivider 와 동일 패턴.
  static const trebleClef = '𝄞';

  /// `𝄢` 낮은음자리표 (U+1D122).
  static const bassClef = '𝄢';

  // -- 체크 / 완료 --

  /// `✓` 체크마크 (U+2713). Tier 2 자필 완료 마크.
  static const check = '✓';

  /// `✗` 엑스 (U+2717). 미완료·취소.
  static const cross = '✗';

  /// `✕` 엑스 (U+2715). close 의 ASCII 대체 (시그니처 영역만).
  static const close = '✕';

  // -- 화살표 (시그니처 영역 navigation) --

  /// `→` 우향 화살표 (U+2192). 다음·진행.
  static const arrowRight = '→';

  /// `←` 좌향 화살표 (U+2190). 이전·뒤로.
  static const arrowLeft = '←';

  /// `↑` 상향 화살표 (U+2191). 증가.
  static const arrowUp = '↑';

  /// `↓` 하향 화살표 (U+2193). 감소.
  static const arrowDown = '↓';

  /// `›` 단일 우측 꺾쇠 (U+203A). chevron_right 의 ASCII 대체.
  static const chevronRight = '›';

  /// `‹` 단일 좌측 꺾쇠 (U+2039).
  static const chevronLeft = '‹';

  /// `»` 더블 우측 꺾쇠 (U+00BB). 강조 진행.
  static const doubleChevronRight = '»';

  // -- 별 / 강조 --

  /// `★` 채워진 별 (U+2605). 즐겨찾기 ON.
  static const starFilled = '★';

  /// `☆` 빈 별 (U+2606). 즐겨찾기 OFF.
  static const starOutline = '☆';

  // -- 좋아요 / 하트 --

  /// `♥` 채워진 하트 (U+2665). 좋아요 ON 대체.
  static const heartFilled = '♥';

  /// `♡` 빈 하트 (U+2661). 좋아요 OFF 대체.
  static const heartOutline = '♡';

  // -- 점 / 마커 --

  /// `•` 불릿 (U+2022). 리스트 마커.
  static const bullet = '•';

  /// `·` 미들 도트 (U+00B7). 메타 구분자.
  static const middleDot = '·';

  /// `●` 채워진 원 (U+25CF). 진행 중·active.
  static const dotFilled = '●';

  /// `○` 빈 원 (U+25CB). 비활성·pending.
  static const dotOutline = '○';

  // -- 부호 --

  /// `+` 플러스 (U+002B). add 의 ASCII 대체.
  static const plus = '+';

  /// `−` 마이너스 (U+2212). remove 의 ASCII 대체.
  static const minus = '−';

  // -- 편집 / 손맛 --

  /// `✎` 연필 (U+270E). edit 의 손글씨 대체.
  static const pencil = '✎';

  /// `✦` 4점 별 (U+2726). 강조·아이디어.
  static const sparkle = '✦';

  // -- 텍스트 마커 --

  /// `§` 섹션 마크 (U+00A7). 스펙·정책 인용.
  static const section = '§';

  /// `¶` 단락 마크 (U+00B6).
  static const paragraph = '¶';

  /// `※` 참조 마크 (U+203B). 주의·참고.
  static const referenceMark = '※';
}
