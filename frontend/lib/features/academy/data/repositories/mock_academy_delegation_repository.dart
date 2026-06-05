import 'package:lessonaza/features/academy/domain/entities/academy_delegation.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_delegation_action.dart';
import 'package:lessonaza/features/academy/domain/entities/delegation_enums.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_delegation_repository.dart';

/// Mock implementation of AcademyDelegationRepository.
///
/// 테스트/dev 환경용. 활성 위임 1개 제약을 in-memory 로 검증.
class MockAcademyDelegationRepository implements AcademyDelegationRepository {
  MockAcademyDelegationRepository({
    List<AcademyDelegation>? seedDelegations,
    List<AcademyDelegationAction>? seedActions,
  }) : _delegations = List.of(seedDelegations ?? const []),
       _actions = List.of(seedActions ?? const []);

  final List<AcademyDelegation> _delegations;
  final List<AcademyDelegationAction> _actions;
  int _idSeq = 0;

  String _nextId(String prefix) {
    _idSeq++;
    return '${prefix}_$_idSeq';
  }

  void clear() {
    _delegations.clear();
    _actions.clear();
  }

  // ------------------------------------------------------------------
  // 학원장 측
  // ------------------------------------------------------------------

  @override
  Future<AcademyDelegation?> getActiveForAcademy(String academyId) async {
    await _delay();
    return _delegations.cast<AcademyDelegation?>().firstWhere(
      (d) => d!.academyId == academyId && d.isLive,
      orElse: () => null,
    );
  }

  @override
  Future<List<AcademyDelegation>> listHistoryForAcademy(
    String academyId, {
    int limit = 100,
  }) async {
    await _delay();
    final filtered =
        _delegations.where((d) => d.academyId == academyId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered.take(limit).toList();
  }

  @override
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
  }) async {
    await _delay();
    final existing = await getActiveForAcademy(academyId);
    if (existing != null) {
      throw StateError(
        'Academy already has an active delegation: ${existing.id}',
      );
    }
    if (!endsAt.isAfter(startsAt)) {
      throw ArgumentError('endsAt must be after startsAt');
    }
    final delegation = AcademyDelegation(
      id: _nextId('delegation'),
      academyId: academyId,
      delegatorUserId: delegatorUserId,
      delegateeMemberId: delegateeMemberId,
      permissions: List.unmodifiable(permissions),
      startsAt: startsAt,
      endsAt: endsAt,
      reason: reason,
      reasonNote: reasonNote,
      requiresPasswordAtStart: requiresPasswordAtStart,
      createdAt: DateTime.now(),
    );
    _delegations.add(delegation);
    return delegation;
  }

  @override
  Future<AcademyDelegation> revoke({
    required String delegationId,
    required String revokedByUserId,
    required DelegationRevokeReason revokedReason,
  }) async {
    await _delay();
    final index = _delegations.indexWhere((d) => d.id == delegationId);
    if (index < 0) {
      throw StateError('Delegation not found: $delegationId');
    }
    final delegation = _delegations[index];
    if (!delegation.isLive) {
      throw StateError(
        'Cannot revoke delegation in state ${delegation.state.name}',
      );
    }
    final updated = delegation.copyWith(
      state:
          revokedReason == DelegationRevokeReason.ownerReturned
              ? DelegationState.autoEnded
              : DelegationState.revoked,
      revokedAt: DateTime.now(),
      revokedByUserId: revokedByUserId,
      revokedReason: revokedReason,
    );
    _delegations[index] = updated;
    return updated;
  }

  // ------------------------------------------------------------------
  // Delegatee 측
  // ------------------------------------------------------------------

  @override
  Future<AcademyDelegation?> getActiveForDelegatee(
    String delegateeMemberId,
  ) async {
    await _delay();
    return _delegations.cast<AcademyDelegation?>().firstWhere(
      (d) => d!.delegateeMemberId == delegateeMemberId && d.isLive,
      orElse: () => null,
    );
  }

  // ------------------------------------------------------------------
  // Action audit
  // ------------------------------------------------------------------

  @override
  Future<List<AcademyDelegationAction>> listActions(
    String delegationId, {
    int limit = 200,
  }) async {
    await _delay();
    final filtered =
        _actions.where((a) => a.delegationId == delegationId).toList()
          ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return filtered.take(limit).toList();
  }

  @override
  Future<AcademyDelegationAction> markActionReviewed({
    required String actionId,
    String? disputeNote,
  }) async {
    await _delay();
    final index = _actions.indexWhere((a) => a.id == actionId);
    if (index < 0) {
      throw StateError('Action not found: $actionId');
    }
    final updated = _actions[index].copyWith(
      ownerReviewedAt: DateTime.now(),
      ownerDisputeNote: disputeNote,
    );
    _actions[index] = updated;
    return updated;
  }

  // ------------------------------------------------------------------
  // Test helpers
  // ------------------------------------------------------------------

  /// 테스트용: action 직접 추가 (실제 audit 는 service 가 자동 기록).
  void addAction(AcademyDelegationAction action) {
    _actions.add(action);
  }

  Future<void> _delay() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}
