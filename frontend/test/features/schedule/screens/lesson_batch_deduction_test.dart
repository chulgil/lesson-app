import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/data/repositories/mock_lesson_repository.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_repository_provider.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_detail/lesson_batch_actions.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_usage.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';

/// #768 ① — 일괄 완료 차감 무결성: N건 완료 → 레슨당 정확히 1회 상태 전이,
/// 일괄 휴강 → 차감 0.
///
/// #1237 이후 완료 차감의 주체는 백엔드(`PATCH /lessons/{id}/status`)다 —
/// 클라이언트가 `addUsage` 를 함께 호출하면 이중 차감이 된다(멱등 가드 없음,
/// backend `test_completion_plus_manual_usage_double_deducts` 로 고정). 따라서
/// 이 테스트의 무결성 조건은 "상태 전이 N회 + addUsage 0회" 로 이동했다.

const _studentId = 'stu_768a';
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

  // Instant fetch — the mock's getLessons() has a 300ms delay that would leave
  // a pending timer when LessonsNotifier refreshes after updateLesson.
  @override
  Future<List<Lesson>> getLessons() async => const [];
}

Subscription _activeSub() => Subscription(
  id: 'sub_768a',
  membershipId: 'mem_768a',
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
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync().path);
  });

  final base = DateTime.now().add(const Duration(days: 2));
  final day = DateTime(base.year, base.month, base.day);

  List<Lesson> subscriptionLessons(int n) => [
    for (var i = 0; i < n; i++)
      Lesson(
        id: 'sub_lesson_768a_$i',
        studentId: _studentId,
        studentName: '학생 A',
        teacherId: _teacherId,
        instrument: '바이올린',
        date: day,
        startTime: '1$i:00',
        status: LessonStatus.scheduled,
        subscriptionId: 'sub_768a',
        createdAt: DateTime(2026, 1, 1),
      ),
  ];

  late _FakeLessonRepository lessonRepo;

  setUp(() => lessonRepo = _FakeLessonRepository());

  Widget harness(_SpySubscriptionRepository spy, Widget child) {
    return ProviderScope(
      overrides: [
        lessonRepositoryProvider.overrideWithValue(lessonRepo),
        subscriptionRepositoryProvider.overrideWithValue(spy),
        activeStudentSubscriptionsProvider(
          _studentId,
        ).overrideWith((ref) async => [_activeSub()]),
        teacherUnifiedRequestsProvider(
          _teacherId,
        ).overrideWith((ref) async => const []),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );
  }

  testWidgets('일괄 완료 3건 → 상태 전이 정확히 3회, 클라이언트 차감 0회', (tester) async {
    final spy = _SpySubscriptionRepository();
    final lessons = subscriptionLessons(3);

    await tester.pumpWidget(
      harness(
        spy,
        Scaffold(
          body: Builder(
            builder:
                (context) => Consumer(
                  builder:
                      (context, ref, _) => ElevatedButton(
                        onPressed:
                            () => batchConfirmAttendance(context, ref, lessons),
                        child: const Text('go'),
                      ),
                ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    // 일괄 완료 확인 다이얼로그의 '완료' 버튼 (notebook 액션 = TextButton).
    await tester.tap(
      find.widgetWithText(TextButton, AppStrings.completeAction),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      lessonRepo.statusTransitions,
      List.filled(3, LessonStatus.completed),
      reason: '일괄 완료 N건은 레슨당 1회씩 정확히 N회 상태 전이 (이중/누락 금지)',
    );
    expect(
      spy.addUsageCount,
      0,
      reason: '차감은 백엔드 상태 전이가 수행한다 — 클라이언트가 또 하면 이중 차감',
    );
  });

  testWidgets('일괄 휴강 3건 → 차감 0회', (tester) async {
    final spy = _SpySubscriptionRepository();
    final lessons = subscriptionLessons(3);

    await tester.pumpWidget(
      harness(
        spy,
        Scaffold(
          body: Builder(
            builder:
                (context) => Consumer(
                  builder:
                      (context, ref, _) => ElevatedButton(
                        onPressed: () => batchMarkDayOff(context, ref, lessons),
                        child: const Text('go'),
                      ),
                ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, AppStrings.confirm));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(spy.addUsageCount, 0, reason: '휴강은 수강권 차감이 없어야 한다');
  });
}
