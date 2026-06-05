import 'delegation_enums.dart';

/// 학원장 → 위임받는 자 임시 권한.
///
/// Spec: docs/specs/web/academy/temporary_delegation_spec.md §3, §4.2, §6.1.
/// BE: backend/app/models/academy_governance.py AcademyDelegation.
///
/// 한 학원당 동시 1개 활성 위임만 (state in scheduled/active).
class AcademyDelegation {
  const AcademyDelegation({
    required this.id,
    required this.academyId,
    required this.delegatorUserId,
    required this.delegateeMemberId,
    required this.permissions,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.createdAt,
    this.reasonNote,
    this.state = DelegationState.scheduled,
    this.revokedAt,
    this.revokedByUserId,
    this.revokedReason,
    this.requiresPasswordAtStart = true,
    this.notificationTemplateId = 'delegation_v1',
  });

  final String id;
  final String academyId;
  final String delegatorUserId;
  final String delegateeMemberId;

  /// 위임 권한 항목 (temporary_delegation_spec §2.1).
  /// 예: `["billing.collect", "inbox.reply", "dashboard.view_only"]`
  final List<String> permissions;

  final DateTime startsAt;
  final DateTime endsAt;
  final DelegationReason reason;
  final String? reasonNote;
  final DelegationState state;
  final DateTime? revokedAt;
  final String? revokedByUserId;
  final DelegationRevokeReason? revokedReason;

  /// 학원장 비밀번호 재인증 여부 (§4.2).
  /// 매니저 영구 위임(trusted_substitute) 인 경우 false 로 설정.
  final bool requiresPasswordAtStart;

  /// 알림 템플릿 id (lesson-app 측 delegatee 알림용).
  final String notificationTemplateId;

  final DateTime createdAt;

  /// scheduled / active 상태 — 활성 위임 1개 제약 검증용.
  bool get isLive => state.isLive;

  AcademyDelegation copyWith({
    String? id,
    String? academyId,
    String? delegatorUserId,
    String? delegateeMemberId,
    List<String>? permissions,
    DateTime? startsAt,
    DateTime? endsAt,
    DelegationReason? reason,
    String? reasonNote,
    DelegationState? state,
    DateTime? revokedAt,
    String? revokedByUserId,
    DelegationRevokeReason? revokedReason,
    bool? requiresPasswordAtStart,
    String? notificationTemplateId,
    DateTime? createdAt,
  }) {
    return AcademyDelegation(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      delegatorUserId: delegatorUserId ?? this.delegatorUserId,
      delegateeMemberId: delegateeMemberId ?? this.delegateeMemberId,
      permissions: permissions ?? this.permissions,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      reason: reason ?? this.reason,
      reasonNote: reasonNote ?? this.reasonNote,
      state: state ?? this.state,
      revokedAt: revokedAt ?? this.revokedAt,
      revokedByUserId: revokedByUserId ?? this.revokedByUserId,
      revokedReason: revokedReason ?? this.revokedReason,
      requiresPasswordAtStart:
          requiresPasswordAtStart ?? this.requiresPasswordAtStart,
      notificationTemplateId:
          notificationTemplateId ?? this.notificationTemplateId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcademyDelegation) return false;
    if (!_listEquals(permissions, other.permissions)) return false;
    return id == other.id &&
        academyId == other.academyId &&
        delegatorUserId == other.delegatorUserId &&
        delegateeMemberId == other.delegateeMemberId &&
        startsAt == other.startsAt &&
        endsAt == other.endsAt &&
        reason == other.reason &&
        reasonNote == other.reasonNote &&
        state == other.state &&
        revokedAt == other.revokedAt &&
        revokedByUserId == other.revokedByUserId &&
        revokedReason == other.revokedReason &&
        requiresPasswordAtStart == other.requiresPasswordAtStart &&
        notificationTemplateId == other.notificationTemplateId &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    academyId,
    delegatorUserId,
    delegateeMemberId,
    // permissions 는 길이 + 첫/마지막 element 만 — List identity 회피.
    Object.hashAll(permissions),
    startsAt,
    endsAt,
    reason,
    reasonNote,
    state,
    revokedAt,
    revokedByUserId,
    revokedReason,
    requiresPasswordAtStart,
    notificationTemplateId,
    createdAt,
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
