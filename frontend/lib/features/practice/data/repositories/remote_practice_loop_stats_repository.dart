import '../../../../core/network/api_client.dart';
import '../../domain/entities/practice_loop_stats.dart';
import '../../domain/repositories/practice_loop_stats_repository.dart';

/// REST client for practice loop stats endpoints (#512).
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4/§5.
class RemotePracticeLoopStatsRepository implements PracticeLoopStatsRepository {
  final ApiClient _apiClient;

  RemotePracticeLoopStatsRepository(this._apiClient);

  @override
  Future<({int totalRepeats, List<PracticeLoopStats> rows})> listForStudent({
    required String studentId,
    required PracticeLoopStatsWindow window,
  }) async {
    final response = await _apiClient.get(
      '/teachers/me/practice-loop-stats/students/$studentId',
      queryParameters: {'window': window.wireName},
    );
    final data = response.data as Map<String, dynamic>;
    final rows = (data['rows'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_rowFromJson)
        .toList(growable: false);
    return (totalRepeats: data['total_repeats'] as int? ?? 0, rows: rows);
  }

  @override
  Future<List<StudentRepeatStats>> summary({
    required PracticeLoopStatsWindow window,
  }) async {
    final response = await _apiClient.get(
      '/teachers/me/practice-loop-stats/summary',
      queryParameters: {'window': window.wireName},
    );
    final data = response.data as Map<String, dynamic>;
    return (data['students'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_summaryFromJson)
        .toList(growable: false);
  }

  @override
  Future<PracticeLoopStatsSyncResult> syncStudent({
    required List<PendingLoopStatsSync> entries,
  }) async {
    final payload = {
      'entries': entries
          .map(
            (e) => {
              'section_id': e.sectionId,
              'repeat_count': e.repeatCount,
              'last_played_at': e.lastPlayedAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
    };
    final response = await _apiClient.post(
      '/students/me/practice-loop-stats/sync',
      data: payload,
    );
    final data = response.data as Map<String, dynamic>;
    return PracticeLoopStatsSyncResult(
      upserted: data['upserted'] as int? ?? 0,
      skipped: data['skipped'] as int? ?? 0,
      rejected: data['rejected'] as int? ?? 0,
    );
  }

  // ------------------------------------------------------------------
  // JSON helpers
  // ------------------------------------------------------------------

  static PracticeLoopStats _rowFromJson(Map<String, dynamic> json) {
    return PracticeLoopStats(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      sectionId: json['section_id'] as String,
      repeatCount: json['repeat_count'] as int? ?? 0,
      lastPlayedAt: DateTime.parse(json['last_played_at'] as String),
      pieceName: json['piece_name'] as String?,
      sectionName: json['section_name'] as String?,
    );
  }

  static StudentRepeatStats _summaryFromJson(Map<String, dynamic> json) {
    return StudentRepeatStats(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String?,
      totalRepeats: json['total_repeats'] as int? ?? 0,
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.parse(json['last_played_at'] as String)
          : null,
    );
  }
}
