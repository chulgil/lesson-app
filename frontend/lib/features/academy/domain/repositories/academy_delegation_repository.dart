import '../entities/academy_delegation.dart';
import '../entities/academy_delegation_action.dart';
import '../entities/delegation_enums.dart';

/// 학원장 임시 권한 위임 + 활동 audit repository.
///
/// Spec: docs/specs/web/academy/temporary_delegation_spec.md.
///
/// 학원장 측:
/// - 본인 학원의 활성 위임 조회 (scheduled / active)
/// - 위임 시작 (validation: 동시 1개)
/// - 위임 수동 회수
/// - 활동 audit 조회 + 사후 검토 마킹
///
/// Delegatee 측 (강사 모드):
/// - 본인이 받은 활성 위임 조회 (lesson-app 상단 배너)
/// - 위임 거절 (수락 전)
abstract class AcademyDelegationRepository {
  // ------------------------------------------------------------------
  // 학원장 (delegator) 측
  // ------------------------------------------------------------------

  /// 본 학원의 활성 위임 1개 (scheduled or active). 없으면 null.
  Future<AcademyDelegation?> getActiveForAcademy(String academyId);

  /// 본 학원의 위임 히스토리 (terminal states 포함).
  Future<List<AcademyDelegation>> listHistoryForAcademy(
    String academyId, {
    int limit = 100,
  });

  /// 새 위임 시작. 동시 활성 위임 존재 시 [StateError].
  Future<AcademyDelegation> create({
    required String academyId,
    required String delegatorUserId,
    required String delegateeMemberId,
    required List<String> permissions,
    required DateTime startsAt,
    required DateTime endsAt,
    required DelegationReason reason,
    String? reasonNote,
    bool requiresPasswordAtStart = true,
  });

  /// 학원장 수동 회수. 이미 종료된 위임이면 [StateError].
  Future<AcademyDelegation> revoke({
    required String delegationId,
    required String revokedByUserId,
    required DelegationRevokeReason revokedReason,
  });

  // ------------------------------------------------------------------
  // Delegatee (강사 모드) 측
  // ------------------------------------------------------------------

  /// delegatee_member_id 기준 본인이 받은 활성 위임. 없으면 null.
  Future<AcademyDelegation?> getActiveForDelegatee(String delegateeMemberId);

  // ------------------------------------------------------------------
  // Action audit
  // ------------------------------------------------------------------

  /// 위임 활동 로그 (학원장 사후 검토용).
  Future<List<AcademyDelegationAction>> listActions(
    String delegationId, {
    int limit = 200,
  });

  /// 학원장이 특정 액션을 사후 검토 완료로 마킹. [disputeNote] 비우면 단순 검토.
  Future<AcademyDelegationAction> markActionReviewed({
    required String actionId,
    String? disputeNote,
  });
}
