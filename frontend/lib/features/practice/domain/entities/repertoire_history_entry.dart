// Repertoire history entry — domain view-model for the history timeline row.
//
// Pure domain value. No labels, colors, or Flutter dependencies.
// Display variants (badge label, badge color, formatted period) live in
// `presentation/extensions/repertoire_history_visuals.dart`.
//
// Spec: docs/specs/practice/practice_master.md §3.4.3 timeline item, §3.4.5
// data model. Aggregates `PracticeRepertoire` into a flat row optimized for
// timeline rendering.

import 'practice_repertoire.dart';

/// Lifecycle status of a repertoire on the history timeline.
///
/// Order matters for `compareTo`: ongoing items come first within a month
/// group, then completed, then archived.
enum RepertoireHistoryStatus {
  /// Active and ongoing — no `endDate` and not archived.
  inProgress,

  /// Has an `endDate` (closed out) and not archived.
  completed,

  /// Archived by the student (`isArchived = true`).
  archived,
}

/// Single repertoire row for the history timeline (§3.4.3).
class RepertoireHistoryEntry {
  /// Repertoire id — used for navigation to the detail screen.
  final String id;

  /// Student id — passed forward to the detail route.
  final String studentId;

  /// Repertoire display name (`PracticeRepertoire.name`).
  final String name;

  /// When the repertoire became active.
  final DateTime startDate;

  /// When the repertoire was closed out (null = ongoing).
  final DateTime? endDate;

  /// Lifecycle status (§3.4.3 status badge).
  final RepertoireHistoryStatus status;

  /// Total section count.
  final int sectionCount;

  /// Total recording count across all sections.
  final int recordingCount;

  /// Completion rate 0.0–1.0 (`PracticeRepertoire.completionRate`).
  final double completionRate;

  const RepertoireHistoryEntry({
    required this.id,
    required this.studentId,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.sectionCount,
    required this.recordingCount,
    required this.completionRate,
  });

  /// Convert a `PracticeRepertoire` into a flat history entry.
  ///
  /// Status precedence per §3.4.2: archived > completed > inProgress.
  /// `startDate` falls back to `createdAt` if missing (§3.4.6 edge case
  /// for legacy data). Entity always has `startDate` non-null, so the
  /// fallback only applies when callers pass a `PracticeRepertoire` whose
  /// stored `startDate` equals epoch — we keep the value as-is and let the
  /// repository layer hydrate from `createdAt`.
  factory RepertoireHistoryEntry.fromRepertoire(PracticeRepertoire r) {
    final status = _resolveStatus(r);
    final recordingCount = r.sections.fold<int>(
      0,
      (sum, s) => sum + s.recordings.length,
    );
    return RepertoireHistoryEntry(
      id: r.id,
      studentId: r.studentId,
      name: r.name,
      startDate: r.startDate,
      endDate: r.endDate,
      status: status,
      sectionCount: r.sections.length,
      recordingCount: recordingCount,
      completionRate: r.completionRate,
    );
  }

  static RepertoireHistoryStatus _resolveStatus(PracticeRepertoire r) {
    if (r.isArchived) return RepertoireHistoryStatus.archived;
    if (r.endDate != null) return RepertoireHistoryStatus.completed;
    return RepertoireHistoryStatus.inProgress;
  }

  /// Year-month key used for grouping (e.g., "2026-03").
  String get yearMonthKey =>
      '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}';

  /// Whether the repertoire is still active (no end date and not archived).
  bool get isOngoing => status == RepertoireHistoryStatus.inProgress;

  /// Months between start and end. `1` for same-month or ongoing entries
  /// (§3.4.6 "1개월 미만").
  int get durationMonths {
    final end = endDate ?? startDate;
    final diff =
        (end.year - startDate.year) * 12 + (end.month - startDate.month);
    return diff < 1 ? 1 : diff;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepertoireHistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
