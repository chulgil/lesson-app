import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_masthead.dart';

/// 회귀 테스트: NotebookMasthead 가 IconButton 트레일링을 받았을 때
/// `RenderBox was not laid out: RenderMetaData NEEDS-LAYOUT` 크래시를 일으켰던 버그.
///
/// 원인: 외부 Row 가 `crossAxisAlignment: CrossAxisAlignment.baseline` 을 사용하면
/// 모든 자식이 텍스트 baseline 을 노출해야 한다. IconButton 은 Material/InkResponse/
/// Tooltip 으로 감싸져 있어 baseline 이 없고, 결과적으로 RenderMetaData 가
/// layout 을 마치지 못한다.
///
/// 수정: trailing 이 제공되면 baseline 대신 center 정렬 사용.
void main() {
  testWidgets('IconButton 트레일링 + 텍스트 eyebrow 조합이 baseline 크래시 없이 렌더된다', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: NotebookMasthead(
              eyebrow: 'LESSONAZA',
              meta: 'VOL. 4 · NO. 27',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.person_add_outlined,
                      color: AppColors.ink,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.ink,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('LESSONAZA'), findsOneWidget);
    expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason:
          'IconButton trailing 환경에서 baseline 정렬을 강제하면 '
          'RenderMetaData NEEDS-LAYOUT 크래시가 발생해야 한다',
    );
  });

  testWidgets('text-only meta 조합은 baseline 정렬을 유지한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: NotebookMasthead(
            eyebrow: 'LESSONAZA',
            meta: 'VOL. IV · NO. 27 · APR MMXXVI',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('LESSONAZA'), findsOneWidget);
    expect(find.text('VOL. IV · NO. 27 · APR MMXXVI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
