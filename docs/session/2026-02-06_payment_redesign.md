# 결제 시스템 재설계: Payment → Subscription 통합

> 날짜: 2026-02-06
> 작업: 미수금 설계 검증 → 결제 시스템 통합

---

## 1. 배경

### 현재 상태

시스템에 **2개의 독립된 결제 흐름**이 존재:

| 시스템 | 엔티티 | 용도 |
|--------|--------|------|
| 레거시 결제 | `Payment` | 월정액 수강료, dueDate 기반 overdue 감지 |
| 수강권 제안 | `SubscriptionProposal` | 수강권 발급 시 2단계 입금확인 |

### 발견된 문제

| # | 문제 | 상세 |
|---|------|------|
| 1 | Payment ↔ Subscription 단절 | `Subscription.paymentId`는 optional이고 Mock에서 미사용. Payment confirmed 되어도 Subscription에 영향 없음 |
| 2 | UnpaidPolicy 미구현 | `allowLesson`, `blockLesson`, `reminderOnly` 가 `docs/schema/entities/payment.md`에만 존재. `frontend/lib/`에 코드 0건 |
| 3 | overdue 자동 전환 없음 | `Payment.isOverdue`는 클라이언트 getter일 뿐, status를 `overdue`로 변경하는 로직 없음. 백엔드 스케줄러도 없음 |
| 4 | 리마인더 미구현 | D+3, D+5, D+7 자동 리마인더 설계만 있고 푸시 알림 자체가 미구현 |
| 5 | 이중 결제 구조 | 월정액은 `Payment`, 회차권은 `SubscriptionProposal`로 처리. 동일한 "결제 확인"이 두 경로로 분산 |

---

## 2. 미수금 발생 경로 검증

### 검증 방법

실제 코드(엔티티, 리포지토리, 프로바이더, UI)를 추적하여 미수금이 발생할 수 있는 경로를 확인.

### 결과

| 시나리오 | 미수금? | 근거 |
|---------|:------:|------|
| 월정액 학생이 dueDate까지 미입금 | O | `Payment.isOverdue` getter로 감지 (레거시) |
| 회차권 제안 후 학생 미입금 | X | `SubscriptionProposal` 7일 후 `expired`. Payment 미생성 |
| 학생 입금 + 선생님 미확인 | △ | Payment에서는 감지 가능, Proposal에서는 미수금으로 안 잡힘 |
| 수강권 만료 후 재등록 미결제 | X | `LessonRequest` → `SubscriptionProposal` 경로만 있고 Payment 미생성 |
| UnpaidPolicy로 레슨 차단 | X | 코드 미구현 |

### 핵심 발견

```
SubscriptionProposal (선불 플로우)에서는 미수금이 발생하지 않음.
→ 결제 확인 전에 수강권이 발급되지 않으므로.

미수금이 실제로 발생하는 유일한 경우:
→ 선생님이 결제 확인 없이 수강권을 직접 발급 (후불)
```

---

## 3. 설계 결정

### 3.1 선불/후불 모델 정의

```
[선불] SubscriptionProposal 경로
──────────────────────────────
제안 → 학생 입금 → 선생님 확인 → 수강권 발급
                                   ↓
                          paymentConfirmed: true
                          → 미수금 아님 (결제 후 발급)

[후불] 직접 발급 경로
──────────────────────────────
선생님이 수강권 먼저 발급:
  ├── [입금 확인됨] → paymentConfirmed: true  → 미수금 아님
  └── [나중에 결제] → paymentConfirmed: false → 미수금!
```

### 3.2 결정: Payment → Subscription 통합

**결제 정보를 Subscription 엔티티에 직접 포함**

이유:
1. **단순함**: 미수금 = `!paymentConfirmed`인 활성 수강권. 별도 엔티티 불필요
2. **레거시 제거**: Payment 엔티티 + payment_repository의 이중 구조 해소
3. **현실 반영**: 선생님들이 "일단 레슨하고 나중에 받을게요" 하는 후불 케이스 지원
4. **복잡도 제거**: UnpaidPolicy, D+3/5/7 리마인더, overdue 스케줄러 등 미구현 설계 삭제

### 3.3 삭제 대상

| 대상 | 이유 |
|------|------|
| `UnpaidPolicy` enum | 미구현, 불필요한 복잡도 |
| `PaymentStatus.overdue` 자동 전환 설계 | 백엔드 없이 구현 불가, Subscription.isUnpaid로 대체 |
| D+3, D+5, D+7 리마인더 설계 | 푸시 알림 미구현, 선생님 직접 관리로 단순화 |
| `TeacherPaymentConfig.unpaidPolicy/graceDays/reminderDays` | 위 삭제에 따라 불필요 |

### 3.4 유지 대상

| 대상 | 이유 |
|------|------|
| `SubscriptionProposal` 2단계 입금확인 | 선불 플로우는 잘 설계됨 |
| `PaymentMethod` 개념 | 결제 수단 기록 필요 (Subscription에 통합) |
| 홈 화면 "미수금" StatCard | 데이터 소스만 변경 |

---

## 4. 통합 설계

### Subscription 엔티티 추가 필드

```dart
// 기존 amount 필드 활용 (할인 후 최종 금액)

@HiveField(21) final bool paymentConfirmed;              // false = 미수금
@HiveField(22) final SubscriptionPaymentMethod? paymentMethod;
@HiveField(23) final DateTime? paidAt;                    // 학생 입금완료 시점
@HiveField(24) final DateTime? paymentConfirmedAt;        // 선생님 확인 시점
@HiveField(25) final int? discountAmount;                 // 할인 금액
@HiveField(26) final String? discountReason;              // 할인 사유
@HiveField(27) final int? originalAmount;                 // 할인 전 원가
```

### 미수금 쿼리

```dart
// 미수금 = 활성 수강권 중 미결제
bool get isUnpaid => status == SubscriptionStatus.active && !paymentConfirmed;

// 미수금 목록
subscriptions.where((s) => s.isUnpaid).toList();

// 미수금 총액
unpaidList.fold(0, (sum, s) => sum + s.amount);
```

### 전체 결제 플로우 (통합 후)

```
                ┌──────────────────────┐
                │  수강권 발급 시점      │
                └──────┬───────────────┘
                       │
          ┌────────────┴────────────┐
          │                         │
[선불: Proposal]             [후불: 직접 발급]
입금 → 확인 → 발급           발급 먼저
          │                         │
paymentConfirmed: true    paymentConfirmed: false
          │                         │
          │                    ⚠️ 미수금
          │                         │
          │                 나중에 입금 확인:
          │                 paymentConfirmed → true
          │                         │
          └────────┬────────────────┘
                   │
             수강권 이용 중
```

---

## 5. 구현 계획

| Phase | 작업 | 파일 수 |
|-------|------|:------:|
| 1 | 이 로그 문서 작성 | 1 |
| 2 | Subscription 엔티티 결제 필드 추가 | 1 (+.g.dart) |
| 3 | Repository interface + Mock 업데이트 | 2 |
| 4 | Provider 추가 (unpaidSubscriptions, unpaidSummary) | 1 (+.g.dart) |
| 5 | 직접 발급 화면에 결제 옵션 UI 추가 | 1 |
| 6 | 홈 화면 미수금 StatCard 데이터 소스 변경 | 1 |
| 7 | 문서 업데이트 (flow_payment, payment_spec, schema) | 3 |

레거시 `Payment` 엔티티/리포지토리/UI 완전 삭제는 **별도 이슈**로 관리.

---

## 6. 관련 문서

| 문서 | 변경 |
|------|------|
| [flow_payment.md](../specs/lesson/flow_payment.md) | UnpaidPolicy → 후불 모델로 재작성 |
| [payment_unified_spec.md](../specs/payment/payment_unified_spec.md) | 미결제 처리 섹션 수정 |
| [payment.md (schema)](../schema/entities/payment.md) | UnpaidPolicy 삭제, Subscription 필드 추가 |
