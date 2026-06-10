import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/entities/academy.dart';
import '../../domain/exceptions/academy_invite_exceptions.dart';
import '../../domain/repositories/academy_invite_repository.dart';

/// REST client for academy invite accept flow — issue #554 영역 1.
///
/// 백엔드 엔드포인트 (baseUrl 에 `/api/v1` 포함):
/// - `GET  /public/academies/invites/{token}/preview` — AcademyInvitePreview (no auth)
/// - `POST /academies/invites/accept?token={token}`    — AcademyMemberResponse (authed)
/// - `POST /academies/invites/decline?token={token}`   — AcademyInviteResponse (authed)
///
/// 에러 분류는 BE HTTP 상태/detail 을 mock 과 동일한 문구로 정규화하여
/// 화면(`AcademyInviteAcceptScreen._errorCodeFor`)이 expired/already_used/not_found
/// 로 분기할 수 있게 한다.
class RemoteAcademyInviteRepository implements AcademyInviteRepository {
  final ApiClient _apiClient;

  RemoteAcademyInviteRepository(this._apiClient);

  @override
  Future<AcademyInvitePreview> getInvitePreview(String token) async {
    try {
      final response = await _apiClient.get(
        '/public/academies/invites/$token/preview',
      );
      final json = response.data as Map<String, dynamic>;
      // BE 는 만료/사용된 토큰도 200 + is_expired:true 로 반환한다.
      // mock 과 동일하게 만료는 예외로 변환해 화면의 expired 분기를 태운다.
      if (json['is_expired'] as bool? ?? false) {
        throw const AcademyInviteExpiredException();
      }
      return _previewFromJson(json);
    } on ApiException catch (e) {
      throw _mapInviteError(e);
    }
  }

  @override
  Future<void> acceptInvite(
    String token, {
    required bool publicPageConsent,
  }) async {
    try {
      await _apiClient.post(
        '/academies/invites/accept',
        queryParameters: {'token': token},
        data: {'public_page_consent': publicPageConsent},
      );
    } on ApiException catch (e) {
      throw _mapInviteError(e);
    }
  }

  @override
  Future<void> rejectInvite(String token, {String? reason}) async {
    try {
      await _apiClient.post(
        '/academies/invites/decline',
        queryParameters: {'token': token},
        data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      );
    } on ApiException catch (e) {
      throw _mapInviteError(e);
    }
  }

  // ──────────────────────────────────────────────────────────
  // JSON mappers (snake_case → camelCase)
  // ──────────────────────────────────────────────────────────

  static AcademyInvitePreview _previewFromJson(Map<String, dynamic> json) {
    return AcademyInvitePreview(
      token: json['token'] as String,
      academy: _academyFromJson(json['academy'] as Map<String, dynamic>),
      ownerName: json['owner_name'] as String,
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((r) => r as String)
          .toList(growable: false),
    );
  }

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

  // ──────────────────────────────────────────────────────────
  // Error normalization — keep messages aligned with the mock so the
  // accept screen classifier (expired / not found / invalid) keeps working.
  // ──────────────────────────────────────────────────────────

  static Exception _mapInviteError(ApiException e) {
    // 404 → invite/academy not found.
    if (e.statusCode == 404) {
      return const AcademyInviteNotFoundException();
    }
    // 409 → invite no longer pending. BE detail: "Invite is expired" /
    // "Invite is accepted" / "Invite is declined" / "Invite is revoked".
    if (e.statusCode == 409) {
      if (e.message.contains('expired')) {
        return const AcademyInviteExpiredException();
      }
      return const AcademyInviteAlreadyUsedException();
    }
    return e;
  }
}
