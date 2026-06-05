import '../entities/context_switch_log.dart';

/// 학원장 ↔ 강사 모드 전환 audit 조회 repository.
///
/// Spec: docs/specs/web/academy/context_toggle_spec.md §9 transparency.
///
/// 본인 audit + 학원 단위 본인 audit 두 가지 view 제공.
/// 학원장 본인 audit 는 학원 단위로 조회 (멤버여야 함).
/// BE endpoint:
/// - GET /api/v1/auth/me/context-switches — 본인 모든 audit
/// - GET /api/v1/academies/{academy_id}/context-switches/me — 본인 학원 단위
abstract class ContextSwitchLogRepository {
  /// 본인 모든 audit (학원 무관). 최근 [limit] 건.
  Future<List<ContextSwitchLog>> listMy({int limit = 100});

  /// 본인 + 특정 학원 audit. 멤버여야 함. 비멤버 → throw.
  Future<List<ContextSwitchLog>> listMyForAcademy(
    String academyId, {
    int limit = 100,
  });
}
