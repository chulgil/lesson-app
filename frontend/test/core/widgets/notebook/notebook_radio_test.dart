import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_radio.dart';

/// §1.3.1 각진 라디오 위젯 smoke + 회귀 테스트.
///
/// HARD-GATE: top-level 시그니처 위젯의 widget smoke test 필수
/// (rules/ux-rules.md "레이아웃 크래시 방지").
void main() {
  Future<void> pumpRadio<T>(
    WidgetTester tester, {
    required T value,
    required T? groupValue,
    ValueChanged<T?>? onChanged,
    bool toggleable = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: NotebookRadio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              toggleable: toggleable,
            ),
          ),
        ),
      ),
    );
  }

  Container findInnerBox(WidgetTester tester) {
    final containers =
        tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(NotebookRadio<int>),
                matching: find.byType(Container),
              ),
            )
            .toList();
    return containers.firstWhere(
      (c) => c.constraints?.maxWidth == 20 && c.constraints?.maxHeight == 20,
    );
  }

  group('NotebookRadio 기본 렌더', () {
    testWidgets('미선택 상태 — paper 배경, ink quaternary 보더, 내부 사각형 없음', (
      tester,
    ) async {
      await pumpRadio<int>(tester, value: 1, groupValue: 0, onChanged: (_) {});
      expect(tester.takeException(), isNull);

      final box = findInnerBox(tester);
      final deco = box.decoration as BoxDecoration;
      expect(deco.borderRadius, BorderRadius.zero);
      expect(deco.color, Colors.transparent);
      expect(deco.border?.top.color, AppColors.inkQuaternary);
      expect(box.child, isNull, reason: '미선택 시 내부 사각형 없음');
    });

    testWidgets('선택 상태 — vermillion 채움 + 내부 8×8 paper 사각형', (tester) async {
      await pumpRadio<int>(tester, value: 1, groupValue: 1, onChanged: (_) {});
      expect(tester.takeException(), isNull);

      final box = findInnerBox(tester);
      final deco = box.decoration as BoxDecoration;
      expect(deco.color, AppColors.paperAccent);
      expect(deco.border?.top.color, AppColors.paperAccent);
      expect(box.child, isNotNull, reason: '선택 시 내부 paper 사각형 표시');
    });

    testWidgets('disabled 상태 — ink tertiary 톤', (tester) async {
      await pumpRadio<int>(tester, value: 1, groupValue: 0, onChanged: null);
      expect(tester.takeException(), isNull);

      final box = findInnerBox(tester);
      final deco = box.decoration as BoxDecoration;
      expect(deco.border?.top.color, AppColors.inkTertiary);
    });
  });

  group('NotebookRadio 인터랙션', () {
    testWidgets('탭하면 onChanged 가 value 로 호출된다', (tester) async {
      int? captured;
      await pumpRadio<int>(
        tester,
        value: 42,
        groupValue: 0,
        onChanged: (v) => captured = v,
      );

      await tester.tap(find.byType(NotebookRadio<int>));
      await tester.pumpAndSettle();
      expect(captured, 42);
    });

    testWidgets('이미 선택된 값을 탭하면 onChanged 미호출 (기본)', (tester) async {
      int? captured;
      bool called = false;
      await pumpRadio<int>(
        tester,
        value: 1,
        groupValue: 1,
        onChanged: (v) {
          captured = v;
          called = true;
        },
      );

      await tester.tap(find.byType(NotebookRadio<int>));
      await tester.pumpAndSettle();
      expect(called, isFalse, reason: 'toggleable=false 면 동일 값 재탭은 무시');
      expect(captured, isNull);
    });

    testWidgets('toggleable=true 면 선택값 재탭 시 null 호출', (tester) async {
      int? captured = 1;
      bool called = false;
      await pumpRadio<int>(
        tester,
        value: 1,
        groupValue: 1,
        onChanged: (v) {
          captured = v;
          called = true;
        },
        toggleable: true,
      );

      await tester.tap(find.byType(NotebookRadio<int>));
      await tester.pumpAndSettle();
      expect(called, isTrue);
      expect(captured, isNull);
    });

    testWidgets('disabled 라디오는 탭에 반응하지 않는다', (tester) async {
      await pumpRadio<int>(tester, value: 1, groupValue: 0, onChanged: null);
      await tester.tap(find.byType(NotebookRadio<int>), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('NotebookRadio 레이아웃 회귀', () {
    testWidgets('Row 좁은 제약에서 BoxConstraints 크래시 없음', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: SizedBox()),
                NotebookRadio<int>(value: 1, groupValue: 1, onChanged: (_) {}),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Column 안에서 크래시 없음', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                NotebookRadio<int>(value: 1, groupValue: 0, onChanged: (_) {}),
                NotebookRadio<int>(value: 2, groupValue: 0, onChanged: (_) {}),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('NotebookRadioListTile', () {
    testWidgets('title 탭으로도 onChanged 호출된다', (tester) async {
      int? captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NotebookRadioListTile<int>(
              value: 7,
              groupValue: 0,
              onChanged: (v) => captured = v,
              title: const Text('옵션'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('옵션'));
      await tester.pumpAndSettle();
      expect(captured, 7);
    });

    testWidgets('disabled tile 은 ListTile.onTap null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NotebookRadioListTile<int>(
              value: 1,
              groupValue: 0,
              onChanged: null,
              title: const Text('disabled'),
            ),
          ),
        ),
      );
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.onTap, isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('NotebookRadio 시맨틱', () {
    testWidgets('inMutuallyExclusiveGroup + checked semantics 노출', (
      tester,
    ) async {
      await pumpRadio<int>(tester, value: 1, groupValue: 1, onChanged: (_) {});
      final semantics = tester.getSemantics(find.byType(NotebookRadio<int>));
      // ignore: deprecated_member_use — flagsCollection (Flutter 3.32+) 까지의 호환 유지
      final inGroupFlag = semantics.hasFlag(
        SemanticsFlag.isInMutuallyExclusiveGroup,
      );
      // ignore: deprecated_member_use
      final checkedFlag = semantics.hasFlag(SemanticsFlag.isChecked);
      expect(inGroupFlag, isTrue);
      expect(checkedFlag, isTrue);
    });
  });
}
