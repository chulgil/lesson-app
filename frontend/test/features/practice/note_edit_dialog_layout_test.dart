import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/practice/presentation/widgets/notes/note_edit_dialog.dart';

/// Regression guard (2026-07-08 FE audit B1).
///
/// NoteEditDialog 의 저장/수정 FilledButton 은 Row(mainAxisAlignment.end) 의
/// 직접 자식이라 loose (0..∞) 폭 제약을 받는데, 앱 테마가
/// FilledButton.minimumSize = Size(∞, 48) 을 강제해
/// "BoxConstraints forces an infinite width" 로 다이얼로그가 열리자마자 크래시했다.
///
/// 수정: FilledButton.styleFrom(minimumSize: Size(0, buttonHeight)) override.
/// 이 테스트는 앱 테마 하에서 실제 다이얼로그를 pump 해 크래시가 없음을 검증한다
/// (fix 를 되돌리면 RED).
void main() {
  testWidgets('NoteEditDialog(추가 모드) 은 앱 테마에서 크래시 없이 렌더된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: NoteEditDialog()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
