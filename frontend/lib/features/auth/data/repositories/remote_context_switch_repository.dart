import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/context_switch_repository.dart';

/// REST client for context toggle endpoints (owner ↔ teacher) — 영역6 / #554.
///
/// Backend: `academy_context.py`, prefix `/api/v1/auth`.
/// - GET  /auth/context        → [ContextResponse]   → [ContextInfo]
/// - POST /auth/context/switch → [ContextSwitchResponse] → [ContextSwitchResult]
///
/// Wire ↔ Dart field mapping (snake_case → camelCase):
/// - `user_id`/`active_context`/`academy_id`/`teacher_id`/`available_contexts`
/// - per-context: `context`/`academy_id`/`label`/`member_id`/`is_onboarding`/
///   `delegation_active`
/// - switch: `access_token`/`active_context`/`academy_id`/`teacher_id`/
///   `member_id`/`redirect_url`
///
/// Context wire values are passed through verbatim (`academy_owner`/`teacher`)
/// so the FE never invents its own enum strings.
class RemoteContextSwitchRepository implements ContextSwitchRepository {
  final ApiClient _apiClient;

  RemoteContextSwitchRepository(this._apiClient);

  @override
  Future<ContextInfo> getContext() async {
    final response = await _apiClient.get('/auth/context');
    return _contextInfoFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ContextSwitchResult> switchContext({
    required String targetContext,
    String? academyId,
  }) async {
    final response = await _apiClient.post(
      '/auth/context/switch',
      data: {
        'target_context': targetContext,
        if (academyId != null) 'academy_id': academyId,
      },
    );
    return _switchResultFromJson(response.data as Map<String, dynamic>);
  }

  // ──────────────────────────────────────────────────────────
  // JSON helpers
  // ──────────────────────────────────────────────────────────

  static ContextInfo _contextInfoFromJson(Map<String, dynamic> json) {
    final rawContexts =
        (json['available_contexts'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    return ContextInfo(
      userId: json['user_id'] as String,
      activeContext: json['active_context'] as String?,
      academyId: json['academy_id'] as String?,
      teacherId: json['teacher_id'] as String?,
      availableContexts:
          rawContexts.map(_availableContextFromJson).toList(growable: false),
    );
  }

  static AvailableContext _availableContextFromJson(Map<String, dynamic> json) {
    return AvailableContext(
      context: json['context'] as String,
      academyId: json['academy_id'] as String,
      label: json['label'] as String,
      memberId: json['member_id'] as String,
      isOnboarding: json['is_onboarding'] as bool? ?? false,
      delegationActive: json['delegation_active'] as bool? ?? false,
    );
  }

  static ContextSwitchResult _switchResultFromJson(Map<String, dynamic> json) {
    return ContextSwitchResult(
      activeContext: json['active_context'] as String,
      // Backend returns a path hint; default to '/today' (teacher home) when
      // absent — matches the service's default redirect for teacher context.
      redirectUrl: json['redirect_url'] as String? ?? '/today',
      // The switch endpoint issues a fresh access token only. No refresh token
      // is rotated, so the existing refresh token remains valid; carry an empty
      // placeholder that callers ignore when persisting the access token.
      tokens: TokenPair(
        accessToken: json['access_token'] as String,
        refreshToken: '',
      ),
    );
  }
}
