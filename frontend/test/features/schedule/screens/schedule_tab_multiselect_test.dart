import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/data/repositories/mock_lesson_repository.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_crud_provider.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_repository_provider.dart';
import 'package:lessonaza/features/schedule/presentation/providers/schedule_tab_state_provider.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/schedule_tab.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_usage.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';

/// #768 ① — 스케줄 다중선택 → 일괄 완료(차감) 통합 흐름.
/// long-press 진입 → 전체 선택 → '2건 완료' → 확인 → 수강권 정확히 2회 차감.

const _studentId = 'stu_768b';
const _teacherId = 'teacher_1';

class _SpySubscriptionRepository extends MockSubscriptionRepository {
  int addUsageCount = 0;
  @override
  Future<SubscriptionUsage> addUsage(SubscriptionUsage usage) async {
    addUsageCount++;
    return usage;
  }
}

class _FakeLessonRepository extends MockLessonRepository {
  final List<LessonStatus> statusTransitions = [];

  @override
  Future<Lesson> updateLesson(Lesson lesson) async => lesson;

  @override
  Future<Lesson> updateLessonStatus(Lesson lesson, LessonStatus status) async {
    statusTransitions.add(status);
    return lesson.copyWith(status: status);
  }
  @override
  Future<List<Lesson>> getLessons() async => const [];
}

class _FixedSelectedDate extends TeacherSelectedDate {
  _FixedSelectedDate(this._date);
  final DateTime _date;
  @override
  DateTime build() => _date;
}

Subscription _activeSub() => Subscription(
  id: 'sub_768b',
  membershipId: 'mem_768b',
  studentId: _studentId,
  type: SubscriptionType.package,
  totalLessons: 10,
  usedLessons: 0,
  amount: 200000,
  startDate: DateTime(2026, 5, 1),
  endDate: DateTime(2026, 12, 1),
  status: SubscriptionStatus.active,
  createdAt: DateTime(2026, 5, 1),
);

void main() {
  late _FakeLessonRepository lessonRepo;

  setUp(() => lessonRepo = _FakeLessonRepository());

  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync().path);
  });

  final base = DateTime.now().add(const Duration(days: 2));
  final day = DateTime(base.year, base.month, base.day);

  List<Lesson> dayLessons() => [
    for (var i = 0; i < 2; i++)
      Lesson(
        id: 'lesson_768b_$i',
        studentId: _studentId,
        studentName: '학생 $i',
        teacherId: _teacherId,
        instrument: '바이올린',
        date: day,
        startTime: '1$i:00',
        status: LessonStatus.scheduled,
        subscriptionId: 'sub_768b',
        createdAt: DateTime(2026, 1, 1),
      ),
  ];

  Widget harness(_SpySubscriptionRepository spy) {
    return ProviderScope(
      overrides: [
        lessonsProvider.overrideWith((ref) async => dayLessons()),
        teacherSelectedDateProvider.overrideWith(() => _FixedSelectedDate(day)),
        lessonRepositoryProvider.overrideWithValue(lessonRepo),
        subscriptionRepositoryProvider.overrideWithValue(spy),
        activeStudentSubscriptionsProvider(
          _studentId,
        ).overrideWith((ref) async => [_activeSub()]),
        teacherUnifiedRequestsProvider(
          _teacherId,
        ).overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: ScheduleTab()),
      ),
    );
  }

  testWidgets('long-press 진입 → 전체 선택 → 일괄 완료 → 정확히 2회 차감', (tester) async {
    final spy = _SpySubscriptionRepository();
    await tester.pumpWidget(harness(spy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // 선택 모드 진입 전: 액션바 없음.
    expect(find.text(AppStrings.selectAllAction), findsNothing);

    // 첫 카드 long-press → 선택 모드 진입.
    await tester.longPress(
      find.byKey(const ValueKey('lesson-swipe-lesson_768b_0')),
    );
    await tester.pumpAndSettle();

    // 액션바 노출.
    expect(find.text(AppStrings.selectAllAction), findsOneWidget);

    // 전체 선택 → 2건.
    await tester.tap(find.text(AppStrings.selectAllAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.selectionCountLabel(2)), findsOneWidget);

    // '2건 완료' → 확인 다이얼로그 → '완료'.
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.batchSelectionComplete(2)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(TextButton, AppStrings.completeAction),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      lessonRepo.statusTransitions,
      List.filled(2, LessonStatus.completed),
      reason: '선택한 2건이 각 1회씩 정확히 2회 상태 전이돼야 한다',
    );
    expect(
      spy.addUsageCount,
      0,
      reason: '차감은 백엔드 상태 전이가 수행 (#1237)',
    );
    // 처리 후 선택 모드 종료(액션바 사라짐).
    expect(find.text(AppStrings.selectAllAction), findsNothing);
  });

  testWidgets('선택 액션바가 375px 에서 overflow 없이 렌더', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final spy = _SpySubscriptionRepository();
    await tester.pumpWidget(harness(spy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.longPress(
      find.byKey(const ValueKey('lesson-swipe-lesson_768b_0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.selectAllAction));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
