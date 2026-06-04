import '../../../../core/network/api_client.dart';
import '../../domain/entities/makeup_credit.dart';
import '../../domain/repositories/makeup_credit_repository.dart';

/// REST client for makeup credit endpoints (#432).
///
/// Spec: docs/specs/subscription/makeup_credit_spec.md §8.
/// TODO(remote): 백엔드 엔드포인트 확정 후 경로/스키마 정합성 검증 필요.
class RemoteMakeupCreditRepository implements MakeupCreditRepository {
  final ApiClient _apiClient;

  RemoteMakeupCreditRepository(this._apiClient);

  @override
  Future<List<MakeupCredit>> listStudentCredits() async {
    final response = await _apiClient.get('/students/me/makeup-credits');
    return _listFromResponse(response.data);
  }

  @override
  Future<List<MakeupCredit>> listTeacherCredits({
    required String studentId,
  }) async {
    final response = await _apiClient.get(
      '/teachers/me/makeup-credits',
      queryParameters: {'student_id': studentId},
    );
    return _listFromResponse(response.data);
  }

  @override
  Future<MakeupCredit> grantCredit({
    required String studentId,
    String? sourceSubscriptionId,
    String? reasonNote,
  }) async {
    final response = await _apiClient.post(
      '/teachers/me/makeup-credits',
      data: {
        'student_id': studentId,
        if (sourceSubscriptionId != null)
          'source_subscription_id': sourceSubscriptionId,
        if (reasonNote != null && reasonNote.isNotEmpty)
          'reason_note': reasonNote,
      },
    );
    return _fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> revokeCredit(String creditId) async {
    await _apiClient.delete('/teachers/me/makeup-credits/$creditId');
  }

  // ──────────────────────────────────────────────────────────
  // JSON helpers
  // ──────────────────────────────────────────────────────────

  static List<MakeupCredit> _listFromResponse(dynamic data) {
    final map = data as Map<String, dynamic>;
    final items =
        (map['credits'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return items.map(_fromJson).toList(growable: false);
  }

  static MakeupCredit _fromJson(Map<String, dynamic> json) {
    return MakeupCredit(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      sourceSubscriptionId: json['source_subscription_id'] as String?,
      reason: _reasonFromWire(json['reason'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedAt:
          json['used_at'] != null
              ? DateTime.parse(json['used_at'] as String)
              : null,
      usedLessonId: json['used_lesson_id'] as String?,
      sourceEventId: json['source_event_id'] as String?,
    );
  }

  static MakeupCreditReason _reasonFromWire(String value) {
    switch (value) {
      case 'teacherVacation':
        return MakeupCreditReason.teacherVacation;
      case 'noShowExempt':
        return MakeupCreditReason.noShowExempt;
      case 'bulkChangeLoss':
        return MakeupCreditReason.bulkChangeLoss;
      case 'fifthWeekBonus':
        return MakeupCreditReason.fifthWeekBonus;
      case 'manualGrant':
      default:
        return MakeupCreditReason.manualGrant;
    }
  }
}
