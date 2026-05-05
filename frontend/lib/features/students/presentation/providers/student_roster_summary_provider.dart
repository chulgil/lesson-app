import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../subscription/subscription_facade.dart';
import '../../domain/entities/class_membership.dart';
import '../../domain/entities/roster_summary.dart';
import 'membership_providers.dart';
import 'student_crud_provider.dart';

part 'student_roster_summary_provider.g.dart';

/// Derived summary for the enrollments tab triage banner + filters.
///
/// Aggregates per-student subscription + membership state into:
/// - expiringCount: active subs with endDate within 14 days
/// - unpaidCount: subs where Subscription.isUnpaid is true
/// - trialCount: memberships with MembershipStatus.trial
/// - archivedStudentIds: students whose active subs == 0 but had past subs
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §4.1
///
/// Performance: O(N students × M subs + K memberships). For typical teachers
/// (< 100 students), this is < 1000 operations — acceptable for a derived view.
@riverpod
Future<RosterSummary> studentRosterSummary(StudentRosterSummaryRef ref) async {
  final students = await ref.watch(studentsNotifierProvider.future);
  if (students.isEmpty) return RosterSummary.empty;

  const expiringWindowDays = 14;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final expiringIds = <String>{};
  final unpaidIds = <String>{};
  final trialIds = <String>{};
  final archivedIds = <String>{};

  for (final student in students) {
    final subscriptions = await ref.watch(
      studentSubscriptionsProvider(student.id).future,
    );
    final memberships = await ref.watch(
      studentMembershipsProvider(student.id).future,
    );

    // Trial: any membership in trial status
    final hasTrial = memberships.any((m) => m.status == MembershipStatus.trial);
    if (hasTrial) trialIds.add(student.id);

    // Unpaid: active postpaid subscription without a recorded student payment.
    final hasUnpaid = subscriptions.any((s) => s.isUnpaid);
    if (hasUnpaid) unpaidIds.add(student.id);

    // Expiring: any active sub with endDate within 14 days
    final hasExpiring = subscriptions.any(
      (s) => _isExpiringSoon(s, today, expiringWindowDays),
    );
    if (hasExpiring) expiringIds.add(student.id);

    // Archive: had past subs AND no currently active
    if (subscriptions.isNotEmpty) {
      final hasActive = subscriptions.any(
        (s) =>
            s.status == SubscriptionStatus.active ||
            s.status == SubscriptionStatus.expiringSoon,
      );
      if (!hasActive) archivedIds.add(student.id);
    }
  }

  return RosterSummary(
    expiringCount: expiringIds.length,
    unpaidCount: unpaidIds.length,
    trialCount: trialIds.length,
    expiringStudentIds: expiringIds,
    unpaidStudentIds: unpaidIds,
    trialStudentIds: trialIds,
    archivedStudentIds: archivedIds,
  );
}

bool _isExpiringSoon(Subscription sub, DateTime today, int windowDays) {
  if (sub.status != SubscriptionStatus.active &&
      sub.status != SubscriptionStatus.expiringSoon) {
    return false;
  }
  final endDate = sub.endDate;
  if (endDate == null) return false;
  final daysLeft = endDate.difference(today).inDays;
  return daysLeft >= 0 && daysLeft <= windowDays;
}
