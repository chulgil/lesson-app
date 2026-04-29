import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_glyph.dart';

/// §9 NotebookGlyph 위젯 smoke + 회귀 테스트.
///
/// HARD-GATE: top-level 시그니처 위젯의 widget smoke test 필수
/// (rules/ux-rules.md "레이아웃 크래시 방지").
void main() {
  Future<void> pumpGlyph(
    WidgetTester tester, {
    required String glyph,
    double size = 16,
    Color? color,
    String? semanticLabel,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: NotebookGlyph(
              glyph,
              size: size,
              color: color,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      ),
    );
  }

  group('NotebookGlyph 기본 렌더', () {
    testWidgets('체크 글리프(✓) 가 Text 로 렌더된다', (tester) async {
      await pumpGlyph(tester, glyph: NotebookGlyph.check);
      expect(find.text('✓'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('size 파라미터가 fontSize 에 반영된다', (tester) async {
      await pumpGlyph(tester, glyph: NotebookGlyph.note, size: 24);
      final text = tester.widget<Text>(find.text('♩'));
      expect(text.style?.fontSize, 24);
    });

    testWidgets('color 미지정 시 기본 ink 색상', (tester) async {
      await pumpGlyph(tester, glyph: NotebookGlyph.bullet);
      final text = tester.widget<Text>(find.text('•'));
      expect(text.style?.color, AppColors.ink);
    });

    testWidgets('color 지정 시 적용된다', (tester) async {
      await pumpGlyph(
        tester,
        glyph: NotebookGlyph.starFilled,
        color: AppColors.paperAccent,
      );
      final text = tester.widget<Text>(find.text('★'));
      expect(text.style?.color, AppColors.paperAccent);
    });
  });

  group('NotebookGlyph 글리프 상수', () {
    test('30개 매핑 상수 모두 비어있지 않다', () {
      const glyphs = [
        NotebookGlyph.note,
        NotebookGlyph.eighthNote,
        NotebookGlyph.beamedNotes,
        NotebookGlyph.sixteenthNotes,
        NotebookGlyph.trebleClef,
        NotebookGlyph.bassClef,
        NotebookGlyph.check,
        NotebookGlyph.cross,
        NotebookGlyph.close,
        NotebookGlyph.arrowRight,
        NotebookGlyph.arrowLeft,
        NotebookGlyph.arrowUp,
        NotebookGlyph.arrowDown,
        NotebookGlyph.chevronRight,
        NotebookGlyph.chevronLeft,
        NotebookGlyph.doubleChevronRight,
        NotebookGlyph.starFilled,
        NotebookGlyph.starOutline,
        NotebookGlyph.heartFilled,
        NotebookGlyph.heartOutline,
        NotebookGlyph.bullet,
        NotebookGlyph.middleDot,
        NotebookGlyph.dotFilled,
        NotebookGlyph.dotOutline,
        NotebookGlyph.plus,
        NotebookGlyph.minus,
        NotebookGlyph.pencil,
        NotebookGlyph.sparkle,
        NotebookGlyph.section,
        NotebookGlyph.paragraph,
        NotebookGlyph.referenceMark,
      ];
      expect(glyphs.length, 31);
      for (final g in glyphs) {
        expect(g, isNotEmpty, reason: '글리프 상수가 빈 문자열이면 안 된다');
      }
    });

    testWidgets('treble clef (𝄞 SMP) 가 크래시 없이 렌더된다', (tester) async {
      // U+1D11E 는 SMP plane char — 폰트 fallback 검증
      await pumpGlyph(tester, glyph: NotebookGlyph.trebleClef, size: 32);
      expect(tester.takeException(), isNull);
    });
  });

  group('NotebookGlyph 레이아웃 회귀', () {
    testWidgets('Row 좁은 제약에서 BoxConstraints 크래시 없음', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: SizedBox()),
                NotebookGlyph(NotebookGlyph.chevronRight, size: 14),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Column + Expanded 안에서 크래시 없음', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Center(
                    child: NotebookGlyph(NotebookGlyph.trebleClef, size: 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('NotebookGlyph 시맨틱', () {
    testWidgets('semanticLabel 없으면 글리프 자체가 시맨틱 (Text 기본)', (tester) async {
      await pumpGlyph(tester, glyph: NotebookGlyph.starFilled);
      final semantics = tester.getSemantics(find.byType(NotebookGlyph));
      // semanticLabel 미지정 시 글리프 문자가 그대로 노출 (Text 기본 동작)
      expect(semantics.label, '★');
    });

    testWidgets('semanticLabel 지정 시 스크린리더에 노출', (tester) async {
      await pumpGlyph(
        tester,
        glyph: NotebookGlyph.starFilled,
        semanticLabel: '즐겨찾기',
      );
      final semantics = tester.getSemantics(find.byType(NotebookGlyph));
      expect(semantics.label, '즐겨찾기');
    });
  });
}
