import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_theme.dart';

/// Regression guard (2026-07-08 FE audit B3).
///
/// recording_comparison_sheet.dart 의 "둘 다 재생" ElevatedButton.icon 은
/// Row(mainAxisAlignment.center) 의 유일 자식이라 loose(0..∞) 폭을 받는데,
/// 앱 테마가 ElevatedButton.minimumSize = Size(∞, 48) 을 강제해 비교 뷰(_step==2)
/// 진입 시 "BoxConstraints forces an infinite width" 로 크래시했다.
/// 수정: styleFrom(minimumSize: Size(0, buttonHeight)) override.
///
/// _RecordingComparisonSheet 는 private + AudioPlayer(플랫폼 채널) 의존이라 실제 pump
/// 가 취약하므로, 크래시를 유발하는 순수 레이아웃을 동일 구조로 재현해 검증하고,
/// 실제 위젯이 override 를 갖는지는 소스 어서션으로 고정한다(fix 를 되돌리면 소스 어서션 RED).
void main() {
  testWidgets(
    'Row(center)[ElevatedButton.icon(minimumSize=0)] 는 앱 테마에서 크래시하지 않는다',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('play'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.buttonHeight),
                  ),
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

  test('둘 다 재생 ElevatedButton 은 theme minimumSize=∞ 를 override 한다 (source)', () {
    final source =
        File(
          'lib/features/practice/presentation/widgets/recording_comparison_sheet.dart',
        ).readAsStringSync();

    expect(
      source.contains('minimumSize: const Size(0, AppSpacing.buttonHeight)'),
      isTrue,
      reason:
          'Row(center) 내 ElevatedButton 은 theme minimumSize=∞ 를 0 폭으로 override 해야 '
          'BoxConstraints(w=Infinity) 크래시를 막는다.',
    );
  });
}
