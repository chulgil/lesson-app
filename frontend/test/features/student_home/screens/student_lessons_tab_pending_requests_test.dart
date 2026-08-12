import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/request_list_item.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_home_booking_provider.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_lessons_tab.dart';
import 'package:lessonaza/features/students/students_facade.dart';

/// P1 — 학생의 대기중(pending)/협상중 레슨 신청이 "레슨" 탭에 보이지 않고
/// 프로필 탭 뒤에 숨어 있던 문제(진입 경로 감사)를 고쳐, 레슨 탭 상단에
/// "진행 중인 신청" 섹션을 노출한다.
void main() {
  setUpAll(() {
    // StudentLessonSortType 가 build() 에서 Hive.openBox('settings') 를
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

  UnifiedLessonRequest makePendingRequest(String id, {DateTime? createdAt}) {
    return UnifiedLessonRequest(
      id: id,
      studentId: studentId,
      teacherId: 't1',
      type: LessonRequestType.regular,
      instrument: '바이올린',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      status: UnifiedRequestStatus.pending,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  testWidgets('대기중인 레슨 신청이 있으면 섹션이 렌더되고 탭하면 상세로 이동한다 (spy-mock router)', (
    tester,
  ) async {
    final pending = makePendingRequest('r1');

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) => const Scaffold(body: StudentLessonsTab()),
        ),
        GoRoute(
          path: AppRoutes.requestDetail,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return Scaffold(
              body: Text(
                'REQUEST_DETAIL_TARGET:$id',
                key: const ValueKey('request_detail_target'),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentStudentProvider.overrideWith((ref) async => fakeStudent),
          studentHomeLessonsScheduleProvider(
            studentId,
          ).overrideWith((ref) async => emptySchedule),
          studentUnifiedRequestsProvider(
            studentId,
          ).overrideWith((ref) async => [pending]),
          studentNameMapProvider.overrideWithValue(const {}),
          teacherNameMapProvider.overrideWithValue(const {}),
          academyNameMapProvider.overrideWithValue(const {}),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // "진행 중인 신청" section header + count is rendered, along with the row.
    expect(
      find.textContaining(AppStrings.studentHomePendingRequestsTitle),
      findsOneWidget,
    );
    expect(find.byType(RequestListItem), findsOneWidget);

    // Tap the pending request row → navigates to request detail.
    await tester.tap(find.byType(RequestListItem));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('request_detail_target')), findsOneWidget);
    expect(find.text('REQUEST_DETAIL_TARGET:r1'), findsOneWidget);
  });

  testWidgets('대기중인 레슨 신청이 하나도 없으면 섹션이 렌더되지 않는다 (빈 상태 노이즈 없음)', (tester) async {
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
          studentNameMapProvider.overrideWithValue(const {}),
          teacherNameMapProvider.overrideWithValue(const {}),
          academyNameMapProvider.overrideWithValue(const {}),
        ],
        child: const MaterialApp(home: Scaffold(body: StudentLessonsTab())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(AppStrings.studentHomePendingRequestsTitle),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
