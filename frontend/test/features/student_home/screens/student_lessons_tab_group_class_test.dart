import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/schedule/domain/entities/group_class.dart';
import 'package:lessonaza/features/schedule/presentation/providers/group_class_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_home_booking_provider.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_lessons_tab.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/student_group_class_card.dart';
import 'package:lessonaza/features/students/students_facade.dart';

/// J12 P1-2 — 학생 아젠다의 "등록된 반" 행.
///
/// 계약:
///   ① 선택한 날짜의 요일이 반의 반복 요일이면 행이 렌더된다
///   ② 반복 요일이 아니면 렌더되지 않는다 (탐색 슬롯이 아니라 아젠다다)
///   ③ 로스터에 없는 반은 어떤 요일에도 오지 않는다 (provider 가 등록분만 반환)
void main() {
  setUpAll(() {
    // StudentLessonSortType 이 build() 에서 Hive.openBox('settings') 를
    // fire-and-forget 으로 호출하므로 init 없이는 HiveError 가 발생한다.
    Hive.init(Directory.systemTemp.createTempSync().path);
  });

  const studentId = 'student-1';

  final fakeStudent = Student(
    id: studentId,
    name: '학생',
    instrument: '바이올린',
    createdAt: DateTime(2026),
  );

  const emptySchedule = StudentHomeLessonsSchedule(
    lessons: [],
    trialBookings: [],
    markerDates: {},
  );

  GroupClass buildClass({required int weekday, String name = '목요일 앙상블반'}) {
    return GroupClass(
      id: 'gc_$weekday',
      teacherId: 't1',
      name: name,
      type: GroupClassType.regular,
      maxCapacity: 4,
      durationMinutes: 60,
      repeatDaysOfWeek: [weekday],
      repeatTimeOfDay: '17:00',
      createdAt: DateTime(2026),
    );
  }

  Future<void> pumpTab(
    WidgetTester tester, {
    required List<GroupClass> enrolled,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentStudentProvider.overrideWith((ref) async => fakeStudent),
          studentHomeLessonsScheduleProvider(
            studentId,
          ).overrideWith((ref) async => emptySchedule),
          studentUnifiedRequestsProvider(
            studentId,
          ).overrideWith((ref) async => const []),
          studentGroupClassesProvider(
            studentId,
          ).overrideWith((ref) async => enrolled),
          studentNameMapProvider.overrideWithValue(const {}),
          teacherNameMapProvider.overrideWithValue(const {}),
          academyNameMapProvider.overrideWithValue(const {}),
        ],
        child: const MaterialApp(home: Scaffold(body: StudentLessonsTab())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('① 오늘 요일에 열리는 등록된 반은 아젠다 행으로 렌더된다', (tester) async {
    // 탭은 오늘 날짜로 시작한다 — 오늘 요일에 맞춘 반이 매칭 대상.
    final today = DateTime.now();

    await pumpTab(tester, enrolled: [buildClass(weekday: today.weekday)]);

    expect(find.byType(StudentGroupClassCard), findsOneWidget);
    expect(find.text('목요일 앙상블반'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('② 오늘이 반복 요일이 아니면 행이 렌더되지 않는다', (tester) async {
    // 오늘 다음 요일로 반복하는 반 — 오늘 아젠다에는 나오지 않아야 한다.
    final today = DateTime.now();
    final otherWeekday = today.weekday == 7 ? 1 : today.weekday + 1;

    await pumpTab(tester, enrolled: [buildClass(weekday: otherWeekday)]);

    expect(find.byType(StudentGroupClassCard), findsNothing);
    expect(find.text('목요일 앙상블반'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('③ 등록된 반이 없으면 아젠다에 반 행이 전혀 없다', (tester) async {
    await pumpTab(tester, enrolled: const []);

    expect(find.byType(StudentGroupClassCard), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
