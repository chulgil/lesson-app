# 수강료 관리 시스템 스펙

> 작성일: 2025-12-25
> 마지막 업데이트: 2025-12-28
> 상태: ✅ 구현 완료
> 연관 스펙: [invite_system_v2.md](../invite/invite_system_v2.md)

---

## 개요

민감한 부분이므로 앱에서 자동 관리하면 선생님/학생 모두에게 좋음. 2단계 입금확인 워크플로우 적용.

---

## 결제 유형

| 유형 | 설명 | 기본 금액 |
|------|------|-----------|
| 체험 레슨 | 1회, 불특정 시간 | 30,000원 |
| 정규 레슨 | 월/주 단위 | 레벨별 상이 |

---

## 레벨별 수강료

| 레벨 | 영문 | 기본 월 수강료 |
|------|------|----------------|
| 입문 | beginner | 160,000원 |
| 초급 | elementary | 180,000원 |
| 중급 | intermediate | 200,000원 |
| 고급 | advanced | 240,000원 |

---

## 결제 상태

### 현재 구현 (V1)

| 상태 | 영문 | 설명 |
|------|------|------|
| 입금 대기 | pending | 결제 생성됨 |
| 확인 대기 | pending + studentConfirmed | 학생 입금완료 표시 |
| 완료 | completed | 선생님 입금확인 완료 |
| 취소 | cancelled | 취소됨 |
| 환불 | refunded | 환불됨 |

### V2 결제 상태 (예정)

> invite_system_v2.md 정의 - 상태 전환 기반 흐름

| 상태 | 영문 | 설명 | 색상 |
|------|------|------|:----:|
| 청구됨 | pending | 결제 생성, 입금 대기 | 🟡 |
| 입금됨 | paid | 학생/학부모가 입금 기록 | 🔵 |
| 확인완료 | confirmed | 선생님이 입금 확인 | 🟢 |
| 연체 | overdue | 마감일 초과 | 🔴 |
| 취소 | cancelled | 취소됨 | ⚪ |

```dart
// V2 PaymentStatus enum
enum PaymentStatus {
  pending,    // 청구됨 (입금 대기)
  paid,       // 입금 기록됨 (학생/학부모가 입력)
  confirmed,  // 확인 완료 (선생님이 확인)
  overdue,    // 연체 (마감일 초과)
  cancelled,  // 취소
}
```

### V2 추가 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| paidAt | DateTime? | 입금 기록 시간 |
| confirmedAt | DateTime? | 선생님 확인 시간 |
| dueDate | DateTime? | 결제 마감일 |

---

## 2단계 입금확인 시스템

### 워크플로우

```
1단계: 학생이 "입금완료" 버튼 클릭 → 상태: "확인 대기" (🔔 아이콘)
2단계: 선생님이 계좌 확인 후 "입금확인" → 상태: "완료"
```

### 관련 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| studentConfirmed | bool | 학생 입금완료 표시 여부 |
| studentConfirmedAt | DateTime? | 학생 입금완료 표시 시간 |
| isAwaitingTeacherConfirmation | bool (getter) | 선생님 확인 대기 여부 |
| displayStatus | String (getter) | 2단계 상태 고려한 표시 상태 |

---

## 레슨 횟수 설정

| 설정 | 월 레슨 횟수 | 회당 수강료 계산 |
|------|-------------|-----------------|
| 주 1회 | 4회 | 월 수강료 ÷ 4 |
| 주 2회 | 8회 | 월 수강료 ÷ 8 |

### Student 모델 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| lessonsPerWeek | int | 주당 레슨 횟수 (1 또는 2) |
| monthlyLessonCount | int (getter) | 월 레슨 횟수 |
| lessonFee | int (getter) | 회당 수강료 |
| lessonFrequency | String (getter) | 표시용 문자열 |

---

## 주차 범위 설정

| 설정 | 설명 | 예시 |
|------|------|------|
| 월 전체 | 1~4주차 | 1월 1일 ~ 1월 31일 |
| 부분 기간 | 지정 주차 | 1월 3~4주차만 |

---

## 관련 파일

| 파일 | 설명 |
|------|------|
| `lib/models/student.dart` | Student, StudentLevel |
| `lib/models/payment.dart` | Payment, PaymentType, PaymentStatus |
| `lib/repositories/payment_repository.dart` | Repository + Mock |
| `lib/providers/payment/` | Riverpod providers |
| `lib/features/profile/.../payment_management_screen.dart` | 수강료 관리 화면 |

---

## 향후 계획

- [ ] SMS 자동 감지 (Android)
- [ ] 카카오페이/토스 연동
