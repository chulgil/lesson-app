import 'dart:io';

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
    'RED 가드: 앱 테마 FilledButton 은 기본 minWidth=∞ 이므로 trailing 버튼은 override 가 필요하다',
    (tester) async {
      final minimumSize = AppTheme.light.filledButtonTheme.style?.minimumSize
          ?.resolve(<WidgetState>{});

      expect(
        minimumSize?.width,
        double.infinity,
        reason: 'Row trailing 단독 버튼은 theme minimumSize 를 0 폭으로 override 해야 한다',
      );
    },
  );

  // 회귀 가드(#998 C2 이모지→IconData 전환 누락): _ClassGroupSection 헤더가
  // `'${widget.group.icon} ...'` 로 IconData 를 String 보간하면 IconData.toString()
  // ("IconData(U+0E3C5)") 이 그대로 렌더되어 "IconData(...) 미분류 (N)" 로 보였다.
  // group.icon 은 IconData 이므로 Icon 위젯으로 렌더해야 한다.
  test('그룹 헤더는 IconData(group.icon) 를 String 보간하지 않고 Icon 위젯으로 렌더한다', () {
    final source = File(
      'lib/features/students/presentation/screens/students_tab.dart',
    ).readAsStringSync();

    expect(
      source.contains(r'${widget.group.icon}'),
      isFalse,
      reason:
          'group.icon 은 IconData 이므로 String 보간 시 "IconData(...)" 가 그대로 렌더된다. '
          'Icon(widget.group.icon) 위젯으로 분리해야 한다.',
    );
    expect(
      RegExp(r'Icon\(\s*widget\.group\.icon').hasMatch(source),
      isTrue,
      reason: '그룹 헤더 아이콘은 Icon(widget.group.icon, ...) 위젯으로 렌더해야 한다.',
    );
  });
}
