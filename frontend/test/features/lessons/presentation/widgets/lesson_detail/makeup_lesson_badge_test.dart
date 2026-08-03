import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_detail/makeup_lesson_badge.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

const _studentId = 'st1';

MakeupCredit _credit({required String id, String? usedLessonId}) =>
    MakeupCredit(
      id: id,
      studentId: _studentId,
      teacherId: 't1',
      reason: MakeupCreditReason.manualGrant,
      createdAt: DateTime(2026, 8, 1),
      expiresAt: DateTime(2126, 1, 1),
      usedAt: usedLessonId == null ? null : DateTime(2026, 8, 2),
      usedLessonId: usedLessonId,
    );

Future<void> _pump(
  WidgetTester tester, {
  required List<MakeupCredit> credits,
  String lessonId = 'l1',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teacherMakeupCreditsProvider(
          _studentId,
        ).overrideWith((ref) async => credits),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MakeupLessonBadge(lessonId: lessonId, studentId: _studentId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('크레딧이 이 레슨에 연결됨 → 보강 배지 표시 (§2.6.6 간접 표현)', (tester) async {
    await _pump(tester, credits: [_credit(id: 'c1', usedLessonId: 'l1')]);

    expect(find.text(AppStrings.lessonMakeupBadge), findsOneWidget);
  });

  testWidgets('다른 레슨에 연결된 크레딧 → 배지 없음', (tester) async {
    await _pump(tester, credits: [_credit(id: 'c1', usedLessonId: 'other')]);

    expect(find.text(AppStrings.lessonMakeupBadge), findsNothing);
  });

  testWidgets('크레딧 없음 → 배지 없음', (tester) async {
    await _pump(tester, credits: []);

    expect(find.text(AppStrings.lessonMakeupBadge), findsNothing);
  });
}
