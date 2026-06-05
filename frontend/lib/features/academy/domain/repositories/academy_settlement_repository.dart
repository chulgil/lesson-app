import '../entities/academy_settlement.dart';

/// 월간 강사 배분 명세 + audit repository.
///
/// Spec: docs/specs/web/academy/billing_settlement.md §6.
///
/// 라이프사이클: draft → confirmed → transferred. adjust/acknowledge/dispute
/// 는 status 전이와 무관 (audit 트레일만 누적).
abstract class AcademySettlementRepository {
  // ------------------------------------------------------------------
  // 조회
  // ------------------------------------------------------------------

  /// 학원의 특정 기간 모든 강사 명세 (학원장 마감 화면용). teacherMemberId asc.
  Future<List<AcademySettlement>> listForAcademyPeriod({
    required String academyId,
    required int periodYear,
    required int periodMonth,
  });

  /// 강사 본인 명세 히스토리 (period year+month desc).
  Future<List<AcademySettlement>> listForTeacher({
    required String teacherMemberId,
    int limit = 24,
  });

  /// 단일 조회. 없으면 null.
  Future<AcademySettlement?> get(String settlementId);

  // ------------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------------

  /// 자동 계산 명세 생성/갱신 (draft). 이미 draft 가 있으면 calculatedAmount /
  /// breakdown 만 replace (status 유지). confirmed 이상이면 [StateError].
  ///
  /// 매월 정기 cron 진입점. 중복 (학원+강사+년+월) 은 자동으로 upsert.
  Future<AcademySettlement> calculate({
    required String academyId,
    required String teacherMemberId,
    required int periodYear,
    required int periodMonth,
    required int calculatedAmount,
    List<Map<String, dynamic>>? breakdown,
  });

  /// 학원장 수동 조정 (audit 누적). draft 단계에서만 허용. finalAmount 자동
  /// 갱신 (== adjustedAmount).
  Future<AcademySettlement> adjust({
    required String settlementId,
    required String byUserId,
    required int adjustedAmount,
    required String reason,
  });

  /// draft → confirmed. confirmedAt 설정. 이미 confirmed/transferred 면
  /// [StateError]. finalAmount 자동 fix (adjustedAmount ?? calculatedAmount).
  Future<AcademySettlement> confirm(String settlementId);

  /// confirmed → transferred. transferredAt 설정. draft 인 경우 [StateError].
  Future<AcademySettlement> markTransferred(String settlementId);

  // ------------------------------------------------------------------
  // Teacher audit (§6.7)
  // ------------------------------------------------------------------

  /// 강사 명세 확인 마킹. teacherAcknowledgedAt 설정. 이미 확인된 행이면
  /// 시각만 갱신 (멱등).
  Future<AcademySettlement> acknowledge({
    required String settlementId,
    String? disputeNote,
  });
}
