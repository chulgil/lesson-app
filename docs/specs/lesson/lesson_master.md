# Lesson System Master Spec

> 구현 상태: ⚠️ 부분 구현 — 레슨 타입 enum 미모델링, 통합 플로우 미완성
> Last updated: 2026-03-07
> 이 문서는 레슨 도메인의 **단일 진실 공급원(Single Source of Truth)**입니다.
> 기존 개별 스펙 문서(flow_*.md, lesson_schedule.md 등)의 내용을 통합합니다.
> 관련 문서: [schedule_master.md](../schedule/schedule_master.md)

---

## 목차

1. [개요](#1-개요)
2. [레슨 유형](#2-레슨-유형)
3. [레슨 플로우](#3-레슨-플로우)
4. [레슨 예약 (Booking)](#4-레슨-예약-booking)
5. [레슨 노트](#5-레슨-노트)
6. [레슨 장소](#6-레슨-장소)
7. [빠른 레슨 등록 (Quick Add)](#7-빠른-레슨-등록-quick-add)
8. [그룹 레슨](#8-그룹-레슨)
9. [3자 관계 (학원-선생님-학생)](#9-3자-관계-학원-선생님-학생)
10. [Enum 정의](#10-enum-정의)
11. [구현 파일 매핑](#11-구현-파일-매핑)
12. [경쟁사 대비 차별점](#12-경쟁사-대비-차별점)
13. [구현 현황](#13-구현-현황)
14. [관련 스펙](#14-관련-스펙)
15. [변경 이력](#15-변경-이력)

---

## 1. 개요

### 1.1 시스템 목적

Lessonaza 레슨 시스템은 음악 선생님과 학생 사이의 레슨 라이프사이클 전체를 관리한다.
선생님 발굴 -> 연결 -> 체험 -> 정기 등록 -> 입금 안내/확인 -> 스케줄 -> 레슨 진행 -> 레슨 노트 -> 갱신/종료까지의 흐름을 앱 내에서 처리한다.

### 1.2 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **수강권 필수** | 레슨 예약은 유효한 수강권이 있어야만 가능 |
| **입금 확인 = 발급 + 스케줄** | 선생님의 "입금 확인" 1탭으로 수강권 발급, 관계 active 전환, 스케줄 생성이 자동 처리 |
| **학생 명시적 확인** | 스케줄은 자동 생성되지만 학생이 명시적으로 확인해야 확정 |
| **자동화 > 수동** | 리마인더, 횟수 차감, 갱신 안내, 입금 안내는 시스템이 자동 처리 |
| **원샷 UX** | 한 번 탭으로 모든 연관 작업 완료 (알림, 상태, 스케줄 자동 처리) |

### 1.3 관계 모델

수강권 중심 관계 모델로 선생님-학생 관계를 자동 관리한다.

| 이벤트 | RelationshipStatus | 설명 |
|--------|-------------------|------|
| 체험 예약 | `trialBooked` | 체험 대기 |
| 수강권 발급 | `active` | 정규 레슨 |
| 수강권 만료 | `expired` | 30일 유예 기간 |
| 유예 기간 초과 | `past` | 이전 학생 |

팔로우 시스템은 수강권과 별개로 동작한다 (누구나 선생님/학원을 팔로우 가능, 소식 알림용).

### 1.4 개인 레슨 vs 학원 레슨

| 기능 | 개인 레슨 | 학원 레슨 |
|------|----------|----------|
| 연결 방식 | QR/URL 초대 | 학원 QR -> 선생님 선택 |
| 데이터 소유 | 공동 (선생님+학생) | 공동 (학원+선생님+학생) |
| 수강권 발행 | 선생님 | 학원 |
| 선생님 변경 | 새로 연결 | 학원 내 전환 가능 |
| 레슨 노트 접근 | 해당 선생님+학생만 | 학원 정책에 따름 |

### 1.5 앱의 한계 (명확화)

| 항목 | 지원 여부 | 비고 |
|------|:--------:|------|
| 신규 선생님 탐색 | X | 외부 플랫폼 이용 (숨고, 크몽 등) |
| 이전 선생님 검색 | O | 레슨 이력 있으면 앱 내 검색 가능 |
| 학원 선생님 검색 | O | 학원 내 등록된 선생님 조회 |
| 결제 처리 | X | 외부 계좌이체 (앱은 입금 안내/확인만) |
| 입금 확인 | 수동 | 선생님이 직접 확인 |

---

## 2. 레슨 유형

### 2.1 개인 레슨 유형

| 유형 | 설명 | 수강권 타입 | 스케줄 |
|------|------|:----------:|:------:|
| **체험레슨** (trial) | 첫 만남, 상호 평가용 1회 | trial | 불특정 (선생님이 시간 제공) |
| **정기레슨** (regular) | 매주 고정 요일/시간 | monthly | 고정 (자동 생성) |
| **회차권 레슨** (package) | N회권, 매 레슨마다 시간 협의 | perPackage | 유동 (매번 예약) |
| **1회 레슨** (oneTime) | 단발성 추가 레슨 | - | 1회성 |

### 2.2 관계별 가능한 레슨 유형

| 관계 | 체험 | 정기 | 1회 | 설명 |
|------|:----:|:----:|:----:|------|
| `none` | O | X | X | 첫 만남은 체험부터 |
| `active` | X | X | O | 이미 정기 진행 중, 추가만 |
| `inactive` | X | O | O | 재개 또는 1회 |

### 2.3 정기레슨 vs 회차권 비교

| 구분 | 정기레슨 (월정액) | 회차권 (패키지) |
|------|-----------------|----------------|
| 레슨 일정 | 고정 (매주 같은 요일/시간) | 유동 (매번 협의) |
| 예약 주체 | 최초 설정 -> 자동 생성 | 선생님 제안 -> 학생 선택 |
| 스케줄 관리 | 변경 요청만 | 매 레슨 예약 필요 |
| 적합 대상 | 장기/정기 수강생 | 불규칙 일정 수강생 |
| 5주차 정책 | 적용 | 해당 없음 |

### 2.4 5주차 정책 (FifthWeekPolicy)

월 4회 기준 정기레슨에서 특정 요일이 5번 있는 달을 처리한다.

| 정책 | 설명 | 결제 |
|------|------|------|
| **skip** (기본값) | 5주차 자동 휴강 | 4회 고정 |
| **optional** | 5주차에 학생이 선택 | 4회 + 선택 시 추가 |
| **credit** | 5주차 진행 -> 다음달 크레딧 | 4회 고정, 크레딧 차감 |
| **always** | 5주차도 항상 진행 | 5회 결제 |

자동 스케줄 생성 로직:
1. 해당 월의 레슨 요일 날짜 목록 추출
2. 4개면 전체 레슨, 5개면 `fifthWeekPolicy`에 따라 처리
3. 캘린더 및 결제 정보 반영

---

## 3. 레슨 플로우

### 3.1 연결 플로우 (Connection)

선생님과 학생이 앱에서 연결되는 시나리오.

#### 3.1.1 개인 레슨: 선생님이 QR로 초대 (신규)

**QR 스캔 = 자동 연결 (제로 탭)**: 추가 버튼 없이 스캔 즉시 연결.

```
외부 플랫폼에서 선생님 발굴 -> 카톡 상담 -> 체험 레슨 대면
    -> 선생님 QR 표시 -> 학생 스캔 -> 앱 설치/로그인 -> 자동 연결 (trialBooked)
```

자동 연결 이유: QR 스캔 자체가 명시적 동의이며 체험 후 대면 상황에서 확인 단계는 과잉.

#### 3.1.2 개인 레슨: 학생이 URL로 초대 (역방향)

```
학생이 앱에서 초대 URL 복사 -> 카톡으로 선생님에게 공유
    -> 선생님 링크 클릭 -> 앱 설치/프로필 설정 -> 자동 연결
```

#### 3.1.3 학원 레슨

```
학원 QR 스캔 -> 학원 페이지 -> 선생님 목록 조회 -> 선생님 선택 -> 체험 신청
```

학원 레슨에서 학생이 직접 선생님을 선택할 수 있다 (학원 배정이 아님).

#### 3.1.4 휴식 후 재등록 (past 상태)

| 휴식 기간 | 관계 상태 | 재등록 방식 |
|----------|----------|------------|
| ~30일 | `expired` | 시스템 자동 갱신 제안 -> 간편 재등록 |
| 30일+ | `past` | 학생이 "레슨 요청" -> 선생님 수강권 제안 |

past 상태 재등록 플로우 (4단계):
1. 학생: "레슨 요청" (희망 시작일, 이전 스케줄 유지 여부, 메시지)
2. 선생님: 수강권 제안 또는 정중히 거절
3. 학생: 수락 + 입금
4. 선생님: 입금 확인 -> 수강권 발급 + 이전 스케줄 자동 복원

#### 3.1.5 기존 정기레슨 -> 앱 전환

이미 앱 없이 진행 중인 정기레슨을 앱으로 전환. 체험/결제 단계 스킵.

플로우 (3단계):
1. 학생: QR 스캔 -> 연결 (trialBooked 스킵 -> active 가능)
2. 선생님: 수강권 등록 (현재 잔여 횟수 입력, "입금 확인 완료로 발급" 선택)
3. 선생님: 현재 스케줄 등록

#### 3.1.6 연결 방식 비교

| 시나리오 | 연결 방식 | 이유 |
|----------|----------|------|
| 개인 QR | 스캔 = 자동 연결 | 체험 후 대면, 동의 명확 |
| 개인 URL | 클릭 + 가입 = 자동 연결 | 카톡 상담 완료 |
| 학원 QR | 스캔 -> 선생님 선택 -> 체험 신청 | 선생님 미정 |

---

### 3.2 체험 레슨 플로우 (Trial)

```
학생: 선생님 프로필 -> "체험 신청" -> 가용 시간 캘린더 확인 -> 시간 칩 탭 (원클릭)
    -> 정보 입력 (이름, 악기 경험, 희망사항) -> 신청 완료
    -> 선생님에게 푸시 알림 -> 선생님 승인 -> 학생에게 확정 알림
    -> D-1 자동 리마인더 (양쪽) -> 체험 레슨 진행
```

#### 체험 신청 폼 필드

| 필드 | 필수 | 설명 |
|------|:----:|------|
| 날짜/시간 | O | 선생님 가용시간 중 선택 |
| 레슨 목표 | O | 취미/입시/전공 |
| 악기 경험 | O | 처음/1년미만/1-3년/3년이상 |
| 메시지 | X | 선생님께 전달할 메시지 |

#### 개선 효과

| 단계 | 앱 미사용 | 앱 사용 |
|------|----------|--------|
| 일정 조율 | 5-10회 메시지 | 1클릭 선택 |
| 정보 교환 | 여러 번 왕복 | 자동 전달 |
| 리마인더 | 수동 | 자동 푸시 |

---

### 3.3 정기 레슨 등록 플로우 (Regular Enrollment)

**핵심 순서**: 수강권 제안 -> 결제 -> 수강권 발급 -> 스케줄 선택

```
Phase 1: 수강권 제안 (체험 후)
    - 자동 제안 ON: 시스템 자동 발송
    - 수동 제안: 선생님이 템플릿 선택 (체크박스 복수) -> 발송

Phase 2: 학생 응답 + 결제
    - 학생: 라디오 버튼으로 1개 선택 -> 계좌이체 -> "입금 완료" 탭

Phase 3: 입금 확인 = 발급 + 스케줄 (선생님 1탭!)
    - 선생님: "입금 확인" 버튼 1번만 탭
    - 자동: 수강권 발급 + 관계 active + 스케줄 확인 카드 생성 + 양쪽 알림

Phase 4: 학생 스케줄 확인 (1탭)
    - 신규: "체험 시간으로 예약?" 카드 표시
    - 재등록: "이전 스케줄로 예약?" 카드 표시
    - 학생: "이 시간으로 예약" 또는 "다른 시간 선택"

Phase 5: 정기 레슨 진행
    - D-1 자동 리마인더, 레슨 완료 -> 잔여 횟수 차감, 레슨 노트 공유

Phase 6: 소진 임박 -> 갱신
    - 잔여 2회 시 시스템 자동 갱신 제안
    - 갱신 시 이전 템플릿 자동 선택 + 스케줄 유지 (3단계)
```

#### 자동 스케줄 로직

| 시나리오 | 기본값 |
|----------|--------|
| 신규 학생 | 체험 레슨 시간 -> 정기 레슨 시간 |
| 재등록 학생 | 이전 정기 레슨 시간 유지 |
| 변경 필요 시 | "다른 시간 선택" -> 가용 시간 칩 표시 |

---

### 3.4 회차권 레슨 플로우 (Package)

```
Phase 1: 회차권 안내 및 결제
    - 선생님: 템플릿 선택 -> 입금 안내 발송 -> 학생 입금
    - 선생님: 입금 확인 -> 수강권 발급 (잔여 N회)

Phase 2: 스마트 레슨 예약 (매 레슨)
    - 선생님: 가용 시간 제안 (기본 1개) -> 학생 확인 (원클릭)
    - 레슨 완료 -> 잔여 횟수 자동 차감

Phase 3: 소진 임박
    - 잔여 2회 시 자동 알림 (양쪽)
    - 연장 시 기존 잔여 + 신규 발급 = 합산
```

#### 회차권 예약 상세 플로우

1. 레슨 완료 시 잔여 횟수 확인
2. 1회 이상 남음 -> 선생님에게 "다음 레슨 시간 제안" 알림
3. 선생님 -> 가용 시간 3~5개 제안 (체크박스 최대 5개)
4. 학생 -> 제안된 시간 중 선택 또는 다른 시간 요청 (라디오 버튼)
5. 확정 -> 양측에 예약 확정 알림

#### 개선 효과

| 단계 | 앱 미사용 | 앱 사용 |
|------|----------|--------|
| 매 예약 | 3-5회 메시지 | 1-2회 탭 |
| 횟수 관리 | 수동 기록 | 자동 차감 |
| 잔여 안내 | 선생님이 알림 | 앱에서 확인 |
| 연장 안내 | 선생님이 문의 | 자동 알림 |
| 10회권 총 메시지 | 40-60회 | 10-15회 |

---

### 3.5 수강권 입금 상태 플로우 (Tuition Deposit)

#### 3.5.1 입금 상태 모델

현재 앱은 선생님/학생/학부모 간 실제 결제를 처리하지 않는다. 수강료는 앱 밖에서 무통장입금/현금으로 처리하고, 앱은 `Subscription` 엔티티의 입금 확인 상태만 기록한다 (별도 Payment 엔티티/API 아님).

**용어 정책**:
- **후불**: 수강권 발급 방식이다. 상태 문구로는 `입금 예정`, `입금 확인 필요`, `입금대기(후불)` 중 현재 단계에 맞는 표현을 쓴다.
- **입금대기(후불)**: 후불 수강권이 발급됐고 아직 입금 완료 기록이 없는 상태다. `Subscription.status == active && paymentConfirmed == false && paidAt == null`인 수강권만 이 상태로 본다.
- **입금 확인 필요**: 학생/학부모가 입금 완료를 알렸지만 선생님이 아직 확인하지 않은 상태다. `Subscription.status == active && paymentConfirmed == false && paidAt != null`로 판별한다.
- **입금 확인 완료**: 선생님이 입금을 확인한 상태다. `paymentConfirmed == true`로 판별한다.

**두 가지 경로:**

| 경로 | 설명 | paymentConfirmed |
|------|------|:----------------:|
| **선불 (Proposal 경로)** | 제안 -> 입금 예정 -> 입금 완료 알림 -> 입금 확인 완료 -> 발급완료 | 항상 true |
| **후불 (직접 발급)** | 직접발급 -> 입금대기(후불) 또는 입금확인 | false -> true |

**입금대기(후불) 판별:**
```dart
bool get isUnpaid =>
    status == SubscriptionStatus.active && !paymentConfirmed && paidAt == null;

bool get needsPaymentConfirmation =>
    status == SubscriptionStatus.active && !paymentConfirmed && paidAt != null;
```

#### 3.5.2 2단계 입금확인 플로우 (선불)

```
1. 선생님: 수강권 템플릿 선택 -> 제안 발송
2. 학생: 계좌이체 -> "입금 완료" 버튼 탭
3. 선생님: 계좌 확인 -> "입금 확인" 1탭
   -> 자동: Subscription 생성 (paymentConfirmed: true) + 관계 active + 스케줄 카드
```

반려 케이스: 선생님이 "반려" -> 학생에게 "입금 내역을 확인해주세요" 알림.

#### 3.5.3 후불 발급 플로우

```
선생님: 학생 상세 -> "수강권 발급" -> "나중에 결제" 선택
    -> Subscription 생성 (paymentConfirmed: false)
    -> 입금대기(후불) 목록에 표시
    -> 나중에 입금확인 시 paymentConfirmed: true로 전환
```

#### 3.5.4 입금대기(후불) 관리

선생님 앱에서 입금대기(후불) 대시보드 제공:
- 총 입금대기(후불) 금액, 건수, 학생 수
- 개별 입금대기(후불) 수강권 카드 (입금확인 / 알림 보내기 버튼)

백엔드 계약:
- 입금대기(후불) 목록: `GET /api/v1/subscriptions?deposit_status=unpaid`
- 입금 확인 필요 목록: `GET /api/v1/subscriptions?deposit_status=needsConfirmation`
- 입금 확인 완료 목록: `GET /api/v1/subscriptions?deposit_status=confirmed`
- 입금 상태 요약: `GET /api/v1/subscriptions/deposits/summary?year=YYYY&month=M`
- 학생/학부모 입금 완료 알림: `PATCH /api/v1/subscriptions/{subscription_id}/notify-payment`
- 선생님 입금 확인: `PATCH /api/v1/subscriptions/{subscription_id}/confirm-payment`

입금 상태 요약은 별도 `Payment` API가 아니라 현재 사용자가 볼 수 있는 `Subscription`만 집계한다.

#### 3.5.5 개선 효과

| 항목 | 앱 미사용 | 앱 사용 |
|------|----------|--------|
| 입금 안내 | 카톡으로 직접 | 앱 자동 알림 |
| 입금 확인 | 수동 | 수동 (동일) |
| 입금대기(후불) 파악 | 수기/기억 | 대시보드 |
| 수강권 발급 | 구두/메모 | 입금확인 1탭 자동 |
| 잔여 횟수 | 선생님만 기억 | 학생 실시간 확인 |
| 후불 관리 | 기억에 의존 | 입금대기(후불) 목록 자동 |

---

### 3.6 취소/변경 플로우 (Cancellation & Reschedule)

#### 시나리오 A: 학생 측 취소

```
학생: 레슨 상세 -> "취소/변경" -> 취소 정책 확인 -> "보강으로 변경" 선택
    -> 보강 가능 시간 표시 -> 시간 선택 -> 선생님에게 알림 -> 승인
    -> 원래 레슨 취소 + 보강 등록 자동 처리
```

**취소 정책:**
| 시점 | 정책 |
|------|------|
| D-2 이전 | 무료 취소 |
| D-1 | 보강 1회 차감 |
| 당일 | 회차 차감 |

#### 시나리오 B: 선생님 측 취소

```
선생님: 레슨 상세 -> "취소" -> 사유 선택 -> 대체 시간 제안
    -> 학생에게 알림 -> 수락/다른 시간 요청
```

선생님 취소 시 항상 보강 제공.

#### 시나리오 C: 당일 노쇼

```
레슨 시작 10분 전: 양쪽 "레슨 임박" 알림
레슨 시작 + 15분: 선생님 "학생 미도착" 버튼
    -> 학생에게 확인 알림: "오늘 레슨에 오시나요?"
    -> 5분 내 응답 없음: 노쇼 자동 처리 (정책에 따라)
    -> 응답 있음: "지각 중" -> 대기 / "못 갑니다" -> 취소 플로우
```

**노쇼 정책 (NoShowPolicy)** - 선생님이 설정:

| 정책 | 설명 | 회차권 처리 |
|------|------|-----------|
| **deductCredit** (기본값) | 회차 차감 | 잔여 -1 |
| **halfCredit** | 0.5회 차감 | 잔여 -0.5 |
| **noDeduction** | 차감 없음 | 차감 없음 |
| **reschedule** | 보강으로 전환 | 보강 +1 |

#### 시나리오 D: 정기 시간 일괄 변경

```
학생: "레슨 시간 변경" -> 변경 방식 선택 (이번 주만 / 앞으로 모두)
    -> 희망 시간 선택 -> 선생님에게 요청
    -> 승인 시: 이후 모든 레슨 일괄 변경
    -> 불가 시: 대안 제시 -> 학생 재선택
```

일괄 변경 시 처리:
- RegularLessonSettings의 `dayOfWeek`, `startTime` 업데이트
- 이미 생성된 미래 레슨들 시간 일괄 변경
- 완료된 과거 레슨은 변경 없음

#### 보강 (Makeup Lesson) 추적 시스템

| 조건 | 보강 생성 |
|------|:--------:|
| 학생 취소 (D-1) | 선택 (정책 따라) |
| 학생 취소 (당일) | X (회차 차감) |
| 선생님 취소 | O (필수) |
| 노쇼 (reschedule 정책) | O |
| 휴강 (5주차 등) | X |

**보강 상태 (MakeupStatus):**
`pending` -> `scheduled` -> `completed` / `expired`(30일) / `waived`(면제)

**보강 엔티티:**
```dart
class MakeupLesson {
  final String id;
  final String studentId;
  final String teacherId;
  final String? originalLessonId;
  final String? scheduledLessonId;
  final MakeupStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;  // 기본 30일
  final String reason;
}
```

---

### 3.7 앱 vs 비앱 플로우 비교

#### 단계 수 비교

| 시나리오 | 앱 미사용 | 앱 사용 |
|----------|:--------:|:------:|
| 신규 등록 | 5단계 | 5단계 (동일) |
| 재등록 | 2-3단계 | 3단계 (동일) |
| 앱 전환 | - | 3단계 |

#### 앱 미사용 핵심 Pain Points

| # | Pain Point | 영향 |
|---|------------|------|
| 3 | 단일 제안 핑퐁 메시지 (시간 조율) | 5-10회 왕복, 2-5일 |
| 6 | 구두 약속 (계약 없음) | 분쟁 시 증거 없음 |
| 7 | 수동 입금 확인 + 수강권 관리 | 메모/기억 의존 |
| 10 | 어색한 결제 독촉 | 관계 부담 |
| 11 | 매번 단일 제안 조율 (회차권) | 레슨당 3-5회 메시지 |
| 15 | 노쇼 정책 불명확 | 환불 분쟁 |

#### 앱 핵심 해결 방법

가장 큰 문제인 **일정 조율 핑퐁**을 근본적으로 해결:
- 선생님이 가용 시간을 미리 오픈
- 학생이 칩 버튼으로 원하는 시간 선택
- 조율 자체가 불필요 (0회)

#### 시간 절약

```
앱 미사용 (학생 10명 기준): 약 9.5시간/월
앱 사용 (학생 10명 기준): 약 2시간/월
절약: 7.5시간/월 (79% 감소)
```

#### 장기 수강생 가치 전환

| 관계 단계 | 앱 가치 |
|----------|---------|
| 신규 (0~3개월) | 편리함 — 핑퐁 제거, 결제 자동화, 노쇼 정책 |
| 중기 (3~12개월) | 체계성 — 스케줄 자동화, 연습 패턴, 레슨 노트 축적 |
| 장기 (1년+) | 성장 증명 — 레슨 이력, 녹음 비교, 학부모 대시보드, 진도 분석 |

---

## 4. 레슨 예약 (Booking)

### 4.1 통합 예약 플로우

모든 레슨 예약은 **LessonBookingScreen** 하나로 통일된다.

```
[선생님 목록/검색] -> [선생님 선택] -> 관계 확인
    -> [레슨 유형 선택] (관계에 따라 활성화)
    -> [일정 선택]
       - 체험/1회: 단일 날짜+시간
       - 정기: 요일 + 시작일 + 기간
    -> [추가 정보 입력]
    -> [신청 확인 & 제출]
    -> [선생님 알림] -> 승인/거절
    -> [학생 알림] -> 일정 확정
```

### 4.2 예약 전 수강권 확인

```
수강권 상태?
  ├── 없음/만료 -> 수강권 제안 플로우 (결제 -> 발급)
  └── 유효함 -> 바로 예약 가능 (시간 선택)
```

### 4.3 BookingStatus

> 정식 enum 정의는 [10.2절](#102-bookingstatus-7개-값) 참조

| 상태 | 설명 |
|------|------|
| `pending` | 신청완료 (승인 대기) |
| `confirmed` | 확정 (선생님 승인) |
| `changeRequested` | 변경 요청 중 |
| `completed` | 완료 |
| `cancelled` | 취소 |
| `unavailable` | 일정 조율 필요 (선생님이 해당 시간 불가) |
| `expired` | 응답 대기 만료 (48시간 초과) |

### 4.4 시간 선택 UI

| 항목 | 설명 |
|------|------|
| 시간 간격 | 30분 단위 |
| 레이아웃 | 4열 그리드 (칩 버튼) |
| 단일 뷰 | 칩 버튼만 사용 (토글 뷰 없음) |
| 가용 시간만 | 예약 불가 시간은 숨김 또는 회색 |
| 스마트 추천 | 평소 레슨 시간 하이라이트 |
| 빈 상태 대응 | 가용 시간 없으면 대안 날짜 제안 |

**슬롯 상태 (AvailabilitySlotStatus):**

> 정식 enum 정의는 [10.3절](#103-availabilityslotstatus-5개-값) 참조

| 상태 | 설명 | UI |
|------|------|-----|
| `available` | 선택 가능 | 흰 배경, 테두리 |
| `booked` | 예약됨 (다른 학생) | 회색 배경 (비노출) |
| `myBooking` | 내 예약 | Primary 색상 |
| `cancelled` | 취소됨 (휴무 등) | 회색 배경 (비노출) |
| `past` | 지난 시간 | 회색 배경 (비노출) |

**UI에서 추가 사용하는 선택 상태:**
| 상태 | 설명 | UI |
|------|------|-----|
| 선택됨 (UI only) | 사용자가 선택한 슬롯 | Primary 색상 |

### 4.5 동시 신청 정책

| 정책 | 허용 |
|------|:----:|
| 여러 선생님 동시 신청 | O |
| 같은 선생님 다른 악기 | O |
| 취소 권한 | 학생, 선생님 모두 |

### 4.6 첫 달 일할 계산

| 항목 | 설명 |
|------|------|
| 주차 계산 기준 | ISO 주차 (월요일 시작) |
| 5주차 처리 | 기본 휴강으로 계산 포함 |
| 적용 범위 | 첫 달만 |
| 계산 공식 | `월 수강료 x (남은 주차 / 4)` |
| 반올림 | 1,000원 단위 |

---

## 5. 레슨 노트

### 5.1 개요

선생님이 레슨 중/후에 피드백, 주요 포인트, 연습 팁을 기록하고
학생(읽기 전용)과 학부모(향후)가 확인할 수 있는 시스템.

| 항목 | 결정 |
|------|------|
| 노트 구성 요소 | feedback(텍스트) + keyPoints(배열) + practiceTips(텍스트) |
| 편집 권한 | 선생님만 편집 / 학생-학부모 읽기 전용 |
| 저장 방식 | Lesson 엔티티에 포함 (별도 테이블 X) |
| 입력 방식 | 인라인 편집 + AddTipBottomSheet |
| 템플릿 지원 | keyPoints, practiceTips에 팁 템플릿 라이브러리 연동 |

### 5.2 데이터 모델

```dart
// Lesson 엔티티 내 레슨 노트 필드 (Lines 160-163)
final String? feedback;           // 선생님 피드백 (자유 텍스트)
final List<String>? keyPoints;    // 주요 포인트 (배열)
final String? practiceTips;       // 연습 팁 (단일 텍스트)
final List<LessonRecording>? recordings;  // 레슨 녹음
```

### 5.3 위젯 구성

| 위젯 | 역할 |
|------|------|
| `LessonNoteEditor` | 선생님 전용 피드백 텍스트 입력 (6줄 multiline) |
| `TeacherFeedbackCard` | 학생 전용 피드백 읽기 전용 표시 |
| `KeyPointsList` | 포인트 목록 + 삭제 (선생님만) |
| `PracticeTipsCard` | 연습 팁 카드 + 편집 (선생님만) |
| `AddTipBottomSheet` | 포인트/팁 추가 바텀시트 |

### 5.4 사용자 플로우

**선생님**: LessonDetailScreen 노트 탭 -> 피드백 인라인 편집, [+] 버튼으로 포인트/팁 추가 -> `lessonsNotifierProvider.updateLesson()` 호출.

**학생**: LessonDetailScreen 노트 탭 -> TeacherFeedbackCard + KeyPointsList + PracticeTipsCard 읽기 전용.

### 5.5 레슨 노트 접근 권한

| 시나리오 | 학생 | 기존 선생님 | 새 선생님 |
|----------|:----:|:----------:|:--------:|
| 정상 연결 중 | O 열람 | O 열람 | - |
| 연결 해제/변경 | O 열람 | X 차단 | X 기본 불가 |
| 새 선생님에게 공유 | O 열람 | X 차단 | O 학생 승인 시 |
| 이전 선생님 재연결 | O 열람 | O 복원 | - |

### 5.6 향후 계획

- Phase 2: 타임라인 뷰 (월별 그룹핑, 학생 프로필에서 진입)
- Phase 3: 학부모 열람 (학부모 대시보드, 새 피드백 알림)
- Phase 4: AI 변환 (레슨 녹음 -> Whisper STT -> 요약 텍스트)

---

## 6. 레슨 장소

### 6.1 장소 유형 (LocationType)

| 유형 | 아이콘 | 설명 | 예시 |
|------|:-----:|------|------|
| `academyRoom` | 학원 | 학원 레슨실 | 레슨실 1 |
| `teacherStudio` | 집 | 선생님 스튜디오 | 남부터미널 우드브릿지 |
| `studentHome` | 차 | 학생 집 방문 | 학생 자택 |
| `externalPlace` | 핀 | 외부 장소 | 뮤직홀 연습실 |
| `online` | PC | 온라인 | Zoom, FaceTime |

### 6.2 핵심 원칙

> **"한 번 설정, 자동 적용, 필요 시 변경"**

| 목표 | 설명 |
|------|------|
| 빠른 레슨 생성 유지 | 학생 선택 -> 장소 자동 프리필 |
| 학생별 기본 장소 | 학생마다 고정 장소 지정 -> 매번 선택 불필요 |
| 장소 변경 알림 | 기존 레슨의 장소 변경 시 자동 알림 |

### 6.3 자동 프리필 우선순위

```
1. Student.defaultLocationId  (학생별 기본 장소)
       -> null이면
2. LessonClass.defaultLocation (반별 기본 장소)
       -> null이면
3. 선생님의 기본 장소 (ownerId=teacherId, isDefault=true)
       -> null이면
4. 빈 상태 (선택 안 됨)
```

### 6.4 "이번만" vs "기본으로 저장"

자동 프리필된 장소를 변경할 때:
- **이번만**: `Lesson.location`만 변경
- **기본으로 저장**: `Student.defaultLocationId`도 업데이트

### 6.5 UI 배치

AddLessonScreen 기존 섹션 사이에 장소 선택 추가 (구현 완료, Phase 1):
```
1. 학생 선택 (기존)
2. 날짜/시간 (기존)
3. 레슨 시간 (기존)
4. 레슨 장소 (구현 완료) — LessonLocationSection 위젯
5. 반복 설정 (기존)
6. 곡명/노트 (기존)
7. 알림 설정 (기존)
```

장소는 **선택 사항** (필수 아님). 학생 선택 전에는 비활성 상태.

**Phase 1 구현 범위 (현행)**:
- 선생님 소유 장소(`teacherLocationsProvider`) ChoiceChip 목록 표시
- 기본 장소(`isDefault`) 자동 프리필
- 선택 결과를 `LessonLocationInfo`(name/address)로 변환하여 `Lesson.location`에 저장

**Phase 2 이후 (미구현)**:
- §6.3 1단계 `Student.defaultLocationId` 기반 프리필 — 엔티티 필드 추가 필요
- §6.3 2단계 `LessonClass.defaultLocation` 기반 프리필
- §6.4 "이번만" vs "기본으로 저장" 다이얼로그
- §6.6 온라인 레슨 미팅 링크 입력 UI
- §6.7 장소 변경 알림

### 6.6 온라인 레슨 특수 처리

- 플랫폼 선택: Zoom, Google Meet, FaceTime
- 미팅 링크 (선택): 고정 링크 또는 레슨별 입력
- 학생 앱: 레슨 시작 30분 전~레슨 중에만 [수업 참여하기] 버튼 표시

### 6.7 장소 변경 알림

기존 레슨(예약 확정 상태)의 장소가 변경되면 자동 알림:
- 수신: 학생 (항상) + 학부모 (미성년 학생)
- 채널: 인앱 알림 + 푸시 (FCM 추후)

---

## 7. 빠른 레슨 등록 (Quick Add)

### 7.1 문제

선생님이 홈에서 레슨 추가 시 최소 10탭 필요. 정기 레슨 패턴 데이터가 활용되지 않음.

### 7.2 핵심 변경: 학생 선택 시 자동 완성

```
학생 선택 시:
1. Student.lessonDay -> 다음 해당 요일 날짜 설정
2. Student.lessonTime -> 시간 자동 입력
3. Student.lessonDuration -> 레슨 시간 칩 자동 선택
4. 마지막 레슨 곡명 -> 힌트 표시 ("이전: 바흐 파르티타 2번")
```

### 7.3 진입 경로별 개선

| 진입 경로 | 현재 | 개선 후 | 절감 |
|----------|:----:|:------:|:----:|
| 홈 -> [레슨 추가] | 10탭 | **3탭** | -70% |
| 레슨 카드 -> [반복] | 없음 | **2탭** | 신규 |
| 스케줄탭 -> [+] | 8탭 | **3탭** | -63% |
| 학생상세 -> FAB | 4~5탭 | **2탭** | -50% |

### 7.4 레슨 카드 반복 버튼 (신규)

오늘의 레슨 카드에 [반복] 아이콘 추가. 탭 시 해당 학생의 다음 주 동일 시간으로 레슨 자동 생성.

```
[반복] 탭 -> 확인 다이얼로그:
  "홍길동 다음 레슨을 추가할까요?"
  다음 주 월요일 14:00 / 60분
  [취소] [추가]
```

---

## 8. 그룹 레슨

### 8.1 개요

GX(Group Exercise) 방식 기반 그룹레슨 시스템. 앙상블, 합주, 이론 수업 등에 활용.

### 8.2 클래스 유형

| 구분 | 정기 클래스 | 예약형 클래스 |
|------|-----------|-------------|
| 스케줄 | 자동 (매주 반복) | 수동 (오픈) |
| 적합 용도 | 앙상블, 합주, 정기 이론 | 특강, 워크샵 |
| 알림 | 예약 가능 알림 | 새 스케줄 오픈 알림 |

### 8.3 정원 관리

| 상태 | 설명 |
|------|------|
| available | 예약 가능 |
| almostFull | 거의 만석 (80% 이상) |
| full | 만석 (대기 가능) |
| waitlist | 대기 중 |
| closed | 예약 마감 |

**대기자 명단 (Waitlist):**
- 만석 시 대기자 등록 (순번 부여)
- 취소 발생 시 순서대로 자동 승급 + 푸시 알림
- 클래스 시작 시 미승급 대기자 자동 취소 (차감 없음)

### 8.4 수강권 차감 정책

| 상황 | 차감 |
|------|:----:|
| 예약 | X |
| 예약 후 사전 취소 | X |
| 클래스 참여 (출석 체크) | O 1회 |
| 노쇼 (미참석) | 설정에 따름 |

**핵심**: 예약만으로는 차감 안 됨. 실제 참여 시 차감.

### 8.5 출석 체크 UI

> "생각없이 출석 체크" - 기본값 자동 적용, 예외만 수정

1. 수업 시작: 예약자 전원 자동 체크
2. 미참석자만 탭하여 해제 (역방향 처리)
3. [수업 종료하기] 원탭: 출석 확정 + 수강권 차감

### 8.6 예약/취소 마감

| 설정 | 설명 | 권장 |
|------|------|:----:|
| 시작 직전 | 0분 전까지 | - |
| **2시간 전** | 클래스 시작 2시간 전까지 | O |
| 24시간 전 | 하루 전까지 | - |
| 커스텀 | 선생님 직접 설정 | - |

### 8.7 데이터 모델

```dart
class GroupClass {
  final String id;
  final String teacherId;
  final String? organizationId;
  final String name;
  final GroupClassType type;      // regular, dropIn
  final int maxCapacity;
  final int? waitlistCapacity;
  final int durationMinutes;
  final int? bookingDeadlineMinutes;
  final int? cancelDeadlineMinutes;  // 기본 120분
  final NoShowPolicy noShowPolicy;
  final int? maxNoShowCount;
  final List<int>? repeatDaysOfWeek;
  final String? repeatTimeOfDay;
  final bool isActive;
}

class GroupClassSchedule {
  final String id;
  final String groupClassId;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleStatus status;
  final int currentBookings;
  final int waitlistCount;
}

class GroupClassBooking {
  final String id;
  final String scheduleId;
  final String studentId;
  final String subscriptionId;
  final BookingStatus status;
  final int? waitlistPosition;
  final DateTime? attendedAt;
  final bool subscriptionDeducted;
}
```

### 8.8 알림

| 알림 | 발송 시점 | 수신자 |
|------|----------|--------|
| 예약 확정 | 예약 즉시 | 학생 |
| 대기자 승급 | 취소 발생 시 | 대기 1순위 |
| 수업 리마인더 | 2시간 전 | 예약 학생 |
| 새 스케줄 오픈 | 스케줄 생성 시 | 구독 학생 |
| 출석 완료 | 출석 체크 시 | 학생 |
| 노쇼 경고 | 노쇼 횟수 초과 시 | 학생 |

---

## 9. 3자 관계 (학원-선생님-학생)

### 9.1 핵심 시나리오

| 시나리오 | 설명 |
|----------|------|
| A: 학원 강사 | 학원 소속 강사로 레슨. 수강권은 학원 발행. 퇴사 시 기록 학원 보존 |
| B: 병행 (선생님) | 학원 A + 학원 B + 개인 레슨 병행. 소속 전환 UI 필요 |
| C: 병행 (학생) | 학원에서 바이올린 + 개인으로 피아노. 통합 캘린더 필요 |
| D: 혼자 연습 | 선생님 없이 메트로놈/튜너/녹음 사용. 나중에 선생님 초대 가능 |

### 9.2 핵심 원칙

```
"organizationId가 null이면 개인, 있으면 학원"
```

### 9.3 데이터 모델 확장 계획

#### Phase 1: Context 필드 추가

```dart
// Student 확장
final String? organizationId;      // 학원 소속 (null = 개인)
final String? assignedTeacherId;   // 담당 선생님

// Teacher 확장
final List<String> organizationIds;  // 소속 학원들 (다중)

// Lesson 확장
final String? organizationId;      // 학원 Context
```

#### Phase 2: 관계 모델 추가

```dart
class TeacherStudentRelation {
  final String teacherId;
  final String studentId;
  final String? organizationId;    // null = 개인 레슨
  final String? instrument;
  final RelationStatus status;     // active, paused, ended
}
```

같은 학생을 학원/개인 양쪽에서 가르칠 수 있다 (organizationId로 구분).

#### Phase 3: 학원 멤버십

```dart
class Membership {
  final String organizationId;
  final String userId;
  final MemberRole role;           // owner, manager, instructor
  final MemberStatus status;
}
```

#### Phase 4: 학원 관리 (웹 대시보드)

학원 설정, 강사 관리, 학생 배정, 레슨실별 캘린더, 매출 리포트.

### 9.4 하위 호환성

기존 개인 선생님 사용자는 아무 영향 없음. 학원 기능은 옵트인(가입 시에만 활성화).

### 9.5 Context 배지

| Context | 아이콘 | 배경색 | 텍스트 |
|---------|:-----:|--------|--------|
| 개인 레슨 | 사람 | #F5F5F5 | "개인" |
| 학원 레슨 | 학교 | #EDE7F6 | 학원명 |

### 9.6 학원 레슨실 충돌 방지

학원에서 여러 강사가 같은 레슨실 사용 시 충돌 감지 -> 다른 레슨실 제안.

---

## 10. Enum 정의

이 섹션은 레슨 도메인에서 사용하는 모든 enum을 정식 Dart 코드 블록으로 정의한다.

### 10.1 LessonStatus (10개 값)

```dart
enum LessonStatus {
  // Basic states
  scheduled,                   // 예정
  completed,                   // 완료

  // Cancellation states (detailed)
  cancelled,                   // 취소 (레거시 호환)
  cancelledByStudentAdvance,   // 학생 사전 취소 (24h+ 전, 차감 없음)
  cancelledByStudentLate,      // 학생 당일 취소 (24h 이내, 차감)
  cancelledByTeacher,          // 선생님 취소 (보강, 차감 없음)
  cancelledMutual,             // 합의 취소 (보강, 차감 없음)

  // Absence
  noShow,                      // 결석 (레거시)
  studentAbsent,               // 학생 불참 (차감)

  // Reschedule pending
  reschedulePending,           // 변경 대기 (확인 전)
}
```

**차감 대상**: `completed`, `cancelledByStudentLate`, `noShow`, `studentAbsent`
**보강 허용**: `cancelledByStudentAdvance`, `cancelledByTeacher`, `cancelledMutual`, `reschedulePending`

> 코드 위치: `features/lessons/domain/entities/lesson.dart`

### 10.2 BookingStatus (7개 값)

```dart
enum BookingStatus {
  pending,          // 신청완료 (승인 대기)
  confirmed,        // 확정 (선생님 승인)
  changeRequested,  // 변경 요청 중
  completed,        // 완료
  cancelled,        // 취소
  unavailable,      // 일정 조율 필요 (선생님이 해당 시간 불가)
  expired,          // 응답 대기 만료 (48시간 초과)
}
```

> 코드 위치: `features/schedule/domain/entities/lesson_booking.dart`

### 10.3 AvailabilitySlotStatus (5개 값)

```dart
enum AvailabilitySlotStatus {
  available,   // 예약 가능
  booked,      // 예약됨 (다른 학생)
  myBooking,   // 내 예약
  cancelled,   // 취소됨 (휴무 등)
  past,        // 지난 시간
}
```

> 코드 위치: `features/schedule/domain/entities/availability_slot.dart`

### 10.4 SlotStatus (3개 값)

```dart
@HiveType(typeId: 71)
enum SlotStatus {
  available,   // 예약 가능
  booked,      // 예약됨
  cancelled,   // 취소됨 (휴무 등)
}
```

> 코드 위치: `features/schedule/domain/entities/teacher_availability.dart`

### 10.5 NoShowPolicy (4개 값)

```dart
@HiveType(typeId: 88)
enum NoShowPolicy {
  deductCredit,  // 1회 차감 (기본값)
  halfCredit,    // 0.5회 차감
  noDeduction,   // 차감 없음
  reschedule,    // 보강으로 전환
}
```

> 코드 위치: `features/schedule/domain/entities/no_show_policy.dart`

### 10.6 MakeupStatus (5개 값) / MakeupReason (4개 값)

```dart
@HiveType(typeId: 85)
enum MakeupStatus {
  pending,     // 시간 미정
  scheduled,   // 시간 확정
  completed,   // 완료
  expired,     // 만료 (30일)
  waived,      // 선생님 면제 처리
}

@HiveType(typeId: 86)
enum MakeupReason {
  studentCancellation,   // 학생 취소 (D-1 이전)
  teacherCancellation,   // 선생님 취소
  noShowReschedule,      // 노쇼 (reschedule 정책)
  other,                 // 기타
}
```

> 코드 위치: `features/schedule/domain/entities/makeup_lesson.dart`

### 10.7 FifthWeekPolicy (4개 값)

```dart
enum FifthWeekPolicy {
  skip,       // 5주차 자동 휴강 (기본값)
  optional,   // 5주차 학생 선택
  credit,     // 5주차 진행 -> 다음달 크레딧
  always,     // 5주차 항상 진행
}
```

> 참고: 현재 코드에 아직 반영되지 않음. 스펙 확정 상태.

### 10.8 LessonType (3개 값)

```dart
enum LessonType {
  trial,    // 체험 레슨
  regular,  // 정규 레슨
  oneTime,  // 1회 레슨
}
```

> 코드 위치: `features/schedule/domain/entities/lesson_booking.dart`

---

## 11. 구현 파일 매핑

### 11.1 엔티티 -> 코드 매핑

| 스펙 항목 | 코드 파일 |
|----------|----------|
| LessonStatus | `features/lessons/domain/entities/lesson.dart` |
| Lesson | `features/lessons/domain/entities/lesson.dart` |
| LessonPiece | `features/lessons/domain/entities/lesson.dart` |
| LessonRecording | `features/lessons/domain/entities/lesson.dart` |
| LessonLocationInfo | `features/lessons/domain/entities/lesson.dart` |
| BookingStatus | `features/schedule/domain/entities/lesson_booking.dart` |
| LessonBooking | `features/schedule/domain/entities/lesson_booking.dart` |
| LessonType | `features/schedule/domain/entities/lesson_booking.dart` |
| ScheduleOption (deprecated) | `features/schedule/domain/entities/lesson_booking.dart` |
| NoShowPolicy | `features/schedule/domain/entities/no_show_policy.dart` |
| NoShowRecord | `features/schedule/domain/entities/no_show_policy.dart` |
| MakeupLesson | `features/schedule/domain/entities/makeup_lesson.dart` |
| MakeupStatus / MakeupReason | `features/schedule/domain/entities/makeup_lesson.dart` |
| ~~LessonScheduleChange~~ | ~~`lesson_schedule_change.dart`~~ → 제거 (Phase 2, 2026-04-28). `RequestEvent` 가 chat history 로 대체. |
| ScheduleChangeType | `features/schedule/domain/entities/request_event.dart` (구 `lesson_schedule_change.dart`, Phase 2 이동) |
| GroupClass | `features/schedule/domain/entities/group_class.dart` |
| GroupClassSchedule | `features/schedule/domain/entities/group_class_schedule.dart` |
| GroupClassBooking | `features/schedule/domain/entities/group_class_booking.dart` |
| TipTemplate | `features/lessons/domain/entities/tip_template.dart` |
| Payment (레거시) | `features/lessons/domain/entities/payment.dart` |

### 11.2 화면 -> 코드 매핑

| 스펙 항목 | 코드 파일 |
|----------|----------|
| 레슨 추가 | `features/lessons/presentation/screens/add_lesson_screen.dart` |
| 레슨 상세 (노트/과제) | `features/lessons/presentation/screens/lesson_detail_screen.dart` |
| 레슨 수정 | `features/lessons/presentation/screens/edit_lesson_screen.dart` |
| 레슨 노트 히스토리 | `features/lessons/presentation/screens/lesson_note_history_screen.dart` |
| 그룹 클래스 상세 | `features/schedule/presentation/screens/group_class_detail_screen.dart` |
| 그룹 출석 관리 | `features/schedule/presentation/screens/group_class_attendance_screen.dart` |

### 11.3 Provider -> 코드 매핑

| 스펙 항목 | 코드 파일 |
|----------|----------|
| 레슨 CRUD | `features/lessons/presentation/providers/lesson_crud_provider.dart` |
| 레슨 캘린더 | `features/lessons/presentation/providers/lesson_calendar_provider.dart` |
| 레슨 통계 | `features/lessons/presentation/providers/lesson_stats_provider.dart` |
| 레슨 노트 | `features/lessons/presentation/providers/lesson_note_providers.dart` |
| 예약 관리 | `features/lessons/presentation/providers/booking_providers.dart` |
| 레거시 입금 기록 | `features/lessons/presentation/providers/payment_providers.dart` |

> 모든 경로는 `frontend/lib/` 기준 상대 경로

---

## 12. 경쟁사 대비 차별점

### 12.1 레슨 시스템 차별화

| 기능 | Lessonaza | 스튜디오메이트/Studiomate | 숨고/크몽 |
|------|:---------:|:------------------------:|:---------:|
| 1:1 + 그룹 통합 | O | 그룹 중심 | X |
| 선생님 가용시간 + 예외 관리 | O | 제한적 | X |
| 멀티옵션 스케줄링 | O (칩 선택) | X (관리자 배정) | X |
| 수강권 기반 자동 관계 관리 | O | 수동 | X |
| 세분화된 취소 정책 (10개 상태) | O | 단순 취소/완료 | X |
| 학생별 노쇼 정책 설정 | O | 일괄 정책 | X |
| 보강 30일 만료 추적 | O | 수동 관리 | X |
| 학부모 대시보드 | O (계획) | 제한적 | X |
| 앱 전환 플로우 (기존 레슨 이관) | O | X | X |

### 12.2 핵심 경쟁력

1. **개인 선생님 최적화**: 학원 관리 시스템(POS/ERP)이 아닌 개인 선생님의 레슨 관리에 초점
2. **슬롯 기반 선착순 예약**: 제안-승인 왕복을 제거하여 예약 프로세스 간소화
3. **수강권 중심 라이프사이클**: 수강권 발급 -> 관계 자동 관리 -> 갱신까지 원스톱
4. **유연한 레슨 정책**: 5주차, 노쇼, 취소, 보강을 선생님이 학생별로 커스터마이징

---

## 13. 구현 현황

### 13.1 구현된 파일 구조

```
frontend/lib/features/lessons/
├── domain/entities/
│   ├── lesson.dart          # Lesson 엔티티 (feedback/keyPoints/practiceTips 포함)
│   ├── payment.dart         # Payment 엔티티 (레거시)
│   └── tip_template.dart    # 팁 템플릿
├── data/repositories/
│   ├── mock_lesson_repository.dart
│   └── remote_lesson_repository.dart
├── presentation/
│   ├── providers/           # lesson CRUD, calendar, booking, payment providers
│   ├── screens/
│   │   ├── add_lesson_screen.dart
│   │   ├── lesson_detail_screen.dart    # 2탭 (노트/과제) — 녹음 탭 제거 (#171)
│   │   └── edit_lesson_screen.dart
│   └── widgets/
│       ├── lesson_form/     # 폼 관련 위젯들
│       └── lesson_detail/   # 노트 관련 위젯들

frontend/lib/features/schedule/
├── domain/entities/
│   ├── lesson_booking.dart
│   ├── teacher_availability.dart
│   ├── group_class.dart / group_class_schedule.dart / group_class_booking.dart
│   ├── makeup_lesson.dart
│   ├── no_show_policy.dart
│   ├── request_event.dart  # ScheduleChangeType 포함 (Phase 2 통합)
│   ├── lesson_request.dart
│   └── schedule_confirmation_card.dart
├── domain/repositories/
│   ├── teacher_availability_repository.dart
│   ├── group_class_booking_repository.dart
│   ├── lesson_request_repository.dart
│   └── schedule_confirmation_card_repository.dart
├── domain/services/
│   └── slot_recommendation_service.dart
├── data/repositories/       # Mock + Remote 구현
└── presentation/
    ├── providers/
    ├── screens/
    │   ├── lesson_booking_screen.dart
    │   ├── teacher_availability_screen.dart
    │   ├── weekly_schedule_screen.dart
    │   ├── time_exception_screen.dart
    │   ├── pending_bookings_screen.dart
    │   ├── booking_confirmation_screen.dart
    │   ├── booking_cancel_screen.dart
    │   ├── booking_reschedule_screen.dart
    │   ├── register_regular_lesson_screen.dart
    │   ├── group_class_detail_screen.dart
    │   ├── group_class_attendance_screen.dart
    │   ├── lesson_request_screen.dart
    │   ├── lesson_requests_screen.dart
    │   └── my_bookings_screen.dart / my_lesson_requests_screen.dart
    └── widgets/             # time_slot, availability, approval 위젯들
```

### 13.2 기능별 구현 상태

| 기능 | 상태 | 완료율 | 비고 |
|------|:----:|:------:|------|
| **선생님-학생 연결 (QR/URL)** | 구현 완료 | 80% | 딥링크, 푸시 알림 미연동 |
| **체험 레슨 예약** | 구현 완료 | 90% | LessonBookingScreen + WeekCalendar + 시간 칩 |
| **정기 레슨 등록** | 부분 구현 | 60% | 제안 플로우 보완 필요 |
| **수강권 발급** | 구현 완료 | 85% | IssueSubscriptionScreen, SubscriptionDetailScreen |
| **수강권 입금 상태 기록** | 구현 완료 | 85% | 수강권 제안/확정 상태로 기록, 독립 결제 기능 아님 |
| **회차권 레슨** | 부분 구현 | 70% | 기본 플로우 구현, 알림 미연동 |
| **레슨 취소/변경** | 구현 완료 | 80% | BookingCancelScreen, BookingRescheduleScreen |
| **노쇼 처리** | 부분 구현 | 40% | 엔티티 설계 완료, 상세 처리 미구현 |
| **보강 추적** | 설계 완료 | 30% | MakeupLesson 엔티티 존재, UI 미구현 |
| **선생님 가용시간** | 구현 완료 | 100% | TeacherAvailabilityScreen, WeeklyScheduleScreen, TimeExceptionScreen |
| **레슨 노트** | 구현 완료 | 95% | Phase 1 완료 (피드백/포인트/팁/녹음) |
| **출석 관리** | 구현 완료 | - | `TeacherAttendanceScreen` — 전체 출석률 + 학생별 현황 |
| **일괄 피드백** | 구현 완료 | - | `BulkFeedbackScreen` — 여러 학생에게 3단계 위저드로 피드백 전송 |
| **레슨 노트 히스토리** | 부분 구현 | 70% | `LessonNoteHistoryScreen` 파일 존재, **BROKEN: `app_routes.dart`에 `lessonNoteHistory` 경로 미등록** — student_routes의 `/students/:id/notes`로만 접근 가능 |
| **빠른 피드백** | 구현 완료 | - | `QuickFeedbackScreen` + `QuickFeedbackStudentList` |
| **레슨 장소** | 부분 구현 | 60% | Phase 1 UI 완료 (LessonLocationSection, teacherLocationsProvider 연동, ChoiceChip + 기본 프리필). Phase 2 이후(§6.3 1~2단계·§6.4·§6.6·§6.7) 미구현 |
| **빠른 레슨 등록** | 스펙 완료 | 0% | 구현 대기 (스펙 §7만 정의) |
| **그룹 레슨** | 설계 완료 | 30% | 엔티티 + 기본 화면 존재 |
| **3자 관계 (학원)** | 설계 완료 | 10% | LessonClass 엔티티 설계만 |
| **앱 전환 플로우** | 부분 구현 | 70% | "입금 확인 완료로 발급" 옵션 보완 필요 |
| **이전 선생님 재연결** | 부분 구현 | 40% | 기본 플로우 구현, 알림/스케줄 복원 작업 중 |
| **정기 시간 일괄 변경** | 설계 완료 | 20% | `RequestEvent` (chat history) 로 통합. Phase 2, 2026-04-28. |
| **스케줄 확인 카드** | 설계 완료 | 50% | ScheduleConfirmationCard 엔티티 172줄 완전 구현 (3-옵션 제안, 재등록/신규 분기, `formattedOptions`/`getOption(index)` 포함). UI 노출·라우팅 검증 필요 |
| **FCM 푸시 알림** | 부분 구현 | 40% | 인프라 완성 (`firebase_messaging:15.2.4` 의존성, `main.dart` 백그라운드 핸들러 초기화, `FcmService.initialize()` 완성, foregroundMessage 스트림). 화면 통합·알림 UI 미구현 |
| **백엔드 API** | 개발 중 | 20% | FastAPI 기본 구조 |

### 13.3 테스트 환경

현재 앱은 Mock 데이터 모드로 실행.

| 기능 | Mock 파일 |
|------|----------|
| 선생님 가용시간 | `MockTeacherAvailabilityRepository` |
| 예약 목록 | `MockBookingRepository` (레거시) |
| 수강권 | `MockSubscriptionRepository` |
| 그룹 클래스 | `MockGroupClassBookingRepository` |
| 레슨 요청 | `MockLessonRequestRepository` |
| 스케줄 확인 카드 | `MockScheduleConfirmationCardRepository` |

### 13.4 우선순위 (다음 단계)

1. **FCM 연동** - 푸시 알림 설정, 수신 처리, 알림 탭 UI
2. **백엔드 API** - 인증, 예약, 수강권 API
3. **추가 기능** - 딥링크, 노쇼 정책 상세화, 정기 레슨 제안 플로우 완성

---

## 14. 관련 스펙

| 문서 | 설명 |
|------|------|
| [schedule_master.md](../schedule/schedule_master.md) | 스케줄 시스템 마스터 (가용시간, 예약, 확인 카드) |
| [subscription_system_spec.md](../subscription/subscription_system_spec.md) | 수강권 시스템 |
| [subscription_proposal_spec.md](../subscription/subscription_proposal_spec.md) | 수강권 제안 시스템 |
| [lesson_request_system.md](../subscription/lesson_request_system.md) | 레슨 요청 시스템 (재등록) |
| [teacher_availability_spec.md](../schedule/teacher_availability_spec.md) | 선생님 가용시간 |
| [subscription_based_relationship.md](invite/subscription_based_relationship.md) | 수강권 중심 관계 모델 |
| [invite_system_v2.md](invite/invite_system_v2.md) | 초대 시스템 |
| [student_class_system.md](../student/student_class_system.md) | LessonClass, ClassMembership 엔티티 |
| [ux_guidelines.md](../design/ux_guidelines.md) | UX 가이드라인 |
| [notification_system.md](../notification/notification_system.md) | 알림 시스템 |
| [attendance_spec.md](attendance_spec.md) | 출석 관리 시스템 |
| [gamification_spec.md](../practice/gamification_spec.md) | 게이미피케이션 (연습/학생 참여) |

#### 통합 원본 (Historical — 작업 근거로 사용 금지)

| 문서 | 비고 |
|------|------|
| [payment_unified_spec.md](../_archive/old/payment_unified_spec.md) | 결제 시스템 통합 (subscription_master에 통합됨) |

### 엔티티 스키마

| 엔티티 | 위치 |
|--------|------|
| Booking | `docs/schema/entities/booking.md` |
| Subscription | `docs/schema/entities/subscription.md` |
| LessonSchedule | `docs/schema/entities/lesson_schedule.md` |
| LessonLocation | `docs/schema/entities/lesson_location.md` |

---

## 15. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-04-23 | §13.2 DRIFT 검증 반영: 레슨 장소 10→60%, 스케줄 확인 카드 10→50%, FCM 0→40% (인프라 완성 반영), 레슨 노트 히스토리 완료→부분 70% (BROKEN 라우트 미등록 표기) |
| 2026-03-07 | Enum 정의 완전성 보강 (LessonStatus 10값 등), 구현 파일 매핑 추가, 경쟁사 차별점 추가, schedule_master 상호 참조, attendance/gamification 스펙 참조 추가, 깨진 링크 수정 |
| 2026-03-06 | Master Spec 초안 작성 - 15개 개별 스펙 통합 |

### 통합 원본 문서 목록

이 마스터 스펙은 다음 개별 문서들을 통합한 것이다:

| 원본 파일 | 통합된 섹션 |
|----------|------------|
| `flow_with_app.md` | 1, 3.7 (앱 핵심 특징, 개인/학원 비교, 개선 효과) |
| `flow_without_app.md` | 3.7 (Pain Points, 시간 비교) |
| `flow_connection.md` | 3.1 (연결 플로우 전체) |
| `flow_trial.md` | 3.2 (체험 레슨) |
| `flow_regular.md` | 3.3 (정기 레슨 등록) |
| `flow_package.md` | 3.4 (회차권 레슨) |
| `flow_payment.md` | 3.5 (입금/입금대기(후불)) |
| `flow_cancel.md` | 3.6 (취소/변경/노쇼/보강) |
| `flow_test_checklist.md` | 13 (구현 현황) |
| `Unified_Lesson_Booking_Spec.md` | 4 (예약 시스템) |
| `lesson_schedule.md` | 2, 3.6 (스케줄 유형, 5주차, 노쇼, 보강, 일괄 변경) |
| `lesson_note_spec.md` | 5 (레슨 노트) |
| `lesson_location_selection.md` | 6 (레슨 장소) |
| `quick_add_lesson.md` | 7 (빠른 레슨 등록) |
| `group_lesson_spec.md` | 8 (그룹 레슨) |
| `three_party_relationship_spec.md` | 9 (3자 관계) |

---

## 10. 레슨 추가 — 수강권 연동 vs 수기 관리 (2026-05-07)

### 10.1 기획 원칙

> **레슨 추가는 수강권 유무와 관계없이 항상 가능하다.**
> 선생님이 수기로 레슨을 등록하면 기록 관리가 되고, 수강권이 있으면 자동으로 횟수가 차감된다.

### 10.2 학생 선택 후 안내 배너

| 상황 | 배너 | 아이콘 | 배경 |
|------|------|--------|------|
| 수강권 있음 | "수강권 N/M회 남음 · 이 레슨은 1회차로 차감됩니다." | ✅ (paperOk) | 연두색 |
| 수강권 없음 | "현재 유효한 수강권이 없는 학생입니다.\n수기로 레슨을 등록할 수 있으며, 수강권 발급 후에는\n레슨 횟수와 이동시간이 자동으로 관리됩니다." | ℹ (ink) | paperDark |

### 10.3 수기 레슨의 의미

- 수강권 없이 추가된 레슨: 기록용 (횟수 차감 없음)
- 나중에 수강권 발급 시: 기존 수기 레슨은 소급 적용 안 함
- 선생님이 학부모와 대면으로 수강료를 처리하는 경우에 활용

### 10.4 학생 선택 UI

레슨 추가 화면 진입 시:
- 학생 선택 영역이 최상단에 표시
- 탭하면 학생 목록 바텀시트 (이름/악기/스케줄)
- 학생 선택 후 수강권 배너 + 나머지 폼 필드 표시

## 11. 과제 제목 구조 + 선생님 호칭 (2026-05-07)

### 11.1 과제 표시 구조

학생에게 과제가 표시될 때:

```
┌─── 피아노 개인레슨 과제 ──── (그룹 헤더: 수강권명 + "과제")
│
│  ☐ Canon in D 1~4마디        ← 개별 항목 (곡명 + 범위)
│  ☐ Chopin Prelude 5~8줄
│  ✓ Scale G Major (완료)
│
└──────────────────────────────
```

**그룹 헤더 조합**: `"{악기} {레슨 타입} 과제"`
- 학원: "피아노 학원레슨 과제"
- 개인: "바이올린 개인레슨 과제"
- 체험: "첼로 체험레슨 과제"

### 11.2 선생님 호칭 (닉네임)

`TeacherProfile.nickname` — 학생에게 표시되는 이름.

| 설정 | 학생에게 표시 |
|------|------------|
| 닉네임 미설정 | 본명 (김영희) |
| "영희쌤" | 영희쌤 |
| "바이올린 선생님" | 바이올린 선생님 |

- 기본정보 수정에서 설정 (이름 바로 아래)
- 기본값: 본명이 자동 채움
- `displayName` getter: nickname ?? name

## 12. 레슨 상세 → 스케줄 변경 진입 규칙 (2026-05-08)

### 12.1 문제

레슨 상세에서 [스케줄 변경] 버튼이 `subscriptionId != null`일 때만 표시됨.
하지만 수기 등록 레슨도 학생에게 활성 수강권이 있으면 스케줄 변경이 가능해야 함.

### 12.2 진입 조건

| 레슨 타입 | subscriptionId | 활성 수강권 | 레슨 상태 | [스케줄 변경] 표시 | 이동 대상 |
|----------|:-----------:|:--------:|:-------:|:-------------:|----------|
| 수강권 레슨 | ✅ 있음 | ✅ | 예정 (미래) | **표시** | 해당 수강권 상세(챗) |
| 수기 레슨 | null | ✅ 있음 | 예정 (미래) | **표시** | 학생의 활성 수강권 상세(챗) |
| 수기 레슨 | null | ❌ 없음 | — | 미표시 | — |
| 모든 레슨 | — | — | **완료/취소/과거** | **미표시** | — |

> **v2 (2026-05-09)**: 완료/취소/과거 레슨에는 스케줄 변경 버튼을 숨긴다.
> 이미 끝난 레슨의 일정을 바꿀 수 없기 때문.

### 12.3 로직

```dart
// 1순위: 레슨에 연결된 수강권
if (lesson.subscriptionId != null) → subscriptionDetail(lesson.subscriptionId)

// 2순위: 학생의 활성 수강권 (수기 레슨)
else → activeSubscriptionBetween(studentId, teacherId) → subscriptionDetail(sub.id)

// 수강권 없음 → 버튼 미표시
```

### 12.4 버튼 위치

- **본문**: 레슨 정보 아래, 피드백 위 — full width OutlinedButton
- **AppBar ⋮ 메뉴**: "스케줄 변경" 옵션

### 12.5 버튼 라벨

수강권 레슨: "스케줄 변경"
수기 레슨 (활성 수강권 있음): "스케줄 변경 (수강권: 8회권)"

## 13. 스케줄 타임라인 길게 누르기 액션 시트 (2026-05-08)

### 13.1 Notebook × Score 디자인

기존 Material `ListTile` → 각진 네모 카드형 액션 UI 전환.

```
┌─── 액션 시트 ──────────────────────────┐
│          ━━━━ (handle)                  │
│     김민지 · 14:00                      │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ [✓] 완료 처리                    → │ │
│ └────────────────────────────────────┘ │
│ ┌────────────────────────────────────┐ │
│ │ [✎] 수기 등록 레슨 편집          → │ │  ← 수기 레슨만
│ └────────────────────────────────────┘ │
│ ┌────────────────────────────────────┐ │
│ │ [↔] 일정 변경                    → │ │  ← 수강권+미래 레슨만
│ └────────────────────────────────────┘ │
│                                        │
│ (닫기: 바깥 탭 / 스와이프)              │
└────────────────────────────────────────┘
```

### 13.2 액션 표시 규칙 (v2, 2026-05-08)

> **원칙**: "취소" 버튼 없음 (레슨 취소와 혼동). 시트 닫기는 바깥 탭/스와이프.
> **일간/주간/월간 모든 뷰에서 동일한 액션 시트**.

**수기 레슨:**

| 액션 | 라벨 | 이동 대상 |
|------|------|----------|
| 완료 처리 | "완료 처리" | 레슨 상태 변경 |
| 편집 | "수기 등록 레슨 편집" | 레슨 편집 화면 (전체 편집) |

**수강권 레슨 (미래):**

| 액션 | 라벨 | 이동 대상 |
|------|------|----------|
| 완료 처리 | "완료 처리" | 레슨 상태 변경 |
| 일정 변경 | "일정 변경" | 수강권 상세(챗) |

**수강권 레슨 (과거):**

| 액션 | 라벨 | 이동 대상 |
|------|------|----------|
| 완료 처리 | "완료 처리" | 레슨 상태 변경 |

### 13.3 적용 화면 (공통)

| 화면 | 파일 | 길게 누르기 |
|------|------|-----------|
| 일간 타임라인 | `schedule_timeline_view.dart` | ✅ 공통 액션 시트 |
| 주간 그리드 | `schedule_weekly_grid_view.dart` | ✅ 공통 액션 시트 |
| 레슨 리스트 | 리스트 뷰 카드 | ✅ 공통 액션 시트 |

## 14. 레슨 편집 수기/수강권 분기 (2026-05-08)

### 14.1 문제

레슨 편집 화면이 수기 레슨과 수강권 레슨을 구분하지 않음.
수강권 레슨의 날짜/시간은 변경권을 소모하므로 자유 편집 불가.

### 14.2 필드별 편집 권한

| 필드 | 수기 레슨 | 수강권 레슨 | 수강권 레슨 안내 |
|------|:---:|:---:|------|
| 학생 | ✅ 편집 | 🔒 고정 | 수강권에 연결된 학생 |
| 날짜 | ✅ 편집 | 🔒 → 스케줄 변경(챗) | "스케줄 변경에서 조절하세요" |
| 시간 | ✅ 편집 | 🔒 → 스케줄 변경(챗) | "스케줄 변경에서 조절하세요" |
| 레슨 시간(분) | ✅ 편집 | 🔒 고정 | 수강권 정책에서 설정 |
| 레슨 장소 | ✅ 편집 | 🔒 고정 | 수강권 정책에서 변경 |
| 알림 | ✅ 편집 | 🔒 고정 | 선생님 전역 설정 |
| 정기 반복 | ✅ 편집 | 🔒 고정 | 수강권이 스케줄 관리 |
| **곡/내용** | ✅ 편집 | ✅ 편집 | 자유 수정 |
| **메모** | ✅ 편집 | ✅ 편집 | 자유 수정 |

### 14.3 잠금 필드 UI

```
┌─── 편집 (수강권 레슨) ──────────────────┐
│                                         │
│ 학생: 김민지                  🔒        │  ← grey-out
│ 날짜: 5/9 금                  🔒        │  ← "스케줄 변경에서 조절"
│ 시간: 14:00                   🔒        │
│ 레슨 시간: 60분               🔒        │
│                                         │
│ ┌─ 안내 ──────────────────────────────┐ │
│ │ 수강권 레슨의 날짜/시간 변경은         │ │
│ │ 스케줄 변경에서 진행해주세요.          │ │
│ │ [스케줄 변경으로 이동 →]              │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 곡: [Canon in D           ]   ✎        │  ← 편집 가능
│ 메모: [3번 마디 주의       ]   ✎        │  ← 편집 가능
│                                         │
│ [저장]                                   │
└─────────────────────────────────────────┘
```

### 14.4 액션 시트 분기 (§13.2와 동일 — 전체 앱 일관성)

> **"취소" 버튼 없음**. 시트 닫기는 바깥 탭/스와이프.
> 일간/주간/월간/레슨상세 모든 화면에서 동일.

**수기 레슨:**
- 완료 처리
- **수기 등록 레슨 편집** → edit_lesson_screen (전체 편집)

**수강권 레슨 (미래):**
- 완료 처리
- **일정 변경** → subscription_detail (챗)

**수강권 레슨 (과거):**
- 완료 처리

### 14.5 아키텍처 일관성 규칙

> 이 액션 규칙은 **공통 함수**로 추출하여 모든 뷰에서 재사용한다.
> 각 뷰가 독자적으로 액션을 정의하면 안 됨.

```dart
// schedule/presentation/widgets/lesson_action_sheet.dart
void showLessonActionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Lesson lesson,
}) {
  // §13.2 규칙에 따라 수기/수강권/미래/과거 분기
  // 모든 스케줄 뷰 + 레슨 상세에서 동일하게 호출
}
```

구현 파일: `schedule/presentation/widgets/lesson_action_sheet.dart`

적용 대상:
- `schedule_timeline_view.dart` (일간) ✅ 구현 완료
- `schedule_weekly_grid_view.dart` (주간) ✅ 구현 완료
- 리스트 뷰 레슨 카드 (Phase 3)
- `lesson_detail_screen.dart` AppBar 메뉴

## 15. 삭제 → 보관(아카이브) 정책 (2026-05-09)

### 15.1 원칙

> **연결된 데이터가 있는 항목은 삭제하지 않고 보관(숨김)한다.**
> 하드 삭제는 연결 데이터가 없는 항목에만 허용.

### 15.2 레슨 아카이브

| 조건 | 동작 |
|------|------|
| 피드백/녹음/노트/구독 연결 있음 | **보관** (isArchived=true) |
| 연결 없는 수기 레슨 | 하드 삭제 허용 (선택) |

**엔티티 필드**: `isArchived: bool`, `archivedAt: DateTime?`

**UI**:
- 레슨 상세 PopupMenu: "삭제" → "보관"
- 확인 다이얼로그: "이 레슨을 보관하시겠습니까? 보관된 레슨은 목록에서 숨겨지지만 데이터는 유지됩니다."
- 보관된 레슨은 기본 목록에서 필터링

### 15.3 학생 아카이브

| 조건 | 동작 |
|------|------|
| 레슨/연습/구독 이력 있음 | **보관** (isArchived=true) |
| 막 추가한 학생 (이력 없음) | 하드 삭제 허용 (선택) |

**엔티티 필드**: `isArchived: bool`, `archivedAt: DateTime?`

**UI**:
- 학생 상세 더보기 메뉴: "삭제" → "보관"
- 확인 다이얼로그: "이 학생을 보관하시겠습니까? 관련 레슨과 연습 기록은 유지됩니다."
- 보관된 학생은 수강관리 탭 목록에서 숨김

### 15.4 하드 삭제 유지 대상

| 대상 | 이유 |
|------|------|
| 녹음 파일 | 용량 관리 목적 |
| 백업 파일 | 용량 관리 목적 |
| 공지 | 연결 데이터 없음 |
| 가용성 슬롯 | 연결 데이터 없음 (isActive 토글 별도 존재) |

### 15.5 레퍼토리/섹션 아카이브

`PracticeRepertoire`는 이미 완전한 아카이브 인프라 보유:
- `isArchived`, `archivedAt` 필드
- `archiveRepertoire()` / `unarchiveRepertoire()` 메서드
- `RepertoireArchiveScreen` 보관함 화면

카드 long-press 메뉴에서 "삭제" → "보관"으로 통일.
