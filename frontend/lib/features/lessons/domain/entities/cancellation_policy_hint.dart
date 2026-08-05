/// Deadline facts the server judges cancellations by (#1241).
///
/// The server owns the advance/late verdict; this is the same computation
/// surfaced early so the teacher sees the consequence before acting.
class CancellationPolicyHint {
  final int deadlineHours;
  final DateTime? deadlineAt;
  final bool isLateNow;

  /// False when no policy/override is configured — the server leaves the
  /// teacher's choice untouched, so no promise should be shown.
  final bool enforced;

  const CancellationPolicyHint({
    required this.deadlineHours,
    required this.deadlineAt,
    required this.isLateNow,
    required this.enforced,
  });

  factory CancellationPolicyHint.fromJson(Map<String, dynamic> json) {
    final rawDeadline = json['deadline_at'] as String?;
    return CancellationPolicyHint(
      deadlineHours: (json['deadline_hours'] as num?)?.toInt() ?? 0,
      deadlineAt: rawDeadline == null ? null : DateTime.tryParse(rawDeadline),
      isLateNow: json['is_late_now'] as bool? ?? false,
      enforced: json['enforced'] as bool? ?? false,
    );
  }
}
