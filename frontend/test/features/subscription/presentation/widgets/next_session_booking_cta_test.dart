import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/next_session_booking_cta.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

/// §8 (subscription_schedule_management_spec) — 미정 회차 CTA 노출 조건.
const _studentId = 'st1';
const _subId = 'sub1';

Subscription _sub({
  SubscriptionType type = SubscriptionType.package,
  int total = 8,
  int used = 2,
}) => Subscription(
  id: _subId,
  studentId: _studentId,
  membershipId: 'm1',
  type: type,
  totalLessons: total,
  usedLessons: used,
  amount: 320000,
  status: SubscriptionStatus.active,
  createdAt: DateTime(2026, 1, 1),
);

Lesson _lesson({
  required String id,
  String? subscriptionId = _subId,
  LessonStatus status = LessonStatus.scheduled,
  bool isPreview = false,
}) => Lesson(
  id: id,
  studentId: _studentId,
  studentName: '김민지',
  instrument: '바이올린',
  subscriptionId: subscriptionId,
  date: DateTime(2026, 9, 1),
  startTime: '14:00',
  duration: 60,
  status: status,
  isPreview: isPreview,
  createdAt: DateTime(2026, 8, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required Subscription subscription,
  required List<Lesson> lessons,
  ValueChanged<int>? onBook,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lessonsByStudentProvider(
          _studentId,
        ).overrideWith((ref) async => lessons),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: NextSessionBookingCta(
            subscription: subscription,
            onBook: onBook ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('미정 회차 존재: CTA 노출 + 다음 회차 번호 (死문자열 재사용)', (tester) async {
    // total 8, used 2 → remaining 6; scheduled 1 → 미정 5, 다음 회차 = 4
    int? booked;
    await _pump(
      tester,
      subscription: _sub(),
      lessons: [_lesson(id: 'l1')],
      onBook: (n) => booked = n,
    );

    expect(find.text(AppStrings.sessionBookingRequired(4)), findsOneWidget);

    await tester.tap(find.text(AppStrings.bookAction));
    expect(booked, 4);
  });

  testWidgets('스케줄이 잔여를 모두 채움: CTA 비노출', (tester) async {
    final scheduled = List.generate(6, (i) => _lesson(id: 'l$i'));
    await _pump(tester, subscription: _sub(), lessons: scheduled);

    expect(find.text(AppStrings.bookAction), findsNothing);
  });

  testWidgets('정규권(monthly): CTA 비노출 (주간 자동 생성)', (tester) async {
    await _pump(
      tester,
      subscription: _sub(type: SubscriptionType.monthly),
      lessons: const [],
    );

    expect(find.text(AppStrings.bookAction), findsNothing);
  });

  testWidgets('잔여 0: CTA 비노출', (tester) async {
    await _pump(
      tester,
      subscription: _sub(total: 8, used: 8),
      lessons: const [],
    );

    expect(find.text(AppStrings.bookAction), findsNothing);
  });

  testWidgets('preview 레슨은 슬롯을 차지하지 않는다 (§2.6.2)', (tester) async {
    // remaining 6, scheduled 1 real + 1 preview → 다음 회차 = 4 (preview 미포함)
    await _pump(
      tester,
      subscription: _sub(),
      lessons: [_lesson(id: 'l1'), _lesson(id: 'p1', isPreview: true)],
    );

    expect(find.text(AppStrings.sessionBookingRequired(4)), findsOneWidget);
  });

  testWidgets('타 수강권/완료 레슨은 카운트 제외', (tester) async {
    await _pump(
      tester,
      subscription: _sub(),
      lessons: [
        _lesson(id: 'l1', subscriptionId: 'other'),
        _lesson(id: 'l2', status: LessonStatus.completed),
      ],
    );

    // scheduled 0 → 다음 회차 = used(2) + 1 = 3
    expect(find.text(AppStrings.sessionBookingRequired(3)), findsOneWidget);
  });
}
