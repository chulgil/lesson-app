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

/// #767 — 레슨 완료=출석 확정 단일화 (차감 무결성) 회귀 가드.
///
/// 스케줄 탭 스와이프 '완료'(좌→우)가 plain `updateLesson(completed)` 만 호출해
/// 수강권 차감(add_usage)을 누락하던 버그. 출석 확인 플로우(confirmAttendance →
/// confirmLessonCompleted)로 라우팅해 수강권 레슨 완료 시 1회 차감이 발생해야 한다.

const _studentId = 'stu_767';
const _teacherId = 'teacher_1';
const _lessonId = 'sub_lesson_767';

/// addUsage 호출 횟수만 카운트하는 스파이.
class _SpySubscriptionRepository extends MockSubscriptionRepository {
  int addUsageCount = 0;
  @override
  Future<SubscriptionUsage> addUsage(SubscriptionUsage usage) async {
    addUsageCount++;
    return usage;
  }
}

/// updateLesson 을 no-op 으로 두어 in-memory 시드에 없는 테스트 레슨도
/// "not found" 없이 완료되도록(양 경로 모두 lessonRepositoryProvider 사용).
class _FakeLessonRepository extends MockLessonRepository {
  @override
  Future<Lesson> updateLesson(Lesson lesson) async => lesson;
}

class _FixedSelectedDate extends TeacherSelectedDate {
  _FixedSelectedDate(this._date);
  final DateTime _date;
  @override
  DateTime build() => _date;
}

Subscription _activeSub() => Subscription(
  id: 'sub_767',
  membershipId: 'mem_767',
  studentId: _studentId,
  type: SubscriptionType.package,
  totalLessons: 4,
  usedLessons: 1,
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

  // 미래일 고정 — displayStatus 가 scheduled 로 남아 스와이프 카드가 렌더되도록.
  final base = DateTime.now().add(const Duration(days: 2));
  final day = DateTime(base.year, base.month, base.day);

  Lesson subscriptionLesson() => Lesson(
    id: _lessonId,
    studentId: _studentId,
    studentName: '학생 A',
    teacherId: _teacherId,
    instrument: '바이올린',
    date: day,
    startTime: '10:00',
    status: LessonStatus.scheduled,
    subscriptionId: 'sub_767',
    createdAt: DateTime(2026, 1, 1),
  );

  testWidgets('수강권 레슨 스와이프 완료 → 수강권 1회 차감(add_usage) 발생', (tester) async {
    final spy = _SpySubscriptionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonsProvider.overrideWith((ref) async => [subscriptionLesson()]),
          teacherSelectedDateProvider.overrideWith(
            () => _FixedSelectedDate(day),
          ),
          lessonRepositoryProvider.overrideWithValue(_FakeLessonRepository()),
          subscriptionRepositoryProvider.overrideWithValue(spy),
          activeStudentSubscriptionsProvider(
            _studentId,
          ).overrideWith((ref) async => [_activeSub()]),
          // RequestEvent 기록 체인 차단(비핵심).
          teacherUnifiedRequestsProvider(
            _teacherId,
          ).overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ScheduleTab()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final card = find.byKey(const ValueKey('lesson-swipe-$_lessonId'));
    expect(card, findsOneWidget);

    // 좌→우(startToEnd) = 완료 스와이프.
    await tester.drag(card, const Offset(600, 0));
    await tester.pumpAndSettle();

    // 완료/출석 확인 다이얼로그의 confirm 버튼('완료') 탭.
    // (스와이프 배경 라벨과 구분 위해 TextButton 으로 한정 — notebook 다이얼로그
    //  액션은 TextButton.)
    await tester.tap(
      find.widgetWithText(TextButton, AppStrings.statusCompleted),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      spy.addUsageCount,
      1,
      reason:
          '수강권 레슨 완료는 출석 확인 플로우(confirmLessonCompleted)로 라우팅돼 '
          '수강권 1회 차감(add_usage)이 발생해야 한다 (#767)',
    );
  });
}
