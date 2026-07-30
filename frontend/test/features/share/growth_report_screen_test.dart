// #1217 — GrowthReportScreen widget smoke test (ux-rules HARD-GATE).
//
// 무가입 자녀 성장 리포트 프리뷰 — 인증 없이 렌더링되는 읽기전용 화면.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/share/presentation/screens/growth_report_screen.dart';

void main() {
  testWidgets('renders loaded growth report from share token without auth', (
    tester,
  ) async {
    const token = 'sample-growth-report-token-abc123';

    await tester.pumpWidget(
      MaterialApp(
        home: GrowthReportScreen(
          token: token,
          loader: (_) async => const PublicGrowthReportViewData(
            givenName: '지선',
            instrument: 'violin',
            practiceStreakDays: 5,
            recentLessonCount: 3,
            progressSummary: '최근 30일 레슨 3회 · 연속 연습 5일째',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('지선'), findsOneWidget);
    expect(find.text('violin'), findsOneWidget);
    expect(find.text('5일'), findsOneWidget);
    expect(find.text('3회'), findsOneWidget);
    expect(find.text('최근 30일 레슨 3회 · 연속 연습 5일째'), findsOneWidget);
  });

  testWidgets('handles empty token gracefully without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GrowthReportScreen(
          token: '',
          loader: (_) async => throw StateError('should not load'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('handles loader error (expired/unknown token) gracefully', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GrowthReportScreen(
          token: 'expired-token',
          loader: (_) async => throw Exception('404'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
