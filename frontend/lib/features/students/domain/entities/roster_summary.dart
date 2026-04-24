/// Triage summary for the enrollments tab.
///
/// Aggregates counts + student ID sets for the 3 triage categories
/// (expiring, unpaid, trial) and archive.
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §4.1
class RosterSummary {
  final int expiringCount;
  final int unpaidCount;
  final int trialCount;

  final Set<String> expiringStudentIds;
  final Set<String> unpaidStudentIds;
  final Set<String> trialStudentIds;
  final Set<String> archivedStudentIds;

  const RosterSummary({
    required this.expiringCount,
    required this.unpaidCount,
    required this.trialCount,
    required this.expiringStudentIds,
    required this.unpaidStudentIds,
    required this.trialStudentIds,
    required this.archivedStudentIds,
  });

  static const empty = RosterSummary(
    expiringCount: 0,
    unpaidCount: 0,
    trialCount: 0,
    expiringStudentIds: {},
    unpaidStudentIds: {},
    trialStudentIds: {},
    archivedStudentIds: {},
  );
}
