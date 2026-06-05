import '../entities/academy_billing_rule.dart';
import '../entities/academy_teacher_payout_override.dart';
import '../entities/billing_enums.dart';

/// 학원 청구·배분 정책 repository.
///
/// Spec: docs/specs/web/academy/billing_settlement.md §2, §6.5.
///
/// BillingRule 은 1 학원 = 1 행 (없으면 default). TeacherPayoutOverride 는
/// 학원 default 와 다른 강사만 행 보유.
abstract class AcademyBillingRuleRepository {
  /// 학원 청구 규칙. 없으면 BE 가 default 행 자동 생성하여 반환.
  Future<AcademyBillingRule> getForAcademy(String academyId);

  /// 학원 청구 규칙 전체 갱신 (부분 patch 는 [copyWith] + 본 메서드 조합).
  Future<AcademyBillingRule> update(AcademyBillingRule rule);

  // ------------------------------------------------------------------
  // TeacherPayoutOverride
  // ------------------------------------------------------------------

  /// 본 학원의 모든 강사별 override (현재+히스토리). 최근 effectiveFrom desc.
  Future<List<AcademyTeacherPayoutOverride>> listOverrides(String academyId);

  /// 특정 강사의 [asOf] 시점 활성 override. 없으면 null (학원 default 사용).
  Future<AcademyTeacherPayoutOverride?> getActiveForTeacher({
    required String teacherMemberId,
    DateTime? asOf,
  });

  /// 새 override 시작. 이전 활성 override 가 있으면 [effectiveUntil] 을
  /// [effectiveFrom] 으로 자동 설정 (히스토리 보존).
  Future<AcademyTeacherPayoutOverride> upsertOverride({
    required String academyId,
    required String teacherMemberId,
    required TeacherDistributionType distributionType,
    required Map<String, dynamic> distributionConfig,
    required DateTime effectiveFrom,
    String? note,
  });
}
