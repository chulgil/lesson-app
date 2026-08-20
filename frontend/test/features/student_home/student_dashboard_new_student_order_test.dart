import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/features/auth/presentation/providers/user_role_provider.dart';
import 'package:lessonaza/features/gamification/domain/entities/challenge.dart';
import 'package:lessonaza/features/gamification/domain/entities/quest_origin.dart';
import 'package:lessonaza/features/gamification/domain/entities/student_quest.dart';
import 'package:lessonaza/features/gamification/gamification_ui_facade.dart';
import 'package:lessonaza/features/gamification/presentation/providers/gamification_onboarding_dismissed_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/student_quest_provider.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/profile_facade.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_home_booking_provider.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_lesson_progress_provider.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_dashboard_tab.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/student_getting_started_card.dart';

/// UXC-9 — 선생님 연결도 레슨도 없는 학생은 시작 체크리스트를 상단에서 먼저
/// 보고, 채울 데이터가 없어 빈 껍데기로만 뜨는 게이미피케이션 섹션은 보지
/// 않는다. 연결된 학생의 기존 레이아웃은 그대로 유지된다.
StudentQuest _activeQuest(String studentId) {
  final today = DateTime(2026, 6, 12);
  return StudentQuest(
    id: 'q1',
    studentId: studentId,
    origin: QuestOrigin.systemRoutine,
    title: '스케일 5분',
    type: ActivityType.practiceMinutes,
    targetValue: 5,
    currentValue: 0,
    startDate: today,
    endDate: today.add(const Duration(days: 7)),
  );
}

Connection _connection(String studentId) => Connection(
  id: 'c1',
  teacherId: 'teacher_1',
  teacherName: '김선생',
  studentId: studentId,
  studentName: '학생',
  connectedAt: DateTime(2026, 6, 1),
);

class _FakeOnboardingDismissStore
    implements GamificationOnboardingDismissStore {
  @override
  Future<bool> isDismissed(String studentId) async => false;
  @override
  Future<void> markDismissed(String studentId) async {}
}

void main() {
  const studentId = 'student_1';

  // PracticeStartSection → studentRepertoiresProvider → mock 연습 repo 가 Hive
  // 박스를 연다 (student_dashboard_layout_test 와 동일한 이유).
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('student_dashboard_order_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required bool connected,
  }) async {
    await tester.binding.setSurfaceSize(const Size(375, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(studentId),
          studentLessonProgressProvider(
            studentId,
          ).overrideWith((ref) async => const []),
          // active quest 를 주입해 onboarding trigger 가 본문을 가로채지 않게 한다.
          activeQuestsProvider(
            studentId,
          ).overrideWith((ref) async => [_activeQuest(studentId)]),
          gamificationOnboardingDismissStoreProvider.overrideWithValue(
            _FakeOnboardingDismissStore(),
          ),
          mySentRequestsProvider.overrideWith((ref) async => const []),
          myConnectionsProvider.overrideWith(
            (ref) async => connected ? [_connection(studentId)] : const [],
          ),
          studentHomeHasAnyBookingProvider(
            studentId,
          ).overrideWith((ref) async => connected),
        ],
        child: const MaterialApp(home: Scaffold(body: StudentDashboardTab())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'unconnected student sees the checklist above practice sections',
    (tester) async {
      await pumpDashboard(tester, connected: false);

      expect(tester.takeException(), isNull);

      // 체크리스트가 보이고, 승격 전 위치(연습 섹션 아래)가 아니라 위에 있다.
      expect(find.byType(StudentGettingStartedCard), findsOneWidget);
      final checklistY =
          tester.getTopLeft(find.byType(StudentGettingStartedCard)).dy;
      final practiceY = tester.getTopLeft(find.byType(PracticeStartSection)).dy;
      expect(
        checklistY,
        lessThan(practiceY),
        reason:
            'getting-started card must be promoted above gamification/practice',
      );
    },
  );

  testWidgets('unconnected student does not see empty gamification shells', (
    tester,
  ) async {
    await pumpDashboard(tester, connected: false);

    expect(tester.takeException(), isNull);
    expect(find.byType(GoalProgressSummaryCard), findsNothing);
    expect(find.byType(DailyMissionsCard), findsNothing);
    expect(find.byType(GamificationHeader), findsNothing);
  });

  testWidgets('connected student keeps the full section list', (tester) async {
    await pumpDashboard(tester, connected: true);

    expect(tester.takeException(), isNull);
    expect(find.byType(GoalProgressSummaryCard), findsOneWidget);
    expect(find.byType(DailyMissionsCard), findsOneWidget);
    expect(find.byType(GamificationHeader), findsOneWidget);
    // 체크리스트는 승격되지 않고 원래 자리(게이미피케이션 아래)에 남는다.
    // 위젯 자체는 트리에 있고 모든 단계를 마치면 스스로 빈 렌더가 되므로,
    // 존재 여부가 아니라 순서로 검증한다.
    final checklistY = tester
        .getTopLeft(find.byType(StudentGettingStartedCard))
        .dy;
    final goalY = tester.getTopLeft(find.byType(GoalProgressSummaryCard)).dy;
    expect(
      checklistY,
      greaterThan(goalY),
      reason: 'established layout must keep its original section order',
    );
  });
}
