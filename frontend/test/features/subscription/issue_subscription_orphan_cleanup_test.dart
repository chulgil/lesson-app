import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/relationship/data/repositories/mock_teacher_student_relation_repository.dart';
import 'package:lessonaza/features/relationship/domain/entities/teacher_student_relation.dart';
import 'package:lessonaza/features/relationship/presentation/providers/relationship_providers.dart';
import 'package:lessonaza/features/students/domain/entities/class_membership.dart';
import 'package:lessonaza/features/students/domain/entities/lesson_class.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/presentation/providers/lesson_class_providers.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_issue_flow_provider.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/issue_subscription_screen.dart';

/// Records ids handed back by create() and any id that gets expired, so a test
/// can assert orphan cleanup runs on a post-create failure.
class _RecordingSubscriptionRepository extends MockSubscriptionRepository {
  final List<String> createdIds = [];
  final List<String> expiredIds = [];

  @override
  Future<Subscription> create(Subscription subscription) async {
    final created = await super.create(subscription);
    createdIds.add(created.id);
    return created;
  }

  @override
  Future<void> updateStatus(String id, SubscriptionStatus status) async {
    if (status == SubscriptionStatus.expired) expiredIds.add(id);
    await super.updateStatus(id, status);
  }
}

/// Relation repo whose post-create wiring step always fails, simulating a
/// transient backend error after the subscription was persisted.
class _ThrowingRelationRepository extends MockTeacherStudentRelationRepository {
  @override
  Future<TeacherStudentRelation> onSubscriptionIssued({
    required String teacherId,
    required String studentId,
    required String subscriptionId,
  }) async {
    throw Exception('relation activation failed');
  }
}

Student _student() => Student(
      id: 'student-1',
      name: 'Test Student',
      instrument: 'piano',
      createdAt: DateTime(2026, 1, 1),
    );

ClassMembership _membership() => ClassMembership(
      id: 'membership-1',
      lessonClassId: 'class-1',
      studentId: 'student-1',
      instrument: 'piano',
      status: MembershipStatus.active,
      monthlyFee: 100000,
      createdAt: DateTime(2026, 1, 1),
    );

LessonClass _lessonClass() => LessonClass(
      id: 'class-1',
      teacherId: 'teacher-1',
      name: 'Private',
      type: LessonClassType.private,
      paymentType: PaymentType.parent,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  testWidgets(
    'single issue deactivates the orphan when post-create wiring fails',
    (tester) async {
      final subRepo = _RecordingSubscriptionRepository();
      final relationRepo = _ThrowingRelationRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(subRepo),
            teacherStudentRelationRepositoryProvider
                .overrideWithValue(relationRepo),
            subscriptionIssueStudentProvider('student-1')
                .overrideWith((ref) async => _student()),
            subscriptionIssueMembershipsProvider('student-1')
                .overrideWith((ref) async => [_membership()]),
            lessonClassProvider('class-1')
                .overrideWith((ref) async => _lessonClass()),
          ],
          child: const MaterialApp(
            home: IssueSubscriptionScreen(
              studentIds: ['student-1'],
              membershipId: 'membership-1',
            ),
          ),
        ),
      );
      // Bounded pumps — pumpAndSettle can hang on persistent indicators.
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Realize and fill the required amount field, then submit.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final amountField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText == AppStrings.issueFormAmountHint,
      );
      expect(amountField, findsOneWidget);
      await tester.enterText(amountField, '100000');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // The subscription was created, the relation step threw, so the created
      // subscription must be expired (orphan cleanup), not left dangling active.
      expect(subRepo.createdIds.length, 1);
      expect(subRepo.expiredIds, subRepo.createdIds,
          reason: 'the created subscription must be deactivated on failure');
    },
  );
}
