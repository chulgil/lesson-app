/// Result of a bulk lesson cancellation (§7.119 B1).
///
/// Returned by [BulkTeacherActionService.cancelLessonsOnDate].
/// Exposes counts so the UI can render a result dialog with evidence
/// (e.g. "3명 휴강 처리 / 1명은 해당 날짜 레슨 없음").
class BulkCancelResult {
  /// Number of lessons whose status was updated to [LessonStatus.cancelledByTeacher].
  final int cancelledLessonCount;

  /// Number of distinct students who received a cancellation notification.
  final int notifiedStudentCount;

  /// Student IDs that had no lesson on the target date (no cancellation fired).
  final List<String> skippedStudentIds;

  const BulkCancelResult({
    required this.cancelledLessonCount,
    required this.notifiedStudentCount,
    required this.skippedStudentIds,
  });

  bool get hasSkipped => skippedStudentIds.isNotEmpty;
}
