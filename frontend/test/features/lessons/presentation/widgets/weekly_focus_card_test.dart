import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/weekly_focus_card.dart';

/// #1106 — 피드백 → 연습 연결.
/// "이번 주 집중" 카드가 학생에게 첫 keyPoint(폴백 practiceTips)를 보여주고
/// "지금 연습하기" CTA 로 연습 허브(/practice/repertoire)로 라우팅되는지 검증.
///
/// 라우팅 검증 패턴: 실제 GoRouter spy + 동기 (Future.delayed 없음).
Lesson _lesson({
  List<String>? keyPoints,
  String? practiceTips,
  String? feedback,
}) {
  return Lesson(
    id: 'l1',
    studentId: 's1',
    studentName: '민지',
    instrument: 'violin',
    date: DateTime(2026, 7, 1),
    startTime: '15:00',
    keyPoints: keyPoints,
    practiceTips: practiceTips,
    feedback: feedback,
    createdAt: DateTime(2026, 7, 1),
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pumpAndSettle();
}

void main() {
  group('WeeklyFocusCard', () {
    testWidgets('학생 뷰: 첫 keyPoint 를 집중 항목으로 노출', (tester) async {
      await _pump(
        tester,
        WeeklyFocusCard(
          lesson: _lesson(keyPoints: const ['활 무게 일정하게', '3번 손가락 음정']),
          isTeacher: false,
        ),
      );

      expect(find.text(AppStrings.weeklyFocusTitle), findsOneWidget);
      expect(find.text('활 무게 일정하게'), findsOneWidget);
      // 두 번째 항목은 노출하지 않는다 (한 가지에 집중).
      expect(find.text('3번 손가락 음정'), findsNothing);
      expect(find.text(AppStrings.weeklyFocusPracticeCta), findsOneWidget);
    });

    testWidgets('학생 뷰: keyPoints 비면 practiceTips 로 폴백', (tester) async {
      await _pump(
        tester,
        WeeklyFocusCard(
          lesson: _lesson(keyPoints: null, practiceTips: '매일 10분 스케일'),
          isTeacher: false,
        ),
      );

      expect(find.text('매일 10분 스케일'), findsOneWidget);
      expect(find.text(AppStrings.weeklyFocusTitle), findsOneWidget);
    });

    testWidgets('학생 뷰: keyPoints 와 practiceTips 모두 없으면 숨김', (tester) async {
      await _pump(
        tester,
        WeeklyFocusCard(
          lesson: _lesson(keyPoints: const [], practiceTips: null),
          isTeacher: false,
        ),
      );

      expect(find.text(AppStrings.weeklyFocusTitle), findsNothing);
      expect(find.text(AppStrings.weeklyFocusPracticeCta), findsNothing);
    });

    testWidgets('교사 뷰: 피드백이 있어도 카드 숨김', (tester) async {
      await _pump(
        tester,
        WeeklyFocusCard(
          lesson: _lesson(keyPoints: const ['활 무게 일정하게']),
          isTeacher: true,
        ),
      );

      expect(find.text(AppStrings.weeklyFocusTitle), findsNothing);
      expect(find.text('활 무게 일정하게'), findsNothing);
    });

    testWidgets('CTA 탭 → /practice/repertoire 라우팅 (spy mock + 동기)', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: WeeklyFocusCard(
                lesson: _lesson(keyPoints: const ['활 무게 일정하게']),
                isTeacher: false,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.practiceRepertoire,
            builder: (context, state) => const Scaffold(
              body: Text(
                'PRACTICE_HUB_TARGET',
                key: ValueKey('practice_hub_target'),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.weeklyFocusPracticeCta));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('practice_hub_target')),
        findsOneWidget,
        reason: '지금 연습하기 탭 → /practice/repertoire 라우팅 (spy mock)',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('smoke: 좁은 제약 컨텍스트에서 렌더 예외 없음', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: WeeklyFocusCard(
                    lesson: _lesson(
                      keyPoints: const ['활 무게를 일정하게 유지하면서 긴 프레이즈를 한 호흡으로 연결하기'],
                    ),
                    isTeacher: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
