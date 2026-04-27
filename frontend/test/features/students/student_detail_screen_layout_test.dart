import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/theme/app_typography.dart';
import 'package:lessonaza/core/theme/notebook_typography.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_masthead.dart';
import 'package:lessonaza/core/widgets/notebook/thin_rule.dart';

/// 회귀 테스트: student_detail_screen.dart 의 Notebook × Score 레이아웃이
/// BoxConstraints/RenderMetaData 크래시 없이 렌더되는지 가드.
///
/// 보호 대상:
/// 1. NotebookMasthead + IconButton trailing (back + more) — RenderMetaData NEEDS-LAYOUT 회귀
/// 2. 신원 스트립 (모노그램 + 학생명 + 메타 라인) — Column 중첩 레이아웃
/// 3. DefaultTabController + 로마숫자 TabBar + TabBarView — 탭 전환 안정성
/// 4. "Fine." 푸터 + TextButton.icon — 하단 액션 바 BoxConstraints
void main() {
  testWidgets('학생 상세화면 헤더(NotebookMasthead + 신원 스트립 + 로마숫자 탭) 가 크래시 없이 렌더된다', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppColors.paper,
            body: SafeArea(
              child: Column(
                children: [
                  // 헤더: Masthead + 신원 스트립 + Roman tabs
                  ColoredBox(
                    color: AppColors.paper,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                          ),
                          child: NotebookMasthead(
                            eyebrow: 'STUDENT',
                            meta: '',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.arrow_back,
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
                                    Icons.more_vert,
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            AppSpacing.space5,
                            AppSpacing.screenPadding,
                            AppSpacing.space4,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.paper,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.ink,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '김',
                                  style: NotebookTypography.masthead.copyWith(
                                    fontSize: 28,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.space3),
                              Text(
                                '김민준',
                                style: NotebookTypography.masthead.copyWith(
                                  fontSize: 28,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '바이올린  ·  체험  ·  보통',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const ThinRule(),
                        TabBar(
                          indicatorColor: AppColors.ink,
                          indicatorWeight: 2,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelColor: AppColors.ink,
                          unselectedLabelColor: AppColors.inkTertiary,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'I.  정보'),
                            Tab(text: 'II.  레슨'),
                            Tab(text: 'III.  연습 현황'),
                          ],
                        ),
                        const ThinRule(),
                      ],
                    ),
                  ),
                  // 본문 placeholder
                  const Expanded(
                    child: TabBarView(
                      children: [
                        Center(child: Text('정보 탭')),
                        Center(child: Text('레슨 탭')),
                        Center(child: Text('연습 탭')),
                      ],
                    ),
                  ),
                  // Fine 푸터
                  ColoredBox(
                    color: AppColors.paper,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          const ThinRule(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenPadding,
                              vertical: AppSpacing.space2,
                            ),
                            child: Row(
                              children: [
                                Text('Fine.', style: NotebookTypography.fine),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.add,
                                    size: 18,
                                    color: AppColors.ink,
                                  ),
                                  label: const Text('레슨 추가'),
                                ),
                              ],
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
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('STUDENT'), findsOneWidget);
    expect(find.text('김민준'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.text('I.  정보'), findsOneWidget);
    expect(find.text('Fine.'), findsOneWidget);
    expect(find.text('레슨 추가'), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason:
          'Notebook × Score 학생 상세 헤더는 BoxConstraints / RenderMetaData '
          '크래시 없이 렌더되어야 한다',
    );
  });

  testWidgets('탭 전환 시 RenderObject 예외가 발생하지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppColors.paper,
            body: const SafeArea(
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: 'I.'),
                      Tab(text: 'II.'),
                      Tab(text: 'III.'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Center(child: Text('A')),
                        Center(child: Text('B')),
                        Center(child: Text('C')),
                      ],
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
    await tester.tap(find.text('II.'));
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    await tester.tap(find.text('III.'));
    await tester.pumpAndSettle();
    expect(find.text('C'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
