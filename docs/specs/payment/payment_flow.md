# 결제 플로우 시스템 스펙

> 작성일: 2025-12-27
> 상태: ✅ 스펙 확정

레슨 앱의 결제 플로우 상세 설계

---

## 목차

1. [개요](#개요)
2. [결제 방식](#결제-방식)
3. [결제 단위](#결제-단위)
4. [결제 수단](#결제-수단)
5. [청구서 발행](#청구서-발행)
6. [미결제 처리](#미결제-처리)
7. [환불 정책](#환불-정책)
8. [할인 시스템](#할인-시스템)
9. [정산 관리](#정산-관리)
10. [데이터 모델](#데이터-모델)
11. [UI 와이어프레임](#ui-와이어프레임)
12. [플로우 다이어그램](#플로우-다이어그램)

---

## 개요

### 설계 원칙

1. **선생님 자율성** - 결제 방식, 미결제 처리, 환불 정책 등 선생님이 설정
2. **유연한 결제 단위** - 월정액, 패키지(N회권) 선택 가능
3. **단계적 확장** - 무통장입금 → 간편결제 → 카드 순차 확장
4. **투명한 정산** - 월별 수익 리포트 제공

### 결정 사항 요약

| 항목 | 결정 |
|------|------|
| 결제 방식 | 선생님 선택 (선결제/후결제) |
| 결제 단위 | 월정액 + 패키지(N회권) |
| 결제 수단 | 무통장 → 추후 간편결제/카드 확장 |
| 청구서 발행 | 월정액: 월초, 패키지: 소진 전 |
| 미결제 처리 | 선생님 설정 |
| 환불 정책 | 선생님 설정 |
| 할인 | 패키지 할인 (8회 5%, 12회 10% 등) |
| 정산 | 월별 리포트 |

---

## 자녀 프로필 결제 처리

> 미성년자 정책에 따라 만 14세 미만 학생은 별도 회원이 아닌 부모 계정의 "자녀 프로필"로 존재합니다.
> 결제 관련 모든 처리는 부모 계정을 대상으로 합니다.

### 청구 대상 결정

```dart
/// 청구 대상 유형
enum BillingTarget {
  student,      // 학생 본인 (만 14세 이상)
  parent,       // 부모 계정 (만 14세 미만 자녀 프로필)
}

/// 청구 대상 결정 로직
BillingTarget determineBillingTarget(StudentOrProfile entity) {
  if (entity is ChildProfile) {
    // 자녀 프로필 → 부모 계정으로 청구
    return BillingTarget.parent;
  } else if (entity is Student) {
    if (entity.hasLinkedParent && entity.parentPaymentEnabled) {
      // 부모 결제 설정된 학생 → 부모 계정으로 청구
      return BillingTarget.parent;
    }
    return BillingTarget.student;
  }
  return BillingTarget.student;
}
```

### 청구서 모델 확장

```dart
/// 청구서 (자녀 프로필 지원)
class Invoice {
  final String id;
  final String teacherId;

  // 레슨 수혜자 (학생 또는 자녀 프로필)
  final String? studentId;           // 학생 계정 ID (만 14세 이상)
  final String? childProfileId;      // 자녀 프로필 ID (만 14세 미만)

  // 결제 책임자
  final BillingTarget billingTarget;
  final String billingAccountId;     // 실제 결제할 계정 (student/parent)

  // ... 기존 필드
}
```

### 청구서 발행 플로우

```
[선생님]
    │
    │ 청구서 발행 요청
    ▼
[시스템] 청구 대상 확인
    │
    ├─── 학생 계정 (만 14세 이상)
    │       → studentId 설정
    │       → billingAccountId = studentId
    │
    └─── 자녀 프로필 (만 14세 미만)
            → childProfileId 설정
            → billingAccountId = parentId
            → 부모에게 알림 발송
```

### 학부모 결제 UI

학부모가 자녀 프로필의 청구서를 관리할 때:

```
┌─────────────────────────────────────┐
│  ← 결제 관리                         │
├─────────────────────────────────────┤
│                                     │
│  자녀: 김민수                        │
│  ┌─────────────────────────────────┐│
│  │ 🔔 미결제 청구서                  ││
│  │                                 ││
│  │ 12월 레슨료 (중급, 주1회)        ││
│  │ 200,000원                       ││
│  │ 납부기한: 2025.12.15            ││
│  │                      [결제하기] ││
│  └─────────────────────────────────┘│
│                                     │
│  결제 내역                           │
│  ├─ 11월 레슨료   200,000원  ✓      │
│  ├─ 10월 레슨료   200,000원  ✓      │
│  └─ 체험레슨       30,000원  ✓      │
│                                     │
└─────────────────────────────────────┘
```

---

## 결제 방식

### 선생님별 설정

```dart
/// 결제 방식
enum PaymentTiming {
  prepaid,   // 선결제: 레슨 전 결제 완료 필요
  postpaid,  // 후결제: 레슨 후 청구
}

/// 선생님 결제 설정
class TeacherPaymentSettings {
  final PaymentTiming defaultTiming;      // 기본 결제 방식
  final bool allowStudentChoice;          // 학생 선택 허용 여부
}
```

### 선결제 vs 후결제

| 항목 | 선결제 | 후결제 |
|------|--------|--------|
| 결제 시점 | 레슨 전 | 레슨 후 (월말/다음 달 초) |
| 노쇼 처리 | 잔여 횟수 차감 | 100% 청구 |
| 취소 처리 | 잔여 횟수 유지/차감 | 청구 안 함/일부 청구 |
| 현금 흐름 | 안정적 | 미수금 위험 |
| 학생 부담 | 초기 비용 높음 | 부담 낮음 |

### 학생별 예외 설정

```dart
/// 학생별 결제 설정 (선생님이 설정)
class StudentPaymentConfig {
  final String studentId;
  final PaymentTiming timing;             // 해당 학생 결제 방식
  final PaymentUnit unit;                 // 결제 단위
  final int? packageSize;                 // 패키지인 경우 회수
}
```

---

## 결제 단위

### 지원 단위

```dart
/// 결제 단위
enum PaymentUnit {
  monthly,   // 월정액
  package,   // 패키지 (N회권)
}
```

### 월정액

| 항목 | 설명 |
|------|------|
| 계산 방식 | 레벨별 기본 수강료 × 주당 레슨 횟수 |
| 청구 주기 | 매월 1일 |
| 레슨 횟수 | 주 1회 = 월 4회, 주 2회 = 월 8회 |

**레벨별 수강료 (기존 유지):**

| 레벨 | 주 1회 (월 4회) | 주 2회 (월 8회) |
|------|----------------|----------------|
| 입문 (beginner) | 160,000원 | 320,000원 |
| 초급 (elementary) | 180,000원 | 360,000원 |
| 중급 (intermediate) | 200,000원 | 400,000원 |
| 고급 (advanced) | 240,000원 | 480,000원 |

### 패키지 (N회권)

```dart
/// 패키지 옵션
class PackageOption {
  final int lessonCount;          // 레슨 횟수
  final int discountPercent;      // 할인율
  final int? expirationDays;      // 유효기간 (일), null=무제한

  int calculatePrice(int basePricePerLesson) {
    final total = basePricePerLesson * lessonCount;
    return (total * (100 - discountPercent) / 100).round();
  }
}

/// 기본 패키지 옵션
const defaultPackages = [
  PackageOption(lessonCount: 4, discountPercent: 0, expirationDays: 60),
  PackageOption(lessonCount: 8, discountPercent: 5, expirationDays: 90),
  PackageOption(lessonCount: 12, discountPercent: 10, expirationDays: 120),
];
```

**패키지 할인 예시 (중급 기준, 회당 50,000원):**

| 패키지 | 정가 | 할인율 | 결제금액 | 유효기간 |
|--------|------|--------|----------|----------|
| 4회권 | 200,000원 | 0% | 200,000원 | 60일 |
| 8회권 | 400,000원 | 5% | 380,000원 | 90일 |
| 12회권 | 600,000원 | 10% | 540,000원 | 120일 |

---

## 결제 수단

### 단계별 확장 계획

| Phase | 결제 수단 | 상태 |
|-------|----------|------|
| Phase 1 | 무통장입금 (2단계 확인) | ✅ 구현 완료 |
| Phase 2 | 카카오페이, 토스페이 | 예정 |
| Phase 3 | 신용카드 (PG 연동) | 예정 |

### Phase 1: 무통장입금 (현재)

```
1. 선생님이 청구서 발행
   ↓
2. 학생에게 알림 (계좌번호, 금액)
   ↓
3. 학생이 계좌이체
   ↓
4. 학생이 "입금완료" 버튼 클릭
   ↓
5. 선생님에게 알림 (확인 대기)
   ↓
6. 선생님이 계좌 확인 후 "입금확인"
   ↓
7. 결제 완료 → 수강권 활성화
```

### Phase 2: 간편결제 (예정)

```dart
/// 결제 수단
enum PaymentMethod {
  bankTransfer,    // 무통장입금
  kakaoPay,        // 카카오페이
  tossPay,         // 토스페이
  creditCard,      // 신용카드 (Phase 3)
}
```

**간편결제 플로우:**

```
1. 선생님이 청구서 발행
   ↓
2. 학생에게 결제 링크 발송
   ↓
3. 학생이 결제 링크 클릭 → 결제 화면
   ↓
4. 카카오페이/토스 결제 완료
   ↓
5. 자동 입금확인 → 수강권 활성화
```

---

## 청구서 발행

### 발행 규칙

| 결제 단위 | 발행 시점 | 발행 방식 |
|----------|----------|----------|
| 월정액 | 매월 1일 | 자동 발행 |
| 패키지 | 잔여 2회 시 | 자동 알림 + 수동 발행 |
| 체험레슨 | 예약 확정 시 | 자동 발행 |

### 청구서 모델

```dart
/// 청구서
class Invoice {
  final String id;
  final String teacherId;
  final String studentId;
  final InvoiceType type;
  final PaymentUnit unit;
  final int amount;                      // 청구 금액
  final int? discountAmount;             // 할인 금액
  final int finalAmount;                 // 최종 금액
  final String? description;             // 청구 내역 설명
  final DateTime issuedAt;               // 발행일
  final DateTime dueDate;                // 납부 기한
  final InvoiceStatus status;
  final List<InvoiceItem> items;         // 청구 항목
}

/// 청구서 유형
enum InvoiceType {
  trial,       // 체험레슨
  monthly,     // 월정액
  package,     // 패키지
  additional,  // 추가 청구 (교재비 등)
}

/// 청구서 상태
enum InvoiceStatus {
  draft,       // 임시저장
  issued,      // 발행됨
  pending,     // 입금 대기
  awaitingConfirmation,  // 확인 대기 (학생 입금완료 표시)
  paid,        // 결제 완료
  overdue,     // 연체
  cancelled,   // 취소
}

/// 청구 항목
class InvoiceItem {
  final String description;
  final int quantity;
  final int unitPrice;
  final int? discountPercent;
  final int totalPrice;
}
```

### 자동 청구서 발행 로직

```dart
/// 월정액 자동 청구 (매월 1일 실행)
Future<void> generateMonthlyInvoices() async {
  final students = await getActiveStudents();

  for (final student in students) {
    if (student.paymentUnit != PaymentUnit.monthly) continue;

    final invoice = Invoice(
      type: InvoiceType.monthly,
      unit: PaymentUnit.monthly,
      amount: student.monthlyFee,
      description: '${DateTime.now().month}월 레슨료',
      dueDate: DateTime.now().add(Duration(days: 7)),
      items: [
        InvoiceItem(
          description: '${student.level.label} ${student.lessonFrequency}',
          quantity: student.monthlyLessonCount,
          unitPrice: student.lessonFee,
          totalPrice: student.monthlyFee,
        ),
      ],
    );

    await createInvoice(invoice);
    await sendInvoiceNotification(student, invoice);
  }
}

/// 패키지 소진 알림 (매일 체크)
Future<void> checkPackageRemaining() async {
  final students = await getActiveStudents();

  for (final student in students) {
    if (student.paymentUnit != PaymentUnit.package) continue;
    if (student.remainingLessons > 2) continue;

    // 잔여 2회 이하 → 알림 발송
    await sendPackageRenewalReminder(student);
  }
}
```

---

## 미결제 처리

### 선생님 설정

```dart
/// 미결제 처리 정책
enum UnpaidPolicy {
  notifyOnly,        // 알림만 (레슨 진행)
  blockBooking,      // 즉시 예약 차단
  graceAndBlock,     // 유예 기간 후 차단
}

/// 미결제 설정
class UnpaidSettings {
  final UnpaidPolicy policy;
  final int? graceDays;              // 유예 기간 (일)
  final List<int> reminderDays;      // 리마인더 발송일 (D-7, D-3, D-1)
}
```

### 미결제 처리 플로우

```
청구서 발행 (D-Day)
    ↓
리마인더 발송 (D+3, D+5, D+7)
    ↓
납부 기한 도래
    ↓
┌─────────────────────────────────────┐
│ 정책별 처리                          │
├─────────────────────────────────────┤
│ notifyOnly: 알림만, 레슨 계속       │
│ blockBooking: 즉시 예약 차단        │
│ graceAndBlock: 7일 유예 후 차단     │
└─────────────────────────────────────┘
    ↓
(차단 시) 결제 완료 → 차단 해제
```

### 예약 차단 UI

```
┌─────────────────────────────────────┐
│  ⚠️ 레슨 예약 불가                   │
├─────────────────────────────────────┤
│                                     │
│  미결제 청구서가 있습니다.            │
│                                     │
│  청구 내역: 12월 레슨료              │
│  금액: 200,000원                    │
│  납부 기한: 2025.12.07 (D+3)        │
│                                     │
│  결제 완료 후 레슨을 예약할 수 있습니다│
│                                     │
├─────────────────────────────────────┤
│  [결제하기]            [문의하기]    │
└─────────────────────────────────────┘
```

---

## 환불 정책

### 선생님 설정

```dart
/// 환불 정책 유형
enum RefundPolicyType {
  fullRefund,           // 잔여 레슨 100% 환불
  percentRefund,        // 잔여 레슨 N% 환불
  recalculateRefund,    // 회당 재계산 후 환불
  noRefund,             // 환불 불가
}

/// 환불 정책 설정
class RefundPolicy {
  final RefundPolicyType type;
  final int? refundPercent;          // percentRefund 시 비율
  final int? perLessonPrice;         // recalculate 시 회당 가격 (할인 제외)
  final String? customNote;          // 정책 설명 (학생에게 표시)
}
```

### 환불 계산 예시

**시나리오: 8회권 380,000원 (5% 할인) 구매, 3회 사용 후 환불 요청**

| 정책 | 계산 | 환불금액 |
|------|------|----------|
| 100% 환불 | 5회 × (380,000 ÷ 8) = 237,500 | 237,500원 |
| 90% 환불 | 237,500 × 0.9 = 213,750 | 213,750원 |
| 회당 재계산 | 380,000 - (3 × 50,000) = 230,000 | 230,000원 |

> **회당 재계산**: 할인 전 정가(50,000원/회)로 사용분 계산 후 잔액 환불

### 환불 처리 플로우

```
학생: 환불 요청
    ↓
선생님: 환불 승인/거절
    ↓
(승인 시)
    ↓
시스템: 환불금액 자동 계산 (정책 적용)
    ↓
선생님: 환불금액 확인 및 처리
    ↓
계좌이체로 환불 (Phase 1)
    ↓
환불 완료 → 수강권 비활성화
```

### 환불 기록

```dart
/// 환불 기록
class RefundRecord {
  final String id;
  final String invoiceId;
  final String studentId;
  final RefundReason reason;
  final int originalAmount;          // 원 결제 금액
  final int usedLessons;             // 사용 레슨 수
  final int remainingLessons;        // 잔여 레슨 수
  final RefundPolicyType policyApplied;
  final int refundAmount;            // 환불 금액
  final RefundStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? note;
}

/// 환불 사유
enum RefundReason {
  studentRequest,      // 학생 요청
  teacherUnavailable,  // 선생님 사정
  qualityIssue,        // 품질 불만
  relocation,          // 이사
  healthIssue,         // 건강 문제
  other,               // 기타
}
```

---

## 할인 시스템

### 패키지 할인

```dart
/// 패키지 할인 설정 (선생님별)
class PackageDiscountSettings {
  final Map<int, int> discountByCount;  // {레슨수: 할인율}

  static const defaultDiscounts = {
    4: 0,    // 4회: 0%
    8: 5,    // 8회: 5%
    12: 10,  // 12회: 10%
  };
}
```

### 할인 적용 UI

```
┌─────────────────────────────────────┐
│  패키지 선택                         │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 4회권                           ││
│  │ 200,000원                       ││
│  │ 유효기간: 60일                   ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 8회권                    🏷️ 5% ││
│  │ 400,000원 → 380,000원           ││
│  │ 유효기간: 90일                   ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 12회권                  🏷️ 10% ││
│  │ 600,000원 → 540,000원           ││
│  │ 유효기간: 120일            BEST ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

---

## 정산 관리

### 월별 리포트

```dart
/// 월별 정산 리포트
class MonthlySettlementReport {
  final String teacherId;
  final int year;
  final int month;
  final SettlementSummary summary;
  final List<SettlementDetail> details;
}

/// 정산 요약
class SettlementSummary {
  final int totalRevenue;            // 총 수입
  final int trialLessonRevenue;      // 체험레슨 수입
  final int regularLessonRevenue;    // 정규레슨 수입
  final int refundAmount;            // 환불 금액
  final int netRevenue;              // 순수입
  final int lessonCount;             // 총 레슨 수
  final int studentCount;            // 학생 수
}

/// 정산 상세
class SettlementDetail {
  final String studentId;
  final String studentName;
  final PaymentType type;            // 체험/정규
  final int lessonCount;             // 레슨 수
  final int amount;                  // 금액
  final PaymentStatus status;        // 결제 상태
}
```

### 정산 리포트 UI

```
┌─────────────────────────────────────┐
│  📊 12월 정산                  2025 │
├─────────────────────────────────────┤
│                                     │
│  총 수입                            │
│  ┌─────────────────────────────────┐│
│  │     1,240,000원                 ││
│  │     ▲ 120,000 (전월 대비)       ││
│  └─────────────────────────────────┘│
│                                     │
│  상세 내역                          │
│  ├─ 정규레슨    1,140,000원  (6명) │
│  ├─ 체험레슨      150,000원  (5명) │
│  └─ 환불         -50,000원  (1건) │
│                                     │
│  레슨 현황                          │
│  ├─ 총 레슨         28회           │
│  ├─ 정규            24회           │
│  └─ 체험             4회           │
│                                     │
├─────────────────────────────────────┤
│  학생별 상세                     >  │
├─────────────────────────────────────┤
│  김민준  중급  주1회    200,000 ✓  │
│  이서연  초급  주2회    360,000 ✓  │
│  박지호  입문  주1회    160,000 ⏳  │
│  최수아  고급  주1회    240,000 ✓  │
│  정하준  체험  1회       30,000 ✓  │
│  ...                               │
└─────────────────────────────────────┘
```

---

## 데이터 모델

### 전체 모델 구조

```dart
/// 수강권 (새로 추가)
class Subscription {
  final String id;
  final String studentId;
  final String teacherId;
  final SubscriptionType type;
  final PaymentUnit unit;
  final SubscriptionStatus status;

  // 월정액
  final int? monthlyFee;

  // 패키지
  final int? totalLessons;
  final int? remainingLessons;
  final int? packagePrice;
  final DateTime? expirationDate;

  // 공통
  final DateTime startDate;
  final DateTime? endDate;
  final String? invoiceId;           // 연결된 청구서
}

/// 수강권 유형
enum SubscriptionType {
  trial,     // 체험
  regular,   // 정규
}

/// 수강권 상태
enum SubscriptionStatus {
  pending,     // 결제 대기
  active,      // 활성
  expired,     // 만료
  exhausted,   // 소진 (패키지)
  cancelled,   // 취소
  suspended,   // 정지 (미결제)
}
```

### 선생님 결제 설정

```dart
/// 선생님 결제 설정 (통합)
class TeacherPaymentConfig {
  // 기본 설정
  final PaymentTiming defaultTiming;
  final bool allowStudentChoice;

  // 결제 수단
  final List<PaymentMethod> acceptedMethods;
  final BankAccount? bankAccount;

  // 패키지 설정
  final bool packageEnabled;
  final List<PackageOption> packageOptions;

  // 미결제 처리
  final UnpaidPolicy unpaidPolicy;
  final int? graceDays;
  final List<int> reminderDays;

  // 환불 정책
  final RefundPolicy refundPolicy;
}

/// 은행 계좌 정보
class BankAccount {
  final String bankName;
  final String accountNumber;
  final String accountHolder;
}
```

---

## UI 와이어프레임

### 선생님: 결제 설정 화면

```
┌─────────────────────────────────────┐
│  ← 결제 설정                         │
├─────────────────────────────────────┤
│                                     │
│  기본 결제 방식                      │
│  ┌─────────────────────────────────┐│
│  │ ○ 선결제 (레슨 전 결제)         ││
│  │ ● 후결제 (레슨 후 청구)         ││
│  │ ☑️ 학생별 예외 허용              ││
│  └─────────────────────────────────┘│
│                                     │
│  결제 단위                           │
│  ┌─────────────────────────────────┐│
│  │ ☑️ 월정액                        ││
│  │ ☑️ 패키지 (N회권)                ││
│  └─────────────────────────────────┘│
│                                     │
│  패키지 할인                         │
│  ┌─────────────────────────────────┐│
│  │ 4회권      0%                   ││
│  │ 8회권      5%        [수정]     ││
│  │ 12회권    10%        [수정]     ││
│  │                     [추가]      ││
│  └─────────────────────────────────┘│
│                                     │
│  미결제 처리                         │
│  ┌─────────────────────────────────┐│
│  │ ○ 알림만 (레슨 계속)            ││
│  │ ○ 즉시 예약 차단                ││
│  │ ● 7일 유예 후 차단              ││
│  └─────────────────────────────────┘│
│                                     │
│  환불 정책                           │
│  ┌─────────────────────────────────┐│
│  │ ● 잔여 레슨 100% 환불           ││
│  │ ○ 잔여 레슨 90% 환불            ││
│  │ ○ 회당 재계산 후 환불           ││
│  │ ○ 환불 불가                     ││
│  │                                 ││
│  │ 정책 설명 (선택)                 ││
│  │ ┌─────────────────────────────┐ ││
│  │ │ 레슨 시작 후에는 환불이...   │ ││
│  │ └─────────────────────────────┘ ││
│  └─────────────────────────────────┘│
│                                     │
│  계좌 정보                           │
│  ┌─────────────────────────────────┐│
│  │ 은행        [국민은행      v]   ││
│  │ 계좌번호    [123-456-789012  ]  ││
│  │ 예금주      [홍길동          ]  ││
│  └─────────────────────────────────┘│
│                                     │
├─────────────────────────────────────┤
│              [저장]                  │
└─────────────────────────────────────┘
```

### 선생님: 청구서 발행 화면

```
┌─────────────────────────────────────┐
│  ← 청구서 발행                       │
├─────────────────────────────────────┤
│                                     │
│  학생 선택                           │
│  ┌─────────────────────────────────┐│
│  │ 김민준                       >  ││
│  └─────────────────────────────────┘│
│                                     │
│  청구 유형                           │
│  ┌─────────────────────────────────┐│
│  │ ○ 월정액 (12월)                 ││
│  │ ● 패키지                        ││
│  │ ○ 추가 청구                     ││
│  └─────────────────────────────────┘│
│                                     │
│  패키지 선택                         │
│  ┌─────────────────────────────────┐│
│  │ ○  4회권   200,000원            ││
│  │ ●  8회권   380,000원  (5% 할인) ││
│  │ ○ 12회권   540,000원 (10% 할인) ││
│  └─────────────────────────────────┘│
│                                     │
│  청구 내역                           │
│  ┌─────────────────────────────────┐│
│  │ 8회권 (중급)                    ││
│  │ 정가: 400,000원                 ││
│  │ 할인: -20,000원 (5%)            ││
│  │ ─────────────────────────────── ││
│  │ 결제금액: 380,000원             ││
│  └─────────────────────────────────┘│
│                                     │
│  납부 기한                           │
│  ┌─────────────────────────────────┐│
│  │ 2025.12.15                   📅 ││
│  └─────────────────────────────────┘│
│                                     │
│  메모 (선택)                         │
│  ┌─────────────────────────────────┐│
│  │                                 ││
│  └─────────────────────────────────┘│
│                                     │
├─────────────────────────────────────┤
│    [임시저장]         [발행하기]     │
└─────────────────────────────────────┘
```

### 학생: 결제 화면

```
┌─────────────────────────────────────┐
│  ← 결제하기                          │
├─────────────────────────────────────┤
│                                     │
│  청구 내역                           │
│  ┌─────────────────────────────────┐│
│  │ 김선생님                        ││
│  │ 8회권 (중급)                    ││
│  │                                 ││
│  │ 결제금액    380,000원           ││
│  │ 납부기한    2025.12.15          ││
│  └─────────────────────────────────┘│
│                                     │
│  결제 방법                           │
│  ┌─────────────────────────────────┐│
│  │ ● 무통장입금                    ││
│  │ ○ 카카오페이 (준비중)           ││
│  │ ○ 토스페이 (준비중)             ││
│  └─────────────────────────────────┘│
│                                     │
│  입금 계좌                           │
│  ┌─────────────────────────────────┐│
│  │ 국민은행 123-456-789012         ││
│  │ 예금주: 홍길동                  ││
│  │                      [복사] 📋  ││
│  └─────────────────────────────────┘│
│                                     │
│  ⓘ 입금 후 아래 버튼을 눌러주세요    │
│                                     │
├─────────────────────────────────────┤
│         [입금완료 알리기]            │
└─────────────────────────────────────┘
```

---

## 플로우 다이어그램

### 선결제 (패키지) 전체 플로우

```
[선생님]                    [시스템]                    [학생]
    │                          │                          │
    │ 1. 청구서 발행            │                          │
    ├─────────────────────────>│                          │
    │                          │ 2. 알림 발송              │
    │                          ├─────────────────────────>│
    │                          │                          │
    │                          │          3. 결제 (입금)   │
    │                          │<─────────────────────────┤
    │                          │                          │
    │                          │    4. "입금완료" 클릭     │
    │                          │<─────────────────────────┤
    │                          │                          │
    │  5. 확인 대기 알림        │                          │
    │<─────────────────────────┤                          │
    │                          │                          │
    │ 6. "입금확인" 클릭        │                          │
    ├─────────────────────────>│                          │
    │                          │ 7. 수강권 활성화          │
    │                          ├─────────────────────────>│
    │                          │                          │
    │                          │        [레슨 진행]        │
    │                          │                          │
    │                          │ 8. 잔여 횟수 차감         │
    │                          │<─────────────────────────┤
    │                          │                          │
    │                          │ 9. 잔여 2회 알림          │
    │                          ├─────────────────────────>│
    │                          │                          │
```

### 후결제 (월정액) 전체 플로우

```
[선생님]                    [시스템]                    [학생]
    │                          │                          │
    │                          │        [레슨 진행]        │
    │                          │                          │
    │                          │ 1. 월초 청구서 자동 발행   │
    │                          │                          │
    │                          │ 2. 알림 발송 (D-7)        │
    │                          ├─────────────────────────>│
    │                          │                          │
    │                          │ 3. 리마인더 (D-3, D-1)    │
    │                          ├─────────────────────────>│
    │                          │                          │
    │                          │          4. 결제 (입금)   │
    │                          │<─────────────────────────┤
    │                          │                          │
    │                          │    5. "입금완료" 클릭     │
    │                          │<─────────────────────────┤
    │                          │                          │
    │  6. 확인 대기 알림        │                          │
    │<─────────────────────────┤                          │
    │                          │                          │
    │ 7. "입금확인" 클릭        │                          │
    ├─────────────────────────>│                          │
    │                          │ 8. 결제 완료 알림         │
    │                          ├─────────────────────────>│
    │                          │                          │
```

---

## 구현 우선순위

### Phase 1 (MVP 확장)

1. 패키지(N회권) 결제 단위 추가
2. 청구서 발행 기능
3. 잔여 횟수 관리
4. 월별 정산 리포트

### Phase 2

1. 선생님 결제 설정 화면
2. 자동 청구서 발행 (월정액)
3. 패키지 소진 알림
4. 환불 처리 기능

### Phase 3

1. 간편결제 연동 (카카오페이, 토스)
2. 미결제 자동 처리 (예약 차단)
3. 패키지 유효기간 관리
4. 정산 상세 리포트

---

## 참고 자료

- [GoCardless - Music Lessons Payments](https://gocardless.com/guides/posts/music-lessons-payments/)
- [My Music Staff - Invoices & Payments](https://www.mymusicstaff.com/invoices-payments/)
- [Duet Partner - Managing Lesson Cancellations](https://www.duetpartner.com/blog/managing-lesson-cancellations-a-guide-for-private-music-teachers)
- [클래스101 환불정책](https://class101.net/docs/refund)
- [숨고 결제/환불](https://help.soomgo.com/hc/ko/sections/4407329708173)
