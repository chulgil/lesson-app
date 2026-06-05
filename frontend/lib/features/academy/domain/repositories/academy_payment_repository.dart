import '../entities/academy_payment.dart';
import '../entities/billing_enums.dart';

/// 수금 기록 + 조회 repository.
///
/// Spec: docs/specs/web/academy/billing_settlement.md §4.
///
/// 청구서 1건당 N 수금 (부분 수금 지원). 학원장 수기 마킹 / CSV 임포트 /
/// fuzzy 매칭 확정 등 source 별로 audit 트레일 보존.
abstract class AcademyPaymentRepository {
  /// 학원의 수금 목록. 기간 옵션. paidAt desc.
  Future<List<AcademyPayment>> listForAcademy(
    String academyId, {
    DateTime? from,
    DateTime? to,
    int limit = 200,
  });

  /// 청구서 단위 수금 목록 (부분 수금 합계 계산용). paidAt asc.
  Future<List<AcademyPayment>> listForInvoice(String invoiceId);

  /// 수금 기록 (1클릭 마킹 / CSV / fuzzy 확정 공용 진입점).
  ///
  /// paidAmount <= 0 → [ArgumentError].
  Future<AcademyPayment> record({
    required String academyId,
    required String invoiceId,
    required int paidAmount,
    required DateTime paidAt,
    required String confirmedByUserId,
    PaymentMethod method = PaymentMethod.transfer,
    PaymentSource source = PaymentSource.manual,
    String? bankTxRef,
    String? depositorRaw,
    String? note,
  });

  /// 청구서 단위 합산 금액 (audit + UI 진행률용).
  Future<int> sumForInvoice(String invoiceId);
}
