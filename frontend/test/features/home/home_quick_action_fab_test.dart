import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/home/presentation/widgets/home_quick_action_fab.dart';

void main() {
  Future<void> pump(WidgetTester tester) {
    return tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(floatingActionButton: HomeQuickActionFab()),
      ),
    );
  }

  testWidgets('FAB 렌더 — 예외 없음', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('FAB 시각 크기는 44x44 (Hyen 표준 H8)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(floatingActionButton: HomeQuickActionFab()),
      ),
    );
    await tester.pumpAndSettle();

    // 잉크가 칠해지는 면 = 44. 바깥 RawMaterialButton 은 Flutter 의
    // MaterialTapTargetSize.padded 로 48 까지 넓혀져 터치 타깃 하한을 지킨다.
    final surface =
        find
            .descendant(
              of: find.byType(RawMaterialButton),
              matching: find.byType(Material),
            )
            .first;
    expect(tester.getSize(surface), const Size(44, 44));
    expect(
      tester.getSize(find.byType(FloatingActionButton)),
      const Size(48, 48),
    );
  });

  testWidgets('탭 시 퀵액션 시트가 예외 없이 열린다', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
