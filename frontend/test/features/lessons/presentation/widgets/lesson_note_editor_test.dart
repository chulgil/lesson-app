import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_detail/lesson_notes_widgets.dart';

/// Widget smoke test for LessonNoteEditor (§7.135 chip → template + undo).
///
/// 1) Renders without RenderBox/BoxConstraints crash.
/// 2) "템플릿 가져오기" 버튼이 노출.
/// 3) Undo 아이콘이 비활성으로 시작 → 타이핑 후 1.5s 경과로 활성화 → 탭 시
///    snackbar "되돌렸습니다" + 텍스트 복원.
void main() {
  Widget harness({String? initial, void Function(String)? onChanged}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: LessonNoteEditor(initialText: initial, onChanged: onChanged),
          ),
        ),
      ),
    );
  }

  testWidgets('renders + 템플릿 가져오기 버튼 노출 (no crash)', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('템플릿 가져오기'), findsOneWidget);
    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('undo: 타이핑 → debounce 1.5s 경과 후 활성화 → 직전 본문 복원', (tester) async {
    String? lastSaved;
    await tester.pumpWidget(
      harness(initial: 'baseline', onChanged: (v) => lastSaved = v),
    );
    await tester.pumpAndSettle();

    // 초기: undo 비활성 (snapshot stack 비어있음).
    final undoBtn = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.undo),
        matching: find.byType(IconButton),
      ),
    );
    expect(undoBtn.onPressed, isNull);

    // 타이핑.
    await tester.enterText(find.byType(TextField), 'baseline edited');
    expect(lastSaved, 'baseline edited');

    // debounce 통과 — snapshot push.
    await tester.pump(const Duration(milliseconds: 1600));

    // 이제 undo 활성.
    final undoBtnAfter = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.undo),
        matching: find.byType(IconButton),
      ),
    );
    expect(undoBtnAfter.onPressed, isNotNull);

    // Undo 탭 → 직전 본문(baseline) 복원 + snackbar.
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'baseline');
    expect(lastSaved, 'baseline');
    expect(find.text('되돌렸습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
