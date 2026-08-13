import '../../../../core/network/api_client.dart';
import '../../domain/repositories/academy_visibility_repository.dart';

/// REST client for academy public-page visibility (consent) — issue #554 영역 2.
///
/// 백엔드 엔드포인트 (baseUrl 에 `/api/v1` 포함):
/// - `GET  /academies/me`                          — 소속 학원 목록 (AcademyResponse[])
/// - `GET  /academies/{academyId}/members`         — 멤버 목록 (consent 포함)
/// - `PATCH /academies/members/{memberId}/consent` — 본인 consent 토글
///
/// FE 계약은 `(academyId, teacherId=userId)` 키이지만 백엔드 PATCH 는 `member_id` 를
/// 요구하므로, members 목록에서 본인 user_id 의 member_id 를 먼저 해석한다.
class RemoteAcademyVisibilityRepository implements AcademyVisibilityRepository {
  final ApiClient _apiClient;

  RemoteAcademyVisibilityRepository(this._apiClient);

  @override
  Future<bool> getTeacherAcademyConsent(
    String academyId,
    String teacherId,
  ) async {
    final member = await _findMember(academyId, teacherId);
    return member?.consent ?? false;
  }

  @override
  Future<bool> updateTeacherAcademyConsent(
    String academyId,
    String teacherId,
    bool consent,
  ) async {
    final member = await _findMember(academyId, teacherId);
    if (member == null) {
      throw Exception('학원 소속 정보를 찾을 수 없습니다.');
    }
    final response = await _apiClient.patch(
      '/academies/members/${member.memberId}/consent',
      data: {'public_page_consent': consent},
    );
    final json = response.data as Map<String, dynamic>;
    return json['public_page_consent'] as bool;
  }

  @override
  Future<List<TeacherAcademyMembership>> listTeacherAcademies(
    String teacherId,
  ) async {
    final academiesResponse = await _apiClient.get('/academies/me');
    final academies =
        (academiesResponse.data as List<dynamic>).cast<Map<String, dynamic>>();

    final memberships = <TeacherAcademyMembership>[];
    for (final academy in academies) {
      final academyId = academy['id'] as String;
      final member = await _findMember(academyId, teacherId);
      // 강사 멤버십만 노출 (소유자 자기 학원은 가시성 토글 대상 아님).
      if (member == null || member.role != 'teacher') continue;
      memberships.add(
        TeacherAcademyMembership(
          academyId: academyId,
          academyName: academy['name'] as String,
          publicPageConsent: member.consent,
          actorMemberId: member.memberId,
        ),
      );
    }
    return memberships;
  }

  // ──────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────

  /// Resolve the member row for [teacherId] (user id) within [academyId].
  Future<_MemberConsent?> _findMember(
    String academyId,
    String teacherId,
  ) async {
    final response = await _apiClient.get('/academies/$academyId/members');
    final map = response.data as Map<String, dynamic>;
    final members =
        (map['members'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    for (final m in members) {
      if (m['user_id'] == teacherId) {
        return _MemberConsent(
          memberId: m['id'] as String,
          role: m['role'] as String,
          consent: m['public_page_consent'] as bool? ?? false,
        );
      }
    }
    return null;
  }
}

/// Internal projection of an academy member's consent state.
class _MemberConsent {
  final String memberId;
  final String role;
  final bool consent;

  const _MemberConsent({
    required this.memberId,
    required this.role,
    required this.consent,
  });
}
