import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/chapter_guide_box.dart';

/// 회귀/스모크: ChapterGuideBox 가 어느 너비 환경에서도 BoxConstraints 크래시 없이
/// title chip + situation 텍스트를 렌더한다는 점을 확인.
///
/// 추출 배경: `_buildSystemGuide()` (request_history_chat.dart) 와
/// 스케줄 변경/일정 비교 흐름의 상단 가이드를 같은 시그니처로 통일.
void main() {
  Widget wrap(Widget child, {double width = 360}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    );
  }

  testWidgets('title 칩과 situation 텍스트가 모두 렌더된다', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ChapterGuideBox(
          title: '시간 변경 제안',
          situation: '대안 시간을 최대 3개까지 선택해 학생에게 제안해주세요',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('시간 변경 제안'), findsOneWidget);
    expect(find.text('대안 시간을 최대 3개까지 선택해 학생에게 제안해주세요'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
  });

  testWidgets('Column 안에 배치돼도 무한 폭 크래시가 발생하지 않는다', (tester) async {
    await tester.pumpWidget(
      wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ChapterGuideBox(title: '응답 대기 중', situation: '학생의 응답을 기다리고 있습니다'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('variant 가 wait/action 이어도 렌더 가능 (Phase 3 색상은 별도 작업)', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ChapterGuideBox(
              title: 'A',
              situation: 'a',
              variant: ChapterGuideVariant.action,
            ),
            SizedBox(height: 4),
            ChapterGuideBox(
              title: 'B',
              situation: 'b',
              variant: ChapterGuideVariant.wait,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ChapterGuideBox), findsNWidgets(2));
  });

  testWidgets('action variant 는 paperAccent 칩 배경, wait 는 ink alpha 회색', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const ChapterGuideBox(
          title: 'ACT',
          situation: 'a',
          variant: ChapterGuideVariant.action,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final actionChip =
        tester
                .widget<Container>(
                  find
                      .ancestor(
                        of: find.text('ACT'),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(actionChip.color, AppColors.paperAccent);

    await tester.pumpWidget(
      wrap(
        const ChapterGuideBox(
          title: 'WAIT',
          situation: 'w',
          variant: ChapterGuideVariant.wait,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final waitChip =
        tester
                .widget<Container>(
                  find
                      .ancestor(
                        of: find.text('WAIT'),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(waitChip.color, AppColors.ink.withValues(alpha: 0.12));
  });
}
