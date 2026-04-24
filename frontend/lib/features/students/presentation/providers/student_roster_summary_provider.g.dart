// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_roster_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentRosterSummaryHash() =>
    r'86c8834b358cc1197a24de15fe49b142c9abfb74';

/// Derived summary for the enrollments tab triage banner + filters.
///
/// Aggregates per-student subscription + membership state into:
/// - expiringCount: active subs with endDate within 14 days
/// - unpaidCount: subs where paymentConfirmed == false
/// - trialCount: memberships with MembershipStatus.trial
/// - archivedStudentIds: students whose active subs == 0 but had past subs
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §4.1
///
/// Performance: O(N students × M subs + K memberships). For typical teachers
/// (< 100 students), this is < 1000 operations — acceptable for a derived view.
///
/// Copied from [studentRosterSummary].
@ProviderFor(studentRosterSummary)
final studentRosterSummaryProvider =
    AutoDisposeFutureProvider<RosterSummary>.internal(
  studentRosterSummary,
  name: r'studentRosterSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentRosterSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StudentRosterSummaryRef = AutoDisposeFutureProviderRef<RosterSummary>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
