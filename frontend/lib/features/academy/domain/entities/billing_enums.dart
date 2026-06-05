// Billing 도메인 enum 모음.
//
// Spec: docs/specs/web/academy/billing_settlement.md §2, §3, §6.
// BE: backend/app/models/academy_billing.py.

/// 강사 배분 모드 (billing_settlement §6.1).
enum TeacherDistributionType {
  /// 시간당 단가.
  hourly,

  /// 수강료 % 비율.
  revenueShare,

  /// 학생별 단가.
  perStudent;

  String get wireValue => switch (this) {
    TeacherDistributionType.hourly => 'hourly',
    TeacherDistributionType.revenueShare => 'revenue_share',
    TeacherDistributionType.perStudent => 'per_student',
  };

  static TeacherDistributionType fromWire(String value) => switch (value) {
    'hourly' => TeacherDistributionType.hourly,
    'revenue_share' => TeacherDistributionType.revenueShare,
    'per_student' => TeacherDistributionType.perStudent,
    _ => throw ArgumentError('Unknown TeacherDistributionType: $value'),
  };
}

/// 정산 계산 베이스 (billing_settlement §6.6).
enum SettlementBase {
  /// 실제 출석 완료된 레슨만.
  attendance,

  /// 학생 청구액 기준 (출결 무관).
  invoiced,

  /// 교집합 (보수적).
  completedInvoice;

  String get wireValue => switch (this) {
    SettlementBase.attendance => 'attendance',
    SettlementBase.invoiced => 'invoiced',
    SettlementBase.completedInvoice => 'completed_invoice',
  };

  static SettlementBase fromWire(String value) => switch (value) {
    'attendance' => SettlementBase.attendance,
    'invoiced' => SettlementBase.invoiced,
    'completed_invoice' => SettlementBase.completedInvoice,
    _ => throw ArgumentError('Unknown SettlementBase: $value'),
  };
}

/// 청구서 상태.
enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled;

  String get wireValue => name;

  static InvoiceStatus fromWire(String value) => switch (value) {
    'draft' => InvoiceStatus.draft,
    'sent' => InvoiceStatus.sent,
    'paid' => InvoiceStatus.paid,
    'overdue' => InvoiceStatus.overdue,
    'cancelled' => InvoiceStatus.cancelled,
    _ => throw ArgumentError('Unknown InvoiceStatus: $value'),
  };

  /// 학원장이 추적해야 할 미수금 상태.
  bool get isOutstanding =>
      this == InvoiceStatus.sent || this == InvoiceStatus.overdue;
}

/// 수금 방법. 모두 학원장이 수기 마킹 (앱이 결제 처리 X).
///
/// Policy: payment_architecture.md 흐름 A' — 학원↔학생 수강료는 외부 결제.
enum PaymentMethod {
  /// 무통장입금 (학원장이 통장 확인 후 마킹).
  transfer,

  /// 현금 (학원장이 받은 후 마킹).
  cash,

  /// 외부 카드 단말기/POS 결제. 앱이 카드 처리 X.
  card;

  String get wireValue => name;

  static PaymentMethod fromWire(String value) => switch (value) {
    'transfer' => PaymentMethod.transfer,
    'cash' => PaymentMethod.cash,
    'card' => PaymentMethod.card,
    _ => throw ArgumentError('Unknown PaymentMethod: $value'),
  };
}

/// 수금 입력 경로.
enum PaymentSource {
  /// 1클릭 마킹.
  manual,

  /// 은행 CSV 임포트.
  csvImport,

  /// payment_matching_spec fuzzy 매칭 확정.
  fuzzyMatch;

  String get wireValue => switch (this) {
    PaymentSource.manual => 'manual',
    PaymentSource.csvImport => 'csv_import',
    PaymentSource.fuzzyMatch => 'fuzzy_match',
  };

  static PaymentSource fromWire(String value) => switch (value) {
    'manual' => PaymentSource.manual,
    'csv_import' => PaymentSource.csvImport,
    'fuzzy_match' => PaymentSource.fuzzyMatch,
    _ => throw ArgumentError('Unknown PaymentSource: $value'),
  };
}

/// 강사 배분 상태.
enum SettlementStatus {
  /// 자동 계산 직후.
  draft,

  /// 학원장 확정 + 명세서 발송.
  confirmed,

  /// 학원장 송금 완료 마킹.
  transferred;

  String get wireValue => name;

  static SettlementStatus fromWire(String value) => switch (value) {
    'draft' => SettlementStatus.draft,
    'confirmed' => SettlementStatus.confirmed,
    'transferred' => SettlementStatus.transferred,
    _ => throw ArgumentError('Unknown SettlementStatus: $value'),
  };
}
