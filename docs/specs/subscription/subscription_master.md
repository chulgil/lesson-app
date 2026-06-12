# Subscription & Tuition Deposit Policy Master Spec

> 구현 상태: ✅ 구현 완료 (Phase 1) — §3.2.4 (입금 확인 대기 가시성) 는 미구현 스펙
> Last updated: 2026-06-12 (launch-readiness audit — §3.2.4 추가)
> 상태: 통합 스펙 (기존 9개 문서 통합)
> 관련 엔티티: [subscription.md](../../schema/entities/subscription.md)
> 참고: [payment.md](../../schema/entities/payment.md)는 레거시 입금 기록 모델이며 현행 결제 API 구현 지시가 아님

---

## 목차

1. [Overview](#1-overview)
2. [Subscription System](#2-subscription-system)
3. [Subscription Proposal Flow](#3-subscription-proposal-flow)
4. [Tuition Deposit Policy](#4-tuition-deposit-policy)
5. [Lesson Policies](#5-lesson-policies)
6. [Legal Documents](#6-legal-documents)
7. [Implementation Status](#7-implementation-status)
8. [Related Specs](#8-related-specs)
9. [Change History](#9-change-history)

---

## 1. Overview

### 1.1 핵심 모델: 수강권 중심 (Subscription-Centric)

lesson-app은 **수강권(Subscription)**을 모든 레슨 관계의 중심축으로 사용한다. 수강권이 있어야 레슨 예약이 가능하고, 수강권 발급/만료 시 관계 상태(RelationshipStatus)가 자동 변경된다.

```
[수강권 중심 관계 모델]
수강권 발급 → RelationshipStatus: active
수강권 만료 → RelationshipStatus: expired
만료 후 30일 → RelationshipStatus: past
```

### 1.2 설계 원칙

| 원칙 | 설명 |
|------|------|
| **수강권 우선** | 수강권이 있어야만 레슨 예약 가능 |
| **돈은 앱 밖에서, 상태는 앱 안에서** | 수강료는 외부(계좌이체/현금)로 입금하고, 앱은 입금 상태만 관리 |
| **학생에게 단순하게** | 모든 유형을 "수강권 N회 남음"으로 통일 표시 |
| **organizationId null 패턴** | null이면 개인, 있으면 학원 |
| **다중 소속 지원** | 선생님: 여러 학원 + 개인 병행 / 학생: 학원 + 개인 병행 |

### 1.3 핵심 용어

| 내부 용어 | 학생 표시 | 설명 |
|----------|----------|------|
| Subscription | **수강권** | 모든 수강 유형 통일 |
| SubscriptionProposal | **수강권 제안** | 선생님이 학생에게 보내는 제안 |
| SubscriptionTemplate | **수강권 템플릿** | 선생님이 미리 설정한 수강권 상품 |
| paymentConfirmed | **입금 확인 여부** | 수강권 발급/확정에 필요한 상태값 |
| paymentStatus | **입금 상태** | 수강권 제안 흐름의 상태값 |
| BillingType | (학생 미표시) | monthly / perPackage |
| remainingLessons | **N회 남음** | 학생에게 보이는 핵심 정보 |
| bonusCount | **보너스 +N회** | 5주차, 이벤트 등 추가 지급 |

### 1.4 플랫폼 분리

| 역할 | 플랫폼 | 주요 기능 |
|------|--------|----------|
| 학생/학부모 | 모바일 앱 | 수강권 확인, 레슨 예약, 연습 도구 |
| 개인 선생님 | 모바일 앱 | 레슨 기록, 수강권 발급/관리 |
| 학원 강사 | 모바일 앱 | 레슨 기록 |
| 학원 대표/매니저 | 웹 (예정) | 학원 설정, 수강권 발행, 레슨/수강권 운영 리포트 |

---

## 2. Subscription System

### 2.1 Core Concepts

#### 2.1.1 계정 타입 및 역할

```
개인 계정 (Personal)           학원 계정 (Academy)
 - 선생님 (Teacher)             - 대표 (Owner): 모든 권한
 - 학생 (Student)               - 매니저 (Manager): 학생 배정, 수강권 발행
 - 학부모 (Parent)              - 강사 (Instructor): 배정 학생만 관리
                                - 수강생 (Member)
```

#### 2.1.2 다중 소속 구조

선생님은 여러 학원에 소속될 수 있고, 학생은 학원 레슨 + 개인 레슨을 병행할 수 있다.

```
[선생님 A]
    ├── OO음악학원 소속 (강사) → 학생 1, 2, 3
    ├── XX피아노학원 소속 (강사) → 학생 4, 5
    └── 개인 레슨 → 학생 6, 7

[학생 B]
    ├── OO음악학원 바이올린 (선생님 A) → 8회권
    └── 개인 피아노 (선생님 C) → 월정액
```

**관계 모델:**

```
Teacher ──┬── Membership ──── Organization (학원)
          └── TeacherStudentRelation ── Student
                    ├── organizationId (nullable: null이면 개인)
                    ├── subscriptionId (연결된 수강권)
                    └── instrument (악기)
```

#### 2.1.3 데이터 소유권 (3자 공동)

| 데이터 유형 | 소유권 | 선생님 탈퇴 후 | 학생 탈퇴 후 |
|------------|--------|--------------|-------------|
| 레슨 기록 | 3자 공동 | 학생 계속 열람 | 선생님/학원 보관 |
| 학생 메모 | 3자 공동 | 학생 계속 열람 | 선생님/학원 보관 |
| 레퍼토리 | 3자 공동 | 학생 계속 열람 | 선생님/학원 보관 |
| 녹음 파일 | 3자 공동 | 학생 계속 열람 | 선생님/학원 보관 |
| 연습 기록 | 학생 | 학생 소유 유지 | - |
| 학생 연락처 | 학생 | **즉시 차단** | - |
| 수강권 기록 | 학원/선생님 | 학생 열람 가능 | 선생님/학원 보관 |

**레슨 기록 공개 범위 (3단계, 학생 설정):**

| 공개 레벨 | 설명 | 기본값 적용 대상 |
|----------|------|----------------|
| 전체 공개 | 누구나 열람 | 레퍼토리 목록 |
| 현재 선생님만 | 담당 선생님만 | 레슨 노트, 연습 기록 |
| 비공개 | 본인만 | 녹음 파일, 연락처(변경불가), 결제정보(변경불가) |

### 2.2 수강권 유형 및 생명주기

#### 2.2.1 수강권 유형

| 유형 | 설명 | 미사용분 | 기간 표시 | 횟수 표시 |
|------|------|:-------:|:--------:|:--------:|
| **체험** (Trial) | 1회 체험 레슨 | - | - | 1회 |
| **월정액** (Monthly) | 월 단위 정기 (월 N회 포함) | 소멸 | D-N | N/M회 |
| **회차권** (Package) | N회권 (유효기간 있음) | 이월 | D-N | N/M회 |

**월정액 vs 회차권 핵심 차이:**

| 구분 | 월정액 | 회차권 |
|------|--------|--------|
| 미사용분 | 소멸 (다음달 이월 불가) | 이월 (유효기간 내) |
| usedLessons 리셋 | 매월 초 리셋 | 누적 |
| 5주차 정책 | 해당 | 해당 없음 |
| 입금 주기 | 매월 고정일 | 불규칙 (수업 시작 전) |
| 적합 대상 | 규칙적 수강 | 불규칙 일정 |

#### 2.2.2 Enum 정의

```dart
/// 수강권 유형
enum SubscriptionType {
  trial,    // 체험 (1회)
  monthly,  // 월정액 (기간제, 월 N회 포함)
  package,  // 회차권 (횟수제, N회권)
}

/// 수강권 상태
enum SubscriptionStatus {
  active,       // 이용중 (정상 사용 가능)
  expiringSoon, // 만료 임박 (D-7 이내 또는 1회 남음)
  expired,      // 만료됨 (기간 초과 또는 횟수 소진)
  paused,       // 일시정지 (학생 요청)
}

/// 과금 기준
enum BillingType {
  perPackage, // 회차 기준 입금
  monthly,    // 월정액 기준 입금
}

/// 5주차 정책 (월정액 전용)
enum FifthWeekPolicy {
  skip,     // 휴강
  bonus,    // 보너스 지급 (+1회)
  deduct,   // 기존에서 차감
  optional, // 학생 선택
}

/// 입금 수단
enum SubscriptionPaymentMethod {
  cash,         // 현금
  bankTransfer, // 계좌이체
  card,         // Deprecated: 현행 수강료 입금 정책에서는 사용 금지
  other,        // 기타
}
```

#### 2.2.3 필드 구조

| 필드 | 체험 | 월정액 | 회차권 | 설명 |
|------|:----:|:-----:|:------:|------|
| `lessonsPerMonth` | - | 4 | - | 월 포함 횟수 |
| `totalLessons` | 1 | - | 8 | 총 횟수 |
| `usedLessons` | 0~1 | 매월 리셋 | 누적 | 사용 횟수 |
| `bonusCount` | - | 5주차 등 | 이벤트 | 보너스 횟수 |
| `billingType` | - | monthly | perPackage | 입금 확인 방식 |
| `billingDay` | - | 27 | - | 입금 예정일 (월정액) |
| `startDate` | O | O | O | 시작일 |
| `endDate` | - | O | O | 만료일 |
| `carryOver` | - | false | true | 이월 가능 여부 |
| `paymentConfirmed` | - | O | O | 입금 확인 여부 |
| `scheduledLessons` | - | O | O | 실제 잡힌 레슨 수 (활성 `LessonBooking` 카운트). `remainingLessons` 와 별개 트랙. 상세: [makeup_credit_spec.md §3.2](makeup_credit_spec.md) |
| `autoExtendedDays` | - | O | O | 휴가 모드로 자동 연장된 누적 일수. `expiresAt` 추적용. 상세: [../schedule/teacher_vacation_mode.md §5.3](../schedule/teacher_vacation_mode.md) |

**잔여 횟수 계산:**

```dart
int get remainingLessons {
  final base = type == SubscriptionType.monthly
      ? lessonsPerMonth
      : totalLessons;
  return (base ?? 0) + bonusCount - usedLessons;
}
```

#### 2.2.4 회차권 발급 프리셋

| 회차 프리셋 | 자동 유효기간 |
|:----------:|:------------:|
| 4회 | 1개월 (30일) |
| 12회 | 3개월 (90일) |
| 24회 | 6개월 (180일) |
| 48회 | 1년 (365일) |
| 직접 입력 | 커스텀 |

#### 2.2.5 보너스 수강권 (bonusCount)

5주차 보너스, 이벤트, 추천, 대량 구매 등으로 추가 지급되는 횟수.

```
학생 표시 예시:
수강권 5회 남음
├── 기본: 4회
├── 보너스: +1회 (5주차)
└── 사용: 0회
```

#### 2.2.6 5주차 정책 (월정액 전용)

| 정책 | 설명 | 학생 표시 |
|------|------|----------|
| **skip** (기본) | 5주차 자동 휴강 | "7/29 휴강" |
| **bonus** (권장) | 보너스 수강권 지급 | "보너스 +1회" |
| **deduct** | 기존 수강권에서 차감 | "수강권 -1회 차감" |
| **optional** | 학생 선택 | "5주차 수업 선택" |

#### 2.2.7 대량 구매 할인/보너스

| 유형 | 설명 | 예시 |
|------|------|------|
| 할인율 (discount) | 금액에서 N% 할인 | 10회권 10% 할인 |
| 보너스 횟수 (bonusLessons) | 무료 N회 추가 | 10회 구매 시 +1회 무료 |

#### 2.2.8 부가 서비스 옵션 (학원)

| 유형 | 제한 방식 | 예시 |
|------|----------|------|
| 연습실 | 무제한 / 횟수제 / 시간제 | 무제한, 월 10회 |
| 악기 대여 | 기간제 | 바이올린, 첼로 |
| 녹음실 | 횟수제 | 월 2회 |
| 합주실 | 횟수제 | 월 4회 |

#### 2.2.9 교차 수강권 (학원)

하나의 수강권으로 여러 악기/클래스를 자유롭게 수강하는 모델.

| SubscriptionScope | 설명 | 사용 예시 |
|-------------------|------|----------|
| `singleClass` (기본) | 지정 클래스에서만 사용 | 기존 방식 |
| `multiClass` | 지정한 클래스들에서만 | 피아노+바이올린만 |
| `organization` | 학원 내 모든 클래스 | 교차 수강권 |

### 2.3 수강권 생명주기 (Lifecycle)

```
[수강권 생성]
     │
     ▼
  pending ──── 입금 확인 완료 ────▶ active
  (대기)                       (활성)
                                 │
                  ┌──────────────┼──────────────┐
                  ▼              ▼              ▼
            exhausted       expired        suspended
            (소진)          (만료)          (정지)
                  │              │              │
                  └──────────────┴──────────────┘
                                 │
                                 ▼
                            cancelled
                             (취소)
```

**관계 상태 연동:**

| 이벤트 | RelationshipStatus 변경 |
|--------|------------------------|
| 수강권 발급 | → `active` |
| 수강권 만료 | → `expired` |
| 만료 후 30일 | → `past` |

### 2.4 Status & Visual System (3+1 색상)

**핵심 원칙:** 3+1 색상 시스템으로 단순하고 명확한 상태 전달

| 상태 | 조건 | 색상 | 코드 | 비고 |
|------|------|------|------|------|
| **이용중** | 정상 사용 중 | 보라 | #6B5B95 | 브랜드 컬러 |
| **갱신 필요** | D-7 이하 OR 잔여 1회 | 주황 | #F4A460 | 행동 유도 |
| **사용 완료** | 잔여 = 0 | 연보라 | #9A8BC4 | 성취감 표현 |
| **일시정지** | 수동 정지 | 회색 | #999999 | 80% opacity |
| **만료됨** | 유효기간 경과 | 회색 | #999999 | 70% opacity |

**판정 우선순위:**

```dart
if (subscription.isDepleted) → 사용 완료 (연보라)
else if (subscription.isExpired) → 만료됨 (회색)
else if (subscription.isExpiringSoon) → 갱신 필요 (주황)
else if (subscription.status == paused) → 일시정지 (회색)
else → 이용중 (보라)
```

**UX 설계 원칙:**
- 빨강 미사용: "내가 뭔가 잘못했다"는 부정적 인상 방지
- 비활성 = 페이드아웃: opacity 낮춰 현재 활성 수강권에 집중 유도
- 사용 완료 = 브랜드 컬러: "완료했다"는 성취감

### 2.5 개인 vs 학원 수강권

| 항목 | 개인 선생님 | 학원 |
|------|-----------|------|
| 발행 주체 | 선생님 본인 | 대표/매니저 |
| 발급 위치 | 앱 | 웹 (매니저) |
| 수금 계좌 | 선생님 계좌 | 학원 계좌 |
| 수강권 필수 | 선택 가능 (설정) | **필수** |
| 사용 차감 | 선생님이 레슨 기록 시 | 담당 강사가 레슨 기록 시 |

**수강권 필수 정책:**
- 학원 모드: 수강권 없으면 레슨 기록 불가 ("활성 수강권이 없습니다")
- 개인 모드 (선택 시): 수강권 없이도 레슨 가능 (경고만 표시)

### 2.6 수강권 이름 및 예약 정책

#### 수강권 커스텀 이름

선생님이 수강권에 커스텀 이름 지정 가능 (예: 바이올린수강권, 그룹레슨수강권, 특강수강권)

#### 변경/취소 횟수 제한 (Reschedule Limit)

선생님이 수강권별로 레슨 변경/취소 가능 횟수 설정. 횟수 소진 시 학생은 선생님에게 직접 문의해야 함.

#### 학생 자율 예약 (Auto Confirm)

`autoConfirm = true`: 학생이 예약하면 선생님 컨펌 없이 즉시 확정. 기존 방식(`false`)은 선생님 승인/거절 필요.

### 2.7 갱신 알림 설정

| 항목 | 설명 | 기본값 |
|------|------|--------|
| `renewalAlertThreshold` | 잔여 N회 이하일 때 알림 | 1회 |
| `renewalAlertDays` | 만료 N일 전 알림 | 7일 |

알림 방식: 앱 푸시 알림, 앱 내 배지 표시, 학부모 알림 (선택)

---

## 3. Subscription Proposal Flow

> **2026-06-01 E2E 감사 보강** (#2·#3·#6·#4·#7):
> - **알림톡 자동 발송 (§3.6, §4.X)** — 제안 송신 시 LNZ_INVOICE, 입금 확인 시 LNZ_PAYMENT_CONFIRM. 템플릿 상세: [alimtalk_templates.md](../notification/alimtalk_templates.md)
> - **선생님 측 입금 대시보드 (신규 §4.X)** — 입금 미확인 N건 집계 + D+1/3/7 자동 리마인드. 상세: [payment_tracking_dashboard.md](payment_tracking_dashboard.md)
> - **입금 확인 Undo (신규 §4.X)** — 24시간 윈도우 내 되돌리기. 첫 레슨 차감 발생 시 불가
> - **수강권 자동 연장 (§2.X)** — 선생님 휴가 모드 시 휴가 일수만큼 만료일 연장. 상세: [../schedule/teacher_vacation_mode.md](../schedule/teacher_vacation_mode.md)
> - **`scheduledLessons` 별도 트랙 + Make-up Bank (§2.X)** — 일괄변경 후 회차 정합성. 상세: [makeup_credit_spec.md](makeup_credit_spec.md)
>
> **범위 명시**: 본 보강은 송금 자동화 아님. 외부 무통장입금 모델 유지 (§1.2 "돈은 앱 밖에서").

### 3.1 통합 수강권 플로우 — Template-First (v7)

> **v7 핵심 변경**: 기존 "수강권 제안"과 "수강권 발급(직접)" 두 개의 분리된 경로를
> 하나의 **Template-First 플로우**로 통합. 템플릿 선택이 Primary Path, 직접 입력은 Fallback.

#### 3.1.1 수강권 템플릿 시스템

선생님이 자주 사용하는 수강권 구성을 미리 저장하고 재사용한다. 가입 시 기본 3개 자동 생성.

| 필드 | 필수 | 설명 | 예시 |
|------|:----:|------|------|
| name | O | 템플릿 이름 | "바이올린 8회권" |
| instrument | O | 악기 | "바이올린" |
| totalLessons | O | 총 횟수 | 8 |
| amount | O | 금액 (원) | 380000 |
| lessonDuration | O | 레슨 시간 (분) | 60 |
| validityDays | O | 유효 기간 (일) | 60 |
| rescheduleLimit | O | 변경 가능 횟수 | 2 |
| description | - | 설명 | "주 1회 권장" |
| isActive | O | 활성화 여부 | true |

**프로필 메뉴판 공개:** 템플릿이 선생님 프로필에 메뉴판처럼 공개되어 학생이 미리 확인 가능.

> **금액/기간 수정은 템플릿 관리에서만** — 선택 시점에서는 수정 불가 (UX 단순화)

#### 3.1.2 통합 플로우 (3단계)

**진입점 (모두 동일 화면으로):**
- 학생 상세 화면 > [수강권 제안/발급]
- 학생 목록 > 길게 누르기 > "수강권 제안"
- 체험레슨 완료 후 > "정규레슨 제안하기"
- 레슨 요청 확인 > "수강권 제안하기"
- 기존 "수강권 발급" 진입점 → 동일 화면으로 리다이렉트

**Step 1**: 학생 선택 (또는 이미 선택됨)

**Step 2**: 템플릿 선택 — **Selectable Card UI** (최대 3개)
- 카드 전체가 터치 영역 (InkWell)
- 선택 시: 2px 보라 테두리(#6B5B95) + 우상단 체크 아이콘
- "추천" 뱃지: 주황색(#F4A460) 필, 추천 템플릿은 기본 선택됨
- 3개 초과 시: 나머지 카드 40% opacity + 스낵바
- 하단: `+ 직접 입력으로 발급` 폴백 (텍스트 버튼)

**Step 3**: 액션 분기

| 조건 | 제안 보내기 | 즉시 발급 |
|------|:---------:|:--------:|
| 1개 선택 | 가능 | **가능** |
| 2~3개 선택 | 가능 | 불가 (학생 선택 필요) |
| 직접 입력 | 불가 | **가능** (유일한 옵션) |

- **제안 보내기**: 학생에게 알림 → 학생이 1개 선택 → 입금 → 확인 → 발급
- **즉시 발급**: 입금 확인 완료 또는 무료/앱 전환 사유 확인 → 바로 수강권 생성

#### 3.1.3 학생 측 — 제안 수신

- **1개 제안**: 라디오 버튼 없이 수락/거절만 표시
- **2~3개 제안**: 라디오 버튼으로 1개 선택 후 입금

#### 3.1.4 자동 제안 설정

| 설정 | 기본값 | 설명 |
|------|--------|------|
| 체험 후 자동 제안 | ON | 체험 완료 시 자동 학생에게 발송 |
| 자동 제안 대상 | 템플릿별 체크 | "자동" 표시된 템플릿만 포함 |
| 골든타임 할인율 | 10% | 체험 완료 후 한정 시간 할인 |
| 골든타임 유효시간 | 24시간 | 체험 완료 시점 기준 |
| 자동 리마인더 | ON | 24h/48h/72h/7일 자동 발송 |

#### 3.1.5 중복 제안 차단 (launch-readiness audit P1-4, 2026-06-12)

> 배경: 같은 학생에게 `pending` 또는 `paymentNotified` 상태의 제안이 이미 존재할 때
> 새 제안을 보낼 경우 학생이 이중 입금할 위험이 있다. 이 섹션은 해당 상황의
> FE 경고 다이얼로그와 BE 단일 활성 제안 제약을 명세한다.

**FE — 제안 생성 전 중복 감지:**

제안 전송 버튼 탭 시, 선택한 학생에 대해 `pending` 또는 `paymentNotified` 상태의 제안이
존재하면 전송을 중단하고 경고 다이얼로그를 표시한다.

```
┌─────────────────────────────────────────┐
│ 대기 중인 제안이 있어요                    │
│                                         │
│ OOO 님에게 아직 확정되지 않은 제안이       │
│ 있어요. 기존 제안을 취소하고 새로 보내거나,  │
│ 기존 제안을 확인하세요.                    │
│                                         │
│  [기존 제안 보기]  [기존 제안 취소 후 재제안] │
└─────────────────────────────────────────┘
```

| 버튼 | 동작 |
|------|------|
| [기존 제안 보기] | 다이얼로그 닫기 + 기존 제안 상세 화면으로 이동 |
| [기존 제안 취소 후 재제안] | 기존 제안 `cancelled` 처리 후 새 제안 전송 진행 |

**BE — 단일 활성 제안 제약:**

동일 `(teacherId, studentId)` 쌍에 대해 `pending` 또는 `paymentNotified` 상태의
`SubscriptionProposal` 은 동시에 1개만 허용한다. 서버는 이를 위반하는 제안 생성 요청을
`409 Conflict` 로 거부한다.

```
POST /api/v1/proposals
→ 409 Conflict (중복 활성 제안 존재 시)
  { "error": "active_proposal_exists", "proposalId": "..." }
```

FE는 409 응답 수신 시 위 경고 다이얼로그를 표시한다 (동시성 방어선으로 활용).

**자동 제안 예외:** 체험 후 자동 제안(§3.1.4)도 동일 규칙 적용 — 이미 활성 제안이 있으면
자동 제안 발송을 건너뛰고 선생님 홈 인박스에 "이미 대기 중인 제안이 있어 자동 제안을 건너뜠어요" 안내.

### 3.2 Student Confirmation (학생 측)

#### 3.2.1 제안 확인 플로우

```
학생 알림 수신 → 제안 상세 확인 (금액/횟수/유효기간/계좌)
    → [옵션 선택 (복수인 경우)]
    → 외부 입금 진행
    → [입금 완료 알림] 클릭
    → 선생님 입금 확인
    → 수강권 자동 발급
    → 스케줄 확인 카드 표시
```

#### 3.2.2 제안 상태 (ProposalStatus)

| 상태 | 설명 | 다음 액션 |
|------|------|----------|
| `pending` | 제안됨, 학생 확인 대기 | 학생: 입금 후 알림 or 거절 |
| `paymentNotified` | 학생이 입금 완료 알림 | 선생님: 입금 확인 |
| `confirmed` | 입금 확인, 수강권 발급됨 | 학생: 레슨 예약 |
| `rejected` | 학생이 거절 | 종료 |
| `expired` | 7일 경과 자동 만료 | 재제안 가능 |
| `cancelled` | 선생님이 취소 | 재제안 가능 |

#### 3.2.3 입금 확인 프로세스

**입금 확인 = 수강권 발급** (자동 처리):

```dart
void onPaymentConfirmed(Proposal proposal) {
  // 1. 수강권 발급
  final subscription = issueSubscription(proposal);
  // 2. 관계 상태 변경 → active
  updateRelationStatus(RelationshipStatus.active);
  // 3. 스케줄 확인 카드 생성 (학생에게 표시)
  createScheduleConfirmationCard(...);
  // 4. 알림 발송
  notifyStudent("수강권 발급! 레슨 시간을 확정해주세요");
}
```

**입금 미확인 시:** 학생에게 "입금 내역을 확인할 수 없습니다" 메시지 전송.

#### 3.2.4 입금 확인 대기 중 학생/학부모 화면 (paymentNotified 가시성)

> 추가: 2026-06-12 launch-readiness audit.
> 배경: §3.2.2 의 `paymentNotified` 상태는 선생님 측 다음 액션(입금 확인)만
> 정의하고, **대기하는 학생/학부모가 무엇을 보는지** 명세가 없었다.
> 무통장입금 구조상 확인까지 시차(수 시간~1일)가 존재하므로, 피드백 없는
> 대기는 "입금했는데 수강권이 안 나왔다" 민원의 1차 원인이 된다.

**[입금 완료 알림] 클릭 직후 (즉시 피드백):**

| 요소 | 명세 |
|------|------|
| 시각 피드백 | 체크마크 + "선생님에게 전달되었어요" (SnackBar 또는 인라인 전환) |
| 버튼 상태 | [입금 완료 알림] → 비활성 + 라벨 "입금 확인 대기 중" |
| 중복 전송 | 동일 제안에 입금 완료 알림 재전송 불가 (멱등) |

**대기 중 상태 표시 (제안 상세 + 수강권 탭):**

| 위치 | 표시 |
|------|------|
| 제안 상세 화면 | 상태 배너 "선생님이 입금을 확인하면 수강권이 발급돼요" (wait/grey 톤) |
| 진행 단계 표시 | 입금 알림 ✓ → **확인 대기 (현재)** → 수강권 발급 — 3단계 프로그레스 |
| 학부모 (자녀 대리 결제) | 자녀 카드에 동일 상태 노출 — 학생과 같은 의미 체계 사용 |

**선생님 측 보조 장치 (확인 지연 방지):**

| 트리거 | 동작 |
|--------|------|
| 입금 완료 알림 수신 | 선생님에게 push (`paymentReceived`, 기본 ON) + 홈 액션 박스에 "입금 확인 필요" 노출 |
| 24h 미확인 | 선생님에게 리마인드 1회 ("OOO 님의 입금 확인이 기다리고 있어요") |
| 확인 완료 | §3.2.3 흐름 + **학생/학부모에게 push** ("수강권이 발급되었어요") — 대기 종료를 명시적으로 알림 |

### 3.3 시나리오별 분기

#### 3.3.1 Enrollment (신규 등록)

```
프로필 메뉴판 확인 → 체험레슨 예약 → 체험 완료
    → 골든타임 할인 제안 (24h 한정)
    → (자동 리마인더 24h/48h/72h)
    → 입금 → 발급 → 스케줄 확인
```

#### 3.3.2 Reactivation (재등록)

수강권 만료/이전 학생이 능동적으로 재등록 요청하는 플로우.

**LessonRequest 시스템:**
- `expired` 또는 `past` 상태의 학생이 [레슨 요청] 버튼으로 의사 표현
- 선생님이 요청 확인 → [수강권 제안] 또는 [정중히 거절]
- 수강권 발급 시 이전 스케줄 자동 복원 (학생 확인 후 확정)
- 7일 미응답 시 자동 만료

**LessonRequest 상태:**

| 상태 | 설명 |
|------|------|
| `pending` | 요청 대기 |
| `proposalSent` | 수강권 제안됨 |
| `accepted` | 수락됨 |
| `declined` | 레슨 불가 |
| `expired` | 만료됨 (7일) |
| `cancelled` | 취소됨 |

**복수 선택 기능 (v4):** 선생님이 여러 학생을 체크박스로 선택하여 일괄 수강권 제안 가능.

#### 3.3.3 Renewal (갱신)

재수강(갱신)은 **시스템이 자동으로 제안**한다. 선생님 개입 없이 학생이 바로 갱신 가능.

**갱신 트리거 (시스템 자동):**

| 트리거 | 조건 | 학생 알림 |
|--------|------|----------|
| 소진 임박 | 남은 횟수 <= 2회 | "수강권이 2회 남았어요" + [갱신하기] |
| 만료 임박 | 유효기간 7일 이내 | "7일 후 만료됩니다" + [갱신하기] |
| 완전 소진 | 남은 횟수 = 0 | "모두 소진되었어요" + [갱신하기] |

**갱신 플로우:** 학생이 [같은 수강권 갱신하기] 또는 [다른 수강권 보기] 선택 → 입금 → 선생님 입금 확인 → 수강권 발급

**갱신 vs 신규 제안:**

| 항목 | 신규 제안 | 갱신 |
|------|----------|------|
| 시작 주체 | 선생님 | 시스템 (학생 액션) |
| 엔티티 | SubscriptionProposal | SubscriptionRenewal |
| 수강 이력 | 미표시 | 이전 수강 이력 표시 |

#### 3.3.4 Additional (추가 악기)

이전 기록이 없는 추가 악기 등록: "레슨 시간을 선택해주세요" → 가용시간에서 선택.

#### 3.3.5 앱 전환 (기존 정기레슨 → 앱)

이미 입금 확인 완료된 상태이므로 입금 확인 없이 바로 수강권 발급.

| 항목 | 일반 발급 | 앱 전환 |
|------|----------|--------|
| 입금 상태 | 입금대기(후불) → 입금 확인 완료 | **이미 입금 확인됨** |
| 입금 확인 | 필요 | 불필요 |
| 스케줄 | 학생 확인 | **선생님 직접 입력** |
| 단계 수 | 5단계 | 3단계 |

### 3.4 리드 관리 시스템

체험레슨을 완료했지만 전환하지 않은 잠재 학생을 추적한다.

**리드 상태:**

| 상태 | 조건 | 설명 |
|------|------|------|
| `hot` | 체험 후 0~24시간 | 전환 가능성 높음 |
| `warm` | 24~72시간 | 관심 있으나 고민 중 |
| `cold` | 72시간+ | 관심 식어감 |
| `converted` | 정규레슨 시작 | 전환 완료 |
| `lost` | 거절 또는 7일 무응답 | 이탈 |

### 3.5 골든타임 전환

체험레슨 직후 24시간 한정 할인을 제공하여 즉시 전환 유도.

| 항목 | 값 | 설정 |
|------|-----|------|
| 기본 할인율 | 10% | 선생님 설정 가능 (0~20%) |
| 유효 시간 | 24시간 | 체험 완료 시점 기준 |
| 적용 대상 | 첫 수강권 | 체험레슨 제외 |

### 3.6 자동 리마인더

체험 후 "다음에 할게요"를 선택한 학생에게 앱이 자동 발송. 선생님은 설정만 하면 됨.

| 단계 | 발송 시점 | 메시지 톤 |
|:----:|----------|----------|
| 1 | 24시간 후 | 부드러운 리마인드 |
| 2 | 48시간 후 | 혜택 강조 |
| 3 | 72시간 후 | 마감 임박 긴급성 |
| 4 | 7일 후 | 마지막 기회 |

**원칙:**
- 선생님 이름으로 발송 ("김선생님이 기다리고 있어요")
- 최대 4회, 무응답 시 중단
- 학생 알림 해제 옵션 제공
- 선생님에게 발송 내역 표시 (투명성)

---

## 4. Tuition Deposit Policy

### 4.1 현행 범위

수강권 도메인의 현행 흐름은 앱 내 결제가 아니다. 선생님/학원과 학생/학부모 사이의 수강료는 앱 밖에서 무통장입금, 현금 등으로 처리하고, 앱은 수강권 제안/입금 안내/입금 완료 알림/입금 확인 필요/입금대기(후불)/수강권 발급 상태만 기록한다.

**용어 정책**:
- **후불**: 수강권 발급 방식이다. 학생에게 부정적 상태명으로 단독 노출하지 않는다.
- **입금대기(후불)**: 후불 수강권이 발급됐고 아직 입금 완료 기록이 없는 상태다. 시스템 판별은 `Subscription.status == active && paymentConfirmed == false && paidAt == null`이다.
- **입금 확인 필요**: 학생/학부모가 입금 완료를 알렸지만 선생님이 아직 확인하지 않은 상태다. 시스템 판별은 `Subscription.status == active && paymentConfirmed == false && paidAt != null`이다.
- **입금 확인 완료**: 선생님이 입금을 확인한 상태다. 시스템 판별은 `paymentConfirmed == true`이다.

| 흐름 | 정책 | 앱의 역할 |
|------|------|-----------|
| 선생님 ↔ 학생/학부모 | 무통장입금/현금 등 외부 입금 | 수강권 제안, 입금 안내, 입금 완료 알림, 수강권 확정 상태 기록 |
| 학원 ↔ 학생/학부모 | 무통장입금/현금 등 외부 입금 | 학원 수강권 입금 상태 기록 |
| Lessonaza 앱관리자 → 사용자 | 미래 스펙에서 별도 정의 | 현재 구현/정의 없음 |

### 4.2 현행 금지 범위

현재 스펙은 다음 기능을 정의하지 않는다:

- `/payments/*` 라우터
- 독립 `payment_service`
- 카드/간편결제/PG SDK
- PG webhook
- 카드 토큰화
- 자동 입금 매칭
- 앱 발행 영수증
- 정산/수수료/에스크로
- 수강료 환불 처리 기능
- 선생님/학원 수강료에 대한 앱 중개 결제

기존 코드의 `Payment` 모델은 현행 API 구현 지시가 아니다. 수강권 흐름의 상태 기록 또는 레거시 모델로만 해석한다.

### 4.3 수강권 제안 상태

수강권 제안 플로우는 입금 상태를 제안/수강권 상태로만 표현한다.

| 상태 | 의미 | 구현 위치 |
|------|------|-----------|
| `pending` | 제안됨, 학생 확인 대기 | `SubscriptionProposal` |
| `paymentNotified` | 학생/학부모가 외부 입금 후 앱에서 입금 완료 알림 | `SubscriptionProposal.status` |
| `confirmed` | 선생님/학원이 실제 입금 확인 후 수강권 발급/확정 | `SubscriptionProposal.status`, `Subscription.paymentConfirmed` |

이 상태는 결제 API가 아니라 수강권 입금 상태 흐름의 일부다.

### 4.4 미래 앱 사용료 과금

향후 결제 스펙은 Lessonaza 앱관리자가 선생님/학생/학부모/학원에게 사용료를 받는 구조에만 적용한다. 예: 선생님 SaaS 구독, 학생 프리미엄 기능, 학부모 플랜, 학원 라이선스.

해당 미래 스펙이 완성되기 전까지 요금제, PG, 환불, 영수증, 관리자 매출 대시보드, `/billing/*` API는 정의하지 않는다.

> **코드 반영 2026-06-03**: 흐름 B(앱 사용료) 요금제·IAP·영수증은 이미 코드에 구현되어 별도 SSOT([paywall_spec.md](./paywall_spec.md))로 정의됨. 본 §4.4 "미래" 문구는 흐름 A(선생님↔학생 수강료) 한정으로 읽는다 — 수강료 PG는 여전히 미정의(무통장입금 유지). 앱 사용료 결제 모델은 `features/billing` + paywall_spec.md 참조 (`/api/v1/me/billing/*`).

> 상세 정책: [payment_architecture.md](./payment_architecture.md)

## 5. Lesson Policies

### 5.1 Cancellation Policy (취소 정책)

#### 5.1.1 기본 원칙

| 원칙 | 설명 |
|------|------|
| 선생님 시간 보호 | 시간 확보된 경우, 학생 사유 당일 취소는 횟수 차감 |
| 학생 권리 보호 | 선생님 사유 취소는 반드시 다른 날짜로 변경 |
| 사전 통보 기준 | 24시간 기준으로 사전/당일 구분 |
| 명확한 기록 | 모든 취소/변경 이력을 SubscriptionUsage에 기록 |

#### 5.1.2 취소 주체별 정책

| 취소 주체 | 사전 취소 (24h+) | 당일 취소 (24h 이내) | 미출석 |
|----------|:---------------:|:------------------:|:----:|
| **학생** | 횟수 유지 | 횟수 차감 | 횟수 차감 |
| **선생님** | 날짜 변경 (횟수 유지) | 날짜 변경 (횟수 유지) | - |
| **상호 합의** | 날짜 변경 (횟수 유지) | 날짜 변경 (횟수 유지) | - |

#### 5.1.3 레슨 완료 확인 방식

```
레슨 예정 시간 종료
    ├── 선생님이 레슨 노트 작성 → 자동 완료 처리 (횟수 차감)
    ├── 30분 경과 후 노트 없음 → "레슨 확인" 알림 발송
    └── 24시간 경과 (미확인) → 자동 완료 처리 (횟수 차감)
```

**레슨 미진행 사유 선택:**

| 선택 | 수강권 처리 |
|------|------------|
| 레슨 완료 | 횟수 1회 차감 |
| 학생 사정으로 불참 | 횟수 1회 차감 (학생 귀책) |
| 선생님 사정으로 취소 | 다른 날짜로 변경 (횟수 유지) |
| 상호 합의로 취소 | 다른 날짜로 변경 (횟수 유지) |

#### 5.1.4 수강권 타입별 차이

**월정액:**

| 상황 | 처리 |
|------|------|
| 사전 취소/변경 | 같은 달 내 날짜 변경 |
| 당일 취소/미출석 | 횟수 차감, 복구 불가 |
| 선생님 취소 | 같은 달 내 다른 날짜 변경 |
| 월말 취소 | 다음 달 초로 변경 가능 (예외) |

**회차권:**

| 상황 | 처리 |
|------|------|
| 사전 취소/변경 | 유효기간 내 자유롭게 변경 |
| 당일 취소/미출석 | 횟수 차감 |
| 선생님 취소 | 유효기간 내 다른 날짜 변경 |

**체험 (1회권):**

> 체험 레슨도 수강권(체험 1회권)이 필수. 유료/무료는 선생님 설정에 따라 결정.
> 변경/취소 정책은 회차권과 동일하게 적용된다.

| 상황 | 처리 |
|------|------|
| 사전 취소/변경 | 변경권 1회 사용 (선생님 설정의 `rescheduleLimit` 적용) |
| 당일 취소/미출석 | 횟수 차감 (1회권이므로 수강권 소진) |
| 선생님 취소 | 날짜 변경 (횟수 유지) |
| 유료 체험 | 일반 수강권과 동일 — 입금 안내 → 입금 확인 → 수강권 발급 |
| 무료 체험 | 시간 확정 즉시 수강권 발급 (입금 단계 스킵, `amount=0`) |

#### 5.1.5 LessonStatus 확장

```dart
enum LessonStatus {
  scheduled,                    // 예약됨
  completed,                    // 완료 (횟수 차감)
  cancelledByStudentAdvance,    // 학생 사전 취소 (24h+, 날짜 변경)
  cancelledByStudentLate,       // 학생 당일 취소 (횟수 차감)
  cancelledByTeacher,           // 선생님 취소 (날짜 변경)
  cancelledMutual,              // 상호 합의 취소 (날짜 변경)
  studentAbsent,                // 미출석 (횟수 차감)
  reschedulePending,            // 일정 변경 요청 중 (확인 대기)
}
```

#### 5.1.6 SubscriptionUsage 확장

```dart
enum UsageType {
  normal,           // 정상 레슨 (차감)
  lateCancellation, // 당일 취소 (차감)
  studentAbsent,    // 미출석 (차감)
  rescheduled,      // 일정 변경됨 (차감 안 함)
}
```

#### 5.1.7 취소 정책 설정 (선생님)

```dart
class CancellationPolicy {
  final int advanceCancelHours;      // 사전 취소 기준 (기본: 24시간)
  final bool allowLateCancelRefund;  // 당일 취소 시 횟수 유지 허용 (기본: false)
}
```

### 5.2 Teacher Policy Settings (레슨 정책 설정)

선생님/학원이 수업 운영 정책을 설정하고, 수강권 발급 시 자동 적용.

#### 5.2.1 정책 카테고리

**1. 수업 일정 정책 (LessonSchedulePolicy)**

| 항목 | 기본값 |
|------|--------|
| 월 수업 횟수 | 4 |
| 연간 휴원 횟수 | 4 |
| 연간 수업 주수 | 48 |

**2. 월정액 이월 정책 (MonthlyCarryoverPolicy)**

| 항목 | 기본값 |
|------|--------|
| 이월 허용 여부 | true |
| 최대 이월 횟수 | 1 |
| 이월 유효 기간 (월) | 1 |

**3. 수업 변경/취소 정책 (LessonChangePolicy)**

| 항목 | 기본값 |
|------|--------|
| 최소 취소 가능 시간 (시간 전) | 4 |
| 월 최대 변경 횟수 | 2 |
| 당일 취소 허용 | false |
| 늦은 취소 마감 시간 | "20:00" |

**4. 환불 정책 (RefundPolicy)** → 현행 앱 기능으로 정의하지 않음. 선생님/학원과 학생/학부모가 외부에서 처리

**5. 노쇼 정책 (NoShowPolicy)**

| 항목 | 기본값 |
|------|--------|
| 노쇼 시 횟수 차감 | true |
| 노쇼 수수료 부과 | false |
| 지각 허용 시간 (분) | 15 |

**6. 멤버십 혜택 (학원용)**

| 항목 | 기본값 |
|------|--------|
| 악기 무료 대여 | false |
| 연습실 무제한 사용 | false |
| 정기수업 자동 연장 | true |
| 행사 할인 적용 | false |
| 기타 혜택 (텍스트) | [] |

#### 5.2.2 정책 적용 흐름

```
1. 선생님/학원이 기본 정책 설정 (설정 > 레슨 정책)
2. 클래스별 정책 오버라이드 (선택)
3. 수강권 발급 시 정책 자동 적용 (발급 화면에 표시)
4. 학생/학부모에게 정책 안내 (수강권 상세에서 확인)
```

### 5.3 Lesson Request System (레슨 요청 시스템)

수강권 만료(`expired`) 또는 이전 레슨(`past`) 상태의 학생이 선생님에게 재등록을 요청하는 시스템.

#### 5.3.1 기존 수강권 제안 시스템과의 관계

```
수강권 제안 시스템
├── 자동 제안 (체험 후 72시간)
├── 수동 제안 (선생님 직접)
└── 학생 레슨 요청 (NEW) → 선생님 확인 → SubscriptionProposal 생성
```

**핵심 원칙:** LessonRequest는 SubscriptionProposal을 트리거하는 수단.

#### 5.3.2 LessonRequest 엔티티

```dart
class LessonRequest extends HiveObject {
  final String id;
  final String studentId;
  final String teacherId;
  final String? message;
  final PreferredStartTiming preferredTiming;  // nextWeek, nextMonth, afterConsultation
  final bool keepPreviousSchedule;
  final int? previousLessonDay;
  final String? previousLessonTime;
  final int? previousLessonDuration;
  final LessonRequestStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;         // 만료 시간 (7일)
  final String? proposalId;         // 연결된 수강권 제안 ID
  final String? declineReason;
  final DateTime? statusUpdatedAt;
}
```

#### 5.3.3 알림 설계

| 수신자 | 트리거 | 내용 |
|--------|--------|------|
| 선생님 | 요청 도착 | "김민수 학생이 레슨을 요청했습니다" |
| 선생님 | 24시간 미응답 | "레슨 요청이 24시간 전에 도착했습니다" |
| 학생 | 제안 도착 | "김선생님이 수강권을 제안했습니다" |
| 학생 | 거절 | "김선생님: 현재 스케줄이 어렵습니다" |
| 학생 | 48시간 미응답 | "다른 선생님을 찾아볼까요?" |
| 학생 | 만료 (7일) | "응답 없이 7일이 지났습니다" |

#### 5.3.4 제한 사항

- 동일 선생님에게 7일 이내 재요청 제한 (스팸 방지)
- `active` 상태에서는 레슨 요청 불가 (기존 "레슨 예약" 플로우 사용)
- 대기 중(pending) 상태만 복수 선택 가능

---

## 6. Legal Documents

### 6.1 개인정보처리방침 (요약)

> 원문: [privacy_policy.md](./privacy_policy.md) | 상태: 초안 (법률 검토 필요)

**수집 항목:**

| 구분 | 항목 |
|------|------|
| 필수 | 이름, 이메일, 비밀번호 |
| 선택 | 연락처, 프로필 사진 |
| 역할별 | 악기 종류, 레벨, 생년월일, 학원 정보 등 |
| 자동 수집 | 서비스 이용 기록, 접속 로그, 기기 정보 |

**보유 기간:**

| 구분 | 기간 | 근거 |
|------|------|------|
| 회원 계정 정보 | 탈퇴 시까지 | 이용자 동의 |
| 탈퇴 회원 정보 | 탈퇴 후 30일 | 재가입 방지, 분쟁 대응 |
| 계약/결제 기록 | 5년 | 전자상거래법 |
| 접속 로그 | 최소 6개월 | 통신비밀보호법 |
| 강사 퇴사 후 계정 | 30일 후 파기 | 익명화 처리 |
| 강사 작성 콘텐츠 | 학원 탈퇴 시까지 | 작성자명 익명화 보존 |

**서비스 내 정보 제공:**

| 제공 방향 | 항목 | 보유 기간 |
|----------|------|----------|
| 선생님 → 학생 | 이름, 연락처(동의 시) | 관계 해지 시 |
| 학생 → 선생님 | 이름, 연락처, 레벨 | 관계 해지 시 |
| 학원 → 강사 | 담당 학생 정보 | 강사 퇴사 시 |

**아동 개인정보:** 만 14세 미만은 법정대리인 동의 필수.

**강사 퇴사 시:** 접근권한 즉시 회수, 접근 로그 6개월 보관, 담당 학생 재배정.

### 6.2 이용약관 (요약)

> 원문: [terms_of_service.md](./terms_of_service.md) | 상태: 초안 (법률 검토 필요)

**핵심 조항:**

| 조항 | 내용 |
|------|------|
| 입금 비개입 | 회사는 결제 대행 미제공. 수강료는 선생님/학원과 학생 간 외부 입금으로 직접 처리 |
| 분쟁 면책 | 수강료 분쟁에 대해 회사 책임 없음 |
| 수강권 설정 | 가격, 유효기간, 외부 환불 정책은 선생님/학원이 자율 설정 |
| 탈퇴 시 수강권 | 앱 내 환불 신청 기능 없음. 잔여 수강권 처리는 선생님/학원과 외부 협의 |
| 서비스 종료 | 90일 전 통지. 수강료 환불/정산은 선생님/학원과 학생/학부모 간 외부 처리 |

**콘텐츠 소유권:**

| 유형 | 소유권 |
|------|--------|
| 개인회원 콘텐츠 | 해당 회원 귀속 |
| 학원 강사 콘텐츠 | 학원과 작성자 공동 소유 |
| 내보내기 | PDF + JSON (학생 개인정보 제외) |
| 탈퇴 후 보존 | 콘텐츠 삭제 안 됨 (학원 운영 연속성) |

**학원 강사 특수 조항:**
- 학생 개인정보 업무 외 사용 금지
- 퇴사 시 데이터 무단 복제 금지 (내보내기 기능 제외)
- 퇴사 후 학원 데이터 접근 불가

---

## 7. Implementation Status

### 7.1 수강권 시스템 (Subscription)

| 항목 | 상태 | 파일 |
|------|:----:|------|
| Subscription 엔티티 | 구현 완료 | `features/subscription/domain/entities/subscription.dart` |
| SubscriptionRepository | 구현 완료 | `features/subscription/domain/repositories/subscription_repository.dart` |
| MockSubscriptionRepository | 구현 완료 | `features/subscription/data/repositories/mock_subscription_repository.dart` |
| RemoteSubscriptionRepository | 구현 완료 | `features/subscription/data/repositories/remote_subscription_repository.dart` |
| Subscription Providers | 구현 완료 | `features/subscription/presentation/providers/subscription_providers.dart` |
| 수강권 목록 화면 | 구현 완료 | `features/subscription/presentation/screens/subscription_list_screen.dart` |
| 수강권 상세 화면 | 구현 완료 | `features/subscription/presentation/screens/subscription_detail_screen.dart` |
| 수강권 발급 화면 | 구현 완료 | `features/subscription/presentation/screens/issue_subscription_screen.dart` |
| 수강권 카드 위젯 | 구현 완료 | `features/subscription/presentation/widgets/subscription_card.dart` |
| 수강권 뱃지 위젯 | 구현 완료 | `features/subscription/presentation/widgets/subscription_badge.dart` |
| 상태별 색상 유틸리티 | 구현 완료 | `features/subscription/presentation/utils/subscription_status_colors.dart` |
| SubscriptionUsage 엔티티 | 구현 완료 | `features/subscription/domain/entities/subscription_usage.dart` |
| SubscriptionSettings 엔티티 | 구현 완료 | `features/subscription/domain/entities/subscription_settings.dart` |
| 만료 예정 수강권 화면 | 구현 완료 | `features/subscription/presentation/screens/expiring_subscriptions_screen.dart` |
| 스케줄 변경 요청 목록 화면 | 구현 완료 | `features/subscription/presentation/screens/schedule_change_request_list_screen.dart` |
| 학생 수강권 제안 수락 화면 | 구현 완료 | `features/subscription/presentation/screens/student_proposal_accept_screen.dart` |
| 갱신 상세 화면 | 구현 완료 | `features/subscription/presentation/screens/renewal_detail_screen.dart` |
| 선생님 수강권 목록 화면 | 구현 완료 | `features/subscription/presentation/screens/teacher_subscription_list_screen.dart` |
| 발급 액션 (바텀시트) | 구현 완료 | `features/subscription/presentation/screens/issue_subscription_actions.dart` |
| 학원 모드 (Organization) | 설계 완료 | 구현 대기 |
| 교차 수강권 (SubscriptionScope) | 설계 완료 | 구현 대기 |
| 부가 서비스 옵션 | 설계 완료 | 구현 대기 |

### 7.2 수강권 제안 (Proposal)

| 항목 | 상태 | 파일 |
|------|:----:|------|
| SubscriptionProposal 엔티티 | 구현 완료 | `features/subscription/domain/entities/subscription_proposal.dart` |
| SubscriptionTemplate 엔티티 | 구현 완료 | `features/subscription/domain/entities/subscription_template.dart` |
| ProposalSettings 엔티티 | 구현 완료 | `features/subscription/domain/entities/proposal_settings.dart` |
| 제안 Repository (Mock+Remote) | 구현 완료 | `features/subscription/data/repositories/` |
| 템플릿 Repository (Mock+Remote) | 구현 완료 | `features/subscription/data/repositories/` |
| ProposalSettings Repository | 구현 완료 | `features/subscription/data/repositories/mock_proposal_settings_repository.dart` |
| Proposal Providers | 구현 완료 | `features/subscription/presentation/providers/subscription_proposal_providers.dart` |
| Template Providers | 구현 완료 | `features/subscription/presentation/providers/subscription_template_providers.dart` |
| ProposalSettings Providers | 구현 완료 | `features/subscription/presentation/providers/proposal_settings_providers.dart` |
| 제안 생성 화면 | 구현 완료 | `features/subscription/presentation/screens/proposal_create_screen.dart` |
| 제안 상세 화면 | 구현 완료 | `features/subscription/presentation/screens/proposal_detail_screen.dart` |
| 입금 확인 화면 | 구현 완료 | `features/subscription/presentation/screens/proposal_confirm_screen.dart` |
| 제안 설정 화면 | 구현 완료 | `features/subscription/presentation/screens/proposal_settings_screen.dart` |
| 템플릿 목록 화면 | 구현 완료 | `features/subscription/presentation/screens/subscription_template_list_screen.dart` |
| 자동 제안 서비스 | 구현 완료 | `features/subscription/domain/services/auto_proposal_service.dart` |
| 자동 리마인더 서비스 | 구현 완료 | `features/subscription/domain/services/proposal_reminder_service.dart` |
| 리드 관리 대시보드 | 설계 완료 | 구현 대기 |
| 골든타임 할인 UI | 설계 완료 | 구현 대기 |

### 7.3 수강료 입금 상태 기록

| 항목 | 상태 | 비고 |
|------|:----:|------|
| 수강권 제안 입금 상태 | 구현 완료 | `SubscriptionProposal.payment_status` |
| 수강권 입금 확인 여부 | 구현 완료 | `Subscription.payment_confirmed` |
| 제안 확정 후 수강권 발급 | 구현 완료 | `subscription_service.confirm_proposal` |
| 독립 `/payments/*` API | 정의하지 않음 | 현행 구현 대상 아님 |
| 앱관리자 사용료 결제 | 향후 별도 스펙 | 현재 정의/구현하지 않음 |
| PG/카드/간편결제/정산/영수증 | 정의하지 않음 | 선생님/학원 수강료에는 도입하지 않음 |

### 7.4 레슨 정책 (Lesson Policy)

| 항목 | 상태 | 파일 |
|------|:----:|------|
| LessonPolicy 엔티티 | 구현 완료 | `features/subscription/domain/entities/lesson_policy.dart` |
| LessonPolicy Repository | 구현 완료 | `features/subscription/domain/repositories/lesson_policy_repository.dart` |
| MockLessonPolicyRepository | 구현 완료 | `features/subscription/data/repositories/mock_lesson_policy_repository.dart` |
| LessonPolicy Providers | 구현 완료 | `features/subscription/presentation/providers/lesson_policy_providers.dart` |
| 정책 설정 화면 | 구현 완료 | `features/subscription/presentation/screens/lesson_policy_screen.dart` |
| LessonStatus 확장 (취소/변경) | 설계 완료 | 구현 대기 |
| 일정 변경 플로우 (선생님→학생) | 설계 완료 | 구현 대기 |
| SubscriptionUsage 확장 (usageType, deducted) | 설계 완료 | 구현 대기 |
| 취소 로직 (24시간 기준 분기) | 설계 완료 | 구현 대기 |

### 7.5 레슨 요청 (Lesson Request)

| 항목 | 상태 | 파일 |
|------|:----:|------|
| LessonRequest 엔티티 | 구현 완료 | `features/schedule/domain/entities/lesson_request.dart` |
| LessonRequestRepository | 구현 완료 | `features/schedule/domain/repositories/lesson_request_repository.dart` |
| MockLessonRequestRepository | 구현 완료 | `features/schedule/data/repositories/mock_lesson_request_repository.dart` |
| lessonRequestProviders | 구현 완료 | `features/schedule/presentation/providers/lesson_request_providers.dart` |
| 학생: 레슨 요청 화면 | 구현 완료 | `features/schedule/presentation/screens/lesson_request_screen.dart` |
| 선생님: 요청 목록 화면 | 구현 완료 | `features/schedule/presentation/screens/lesson_requests_screen.dart` |
| 선생님: 복수 선택 제안 (v4) | 구현 완료 | 체크박스 선택 → 일괄 수강권 제안 |
| 수강권 제안 시 상태 연동 | 구현 완료 | IssueSubscriptionScreen → lessonRequestId 파라미터 |
| 선생님 홈 레슨 요청 버튼 | 구현 완료 | HomeScreen → 뱃지 포함 버튼 |
| 학생: 내 요청 현황 화면 | 구현 완료 | `features/schedule/presentation/screens/my_lesson_requests_screen.dart` |
| 스케줄 확인 카드 | 미구현 | 수강권 발급 후 학생에게 표시 |
| 알림 시스템 연동 | 미구현 | 푸시 알림 연결 필요 |

### 7.6 법적 문서

| 항목 | 상태 |
|------|:----:|
| 개인정보처리방침 | 초안 완료 (법률 검토 필요) |
| 이용약관 | 초안 완료 (법률 검토 필요) |

---

## 8. Related Specs

| 문서 | 설명 |
|------|------|
| [subscription_system_spec.md](./subscription_system_spec.md) | 수강권 시스템 및 학원 모드 설계서 (원본) |
| [subscription_master.md](./subscription_master.md) | 수강권 제안 시스템 스펙 (원본) |
| [lesson_cancellation_policy.md](./lesson_cancellation_policy.md) | 취소/변경 정책 (원본) |
| [lesson_policy_settings.md](./lesson_policy_settings.md) | 레슨 정책 설정 (원본) |
| [lesson_request_system.md](./lesson_request_system.md) | 학생 레슨 요청 (원본) |
| [privacy_policy.md](./privacy_policy.md) | 개인정보처리방침 (원본) |
| [terms_of_service.md](./terms_of_service.md) | 이용약관 (원본) |
| [subscription_based_relationship.md](../lesson/invite/subscription_based_relationship.md) | 수강권 중심 관계 모델 |
| [teacher_availability_spec.md](../schedule/teacher_availability_spec.md) | 선생님 가용 시간 |
| [subscription.md](../../schema/entities/subscription.md) | Subscription 엔티티 스키마 |
| [payment.md](../../schema/entities/payment.md) | Payment 엔티티 스키마 |

#### 통합 원본 (Historical — 작업 근거로 사용 금지)

| 문서 | 비고 |
|------|------|
| [payment_unified_spec.md](../_archive/old/payment_unified_spec.md) | 결제 시스템 통합 스펙 (본 문서에 통합됨) |
| [flow_with_app.md](../_archive/old/flow_with_app.md) | 레슨 플로우 (lesson_master.md에 통합됨) |

---

## 9. Change History

| 날짜 | 변경 내용 |
|------|----------|
| 2026-05-07 | §5.1.4 체험 수강권 변경/취소 정책 명시 — 체험도 수강권 필수 (유료 기본, 무료 선택), 변경권 동일 적용 |
| 2026-03-12 | **제안/발급 통합 (Template-First UX v7)**: 섹션 3.1 전면 개편 — Selectable Card UI, 최대 3개 선택, 즉시 발급 옵션 추가, 직접 입력 Fallback |
| 2026-03-07 | Enum 정의 추가(2.2.2) 후 섹션 넘버링 수정 (2.2.3~2.2.9), 링크 검증 완료 |
| 2026-03-06 | 마스터 스펙 초판 작성 (9개 문서 통합) |
| 2026-02-06 | UnpaidPolicy 삭제, paymentConfirmed 기반 단순 입금대기(후불) 모델 |
| 2026-02-02 | 레슨 요청 시스템 v4 (복수 선택 제안 기능) |
| 2026-02-01 | 수강권 제안 v6 (제안 상세 헤더 UI 개선) |
| 2026-01-30 | 수강권 제안 v5 (앱 전환 플로우, 자동 스케줄 보완) |
| 2026-01-29 | 수강권 제안 v4 (옵션 제안, 갱신 간소화 플로우) |
| 2026-01-28 | 수강권 제안 v3 (학원/개인 분리, 예약 UI 개선) |
| 2026-01-27 | 수강권 제안 v2 (리드 관리, 골든타임, 자동 리마인더) |
| 2026-01-27 | 수강권 발급 옵션 (회차/유효기간 프리셋) |
| 2026-01-26 | 수강권 이름, 변경/취소 횟수 제한, 자율 예약 |
| 2026-01-25 | 수강권 상태 색상 3+1 시스템 확정 |
| 2026-01-25 | 취소/변경 정책, 레슨 정책 설정 초안 |
| 2026-01-25 | 부가 서비스, 교차 수강권, 대량 구매 할인 설계 |
| 2026-01-25 | 결제 시스템 통합 스펙 확정 |
| 2026-01-24 | 결제 엔티티 분리 (schema/entities/payment.md) |
| 2026-01-23 | 수강권 시스템 및 학원 모드 설계 완료 |
