// Delegation 도메인 enum 모음.
//
// Spec: docs/specs/web/academy/temporary_delegation_spec.md §3, §6.1.
// BE: backend/app/models/academy_governance.py (DelegationReason / State /
// RevokeReason).

/// 임시 위임 사유.
enum DelegationReason {
  trip,
  sick,
  vacation,
  event,
  other;

  String get wireValue => name;

  static DelegationReason fromWire(String value) => switch (value) {
    'trip' => DelegationReason.trip,
    'sick' => DelegationReason.sick,
    'vacation' => DelegationReason.vacation,
    'event' => DelegationReason.event,
    'other' => DelegationReason.other,
    _ => throw ArgumentError('Unknown DelegationReason: $value'),
  };
}

/// 위임 상태 (라이프사이클).
///
/// scheduled → active → (expired | revoked | autoEnded)
enum DelegationState {
  /// 예약됨, 아직 시작 안 됨 (startsAt 미래).
  scheduled,

  /// 활성 (startsAt 도달, endsAt 이전, 미회수).
  active,

  /// 자연 만료 (endsAt 도달, cron 처리).
  expired,

  /// 학원장 수동 회수.
  revoked,

  /// 학원장 자동 복귀 감지로 종료 (콘솔 로그인 등).
  autoEnded;

  String get wireValue => switch (this) {
    DelegationState.scheduled => 'scheduled',
    DelegationState.active => 'active',
    DelegationState.expired => 'expired',
    DelegationState.revoked => 'revoked',
    DelegationState.autoEnded => 'auto_ended',
  };

  static DelegationState fromWire(String value) => switch (value) {
    'scheduled' => DelegationState.scheduled,
    'active' => DelegationState.active,
    'expired' => DelegationState.expired,
    'revoked' => DelegationState.revoked,
    'auto_ended' => DelegationState.autoEnded,
    _ => throw ArgumentError('Unknown DelegationState: $value'),
  };

  /// scheduled / active 인 위임 — 활성 위임 1개 제약 검증용.
  bool get isLive =>
      this == DelegationState.scheduled || this == DelegationState.active;
}

/// 위임 종료 사유.
enum DelegationRevokeReason {
  /// 학원장 콘솔 로그인 자동 감지 — autoEnded 와 함께 사용.
  ownerReturned,

  /// 학원장 수동 회수.
  ownerManual,

  /// 자연 만료.
  expired,

  /// delegatee 거절 (수락 전).
  delegateeDeclined;

  String get wireValue => switch (this) {
    DelegationRevokeReason.ownerReturned => 'owner_returned',
    DelegationRevokeReason.ownerManual => 'owner_manual',
    DelegationRevokeReason.expired => 'expired',
    DelegationRevokeReason.delegateeDeclined => 'delegatee_declined',
  };

  static DelegationRevokeReason fromWire(String value) => switch (value) {
    'owner_returned' => DelegationRevokeReason.ownerReturned,
    'owner_manual' => DelegationRevokeReason.ownerManual,
    'expired' => DelegationRevokeReason.expired,
    'delegatee_declined' => DelegationRevokeReason.delegateeDeclined,
    _ => throw ArgumentError('Unknown DelegationRevokeReason: $value'),
  };
}
