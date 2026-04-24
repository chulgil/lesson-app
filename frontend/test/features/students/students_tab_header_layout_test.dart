import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_theme.dart';

/// 회귀 테스트: students_tab.dart _buildHeader 의 "학생 추가" FilledButton 이
/// 앱 테마의 `FilledButton.minimumSize = Size(∞, 48)` 과 충돌해
/// BoxConstraints(w=Infinity) 크래시를 일으켰던 버그에 대한 가드.
///
/// 원 증상: Row(mainAxisAlignment: end, children: [FilledButton.icon]) 단독 배치시
/// Row 가 자식에 loose (0..∞) 제약을 주는데 테마가 minWidth=∞ 를 강제해 invalid.
///
/// 수정: Align + FilledButton.styleFrom(minimumSize: Size(0, buttonHeight)) 로 override.
void main() {
  testWidgets(
    '테마 FilledButton minimumSize=Size(∞, h) 환경에서 컴팩트 trailing 버튼이 크래시하지 않는다',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // _buildHeader 의 action row 와 동일 구조.
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.space2,
                            bottom: AppSpacing.space2,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text('학생 추가'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(
                                  0,
                                  AppSpacing.buttonHeight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.space4,
                                  vertical: AppSpacing.space2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('학생 추가'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'RED 가드: 테마 minWidth=∞ 상태에서 Row+end 단독 FilledButton 은 크래시한다 (회귀 감지용)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 의도적으로 버그 구조 — minimumSize override 없음 + Row end.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text('학생 추가'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isNotNull,
        reason: '테마 minWidth=∞ × Row loose 제약은 반드시 layout exception 을 내야 한다',
      );
    },
  );
}
