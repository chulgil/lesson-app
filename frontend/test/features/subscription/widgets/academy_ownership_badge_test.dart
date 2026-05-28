import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_enums.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/academy_ownership_badge.dart';

void main() {
  group('AcademyOwnershipBadge', () {
    testWidgets('shows badge when subscription ownership is academy', (
      tester,
    ) async {
      final subscription = Subscription(
        id: 'sub-1',
        studentId: 'student-1',
        membershipId: 'member-1',
        type: SubscriptionType.package,
        totalLessons: 12,
        amount: 300000,
        status: SubscriptionStatus.active,
        createdAt: DateTime.now(),
        ownership: SubscriptionOwnership.academy,
        academyId: 'academy-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcademyOwnershipBadge(subscription: subscription),
          ),
        ),
      );

      expect(find.text(AppStrings.academyIssuedBadge), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides badge when subscription ownership is teacher', (
      tester,
    ) async {
      final subscription = Subscription(
        id: 'sub-2',
        studentId: 'student-2',
        membershipId: 'member-2',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        amount: 200000,
        status: SubscriptionStatus.active,
        createdAt: DateTime.now(),
        ownership: SubscriptionOwnership.teacher,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcademyOwnershipBadge(subscription: subscription),
          ),
        ),
      );

      expect(find.text(AppStrings.academyIssuedBadge), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides badge when ownership is null', (tester) async {
      final subscription = Subscription(
        id: 'sub-3',
        studentId: 'student-3',
        membershipId: 'member-3',
        type: SubscriptionType.trial,
        amount: 0,
        status: SubscriptionStatus.active,
        createdAt: DateTime.now(),
        ownership: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcademyOwnershipBadge(subscription: subscription),
          ),
        ),
      );

      expect(find.text(AppStrings.academyIssuedBadge), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
