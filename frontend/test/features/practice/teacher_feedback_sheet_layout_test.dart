import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_theme.dart';

/// Regression guard (2026-07-08 FE audit B2).
///
/// teacher_feedback_sheet.dart 의 _InputBar 전송 FilledButton 은
/// Row[Expanded(TextField), SizedBox, FilledButton] 의 비-flex 자식이라 loose(0..∞)
/// 폭을 받는데, 앱 테마가 FilledButton.minimumSize = Size(∞, 48) 을 강제해
/// 시트가 열리자마자 "BoxConstraints forces an infinite width" 로 크래시했다.
/// 수정: styleFrom(minimumSize: Size(0, buttonHeight)) override.
///
/// TeacherFeedbackSheet 는 SharedRecording + Riverpod family provider 를 요구하므로,
/// 크래시를 유발하는 순수 레이아웃(Row+테마버튼) 을 동일 구조로 재현해 검증하고,
/// 실제 위젯이 override 를 갖는지는 소스 어서션으로 고정한다(fix 를 되돌리면 소스 어서션 RED).
void main() {
  testWidgets(
    'Row[Expanded, SizedBox, FilledButton(minimumSize=0)] 는 앱 테마에서 크래시하지 않는다',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(child: TextField()),
                const SizedBox(width: AppSpacing.space2),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.buttonHeight),
                  ),
                  child: const Text('send'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  test(
    '_InputBar 전송 FilledButton 은 theme minimumSize=∞ 를 override 한다 (source)',
    () {
      final source =
          File(
            'lib/features/practice/presentation/widgets/teacher_feedback_sheet.dart',
          ).readAsStringSync();

      expect(
        source.contains('minimumSize: const Size(0, AppSpacing.buttonHeight)'),
        isTrue,
        reason:
            'Row 내 비-flex FilledButton 은 theme minimumSize=∞ 를 0 폭으로 override 해야 '
            'BoxConstraints(w=Infinity) 크래시를 막는다.',
      );
    },
  );
}
