import '../../../../core/network/api_client.dart';
import '../../domain/entities/academy.dart';
import '../../domain/entities/academy_enums.dart';
import '../../domain/entities/academy_member.dart';
import '../../domain/entities/academy_student.dart';
import '../../domain/repositories/academy_repository.dart';

/// REST client for academy base info — issue #554 영역 3.
///
/// 백엔드 엔드포인트 (baseUrl 에 `/api/v1` 포함):
/// - `GET /academies/{id}`          — AcademyResponse
/// - `GET /academies/{id}/members`  — AcademyMemberListResponse
/// - `GET /academies/{id}/students` — AcademyStudentListResponse
///
/// 강사 모드에서 `/students` 는 백엔드가 본인 매칭 학생만 반환한다 (AC-M2 §6.2).
class RemoteAcademyRepository implements AcademyRepository {
  final ApiClient _apiClient;

  RemoteAcademyRepository(this._apiClient);

  @override
  Future<Academy?> getById(String id) async {
    final response = await _apiClient.get('/academies/$id');
    final json = response.data;
    if (json == null) return null;
    return _academyFromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<AcademyMember>> listMembers(String academyId) async {
    final response = await _apiClient.get('/academies/$academyId/members');
    final map = response.data as Map<String, dynamic>;
    final items =
        (map['members'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return items.map(_memberFromJson).toList(growable: false);
  }

  @override
  Future<List<AcademyStudent>> listStudents(String academyId) async {
    final response = await _apiClient.get('/academies/$academyId/students');
    final map = response.data as Map<String, dynamic>;
    final items =
        (map['students'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return items.map(_studentFromJson).toList(growable: false);
  }

  // ──────────────────────────────────────────────────────────
  // JSON mappers (snake_case → camelCase)
  // ──────────────────────────────────────────────────────────

  static Academy _academyFromJson(Map<String, dynamic> json) {
    return Academy(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      ownerUserId: json['owner_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static AcademyMember _memberFromJson(Map<String, dynamic> json) {
    return AcademyMember(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      userId: json['user_id'] as String,
      role: _memberRoleFromWire(json['role'] as String),
      publicPageConsent: json['public_page_consent'] as bool? ?? false,
      onboardingUntil: _parseNullableDate(json['onboarding_until']),
      createdAt: DateTime.parse(json['created_at'] as String),
      accessRevokedAt: _parseNullableDate(json['access_revoked_at']),
      delegateRole: json['delegate_role'] as String? ?? 'none',
      delegateRoleGrantedAt: _parseNullableDate(json['delegate_role_granted_at']),
    );
  }

  static AcademyStudent _studentFromJson(Map<String, dynamic> json) {
    return AcademyStudent(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      studentUserId: json['student_user_id'] as String?,
      parentUserId: json['parent_user_id'] as String?,
      teacherMemberId: json['teacher_member_id'] as String?,
      name: json['name'] as String,
      instrument: json['instrument'] as String?,
      status: _studentStatusFromWire(json['status'] as String),
      registeredAt: DateTime.parse(json['registered_at'] as String),
      matchedAt: _parseNullableDate(json['matched_at']),
      statusChangedAt: _parseNullableDate(json['status_changed_at']),
      intakeNotes: json['intake_notes'] as String?,
      depositCode: json['deposit_code'] as String?,
    );
  }

  static DateTime? _parseNullableDate(dynamic value) =>
      value == null ? null : DateTime.parse(value as String);

  static AcademyMemberRole _memberRoleFromWire(String value) {
    switch (value) {
      case 'owner':
        return AcademyMemberRole.owner;
      case 'teacher':
      default:
        return AcademyMemberRole.teacher;
    }
  }

  static AcademyStudentStatus _studentStatusFromWire(String value) {
    switch (value) {
      case 'waiting':
        return AcademyStudentStatus.waiting;
      case 'matched':
        return AcademyStudentStatus.matched;
      case 'paused':
        return AcademyStudentStatus.paused;
      case 'alumni':
        return AcademyStudentStatus.alumni;
      case 'active':
      default:
        return AcademyStudentStatus.active;
    }
  }
}
