// R1 (audit 2026-07-10) — the "수강권 미등록" warning banner puts a FilledButton
// directly inside a Row. The theme's minimumSize=Size(∞,h) must be overridden
// or the banner crashes with BoxConstraints(w=Infinity) on render.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/students/domain/entities/class_membership.dart';
import 'package:lessonaza/features/students/presentation/providers/membership_providers.dart';
import 'package:lessonaza/features/students/presentation/widgets/student_detail/student_subscription_section.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';

void main() {
  const studentId = 'student_1';

  final membership = ClassMembership(
    id: 'membership_1',
    lessonClassId: 'class_1',
    studentId: studentId,
    instrument: '바이올린',
    status: MembershipStatus.active,
    monthlyFee: 200000,
    createdAt: DateTime(2026, 7, 1),
  );

  Widget buildSection() {
    return ProviderScope(
      overrides: [
        studentMembershipsProvider(
          studentId,
        ).overrideWith((ref) async => [membership]),
        studentSubscriptionsProvider(studentId).overrideWith((ref) async => []),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: StudentSubscriptionSection(studentId: studentId),
          ),
        ),
      ),
    );
  }

  testWidgets('수강권 미등록(멤버십 O, 수강권 X) 배너가 크래시 없이 렌더된다', (tester) async {
    await tester.pumpWidget(buildSection());
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason:
          'Row 직계 FilledButton 이 테마 minimumSize=∞ 를 상속하면 '
          'BoxConstraints(w=Infinity) 크래시 (R1)',
    );
    expect(find.byType(FilledButton), findsWidgets);
  });
}
