# Schedule System Master Spec

> 구현 상태: ✅ 구현 완료
> 최종 업데이트: 2026-03-12
> 통합 문서: `teacher_availability_spec.md`, `schedule_confirmation_card_spec.md`
> 관련 문서: [lesson_master.md](../lesson/lesson_master.md), [subscription_system_spec.md](../subscription/subscription_system_spec.md), [subscription_master.md](../subscription/subscription_master.md), [group_lesson_spec.md](../lesson/group_lesson_spec.md), [ux_guidelines.md](../design/ux_guidelines.md)

---

## 1. 개요

### 1.1 시스템 목적

음악 레슨 예약의 전체 생명주기를 관리하는 통합 스케줄 시스템. 선생님이 가용 시간을 미리 등록하고, 학생이 선착순으로 예약하는 **슬롯 기반 예약 모델**을 핵심으로 한다.

### 1.2 핵심 설계 원칙

| 원칙 | 설명 |
|------|------|
| **슬롯 기반 선착순** | 선생님 가용 슬롯 등록 -> 학생 예약 -> 즉시 확정 (승인 불필요) |
| **1:1 = 정원 1명 클래스** | 1:1 레슨과 그룹 클래스가 동일한 슬롯 예약 로직 재사용 |
| **수강권 필수** | 레슨 예약은 유효한 수강권이 있어야만 가능 |
| **가용 시간만 노출** | 다른 학생의 예약된 시간은 절대 표시하지 않음 |

### 1.3 기존 방식 vs 현재 방식

```
[기존 - 3단계 왕복]
선생님 -> 3개 시간 제안 -> 학생 선택 -> 선생님 승인 -> 확정
         (알림)          (알림)        (알림)

[현재 - 2단계 선착순]
선생님 -> 가용 슬롯 등록 -> 학생 예약 -> 즉시 확정
         (1회)           (자동)
```

| 비교 항목 | 기존 (3개 제안) | 현재 (선착순) |
|----------|----------------|--------------|
| 스케줄 등록 | 레슨마다 제안 | 미리 가용 시간 등록 |
| 예약 확정 | 선생님 승인 필요 | 즉시 자동 확정 |
| 알림 횟수 | 3회 | 1회 (확정) |
| 선생님 관여 | 매번 필요 | 초기 설정만 |

### 1.4 시스템 구성 요소

```
┌─────────────────────────────────────────────────────────────┐
│                  통합 슬롯 예약 시스템                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [1:1 레슨 슬롯]              [그룹레슨 슬롯]                │
│  - 정원: 1명                  - 정원: N명                   │
│  - 예약 = 확정                - 예약 = 확정 (정원 내)        │
│  - 참여 시 차감               - 참여 시 차감                │
│                                                             │
│  -> 동일한 예약 로직 재사용                                   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  [스케줄 확인 카드]            [보강/노쇼 정책]               │
│  - 수강권 발급 후 유도         - 보강 추적 (30일 만료)        │
│  - 시나리오별 자동 분기         - 노쇼 정책 (차감/면제/보강)    │
│                                                             │
│  [정기 레슨 시간 변경]          [레슨 요청 (재등록)]            │
│  - 1회성/일괄 변경              - 이전 학생 재수강 요청         │
│  - 대안 제시 플로우              - 수강권 제안 연동             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 선생님 가용 시간 시스템

### 2.1 슬롯 기반 모델

선생님의 가용 시간은 `TeacherAvailability` 엔티티로 관리된다. 주간 반복 스케줄(`WeeklySchedule`)과 예외(`TimeException`)로 구성된다.

**TeacherAvailability 핵심 속성:**

| 속성 | 타입 | 설명 | 기본값 |
|------|------|------|--------|
| `slotDurationMinutes` | int | 레슨 시간 (30/45/50/60분) | 60 |
| `slotStartInterval` | int | 슬롯 시작 간격 (30/60분) | 30 |
| `breakTimeBetweenLessons` | int | 레슨 사이 쉬는 시간 (0/5/10/15분) | 0 |
| `minBookingHours` | int | 최소 예약 사전 시간 | 24 |
| `autoGenerateWeeks` | int | 자동 슬롯 생성 주 수 | 4 |

**effectiveSlotDuration** = `slotDurationMinutes` + `breakTimeBetweenLessons`
(다음 슬롯 시작 시간 계산에 사용)

### 2.2 주간 스케줄 (WeeklySchedule)

매주 반복되는 가용 시간 블록 정의.

| 속성 | 설명 |
|------|------|
| `dayOfWeek` | 요일 (0=월, 6=일) |
| `startTime` | 시작 시간 ("HH:mm" 형식, 예: "14:00") |
| `endTime` | 종료 시간 ("HH:mm" 형식, 예: "18:00") |
| `isActive` | 활성 여부 |

**동작 규칙:**
- `startTime`~`endTime` 범위 내에서 `slotStartInterval` 간격으로 슬롯 자동 생성
- 예: startTime=14:00, endTime=18:00, interval=30분 -> 14:00, 14:30, 15:00, ..., 17:30
- `autoGenerateWeeks` 주 수만큼 미래 슬롯 자동 생성

### 2.3 시간 예외 관리 (TimeException)

정기 스케줄의 예외를 관리한다.

| 예외 유형 | `ExceptionType` | 설명 |
|----------|----------------|------|
| 휴무 | `holiday` | 특정 날짜 1일 휴무 |
| 휴가 | `vacation` | 기간 휴무 (startDate ~ endDate) |
| 추가 오픈 | `additionalSlot` | 1회성 추가 슬롯 (startTime/endTime 포함) |

**예외 처리 규칙:**
- 휴무/휴가: 해당 날짜의 모든 정기 슬롯 비활성화
- 추가 오픈: 정기 스케줄 외 1회성 슬롯 추가
- 기존 예약이 있는 날짜에 휴무 등록 시 학생에게 알림 전송

```
[선생님 - 휴무 설정]
┌─────────────────────────────────────┐
│  휴무 등록                           │
├─────────────────────────────────────┤
│  ○ 특정 날짜: [2/20(목)]            │
│  ○ 기간: [2/25] ~ [3/1]            │
│  사유: [개인 사정]                   │
│                                     │
│  주의: 해당 날짜의 기존 예약이 있다면 │
│  학생에게 알림이 전송됩니다            │
│  [휴무 등록]                         │
└─────────────────────────────────────┘
```

### 2.4 가용 슬롯 (AvailabilitySlot) - UI 모델

`TeacherAvailability` + `WeeklySchedule` + `TimeException`으로부터 계산되는 **비영속 UI 모델**.

| 속성 | 설명 |
|------|------|
| `date` | 날짜 |
| `startTime` / `endTime` | 시작/종료 시간 |
| `status` | `available` / `booked` / `myBooking` / `cancelled` / `past` |
| `isRecommended` | 평소 시간 추천 여부 |
| `bookedByStudentId` | 예약 학생 ID (선생님 뷰에서만 사용) |

**슬롯 상태 전이:**
```
available -> booked (학생 예약)
available -> cancelled (휴무 등록)
available -> past (시간 경과)
booked -> available (취소)
```

---

## 3. 레슨 예약 플로우

### 3.1 학생 예약 프로세스

**전제 조건:**
- 유효한 수강권 보유 (잔여 횟수 > 0)
- 수강권 없는 경우 [수강권 제안 플로우](../subscription/subscription_master.md) 먼저 진행

**예약 플로우:**

```
1. 수강권 선택
   │
   ▼
2. 주간 캘린더에서 날짜 선택 (가용 날짜에 초록색 점 표시)
   │
   ▼
3. 해당 날짜의 가용 시간 칩 목록에서 시간 선택
   │
   ▼
4. 하단 미리보기 확인 (시간, 선생님, 잔여 횟수)
   │
   ▼
5. [예약하기] 버튼 -> 즉시 확정 (autoConfirm = true)
   │
   ▼
6. 확정 화면 (캘린더 추가, 수강권은 레슨 참여 시 차감)
```

**예약 확정 조건:**

| 조건 | 설명 |
|------|------|
| 슬롯 가용 | 해당 시간 슬롯이 비어있음 |
| 수강권 유효 | 활성 수강권 보유 + 잔여 횟수 > 0 |
| 중복 없음 | 같은 시간에 다른 예약 없음 |
| 최소 사전 시간 | `minBookingHours` 이상 남은 시간 |

**회원 자동 인식:**
- `studentId`가 있으면 게스트 입력 다이얼로그 생략 -> 확인 다이얼로그만 표시

### 3.2 시간 선택 UI (학생용)

**설계 원칙: "생각없이 예약" - 최소 인지 부하, 원클릭 선택**

```
┌─────────────────────────────────────┐
│  <- 레슨 예약                        │
├─────────────────────────────────────┤
│  선생님명 - 악기                     │
│  수강권: 5/8회                       │
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │       <  2026년 2월  >  [오늘]  ││  <- WeekCalendarWidget
│  │  월  화  수  목  금  토  일      ││
│  │  17  18  19  20  21  22  23      ││
│  │      *       *       *          ││  <- * = 가용 슬롯 있음
│  └─────────────────────────────────┘│
├─────────────────────────────────────┤
│  예약 가능한 시간                    │
│  [15:00]  [* 16:00]                 │  <- * = 평소 시간 추천
│  [17:00]  [18:00]                   │
│                                     │
│  선택 결과 미리보기                  │
│  16:00 (60분) / 선생님 / 수강권 5/8  │
│  [예약하기]                          │
└─────────────────────────────────────┘
```

**캘린더 날짜 표시 규칙:**

| 날짜 상태 | 시각적 표현 | 선택 가능 |
|----------|------------|:--------:|
| 오늘 | 밝은 배경 강조 | O |
| 가용 슬롯 있음 | 밝은 텍스트 + 초록 점 (#4CAF50) | O |
| 가용 슬롯 없음 | 흐린 텍스트 (35% 투명도) | X |
| 선택된 날짜 | 흰색 배경 + 보라색 텍스트 | - |
| 과거 날짜 | 매우 흐린 텍스트 (30% 투명도) | X |

**칩 버튼 스타일:**

| 상태 | 배경색 | 테두리 | 텍스트 |
|------|--------|--------|--------|
| 기본 | #FFFAF5 | #E0E0E0 | #333333 |
| 호버 | #FFF5EB | #F4A460 | #333333 |
| 선택됨 | #6B5B95 | #6B5B95 | #FFFFFF |
| 추천 | #FFF5EB | #F4A460 | #333333 |

**칩 크기:** 최소 72 x 44 pt (터치 영역), 패딩 16/12pt, 간격 8pt

**시간대 그룹화:**
- 가용 시간 1~4개: 그룹 없이 평면 나열
- 가용 시간 5개 이상: 오전/오후 구분

**스마트 추천 조건:**
- 최근 3개월 내 동일 요일에 2회 이상 같은 시간 레슨 이력이 있을 때 해당 시간에 별 표시
- 추천 칩: 테두리 Secondary (#F4A460), 배경 #FFF5EB

**빈 상태 처리:**
- 선택한 날짜에 가용 시간이 없을 때 가장 가까운 2~3개 가용일 + 시간 미리보기 표시
- 각 대안 날짜에 [선택하기] 버튼

**인터랙션:**

| 제스처 | 동작 |
|--------|------|
| 탭 | 시간 선택/해제 |
| 더블탭 | 선택 후 즉시 예약 확정 |
| 스와이프 좌/우 | 이전/다음 날짜 |

### 3.3 예약 변경 및 취소

#### 3.3.1 학생 변경/취소 정책

| 주체 | 액션 | 처리 | 수강권 영향 |
|------|------|------|-----------|
| 학생 | 레슨 변경 | `usedRescheduleCount` += 1 | 없음 (참여 전) |
| 학생 | 레슨 취소 | `usedRescheduleCount` += 1 | 없음 (참여 전) |
| 선생님 | 레슨 취소 | 학생 페널티 없음 | 없음 |
| 선생님 | 수강권 변경 | 재작성 (usedLessons 유지) | 사용분 유지 |

**변경 횟수 상태별 UI:**

| 남은 횟수 | UI 표시 | 변경 버튼 |
|----------|--------|---------|
| >= 2회 | "변경: N/M회" | 활성 |
| = 1회 | "변경 1회 남음" (경고) | 활성 + 확인 다이얼로그 |
| = 0회 | "변경 불가" | 비활성 (회색) + "선생님께 직접 문의" 안내 |

**마지막 변경 기회 확인 다이얼로그 (1회 남았을 때):**
- "마지막 변경 기회입니다"
- "이후 더 이상 변경/취소가 불가합니다"
- [취소] [변경하기]

#### 3.3.2 선생님 레슨 취소

- 학생 변경 횟수 차감 안 함
- 슬롯 자동 반환 (다른 학생 예약 가능)
- 학생에게 알림 전송
- 취소 사유 입력 필수

#### 3.3.3 수강권 재작성 (선생님)

기존 스튜디오메이트의 "삭제+재발급" 대신 **재작성** 방식 채택:

| 구분 | 재작성 (lesson-app) | 삭제+재발급 (기존) |
|------|---------------------|-------------------|
| 학생 경험 | 연속성 유지 | "내 수강권 삭제됨" 불안 |
| 이력 추적 | 같은 ID로 이력 관리 | ID 변경, 연결 끊김 |
| 적합 환경 | 개인 선생님, 외부 결제 | 학원, 앱 내 결제 |

**재작성 규칙:**
- 사용분(`usedLessons`)은 유지
- 총 횟수/금액/유효기간 변경 가능
- 변경 이력(`SubscriptionHistory`)에 기록 (changeType, oldValue, newValue, reason)

### 3.4 정기 레슨 시간 변경 (Rescheduling)

정기 레슨의 시간을 변경하는 플로우. `RequestEvent` (chat history) 로 관리.

**변경 유형:**

| 유형 | `ScheduleChangeType` | 설명 |
|------|---------------------|------|
| 1회성 변경 | `singleLesson` | 이번 주만 시간 변경 |
| 일괄 변경 | `bulkChange` | 앞으로 모든 레슨 시간 변경 |

**변경 요청 상태** (Phase 2 이후 — `RequestEventType` 으로 통합, 2026-04-28):

| 상태 | `RequestEventType` | 설명 |
|------|---------------------|------|
| 대기 중 | `scheduleChangeProposed` | 요청 접수 |
| 승인됨 | `scheduleChangeAccepted` | 변경 확정 |
| 거절됨 | `scheduleChangeRejected` | 변경 불가 |
| 대안 제시 | `scheduleChangeCountered` | 선생님이 대안 시간 제시 |
| 취소됨 | `cancel` | 요청 취소 |

**변경 요청 속성** (`RequestEvent`):
- `scheduleChangeType`: 변경 유형 (singleLesson / bulkChange)
- `proposedDayOfWeek` / `proposedTime`: 제안된 새 스케줄 (bulkChange 시)
- `suggestedSlots`: 제안 시간 목록 (singleLesson / 대안 제시 시)
- `actorId` + `actorType`: 요청자
- `createdAt`: 요청 시각
- `subscriptionId` + `sessionNumber`: 어떤 수강권의 몇 번째 회차인지

### 3.5 동시성 처리

```
학생 A (14:00:00) ──┬──> 2/18 15:30 슬롯 예약 요청
학생 B (14:00:01) ──┘

[처리 방식: 낙관적 락]

1. 학생 A: 슬롯 상태 확인 -> 가용 -> 트랜잭션 -> 예약 성공
2. 학생 B: 슬롯 상태 확인 -> 이미 예약됨 -> 실패 + "이미 예약된 시간" 안내
```

---

## 4. 스케줄 확인 카드 (Schedule Confirmation Card)

### 4.1 카드 타입

수강권 발급 후 학생 대시보드 상단에 표시되어 레슨 스케줄 확정을 유도하는 카드.

| 시나리오 | 카드 타입 | 제안 시간 | 판단 기준 |
|----------|-----------|-----------|-----------|
| 첫 수강권 (체험 후) | `afterTrial` | 체험 레슨 시간 | 이전 수강권 없음, 다른 악기 수강권도 없음 |
| 재등록 | `reEnrollment` | 이전 스케줄 | 같은 membershipId에 이전 수강권 존재 |
| 추가 악기 | `additionalInstrument` | 없음 (직접 선택) | 다른 membershipId에 수강권 존재 |

### 4.2 자동 분기 로직

수강권 발급 시 **자동으로** 카드 타입이 결정된다:

```
1. 같은 membershipId로 이전 수강권이 있는가?
   -> YES: reEnrollment (이전 스케줄 제안)

2. 다른 membershipId로 수강권이 있는가?
   -> YES: additionalInstrument (시간 선택 유도)

3. 이전 수강권이 전혀 없는가?
   -> YES: afterTrial (체험 레슨 시간 제안)
```

**제안 시간의 출처:**
- membership의 `lessonDay`, `lessonTime`, `lessonDuration` 필드에서 가져옴
- 체험 레슨 예약 시 설정된 요일/시간이 membership에 기록됨
- `additionalInstrument`는 제안 시간 없이 직접 선택 화면으로 이동

### 4.3 카드 상태 및 UI

**상태 전이:**
```
pending -> confirmed (제안 시간 수락)
pending -> changedTime (다른 시간 선택)
pending -> dismissed (카드 닫기/만료)
```

**UI 표시:**
- 위치: 학생 대시보드 상단 (액션 필요 섹션)
- 제안 있을 때 버튼: [다른 시간] [이 시간으로 예약]
- 제안 없을 때 버튼: [시간 선택하기]

### 4.4 ScheduleConfirmationCard 엔티티

| 속성 | 타입 | 설명 |
|------|------|------|
| `studentId` | String | 학생 ID |
| `teacherId` / `teacherName` | String | 선생님 정보 |
| `subscriptionId` | String | 연관 수강권 ID |
| `suggestedDay` | int? | 제안 요일 (1=월, 7=일) |
| `suggestedTime` | String? | 제안 시간 (예: "15:00") |
| `lessonDuration` | int? | 레슨 시간 (분) |
| `cardType` | ScheduleCardType | afterTrial / reEnrollment / additionalInstrument |
| `status` | ScheduleCardStatus | pending / confirmed / changedTime / dismissed |
| `totalLessons` | int? | 수강권 총 횟수 (표시용) |
| `lessonRequestId` | String? | 재등록 시 연관 레슨 요청 ID |

---

## 5. 그룹 클래스 스케줄링

### 5.1 그룹 클래스 정의 (GroupClass)

| 속성 | 설명 |
|------|------|
| `type` | `regular` (정기 반복) / `dropIn` (1회성) |
| `maxCapacity` | 최대 정원 |
| `waitlistCapacity` | 대기자 최대 수 (null = 무제한) |
| `durationMinutes` | 수업 시간 |
| `bookingDeadlineMinutes` | 예약 마감 시간 (기본 60분 전) |
| `cancelDeadlineMinutes` | 취소 마감 시간 (기본 24시간 전) |
| `noShowPolicy` | `deduct` (차감) / `noDeduct` (면제) |
| `repeatDaysOfWeek` | 반복 요일 (정기 클래스, 1~7=월~일) |
| `repeatTimeOfDay` | 반복 시간 (정기 클래스, "HH:mm") |

### 5.2 그룹 클래스 세션 (GroupClassSchedule)

개별 수업 회차를 나타낸다.

**세션 상태 (`ScheduleStatus`):**

| 상태 | 설명 |
|------|------|
| `open` | 예약 가능 |
| `full` | 만석 (대기자 가능) |
| `closed` | 예약 마감 |
| `cancelled` | 수업 취소 |
| `inProgress` | 수업 진행 중 |
| `completed` | 수업 완료 |

**정원 관리 규칙:**
- `canBook`: status == open && currentBookings < maxCapacity
- `canWaitlist`: (status == open || full) && currentBookings >= maxCapacity && 대기자 공간 남음
- `isFull`: currentBookings >= maxCapacity
- 상태 텍스트: 잔여 2명 이하 -> "마감임박", 만석 -> "만석"

**용량 표시:** `currentBookings/maxCapacity명` (예: "4/6명")

### 5.3 그룹 클래스 예약 (GroupClassBooking)

개별 학생의 예약을 관리한다.

**예약 상태 (`GroupBookingStatus`):**

| 상태 | 설명 | 취소 가능 |
|------|------|:--------:|
| `confirmed` | 예약 확정 | O |
| `waitlist` | 대기 중 (위치 표시) | O |
| `attended` | 출석 완료 | X |
| `noShow` | 미참석 | X |
| `cancelled` | 취소됨 | X |
| `autoCancelled` | 자동 취소 (수업 시작 시 대기자) | X |

**대기자 -> 확정 승급:**
- 확정자가 취소하면 대기자 중 `waitlistPosition`이 가장 낮은 학생이 자동 승급
- 승급 시 `promotedAt` 기록 + 학생에게 알림

**출석 시 수강권 차감:**
- `subscriptionDeducted` 플래그로 중복 차감 방지
- `attendedAt`에 출석 시각 기록

### 5.4 그룹 클래스 출석 관리

`GroupClassAttendanceScreen`에서 선생님이 출석/미참석 처리:
- 예약 학생 목록 표시
- 개별 출석/미참석 체크
- 출석 시 수강권 자동 차감
- 미참석 시 `noShowPolicy`에 따라 처리

---

## 6. 보강 및 노쇼 정책

### 6.1 노쇼 정책 (NoShowPolicy)

선생님이 학생별/전체로 설정하는 무단 결석 처리 정책.

| 정책 | 차감 비율 | 보강 생성 | 설명 |
|------|:--------:|:--------:|------|
| `deductCredit` | 1.0 | X | 1회 차감 (기본값) |
| `halfCredit` | 0.5 | X | 0.5회 차감 |
| `noDeduction` | 0.0 | X | 차감 없음 |
| `reschedule` | 0.0 | O | 보강으로 전환 |

**노쇼 기록 (NoShowRecord):**
- `appliedPolicy`: 적용된 정책
- `deductedCredits`: 실제 차감 회차 (0, 0.5, 1)
- `makeupLessonId`: 보강 연결 ID (reschedule 정책 시)
- `processedBy`: 처리자 (자동 또는 선생님 ID)

### 6.2 보강 추적 (MakeupLesson)

**보강 상태 (`MakeupStatus`):**

| 상태 | 설명 |
|------|------|
| `pending` | 시간 미정 (보강 발생) |
| `scheduled` | 시간 확정 |
| `completed` | 보강 완료 |
| `expired` | 30일 만료 |
| `waived` | 선생님이 면제 처리 |

**보강 발생 사유 (`MakeupReason`):**
- `studentCancellation`: 학생 취소 (D-1 이전)
- `teacherCancellation`: 선생님 취소
- `noShowReschedule`: 노쇼 (reschedule 정책)

**핵심 규칙:**
- 보강은 생성 후 **30일 이내** 예약해야 함 (`expiresAt`)
- 7일 이내 만료 시 `isExpiringSoon` = true -> 알림
- `originalLessonId`: 원래 레슨 연결
- `scheduledLessonId`: 보강으로 예약된 레슨 연결

---

## 7. 레슨 요청 시스템 (LessonRequest)

이전 학생이 레슨을 재개하고 싶을 때 선생님에게 보내는 요청.

### 7.1 요청 플로우

```
1. 학생이 요청 생성 (메시지 + 스케줄 선호 + 이전 스케줄 유지 여부)
   │
   ▼
2. 선생님에게 알림
   │
   ▼
3. 선생님이 수강권 제안 전송 (또는 거절)
   │
   ▼
4. 학생이 수락 + 결제
   │
   ▼
5. 선생님 확인 -> 수강권 발급 + 스케줄 복원
```

### 7.2 요청 상태 (LessonRequestStatus)

| 상태 | 설명 |
|------|------|
| `pending` | 요청 대기 (7일 만료) |
| `proposalSent` | 수강권 제안됨 |
| `accepted` | 수락 + 입금 확인 완료 |
| `declined` | 선생님 거절 (사유 포함) |
| `expired` | 7일 만료 |
| `cancelled` | 학생 취소 |

### 7.3 핵심 속성

| 속성 | 설명 |
|------|------|
| `preferredTiming` | 시작 선호 (다음 주 / 다음 달 / 상담 후) |
| `keepPreviousSchedule` | 이전 스케줄 유지 여부 |
| `previousLessonDay` / `previousLessonTime` / `previousLessonDuration` | 이전 스케줄 정보 |
| `proposalId` | 연결된 수강권 제안 ID |
| `expiresAt` | 만료일 (생성 후 7일) |

---

## 8. 선생님 스케줄 관리 UI

> v3 (2026-03-12): World-class UX 리파인 — Invisible Design 원칙 적용
> v2 (2026-03-12): 주간 스케줄 뷰 추가 — 일별 타임라인 + 주간 요약 그리드 + 가용 시간 표시

### 8.0 설계 철학: Invisible Design

> "최고의 디자인은 사용자가 디자인의 존재를 느끼지 못하는 것이다."
> 선생님이 앱을 열면 **오늘 해야 할 일이 즉시 보이고, 한 번의 탭 없이도 현재 상황을 파악**할 수 있어야 한다.

**핵심 원칙:**

| 원칙 | 적용 | 예시 |
|------|------|------|
| **시간 인식 (Time-Aware)** | 현재 시각 기준으로 모든 것이 자동 배치 | 앱 열면 "지금" 위치로 자동 스크롤 |
| **점진적 노출 (Progressive Disclosure)** | 가장 중요한 정보만 먼저, 나머지는 탭 시 | 블록에 이름만, 탭하면 상세 |
| **맥락 전환 최소화** | 뷰 전환 시 선택 상태 유지 | 타임라인→주간 전환해도 같은 날짜 하이라이트 |
| **예측 가능한 애니메이션** | 의미 있는 전환만, 장식적 애니메이션 없음 | 뷰 전환은 crossfade 200ms, 날짜 이동은 slide |
| **인지 부하 제로** | 선생님이 "생각"할 필요가 없어야 함 | 다음 레슨까지 남은 시간 자동 표시 |

### 8.1 뷰 모드 (3가지)

ScheduleTab에서 토글로 전환하는 3가지 뷰 모드:

| 뷰 | 아이콘 | 용도 | 기존 여부 |
|----|--------|------|:--------:|
| **리스트 뷰** | ≡ | 선택 날짜의 레슨 목록 (현재 기본) | ✅ 기존 |
| **타임라인 뷰** | ▤ | 선택 날짜의 시간축 블록 뷰 | 🆕 추가 |
| **주간 요약 뷰** | ⊞ | 월~일 전체 축약 그리드 | 🆕 추가 |

**뷰 전환 UI:**

```
┌─────────────────────────────────────────┐
│  스케줄                    [≡] [▤] [⊞]  │ ← 3-segment 토글 (AppBar)
├─────────────────────────────────────────┤
│  월  화  수  목  금  토  일              │ ← 공통: 상단 요일 스트립
│       ●   ●       ●   ●                │
│      [3] [4]     [2] [5]               │ ← 레슨 수 뱃지
└─────────────────────────────────────────┘
```

- 토글 선택은 Hive에 저장 (앱 재시작 시 유지)
- 상단 요일 스트립은 3가지 뷰 모두 공통 사용
- **뷰 전환 애니메이션**: `AnimatedSwitcher` + `FadeTransition` 200ms (slide 아님 — 같은 데이터를 다른 형태로 볼 뿐이므로)
- **상태 보존**: 뷰 전환 시 선택된 날짜, 스크롤 위치(시간대) 유지. 타임라인에서 14:00을 보고 있었다면 주간 뷰도 14:00 근처 표시

---

### 8.2 타임라인 뷰 (일별) 🆕

선택한 날짜의 레슨을 **시간축 블록**으로 표시하는 뷰.

> **UX 근거**: Google Calendar, Acuity Scheduling, 스튜디오메이트 등 업계 표준.
> 모바일에서 일별 타임라인이 가장 가독성 높음 (7열 그리드는 열당 45px로 비실용적).

#### 와이어프레임

```
┌─────────────────────────────────────────┐
│  스케줄                    [≡] [▤] [⊞]  │
├─────────────────────────────────────────┤
│  월  화  [수]  목  금  토  일            │ ← 수요일 선택됨
│       ●   ●       ●   ●                │
├─────────────────────────────────────────┤
│                                         │
│  09:00 ┃                                │
│        ┃ ██ 김민수 · 바이올린 · 30분     │ ← 악기 색상 블록
│  09:30 ┃                                │
│        ┃ ░░ 가용 시간                    │ ← 연한 대시 테두리
│  10:00 ┃                                │
│        ┃ ██ 박서연 · 피아노 · 60분       │ ← 60분 = 2배 높이
│        ┃ ██                             │
│  ────────── 지금 (10:45) ──────────────  │ ← 🔴 현재 시각 인디케이터
│  11:00 ┃                                │
│        ┃ ██ 이지훈 · 첼로 · 45분         │ ← "15분 후" 배지
│  11:45 ┃                                │
│        ┃ ░░ 가용 시간                    │
│  12:00 ┃                                │
│        ┃                                │
│  ─ ─ ─ 점심 (비가용) ─ ─ ─              │ ← 비가용 시간 축약
│                                         │
│  14:00 ┃                                │
│        ┃ ██ 최유나 · 플루트 · 30분       │
│  14:30 ┃                                │
│        ┃ ░░ 가용 시간                    │
│  15:00 ┃                                │
│                                         │
├─────────────────────────────────────────┤
│  다음: 이지훈 · 첼로 · 15분 후          │ ← 상황 인식 요약 바
│  📊 오늘 4레슨 · 2시간 45분 · 가용 1.5h │
└─────────────────────────────────────────┘
```

#### 시간 인식 (Time-Aware) 기능

앱을 열었을 때 선생님이 **한 번도 스크롤하지 않고** 현재 상황을 파악할 수 있어야 한다.

| 기능 | 동작 | 구현 |
|------|------|------|
| **자동 스크롤** | 오늘 날짜 진입 시 "지금" 위치로 자동 스크롤 (상단 여백 80px) | `scrollController.jumpTo(nowOffset - 80)` |
| **현재 시각 인디케이터** | 빨간 수평선 + 왼쪽 원형 노드 (Google Calendar 스타일) | 1분마다 위치 업데이트, 오늘만 표시 |
| **다음 레슨 배지** | 다음 레슨 블록에 "15분 후" 배지 표시 | 60분 이내일 때만, 1분마다 갱신 |
| **진행 중 블록** | 현재 진행 중인 레슨 블록 좌측에 2px 애니메이팅 보더 | `AnimatedContainer` pulse (opacity 0.6↔1.0, 2s) |
| **완료된 레슨** | 오늘 지나간 레슨 블록은 opacity 0.5 + 체크 아이콘 오버레이 | 출석 처리된 경우 ✓, 미처리는 ! |
| **미래 날짜** | "지금" 인디케이터 없음, 첫 레슨 위치로 스크롤 | 레슨 없으면 가용 시간 시작 |

**"지금" 인디케이터 디자인:**
```
                  ┃
  ── 🔴 ──────────┃──────────────────────
                  ┃
```
- 빨간 원 (지름 8px, #E53935) + 수평선 (1px, #E53935, opacity 0.7)
- 시간축 좌측에 현재 시각 텍스트 표시 (예: "10:45")
- 과거/미래 날짜에서는 표시하지 않음

#### 시간 블록 높이 (비례)

| 레슨 시간 | 높이 | 비율 |
|:--------:|:----:|:----:|
| 30분 | 60px | 1x (기본 단위) |
| 45분 | 90px | 1.5x |
| 60분 | 120px | 2x |

#### 블록 상태 및 색상

| 상태 | 배경 | 테두리 | 텍스트 |
|------|------|--------|--------|
| **레슨 예약** | 악기별 색상 (아래 표) | 좌측 4px solid 진한 색상 (accent bar) | 학생 이름 · 악기 · 시간 |
| **진행 중 레슨** | 악기별 색상 | 좌측 4px + pulse 애니메이션 | 학생 이름 · 악기 · "진행 중" |
| **완료된 레슨 (오늘)** | 악기별 색상, opacity 0.5 | 좌측 4px solid | 학생 이름 · ✓ |
| **가용 시간** | #FAFAFA | 1px dashed #E0E0E0 | "가용" (연한 회색, 12sp) |
| **비가용 시간** | 렌더링 안 함 | — | 축약 표시 ("점심", "비가용") |
| **쉬는 시간** | 투명 | 얇은 구분선 (0.5px #E0E0E0) | 없음 (공간만 8px) |

> **블록 테두리 변경 (v3)**: 전체 2px 테두리 → 좌측 4px accent bar로 변경.
> 이유: Google Calendar, Notion Calendar, Calendly 등 모든 상위 제품이 좌측 accent bar 패턴 사용.
> 전체 테두리는 "버튼처럼" 보여 인지 부하 증가. accent bar는 색상 구분은 유지하면서 시각적 노이즈 최소화.

#### 레슨 블록 내부 레이아웃

블록 높이에 따라 정보 밀도를 자동 조절 (Progressive Disclosure):

```
[30분 블록 — 1줄]
┌──────────────────────────────────┐
│ ▎ 김민수 · 바이올린              │  ← 이름 + 악기만
└──────────────────────────────────┘

[45분 블록 — 2줄]
┌──────────────────────────────────┐
│ ▎ 김민수                         │  ← 이름
│ ▎ 바이올린 · 45분                │  ← 악기 + 시간
└──────────────────────────────────┘

[60분 블록 — 3줄]
┌──────────────────────────────────┐
│ ▎ 김민수                         │  ← 이름
│ ▎ 바이올린 · 60분                │  ← 악기 + 시간
│ ▎ 소나타 3악장 복습               │  ← 마지막 피드백/과제 (있으면)
└──────────────────────────────────┘
```

- 30분: 이름 + 악기 (한 줄, 13sp)
- 45분: 이름 / 악기 + 시간 (두 줄, 13sp / 12sp)
- 60분: 이름 / 악기 + 시간 / 최근 과제 미리보기 (세 줄) — **선생님이 바로 이전 수업 맥락 파악 가능**
- 텍스트 overflow: `ellipsis`, 절대 줄바꿈하여 블록 높이 변경 안 함

#### 악기별 색상 코딩

| 악기 | 배경색 | Accent Bar / 텍스트 |
|------|--------|-------------|
| 바이올린 | #EDE7F6 (연보라) | #6B5B95 |
| 피아노 | #E3F2FD (연파랑) | #1976D2 |
| 첼로 | #FFF3E0 (연주황) | #F57C00 |
| 플루트 | #E8F5E9 (연초록) | #388E3C |
| 기타 | #FCE4EC (연분홍) | #C2185B |
| 성악 | #FFF8E1 (연노랑) | #FFA000 |
| 클라리넷 | #E0F7FA (연청록) | #00838F |
| 드럼/타악기 | #EFEBE9 (연갈색) | #5D4037 |
| 기타 악기 | #F3E5F5 (연자주) | #7B1FA2 |

> 색상은 악기 첫 등록 시 자동 배정. 선생님이 변경 불가 (일관성 유지).
> 10개 이상 악기 시 팔레트 순환.

#### 인터랙션

| 제스처 | 동작 | 피드백 |
|--------|------|--------|
| 블록 탭 | 레슨 상세 화면으로 이동 | `HapticFeedback.lightImpact()` + 블록 scale 0.98 → 1.0 (100ms) |
| 블록 롱프레스 | 바텀시트: 완료 처리 / 일정 변경 / 취소 | `HapticFeedback.mediumImpact()` + 블록 살짝 들림 (elevation 2→6, 200ms) |
| 가용 시간 탭 | 예약 추가 화면 (해당 시간대 프리필) | 탭 영역 ripple |
| 상하 스크롤 | 타임라인 스크롤 | 시간축 라벨 sticky (좌측 고정) |
| 좌우 스와이프 | 이전/다음 날짜 이동 (요일 스트립 연동) | `PageView` physics, 요일 스트립 애니메이션 동기화 |
| "지금" 인디케이터 탭 | 없음 (장식 요소) | — |

#### 비가용 시간 축약 (Gap Collapse)

연속 비가용 시간이 1시간 이상이면 축약하여 스크롤 영역 절약:

```
│  12:00 ┃                                │
│        ┃                                │
│  ╌╌╌╌╌ 비가용 2시간 ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  │ ← 접힌 영역 (높이 32px)
│                                         │
│  14:00 ┃                                │
```

- 비가용 1시간 미만: 그냥 빈 공간으로 표시 (축약 안 함)
- 비가용 1시간 이상: 32px 축약 바 + "비가용 N시간" 텍스트
- 축약 바 탭: 확장/축소 토글 (탭하면 실제 시간 비례로 펼침)

#### 하단 상황 인식 요약 바

```
┌─────────────────────────────────────────┐
│  다음: 이지훈 · 첼로 · 15분 후          │ ← 상황 라인 (동적)
│  📊 오늘 4레슨 · 2시간 45분 · 가용 1.5h │ ← 통계 라인 (고정)
└─────────────────────────────────────────┘
```

**상황 라인 규칙 (시간에 따라 자동 변경):**

| 시간 맥락 | 표시 내용 | 예시 |
|----------|----------|------|
| 첫 레슨 전 | "첫 레슨: {이름} · {악기} · {시간}" | "첫 레슨: 김민수 · 바이올린 · 09:00" |
| 레슨 진행 중 | "진행 중: {이름} · {악기} · {남은}분" | "진행 중: 박서연 · 피아노 · 20분 남음" |
| 레슨 사이 | "다음: {이름} · {악기} · {N}분 후" | "다음: 이지훈 · 첼로 · 15분 후" |
| 마지막 레슨 후 | "오늘 레슨 완료 🎵" | "오늘 레슨 완료 🎵" |
| 레슨 없는 날 | "오늘은 레슨이 없습니다" | — |
| 미래/과거 날짜 | 상황 라인 숨김 (통계만 표시) | — |

- 상황 라인은 **오늘일 때만** 표시, 30초마다 자동 갱신
- 고정 위치 (스크롤 시에도 하단 표시)
- 통계 라인: 레슨 수, 총 레슨 시간, 남은 가용 시간

---

### 8.3 주간 요약 뷰 (7일 그리드) 🆕

월~일 전체 레슨을 **축약 그리드**로 표시하는 뷰. 선생님이 주간 패턴을 한눈에 파악하는 "새의 눈(Bird's Eye)" 뷰.

> **UX 근거**: Google Calendar 3-day 뷰 + 스튜디오메이트 주간 뷰 참조.
> 모바일 한계로 학생 이름은 2글자 축약, 탭하면 일별 타임라인으로 드릴다운.

#### 와이어프레임

```
┌──────────────────────────────────────────────┐
│  스케줄                       [≡] [▤] [⊞]    │
├──────────────────────────────────────────────┤
│  < 3/10 ~ 3/16 >               [오늘]        │
│                                              │
│        월    화    수    목    금    토    일  │
│             [3]   [4]         [2]            │ ← 일별 레슨 수 (밀도 뱃지)
│  09   ■민수       ■민수             ■유나    │
│  10   ■서연  ■서연 ■지훈  ■민수              │
│  11   ■지훈       ■유나  ■서연  ■지훈        │
│  12                                          │
│  ╌╌╌  점심  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌    │
│  14         ■유나              ■민수          │
│  15   ■서연 ■지훈                      ■서연 │
│  16                ■서연                     │
│                                              │
│  ░ = 가용 시간 (빈 셀 중 가용)                │
│  ■ = 레슨 (악기별 색상, 이름 2글자)           │
│                                              │
│  ── 🔴 ── 지금 (수 10:45) ────────────────── │ ← 오늘 열에만 표시
│                                              │
├──────────────────────────────────────────────┤
│  📊 이번 주: 14레슨 · 총 11시간 · 가용 8시간  │
└──────────────────────────────────────────────┘
```

#### 그리드 디자인 규칙

| 요소 | 상세 |
|------|------|
| **셀 크기** | 가로 `(screenWidth - 40) / 7` ≈ 45~50px, 세로 30분당 ~28px |
| **레슨 셀** | 악기별 색상 배경 + 학생 이름 2글자 (예: "민수"), 좌측 2px accent bar |
| **가용 시간 셀** | 연한 점선 배경 (#FAFAFA, border: 0.5px dashed #E8E8E8) |
| **빈 셀** | 비가용 = 완전 빈칸 (렌더링 안 함) |
| **시간 축** | 좌측 시간 라벨 (9, 10, 11, ...) — 30분 간격 생략 |
| **요일 헤더** | 상단 고정, 오늘 열 전체 연한 하이라이트 (#6B5B95, 4% opacity) |
| **비가용 구간** | 접힘 처리 (예: "점심" 라벨만 표시) |
| **"지금" 인디케이터** | 오늘 열에만 빨간 수평선 (타임라인 뷰와 동일 스타일, 단 전체 너비가 아닌 해당 열만) |
| **일별 밀도 뱃지** | 요일 헤더 아래 레슨 수 표시 (0이면 숨김) |

#### 오늘 열 하이라이트

주간 뷰에서 **오늘이 어디인지 0.1초 만에 파악**할 수 있어야 한다:

- 오늘 요일 헤더: Bold + 보라 원 배경 (#6B5B95)
- 오늘 열 전체: `#6B5B95` 4% opacity 배경 (매우 연한 보라 세로 띠)
- "지금" 인디케이터: 오늘 열에만 빨간 수평선

> 내일/어제 등 다른 날에는 아무 하이라이트 없음. 오늘만 강조.

#### 셀 상세 표시 (60분 레슨)

60분 레슨은 2행을 차지하며 셀 병합:

```
│  10   ■서연  │  ← 60분 레슨: 2행 병합, 이름은 상단 행에
│  10:30 ■    │
│  11   ■지훈  │  ← 30분 레슨: 1행
```

45분 레슨은 1.5행 차지 (반올림하여 2행 표시, 하단 셀은 절반 높이).

#### 인터랙션

| 제스처 | 동작 | 피드백 |
|--------|------|--------|
| 셀 탭 (레슨) | 레슨 상세 화면 | `HapticFeedback.lightImpact()` |
| 셀 탭 (가용) | 해당 시간 예약 추가 | ripple |
| 요일 헤더 탭 | 해당 일 **타임라인 뷰**로 전환 (drill-down) | slide left 전환 |
| 좌우 스와이프 | 이전/다음 주 이동 | `PageView` + week header 애니메이션 |
| 핀치 줌 | 시간 축 확대/축소 (30분 ↔ 1시간 간격) | 부드러운 스케일 |

> **Drill-down 패턴**: 주간 그리드는 "Overview → Detail" 네비게이션의 시작점.
> 요일 헤더 탭 → 타임라인 뷰로 전환되며, 뒤로가기(스와이프 백)로 주간 뷰 복귀.
> 레슨 셀 탭 → 레슨 상세로 직접 이동 (중간 단계 없음).

#### 빈 주 처리

레슨이 하나도 없는 주의 경우:

```
┌──────────────────────────────────────────────┐
│  < 3/17 ~ 3/23 >               [오늘]        │
├──────────────────────────────────────────────┤
│                                              │
│        이번 주는 레슨이 없습니다               │
│        [가용 시간 설정하기]                    │
│                                              │
└──────────────────────────────────────────────┘
```

#### 하단 요약 바

```
📊 이번 주: N레슨 · 총 N시간 · 가용 N시간
```

- 주간 뷰에서는 상황 라인(다음 레슨) 없음 — 통계만 표시
- 타임라인 뷰의 상황 라인과 구분하여 인지 부하 감소

---

### 8.4 가용 시간 블록 그리드 (기존 — 설정용)

선생님이 자신의 가용 시간을 시각적으로 관리하는 인터페이스 (WeeklyScheduleScreen에서 사용).

```
┌─────────────────────────────────────┐
│  2/18(화) 가용 시간 관리             │
├─────────────────────────────────────┤
│       :00      :30                  │
│   9  │ [가용] │ [가용] │             │
│  10  │ [가용] │ [휴무] │             │
│  14  │ [예약] │ [가용] │             │
│  15  │ [가용] │ [가용] │             │
│                                     │
│  범례: 가용(녹) 예약됨(청) 휴무(회)  │
│  [저장]                              │
└─────────────────────────────────────┘
```

**블록 색상:**

| 상태 | 배경색 |
|------|--------|
| 예약 가능 | #E8F5E9 |
| 예약됨 | #E3F2FD |
| 휴무/불가 | #F5F5F5 |

**인터랙션:**

| 제스처 | 동작 |
|--------|------|
| 탭 | 가용 <-> 불가 토글 |
| 드래그 | 연속 블록 선택 |
| 길게 누르기 | 반복 패턴 설정 메뉴 |

---

### 8.5 크로스-뷰 일관성 (Cross-View Coherence)

3가지 뷰가 **같은 데이터를 다른 밀도로 보여주는 것**임을 사용자가 자연스럽게 인식하도록:

| 규칙 | 설명 |
|------|------|
| **색상 동일** | 리스트/타임라인/주간 모두 같은 악기별 색상 사용 |
| **날짜 연동** | 뷰 전환 시 선택 날짜 유지. 타임라인에서 수요일 보다가 주간으로 전환하면 수요일 열 하이라이트 |
| **시간 위치 동기화** | 타임라인에서 14:00 부근 스크롤 → 주간 전환 시 14:00 행 근처 표시 |
| **요약 바 공통** | 하단 통계 형식 동일 ("N레슨 · N시간 · 가용 N시간"), 뷰별 범위만 다름 (일/주) |
| **"오늘" 버튼** | AppBar 또는 요일 스트립에 [오늘] 버튼 — 어떤 뷰에서든 오늘로 즉시 복귀 |

**뷰 전환 매트릭스:**

| From → To | 전환 애니메이션 | 상태 보존 |
|-----------|---------------|----------|
| 리스트 → 타임라인 | crossfade 200ms | 선택 날짜 유지 |
| 리스트 → 주간 | crossfade 200ms | 선택 날짜 포함 주 표시 |
| 타임라인 → 주간 | crossfade 200ms | 선택 날짜 + 스크롤 시간 |
| 주간 → 타임라인 (요일 탭) | slide left 300ms | 탭한 요일로 이동 |
| 주간 → 타임라인 (토글) | crossfade 200ms | 이전 선택 날짜 유지 |

### 8.6 데이터 흐름

```
[타임라인 뷰 / 주간 요약 뷰]
    │
    ├── lessonsProvider (선택 날짜 / 주간 레슨 목록)
    │     └── Lesson { date, time, duration, studentId, instrument }
    │
    ├── teacherAvailabilityProvider (가용 시간)
    │     └── TeacherAvailability { weeklySchedule, exceptions }
    │
    └── studentProvider (학생 이름 매핑)
          └── Student { id, name }
```

**주간 요약 뷰 데이터 로딩:**
- 선택 주의 월~일 전체 레슨을 한 번에 로드 (기존 일별 → 주별 확장)
- `weekLessonsProvider(weekStartDate)` 추가 필요

---

### 8.7 구현 파일 계획

| 파일 | 역할 |
|------|------|
| `schedule_tab.dart` | 기존 파일 수정 — 뷰 모드 토글 + 뷰 분기 |
| `widgets/schedule_timeline_view.dart` | 🆕 타임라인 뷰 위젯 |
| `widgets/schedule_weekly_grid_view.dart` | 🆕 주간 요약 그리드 위젯 |
| `widgets/timeline_lesson_block.dart` | 🆕 타임라인 레슨 블록 위젯 |
| `widgets/timeline_availability_block.dart` | 🆕 가용 시간 블록 위젯 |
| `providers/week_lessons_provider.dart` | 🆕 주간 레슨 데이터 Provider |
| `providers/schedule_view_mode_provider.dart` | 🆕 뷰 모드 상태 (Hive 저장) |
| `utils/instrument_colors.dart` | 🆕 악기별 색상 매핑 유틸 |

---

## 9. 데이터 모델 요약

### 9.1 Hive TypeId 할당표

| TypeId | 엔티티 |
|:------:|--------|
| 70 | AvailabilityType (enum) |
| 71 | SlotStatus (enum) |
| 72 | TeacherAvailability |
| 73 | WeeklySchedule |
| 74 | ExceptionType (enum) |
| 75 | TimeException |
| 76 | AvailabilitySlot (비영속 - 실제 미사용) |
| 80 | GroupClassType (enum) |
| 81 | GroupClass |
| 82 | ScheduleStatus (enum) |
| 83 | GroupClassSchedule |
| 84 | GroupBookingStatus (enum) |
| 85 | GroupClassBooking / MakeupStatus (enum, 충돌 주의) |
| 86 | NoShowPolicy (enum, GroupClass용) / MakeupReason (enum, 충돌 주의) |
| 87 | MakeupLesson |
| 88 | NoShowPolicy (enum, 독립 정책) |
| 89 | NoShowRecord |
| 90 | ~~ScheduleChangeType (enum)~~ → 132로 이전 (Phase 2, 2026-04-28) |
| 91 | ~~ScheduleChangeStatus (enum)~~ → 제거 (dead, 2026-04-28) |
| 92 | ~~LessonScheduleChange~~ → 제거 (dead, 2026-04-28) |
| 98 | PreferredStartTiming (enum) |
| 99 | LessonRequestStatus (enum) |
| 100 | ScheduleCardType (enum) / LessonRequest (충돌 주의) |
| 101 | ScheduleCardStatus (enum) |
| 102 | ScheduleConfirmationCard |

> **주의:** TypeId 85, 86, 100에 충돌이 존재한다. 백엔드 전환 시 정리 필요.

### 9.2 레거시 엔티티 (Deprecated)

| 엔티티 | 상태 | 대체 |
|--------|------|------|
| `ScheduleOption` | @Deprecated | `AvailabilitySlot` 사용 |
| `TrialLessonRequest` | 레거시 | 슬롯 기반 예약으로 대체 |
| `RegularLessonRegistration` | 레거시 | 슬롯 기반 예약으로 대체 |
| `RegularLessonRequest` | 레거시 | 슬롯 기반 예약으로 대체 |

---

## 10. Enum 정의

이 섹션은 스케줄 도메인에서 사용하는 모든 enum을 정식 Dart 코드 블록으로 정의한다.

### 10.1 AvailabilitySlotStatus (5개 값)

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

### 10.2 SlotStatus (3개 값)

```dart
@HiveType(typeId: 71)
enum SlotStatus {
  available,   // 예약 가능
  booked,      // 예약됨
  cancelled,   // 취소됨 (휴무 등)
}
```

> 코드 위치: `features/schedule/domain/entities/teacher_availability.dart`

### 10.3 AvailabilityType (2개 값)

```dart
@HiveType(typeId: 70)
enum AvailabilityType {
  regular,   // 주간 반복
  oneTime,   // 1회성
}
```

> 코드 위치: `features/schedule/domain/entities/teacher_availability.dart`

### 10.4 ExceptionType (3개 값)

```dart
@HiveType(typeId: 74)
enum ExceptionType {
  holiday,          // 특정 날짜 1일 휴무
  vacation,         // 기간 휴무 (startDate ~ endDate)
  additionalSlot,   // 1회성 추가 슬롯
}
```

> 코드 위치: `features/schedule/domain/entities/teacher_availability.dart`

### 10.5 BookingStatus (7개 값)

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

### 10.6 ScheduleStatus (6개 값 - 그룹 클래스)

```dart
@HiveType(typeId: 82)
enum ScheduleStatus {
  open,         // 예약 가능
  full,         // 만석 (대기자 가능)
  closed,       // 예약 마감
  cancelled,    // 수업 취소
  inProgress,   // 수업 진행 중
  completed,    // 수업 완료
}
```

> 코드 위치: `features/schedule/domain/entities/group_class_schedule.dart`

### 10.7 GroupBookingStatus (6개 값)

```dart
@HiveType(typeId: 84)
enum GroupBookingStatus {
  confirmed,       // 예약 확정
  waitlist,        // 대기 중
  attended,        // 출석 완료
  noShow,          // 미참석
  cancelled,       // 취소됨
  autoCancelled,   // 자동 취소 (수업 시작 시 대기자)
}
```

> 코드 위치: `features/schedule/domain/entities/group_class_booking.dart`

### 10.8 GroupClassType (2개 값)

```dart
@HiveType(typeId: 80)
enum GroupClassType {
  regular,   // 정기 반복 클래스
  dropIn,    // 1회성 클래스
}
```

> 코드 위치: `features/schedule/domain/entities/group_class.dart`

### 10.9 ScheduleChangeType (2개 값)

```dart
@HiveType(typeId: 132)
enum ScheduleChangeType {
  singleLesson,   // 1회성 변경 (이번 주만)
  bulkChange,      // 일괄 변경 (앞으로 모든 레슨)
}
```

> 코드 위치: `features/schedule/domain/entities/request_event.dart` (Phase 2, 2026-04-28)
>
> - `ScheduleChangeStatus` (구 typeId 91) — 협상 상태가 `RequestEventType` 으로 통합되어 제거됨
> - `LessonScheduleChange` 엔티티 (구 typeId 92) — `RequestEvent` 가 chat history 로 대체하여 제거됨
> - `dayOfWeekLabel(int)` 헬퍼 — `core/utils/date_format_utils.dart` 로 이동

### 10.10 NoShowPolicy (4개 값)

```dart
@HiveType(typeId: 88)
enum NoShowPolicy {
  deductCredit,   // 1회 차감 (기본값)
  halfCredit,     // 0.5회 차감
  noDeduction,    // 차감 없음
  reschedule,     // 보강으로 전환
}
```

> 코드 위치: `features/schedule/domain/entities/no_show_policy.dart`
> 주의: `group_class.dart`에도 별도 `NoShowPolicy` enum 존재 (TypeId: 86, `deduct`/`noDeduct` 2개 값). 백엔드 전환 시 통합 필요.

### 10.11 MakeupStatus (5개 값) / MakeupReason (4개 값)

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

### 10.12 LessonRequestStatus (6개 값)

```dart
@HiveType(typeId: 99)
enum LessonRequestStatus {
  pending,         // 요청 대기 (7일 만료)
  proposalSent,    // 수강권 제안됨
  accepted,        // 수락 + 입금 확인 완료
  declined,        // 선생님 거절 (사유 포함)
  expired,         // 7일 만료
  cancelled,       // 학생 취소
}
```

> 코드 위치: `features/schedule/domain/entities/lesson_request.dart`

### 10.13 ScheduleCardType (3개 값) / ScheduleCardStatus (4개 값)

```dart
@HiveType(typeId: 100)
enum ScheduleCardType {
  afterTrial,              // 체험 후 등록
  reEnrollment,            // 재등록
  additionalInstrument,    // 추가 악기
}

@HiveType(typeId: 101)
enum ScheduleCardStatus {
  pending,       // 확인 대기
  confirmed,     // 확정됨
  changedTime,   // 시간 변경됨
  dismissed,     // 닫힘
}
```

> 코드 위치: `features/schedule/domain/entities/schedule_confirmation_card.dart`

---

## 11. 구현 파일 매핑

### 11.1 엔티티 -> 코드 매핑

| 스펙 항목 | 코드 파일 |
|----------|----------|
| TeacherAvailability | `features/schedule/domain/entities/teacher_availability.dart` |
| WeeklySchedule | `features/schedule/domain/entities/teacher_availability.dart` |
| TimeException | `features/schedule/domain/entities/teacher_availability.dart` |
| AvailabilitySlot (UI 모델) | `features/schedule/domain/entities/availability_slot.dart` |
| LessonBooking | `features/schedule/domain/entities/lesson_booking.dart` |
| GroupClass | `features/schedule/domain/entities/group_class.dart` |
| GroupClassSchedule | `features/schedule/domain/entities/group_class_schedule.dart` |
| GroupClassBooking | `features/schedule/domain/entities/group_class_booking.dart` |
| MakeupLesson | `features/schedule/domain/entities/makeup_lesson.dart` |
| NoShowPolicy / NoShowRecord | `features/schedule/domain/entities/no_show_policy.dart` |
| ~~LessonScheduleChange~~ | ~~`features/schedule/domain/entities/lesson_schedule_change.dart`~~ → 제거 (Phase 2, 2026-04-28). `RequestEvent` 가 대체. |
| LessonRequest | `features/schedule/domain/entities/lesson_request.dart` |
| ScheduleConfirmationCard | `features/schedule/domain/entities/schedule_confirmation_card.dart` |
| TimeSlot | `features/schedule/domain/entities/time_slot.dart` |

### 11.2 Repository -> 코드 매핑

| 스펙 항목 | 인터페이스 | Mock 구현 |
|----------|----------|----------|
| 가용시간 | `domain/repositories/teacher_availability_repository.dart` | `data/repositories/mock_teacher_availability_repository.dart` |
| 그룹클래스 | `domain/repositories/group_class_booking_repository.dart` | `data/repositories/mock_group_class_booking_repository.dart` |
| 레슨요청 | `domain/repositories/lesson_request_repository.dart` | `data/repositories/mock_lesson_request_repository.dart` |
| 확인카드 | `domain/repositories/schedule_confirmation_card_repository.dart` | `data/repositories/mock_schedule_confirmation_card_repository.dart` |

### 11.3 화면 -> 코드 매핑

| 스펙 항목 | 코드 파일 |
|----------|----------|
| 레슨 예약 | `presentation/screens/lesson_booking_screen.dart` |
| 예약 확인 | `presentation/screens/booking_confirmation_screen.dart` |
| 예약 취소 | `presentation/screens/booking_cancel_screen.dart` |
| 예약 변경 | `presentation/screens/booking_reschedule_screen.dart` |
| 내 예약 목록 | `presentation/screens/my_bookings_screen.dart` |
| 대기 예약 (선생님) | `presentation/screens/pending_bookings_screen.dart` |
| 선생님 가용시간 설정 | `presentation/screens/teacher_availability_screen.dart` |
| 주간 스케줄 | `presentation/screens/weekly_schedule_screen.dart` |
| 시간 예외 관리 | `presentation/screens/time_exception_screen.dart` |
| 정기 레슨 등록 | `presentation/screens/register_regular_lesson_screen.dart` |
| 그룹 클래스 상세 | `presentation/screens/group_class_detail_screen.dart` |
| 그룹 출석 관리 | `presentation/screens/group_class_attendance_screen.dart` |
| 레슨 요청 (학생) | `presentation/screens/lesson_request_screen.dart` |
| 레슨 요청 목록 (선생님) | `presentation/screens/lesson_requests_screen.dart` |
| 내 레슨 요청 (학생) | `presentation/screens/my_lesson_requests_screen.dart` |
| 스케줄 탭 | `presentation/screens/schedule_tab.dart` |

> 모든 경로는 `frontend/lib/features/schedule/` 기준 상대 경로

---

## 12. 경쟁사 대비 차별점

### 12.1 스케줄 시스템 차별화

| 기능 | Lessonaza | 스튜디오메이트/Studiomate | 일반 예약 시스템 |
|------|:---------:|:------------------------:|:---------------:|
| 슬롯 기반 선착순 예약 | O | X (관리자 배정) | 부분적 |
| 선생님 주간 스케줄 + 예외 관리 | O | 제한적 | X |
| 스마트 추천 (이전 레슨 시간 기반) | O | X | X |
| 1:1 = 정원 1명 클래스 (통합 로직) | O | X (별도 구현) | X |
| 스케줄 확인 카드 (3 시나리오 자동 분기) | O | X | X |
| 정기 레슨 일괄 시간 변경 + 대안 제시 | O | 수동 | X |
| 보강 30일 자동 만료 추적 | O | 수동 | X |
| 학생별 노쇼 정책 커스터마이징 | O | 일괄 정책 | X |
| 대기자 자동 승급 (그룹 클래스) | O | 수동 | 부분적 |

### 12.2 핵심 경쟁력

1. **제로 핑퐁 예약**: 기존 3단계 왕복(제안-선택-승인)을 2단계(등록-예약)로 단축, 알림 1회만 발생
2. **통합 슬롯 로직**: 1:1과 그룹 레슨이 동일한 예약 엔진 사용하여 일관성 보장
3. **멀티옵션 스케줄링**: 선생님이 복수 가용시간 등록, 학생이 칩 UI로 원클릭 선택
4. **자동 시나리오 분기**: 수강권 발급 시 체험후/재등록/추가악기를 자동 판별하여 최적 스케줄 카드 표시

---

## 13. 구현 현황

### 13.1 선생님 가용 시간 시스템

| 기능 | 상태 | 파일 |
|------|:----:|------|
| TeacherAvailability 엔티티 | 완료 | `domain/entities/teacher_availability.dart` |
| WeeklySchedule / TimeException 엔티티 | 완료 | `domain/entities/teacher_availability.dart` |
| AvailabilitySlot (UI 모델) | 완료 | `domain/entities/availability_slot.dart` |
| Repository 인터페이스 | 완료 | `domain/repositories/teacher_availability_repository.dart` |
| Mock Repository | 완료 | `data/repositories/mock_teacher_availability_repository.dart` |
| Remote Repository | 완료 | `data/repositories/remote_teacher_availability_repository.dart` |
| Riverpod Providers | 완료 | `presentation/providers/teacher_availability_providers.dart` |
| TeacherAvailabilityScreen | 완료 | `presentation/screens/teacher_availability_screen.dart` |
| WeeklyScheduleScreen | 완료 | `presentation/screens/weekly_schedule_screen.dart` |
| TimeExceptionScreen | 완료 | `presentation/screens/time_exception_screen.dart` |
| AvailabilityBlockGrid (선생님 블록 그리드) | 완료 | `presentation/widgets/availability/availability_block_grid.dart` |
| AvailabilityBlock / AvailabilityLegend | 완료 | `presentation/widgets/availability/` |

### 13.2 학생 예약 플로우

| 기능 | 상태 | 파일 |
|------|:----:|------|
| LessonBookingScreen | 완료 | `presentation/screens/lesson_booking_screen.dart` |
| BookingConfirmationScreen | 완료 | `presentation/screens/booking_confirmation_screen.dart` |
| AvailabilityChipSelector (칩 선택기) | 완료 | `presentation/widgets/availability/availability_chip_selector.dart` |
| AvailabilityDateNavigator | 완료 | `presentation/widgets/availability/availability_date_navigator.dart` |
| AvailabilityBookingPreview | 완료 | `presentation/widgets/availability/availability_booking_preview.dart` |
| EmptySlotsSuggestion (빈 슬롯 대안) | 완료 | `presentation/widgets/availability/empty_slots_suggestion.dart` |
| GuestStudentInputDialog | 완료 | `presentation/widgets/availability/guest_student_input_dialog.dart` |
| BookingConfirmDialog | 완료 | `presentation/widgets/availability/booking_confirm_dialog.dart` |
| NoSubscriptionView | 완료 | `presentation/widgets/availability/no_subscription_view.dart` |
| 예약 가능 시간만 표시 (blocked 미노출) | 완료 | - |
| 회원 자동 인식 (게스트 다이얼로그 생략) | 완료 | - |

### 13.3 예약 변경/취소

| 기능 | 상태 | 파일 |
|------|:----:|------|
| BookingRescheduleScreen | 완료 | `presentation/screens/booking_reschedule_screen.dart` |
| BookingCancelScreen | 완료 | `presentation/screens/booking_cancel_screen.dart` |
| MyBookingsScreen | 완료 | `presentation/screens/my_bookings_screen.dart` |
| BookingNotificationService | 완료 | `presentation/services/booking_notification_service.dart` |
| SlotRecommendationService | 완료 | `domain/services/slot_recommendation_service.dart` |

### 13.4 스케줄 확인 카드

| 기능 | 상태 | 파일 |
|------|:----:|------|
| ScheduleConfirmationCard 엔티티 | 완료 | `domain/entities/schedule_confirmation_card.dart` |
| ScheduleConfirmationCardWidget | 완료 | `presentation/widgets/schedule_confirmation_card_widget.dart` |
| Provider | 완료 | `presentation/providers/schedule_confirmation_card_providers.dart` |
| Repository (Mock/Remote) | 완료 | `data/repositories/mock_schedule_confirmation_card_repository.dart` |
| 카드 타입 분기 로직 | 완료 | `subscription/.../issue_subscription_screen.dart` (`_detectScheduleCardType`) |
| 대시보드 표시 | **비활성** | 설계 재검토 필요 시 재활성화 |

### 13.5 그룹 클래스

| 기능 | 상태 | 파일 |
|------|:----:|------|
| GroupClass / GroupClassSchedule / GroupClassBooking 엔티티 | 완료 | `domain/entities/group_class*.dart` |
| GroupClassBookingRepository | 완료 | `domain/repositories/group_class_booking_repository.dart` |
| Mock / Remote Repository | 완료 | `data/repositories/` |
| GroupClassDetailScreen | 완료 | `presentation/screens/group_class_detail_screen.dart` |
| GroupClassAttendanceScreen | 완료 | `presentation/screens/group_class_attendance_screen.dart` |
| GroupClassBookingProviders | 완료 | `presentation/providers/group_class_booking_providers.dart` |

### 13.6 정기 레슨 변경 / 보강 / 노쇼

| 기능 | 상태 | 파일 |
|------|:----:|------|
| ~~LessonScheduleChange 엔티티~~ | 제거 (Phase 2, 2026-04-28) | `RequestEvent` 가 chat history 로 대체. `ScheduleChangeType` 만 `request_event.dart` 로 이전 |
| MakeupLesson 엔티티 | 완료 | `domain/entities/makeup_lesson.dart` |
| NoShowPolicy / NoShowRecord 엔티티 | 완료 | `domain/entities/no_show_policy.dart` |

### 13.7 레슨 요청 (재등록)

| 기능 | 상태 | 파일 |
|------|:----:|------|
| LessonRequest 엔티티 | 완료 | `domain/entities/lesson_request.dart` |
| LessonRequestRepository | 완료 | `domain/repositories/lesson_request_repository.dart` |
| Mock / Remote Repository | 완료 | `data/repositories/` |
| LessonRequestScreen | 완료 | `presentation/screens/lesson_request_screen.dart` |
| LessonRequestsScreen (선생님) | 완료 | `presentation/screens/lesson_requests_screen.dart` |
| MyLessonRequestsScreen (학생) | 완료 | `presentation/screens/my_lesson_requests_screen.dart` |
| LessonRequestProviders | 완료 | `presentation/providers/lesson_request_providers.dart` |

### 13.8 통합 레슨 요청 + 스케줄 변경 (2026-03 추가)

| 기능 | 상태 | 파일 |
|------|:----:|------|
| AllLessonRequestsScreen | 완료 | `presentation/screens/all_lesson_requests_screen.dart` — 전체 요청 조회 (달력/페이즈탭/필터) |
| RequestDetailScreen | 완료 | `presentation/screens/request_detail_screen.dart` — 요청 상세 (프로그레스바+챗 패턴) |
| RequestCompletionScreen | 완료 | `presentation/screens/request_completion_screen.dart` — 신청 완료 5단계 가이드 |
| UnifiedLessonRequestScreen | 완료 | `presentation/screens/unified_lesson_request_screen.dart` — 통합 레슨 신청 |
| SuggestAlternativeScreen | 완료 | `presentation/screens/suggest_alternative_screen.dart` — 역제안 슬롯 선택 |
| ScheduleChangeSlotScreen | 완료 | `presentation/screens/schedule_change_slot_screen.dart` — 스케줄 변경 슬롯 선택 (주간 그리드) |
| ScheduleTab | 완료 | `presentation/screens/schedule_tab.dart` — 스케줄 탭 |

### 13.9 미완료 / 향후 개선

| 항목 | 우선순위 | 상태 |
|------|:--------:|:----:|
| **타임라인 뷰 (일별 블록 뷰)** | **높음** | **스펙 완료, 구현 대기** |
| **주간 요약 그리드 (7일 축약 뷰)** | **높음** | **스펙 완료, 구현 대기** |
| **뷰 모드 토글 (리스트/타임라인/주간)** | **높음** | **스펙 완료, 구현 대기** |
| **악기별 색상 코딩 유틸** | **높음** | **스펙 완료, 구현 대기** |
| **weekLessonsProvider (주간 레슨 로드)** | **높음** | **스펙 완료, 구현 대기** |
| 추천 슬롯 로직 개선 (3개월 이력 기반) | 중간 | 미구현 |
| 드래그 선택 (블록 그리드) | 낮음 | 미구현 |
| 레거시 화면 제거 (ScheduleOption 등) | 낮음 | 미구현 |
| 스케줄 확인 카드 대시보드 재활성화 | 중간 | 비활성 (설계 재검토 필요) |
| Hive TypeId 충돌 정리 (85, 86, 100) | 높음 | 미구현 |

---

## 14. 관련 스펙

| 문서 | 설명 |
|------|------|
| [lesson_master.md](../lesson/lesson_master.md) | 레슨 시스템 마스터 (레슨 플로우, 예약, 취소/변경) |
| [subscription_system_spec.md](../subscription/subscription_system_spec.md) | 수강권 시스템 |
| [subscription_master.md](../subscription/subscription_master.md) | 수강권 제안 (결제 전 플로우) |
| [group_lesson_spec.md](../lesson/group_lesson_spec.md) | 그룹레슨 시스템 |
| [attendance_spec.md](../_archive/old/attendance_spec.md) | 출석 관리 시스템 |
| [gamification_spec.md](../_archive/old/gamification_spec.md) | 게이미피케이션 (연습/학생 참여) |
| [ux_guidelines.md](../design/ux_guidelines.md) | UX 가이드라인 (섹션 11~12) |
| [subscription.md](../../schema/entities/subscription.md) | 수강권 엔티티 스키마 |

---

## 15. 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-03-12 | v3: Invisible Design 원칙 추가 — 시간 인식 자동 스크롤, "지금" 인디케이터, 상황 인식 요약 바, Progressive Disclosure 블록 레이아웃, accent bar 패턴, 크로스-뷰 일관성, Gap Collapse, drill-down 패턴 |
| 2026-03-12 | v2: 주간 스케줄 뷰 추가 — 일별 타임라인 + 주간 요약 그리드 + 가용 시간 표시 + 악기별 색상 코딩 |
| 2026-03-07 | Enum 정의 완전성 보강 (모든 enum Dart 코드 블록 추가), 구현 파일 매핑 추가, 경쟁사 차별점 추가, lesson_master 상호 참조, attendance/gamification 스펙 참조 추가 |
| 2026-03-06 | Master Spec 작성 (teacher_availability_spec.md + schedule_confirmation_card_spec.md 통합) |
| 2026-03-02 | 스케줄 확인 카드 타입 분기 로직 구현, 대시보드 표시 비활성화 |
| 2026-02-01 | 예약 가능 시간만 표시 + 회원 자동 인식 구현 |
| 2026-01-27 | 주간 캘린더 통합, 칩 선택 UI 개선, 예약 변경/취소 플로우 구현 |
| 2026-01-26 | 선생님 가용 스케줄 시스템 설계서 초안 작성 |
