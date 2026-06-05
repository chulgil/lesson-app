import '../entities/academy_invoice.dart';
import '../entities/billing_enums.dart';

/// 청구서 + 수금 통합 view.
///
/// Spec: docs/specs/web/academy/billing_settlement.md §3, §4.
///
/// 청구서 상태 전이는 학원장이 일괄 발송 (`bulkSend`) 또는 수금 마킹으로
/// 자동 paid 전환. 부분 수금은 `paid_amount sum < total_amount` 라면
/// 여전히 sent 상태 (학원장 수동 확정 시 paid 전환).
abstract class AcademyInvoiceRepository {
  // ------------------------------------------------------------------
  // CRUD
  // ------------------------------------------------------------------

  /// 학원의 청구서 목록. status 필터 옵션.
  Future<List<AcademyInvoice>> listForAcademy(
    String academyId, {
    InvoiceStatus? status,
    int? periodYear,
    int? periodMonth,
    int limit = 200,
  });

  /// 학생의 청구서 히스토리 (최근 desc).
  Future<List<AcademyInvoice>> listForStudent(
    String academyStudentId, {
    int limit = 50,
  });

  /// 단일 조회. 없으면 null.
  Future<AcademyInvoice?> get(String invoiceId);

  /// 신규 청구서 (draft). 중복 (학원+학생+년+월) 시 [StateError].
  Future<AcademyInvoice> create({
    required String academyId,
    required String academyStudentId,
    required int periodYear,
    required int periodMonth,
    int baseAmount = 0,
    int extraAmount = 0,
    int discountAmount = 0,
    List<Map<String, dynamic>>? lineItems,
    DateTime? dueDate,
  });

  /// 갱신 (전체 replace). 부분 patch 는 [copyWith] + 본 메서드 조합.
  Future<AcademyInvoice> update(AcademyInvoice invoice);

  // ------------------------------------------------------------------
  // Bulk operations
  // ------------------------------------------------------------------

  /// 다중 청구서 일괄 발송 (draft → sent). issuedAt + sentAt 설정.
  /// draft 가 아닌 행은 건너뛰고 결과 리스트에서 제외.
  /// 반환: 실제로 sent 상태로 전환된 갱신 행.
  Future<List<AcademyInvoice>> bulkSend(List<String> invoiceIds);

  /// 청구서 취소 (sent / draft → cancelled). paid 는 취소 불가.
  Future<AcademyInvoice> cancel(String invoiceId);
}
