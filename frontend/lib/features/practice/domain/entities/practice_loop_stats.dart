/// Aggregated per-section repeat counts for the teacher dashboard (#512).
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4 (선생님 통계).
///
/// One row per (student, section) pair. ``repeatCount`` is the cumulative
/// total the student has played for that section across all sessions.
class PracticeLoopStats {
  /// Backend row id.
  final String id;

  /// Student profile id (NOT the user id — these come from the server).
  final String studentId;

  /// Teacher profile id (owner of the student).
  final String teacherId;

  /// Practice section id this row aggregates.
  final String sectionId;

  /// Cumulative repeat count reported by the client.
  final int repeatCount;

  /// Latest known play time across all syncs.
  final DateTime lastPlayedAt;

  /// Piece label hydrated by the server when available (UI sugar).
  final String? pieceName;

  /// Section label hydrated by the server when available (UI sugar).
  final String? sectionName;

  const PracticeLoopStats({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.sectionId,
    required this.repeatCount,
    required this.lastPlayedAt,
    this.pieceName,
    this.sectionName,
  });
}

/// Roll-up of one student's repeats for the dashboard summary card.
class StudentRepeatStats {
  final String studentId;
  final String? studentName;
  final int totalRepeats;
  final DateTime? lastPlayedAt;

  const StudentRepeatStats({
    required this.studentId,
    required this.totalRepeats,
    this.studentName,
    this.lastPlayedAt,
  });
}

/// Time-window toggle for the teacher view. Spec §4.3.
enum PracticeLoopStatsWindow {
  weekly,
  monthly;

  /// Wire value sent to the backend (`?window=...`).
  String get wireName => switch (this) {
    PracticeLoopStatsWindow.weekly => 'weekly',
    PracticeLoopStatsWindow.monthly => 'monthly',
  };
}

/// Server-side outcome of a sync request — exposed for instrumentation/tests.
class PracticeLoopStatsSyncResult {
  final int upserted;
  final int skipped;
  final int rejected;

  const PracticeLoopStatsSyncResult({
    this.upserted = 0,
    this.skipped = 0,
    this.rejected = 0,
  });

  /// Convenience flag for the offline-queue retry path.
  bool get hadAnyServerWrites => upserted > 0;
}

/// Pending sync entry persisted in the offline Hive queue.
///
/// The queue is flushed at session end or when connectivity returns; the
/// server treats the upload as idempotent so re-flush is safe.
class PendingLoopStatsSync {
  final String sectionId;
  final int repeatCount;
  final DateTime lastPlayedAt;

  const PendingLoopStatsSync({
    required this.sectionId,
    required this.repeatCount,
    required this.lastPlayedAt,
  });

  Map<String, dynamic> toJson() => {
    'sectionId': sectionId,
    'repeatCount': repeatCount,
    'lastPlayedAt': lastPlayedAt.toIso8601String(),
  };

  static PendingLoopStatsSync fromJson(Map<String, dynamic> json) {
    return PendingLoopStatsSync(
      sectionId: json['sectionId'] as String,
      repeatCount: json['repeatCount'] as int,
      lastPlayedAt: DateTime.parse(json['lastPlayedAt'] as String),
    );
  }
}
