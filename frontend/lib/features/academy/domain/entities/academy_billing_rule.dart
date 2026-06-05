import 'billing_enums.dart';

/// 학원 단위 청구·배분 규칙 (1 학원 = 1 행).
///
/// Spec: docs/specs/web/academy/billing_settlement.md §2.
/// BE: backend/app/models/academy_billing.py AcademyBillingRule.
///
/// 강사별 override 는 [AcademyTeacherPayoutOverride] 에 별개로 관리.
class AcademyBillingRule {
  AcademyBillingRule({
    required this.id,
    required this.academyId,
    required this.createdAt,
    this.invoiceIssueDay = 25,
    this.paymentDueDays = 7,
    List<PaymentMethod>? paymentMethods,
    this.bankAccountName,
    this.bankAccountNumber,
    this.teacherDistributionType = TeacherDistributionType.revenueShare,
    Map<String, dynamic>? teacherDistributionConfig,
    this.settlementBase = SettlementBase.attendance,
    this.taxInvoiceEnabled = false,
    this.cashReceiptEnabled = true,
    this.absentTeacherPayPct = 0.4,
    this.substitutePayPct = 0.6,
    this.noShowPenaltyAmount = 0,
    this.noShowPenaltyStrikes = 3,
  }) : paymentMethods = List.unmodifiable(paymentMethods ?? const []),
       teacherDistributionConfig = Map.unmodifiable(
         teacherDistributionConfig ?? const {},
       ) {
    assert(
      invoiceIssueDay >= 1 && invoiceIssueDay <= 28,
      'invoiceIssueDay must be in 1..28',
    );
    assert(
      paymentDueDays >= 0 && paymentDueDays <= 60,
      'paymentDueDays must be in 0..60',
    );
    assert(
      absentTeacherPayPct >= 0 && absentTeacherPayPct <= 1,
      'absentTeacherPayPct must be in 0..1',
    );
    assert(
      substitutePayPct >= 0 && substitutePayPct <= 1,
      'substitutePayPct must be in 0..1',
    );
  }

  final String id;
  final String academyId;

  /// 청구서 발급일 (월 N 일). 1..28.
  final int invoiceIssueDay;

  /// 발급 → 납기까지 N일. 0..60.
  final int paymentDueDays;

  /// 학원이 받는 결제 방법 (전부 학원장 수기 마킹).
  final List<PaymentMethod> paymentMethods;

  final String? bankAccountName;
  final String? bankAccountNumber;

  /// 학원 단위 기본 강사 배분 모드. 강사별 override 는 별도 엔티티.
  final TeacherDistributionType teacherDistributionType;

  /// 배분 모드별 추가 config (예: `{"hourly_rate": 50000}`).
  final Map<String, dynamic> teacherDistributionConfig;

  final SettlementBase settlementBase;

  final bool taxInvoiceEnabled;
  final bool cashReceiptEnabled;

  /// 강사 휴가 시 본인 페이 비율 (0.0~1.0). teacher_absence §6.1.
  final double absentTeacherPayPct;

  /// 대체 강사 페이 비율 (0.0~1.0).
  final double substitutePayPct;

  /// 무단 결근 페널티 금액 (KRW). 0 = 미사용.
  final int noShowPenaltyAmount;

  /// 페널티 발동 strike 누적 임계. teacher_absence §7.2.
  final int noShowPenaltyStrikes;

  final DateTime createdAt;

  AcademyBillingRule copyWith({
    String? id,
    String? academyId,
    int? invoiceIssueDay,
    int? paymentDueDays,
    List<PaymentMethod>? paymentMethods,
    String? bankAccountName,
    String? bankAccountNumber,
    TeacherDistributionType? teacherDistributionType,
    Map<String, dynamic>? teacherDistributionConfig,
    SettlementBase? settlementBase,
    bool? taxInvoiceEnabled,
    bool? cashReceiptEnabled,
    double? absentTeacherPayPct,
    double? substitutePayPct,
    int? noShowPenaltyAmount,
    int? noShowPenaltyStrikes,
    DateTime? createdAt,
  }) {
    return AcademyBillingRule(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      invoiceIssueDay: invoiceIssueDay ?? this.invoiceIssueDay,
      paymentDueDays: paymentDueDays ?? this.paymentDueDays,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      teacherDistributionType:
          teacherDistributionType ?? this.teacherDistributionType,
      teacherDistributionConfig:
          teacherDistributionConfig ?? this.teacherDistributionConfig,
      settlementBase: settlementBase ?? this.settlementBase,
      taxInvoiceEnabled: taxInvoiceEnabled ?? this.taxInvoiceEnabled,
      cashReceiptEnabled: cashReceiptEnabled ?? this.cashReceiptEnabled,
      absentTeacherPayPct: absentTeacherPayPct ?? this.absentTeacherPayPct,
      substitutePayPct: substitutePayPct ?? this.substitutePayPct,
      noShowPenaltyAmount: noShowPenaltyAmount ?? this.noShowPenaltyAmount,
      noShowPenaltyStrikes: noShowPenaltyStrikes ?? this.noShowPenaltyStrikes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcademyBillingRule) return false;
    if (!_listEqualsEnum(paymentMethods, other.paymentMethods)) return false;
    if (!_mapEquals(
      teacherDistributionConfig,
      other.teacherDistributionConfig,
    )) {
      return false;
    }
    return id == other.id &&
        academyId == other.academyId &&
        invoiceIssueDay == other.invoiceIssueDay &&
        paymentDueDays == other.paymentDueDays &&
        bankAccountName == other.bankAccountName &&
        bankAccountNumber == other.bankAccountNumber &&
        teacherDistributionType == other.teacherDistributionType &&
        settlementBase == other.settlementBase &&
        taxInvoiceEnabled == other.taxInvoiceEnabled &&
        cashReceiptEnabled == other.cashReceiptEnabled &&
        absentTeacherPayPct == other.absentTeacherPayPct &&
        substitutePayPct == other.substitutePayPct &&
        noShowPenaltyAmount == other.noShowPenaltyAmount &&
        noShowPenaltyStrikes == other.noShowPenaltyStrikes &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    academyId,
    invoiceIssueDay,
    paymentDueDays,
    Object.hashAll(paymentMethods),
    bankAccountName,
    bankAccountNumber,
    teacherDistributionType,
    teacherDistributionConfig.length,
    settlementBase,
    taxInvoiceEnabled,
    cashReceiptEnabled,
    absentTeacherPayPct,
    substitutePayPct,
    noShowPenaltyAmount,
    noShowPenaltyStrikes,
    createdAt,
  );

  static bool _listEqualsEnum(List<PaymentMethod> a, List<PaymentMethod> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
