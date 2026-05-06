import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../students/students_facade.dart';
import '../../../subscription/subscription_facade.dart';

part 'student_home_subscription_summary_provider.g.dart';

@riverpod
Future<List<StudentHomeSubscriptionSummaryItem>>
studentHomeSubscriptionSummaries(
  StudentHomeSubscriptionSummariesRef ref,
  String studentId,
) async {
  final memberships = await ref.watch(
    activeStudentMembershipsProvider(studentId).future,
  );
  final subscriptions = await ref.watch(
    activeStudentSubscriptionsProvider(studentId).future,
  );

  return Future.wait(
    memberships.map((membership) async {
      final subscription = subscriptions.firstWhere(
        (subscription) => subscription.membershipId == membership.id,
        orElse: () => _emptySubscription(studentId, membership.id),
      );

      String? className;
      try {
        final lessonClass = await ref.watch(
          lessonClassProvider(membership.lessonClassId).future,
        );
        className = lessonClass?.name;
      } catch (_) {
        className = null;
      }

      return StudentHomeSubscriptionSummaryItem(
        subscription: subscription,
        className: className,
        instrument: membership.instrument,
      );
    }),
  );
}

class StudentHomeSubscriptionSummaryItem {
  final Subscription subscription;
  final String? className;
  final String instrument;

  const StudentHomeSubscriptionSummaryItem({
    required this.subscription,
    required this.className,
    required this.instrument,
  });
}

Subscription _emptySubscription(String studentId, String membershipId) {
  return Subscription(
    id: '',
    studentId: studentId,
    membershipId: membershipId,
    type: SubscriptionType.monthly,
    amount: 0,
    status: SubscriptionStatus.expired,
    createdAt: DateTime.now(),
  );
}
