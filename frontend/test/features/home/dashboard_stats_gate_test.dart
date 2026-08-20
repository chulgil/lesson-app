// UXC-6 (2026-08-20) — 통계 카드 점진 공개 회귀 테스트.
//
// 학생도 레슨도 없는 첫 홈에서는 "이번 달" StatCard 를 숨긴다. 이 카드는
// Pro 잠금 analytics 화면의 유일한 진입점(#749)이라, 아직 아무것도 못 해본
// 선생님에게는 0으로 채워진 카드 + 유료 잠금만 남는다.
//
// 핵심 계약: 숨김은 영구 제거가 아니다 — 학생이나 레슨이 하나라도 생기면
// 다시 나타나야 한다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/stat_card.dart';
import 'package:lessonaza/features/home/presentation/providers/assignment_summary_provider.dart';
import 'package:lessonaza/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:lessonaza/features/home/presentation/providers/home_lesson_summary_provider.dart';
import 'package:lessonaza/features/home/presentation/widgets/dashboard_tab.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';

Lesson _lesson() => Lesson(
  id: 'l1',
  studentId: 's1',
  studentName: '학생',
  instrument: '피아노',
  date: DateTime(2026, 8, 20),
  startTime: '10:00',
  createdAt: DateTime.utc(2026, 8, 1),
);

Student _student() => Student(
  id: 's1',
  name: '학생',
  instrument: '피아노',
  createdAt: DateTime.utc(2026, 5, 1),
);

HomeDashboardData _dashboard({required List<Lesson> lessons}) {
  return HomeDashboardData(
    lessons: AsyncData(lessons),
    lessonStats: const AsyncData({'completed': 0}),
    teacherId: 't1',
    unpaidSummary: const AsyncData((studentCount: 0, totalAmount: 0)),
    needsConfirmation: const AsyncData([]),
  );
}

Future<void> _pumpTab(
  WidgetTester tester, {
  required List<Student> students,
  required List<Lesson> lessons,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeDashboardProvider.overrideWithValue(_dashboard(lessons: lessons)),
        homeStudentsProvider.overrideWith((ref) async => students),
        // mock 연습 repo 의 150ms 지연 Future 가 teardown 까지 남아
        // "Timer is still pending" 로 터진다 — 요약을 값으로 고정한다.
        weeklyAssignmentSummaryProvider.overrideWith(
          (ref) async => const WeeklyAssignmentSummary(
            totalItems: 0,
            completedItems: 0,
            incompleteStudents: [],
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: DashboardTab(onViewAllLessons: () {})),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // mock repo 들이 150ms 지연 Future 를 만든다 — 위젯 트리 폐기 전에 배수.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  // DashboardTab 하위의 mock 연습/온보딩 repo 가 Hive 박스를 연다.
  // 초기화 없이는 HiveError 로 렌더가 중단된다.
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('dashboard_stats_gate_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('학생 0 + 레슨 0 → 이번 달 통계 카드 숨김', (tester) async {
    await _pumpTab(tester, students: [], lessons: []);

    expect(find.text(AppStrings.dashboardThisMonth), findsNothing);
    expect(find.byType(StatCard), findsNothing);
  });

  testWidgets('학생이 생기면 통계 카드 재노출 (영구 제거 아님)', (tester) async {
    await _pumpTab(tester, students: [_student()], lessons: []);

    expect(find.text(AppStrings.dashboardThisMonth), findsOneWidget);
  });

  testWidgets('레슨이 생기면 통계 카드 재노출', (tester) async {
    await _pumpTab(tester, students: [], lessons: [_lesson()]);

    expect(find.text(AppStrings.dashboardThisMonth), findsOneWidget);
  });
}
