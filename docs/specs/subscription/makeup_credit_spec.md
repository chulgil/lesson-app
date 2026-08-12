# 보강 크레딧 스펙 (Makeup Credit / Make-up Bank)

> 작성일: 2026-06-01
> 상태: 스펙 초안
> 출처: E2E 감사 Top 10 #7 H-002 — `docs/specs/review/2026-06-01-teacher-e2e/30-gap-catalog.md`
> 관련 이슈: #427
> 관련 스펙: [subscription_master.md §2](subscription_master.md), [subscription_schedule_change_spec.md](../schedule/subscription_schedule_change_spec.md), [teacher_vacation_mode.md](../schedule/teacher_vacation_mode.md)
> 글로서리: [glossary.md §4](../../../.harness/knowledge/glossary.md) — "보강 크레딧", "스케줄된 회차"

---

## 1. 문제 정의

E2E 감사: 정규권 일괄 변경(요일·시간 변경) 후 5주차·보강·이월 회차 자동 재계산 로직 부재. `bulkChange` 후 학생 측 회차 표시와 실제 차감이 어긋남.

### 1.1 현재 결함

| # | 문제 | 영향 |
|---|---|---|
| 1 | `Subscription.remainingLessons` 만으로는 "실제 잡힌 레슨 수"와 "남은 권리"를 구분 못함 | 학생-선생님 회차 표시 불일치 |
| 2 | 일괄 변경 시 기존 `scheduledLessons` 취소 → 새 시간 재생성 로직 없음 | "5주차인데 4회만 차감됨" 분쟁 |
| 3 | 보강 회차가 정규 수강권에 섞여 카운팅 | 보강 1회 사용 시 정규 1회 차감 (회계 혼란) |
| 4 | 노쇼 면제·휴가 손실분 추적 불가 | 운영자가 수동 보전 |

### 1.2 영향 범위 (펀넬)

H (일정 조절·갱신) 단계의 가장 큰 분쟁 원인. "이번 달 5주차인데 수강권은 4회만 차감됨" → 한 달 단위 다툼 → 갱신 거부 → 매출 손실.

---

## 2. 설계 원칙

> **"보강 회차는 정규 수강권에서 분리한다. Teachworks 'Make-up bank' 패턴."**

| 원칙 | 의미 |
|---|---|
| 별도 엔티티 | `MakeupCredit` 를 정규 `Subscription` 과 독립 관리 |
| 사용 우선순위 | 학생이 차시 예약 시 정규 수강권 차감 vs 크레딧 사용을 명시적 선택 |
| 자동 적립 | 휴가·노쇼 면제·일괄변경 손실분에서 시스템이 자동 적립 |
| 만료 30일 | 무기한 적립 방지. 정규 수강권 만료 정책과 동일 |
| 회차 분리 | `remainingLessons` (남은 권리) vs `scheduledLessons` (실제 잡힌 수) 분리 트랙 |

---

## 3. 데이터 모델

### 3.1 MakeupCredit 신규 엔티티

```dart
@HiveType(typeId: 78)
class MakeupCredit {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String teacherId;

  @HiveField(3)
  final String? sourceSubscriptionId;  // 적립 사유 수강권 (있으면)

  @HiveField(4)
  final MakeupCreditReason reason;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime expiresAt;            // 기본: createdAt + 30일

  @HiveField(7)
  final DateTime? usedAt;              // 사용 시각

  @HiveField(8)
  final String? usedLessonId;          // 사용된 레슨 ID

  @HiveField(9)
  final String? sourceEventId;         // 휴가 ID / 노쇼 ID / 일괄변경 ID
}

enum MakeupCreditReason {
  teacherVacation,        // 선생님 휴가 (teacher_vacation_mode.md 의존)
  noShowExempt,           // 학생 노쇼 면제 (선생님 재량)
  bulkChangeLoss,         // 정규 일괄변경 중 손실 회차
  manualGrant,            // 선생님 수동 지급 (예외 처리)
}
```

**파생 게터 (코드 반영 2026-06-04):** `isUsed` (`usedAt != null`), `isExpired(now)` (`expiresAt < now && !isUsed`), `isAvailable(now)` (`!isUsed && !isExpired(now)`), `daysUntilExpiry(now)` — UI 만료 임박 표시용.

### 3.1.1 MakeupCreditBalance — UI 집계 값 객체 (2026-06-04 본문 통합)

학생/선생님 화면(§9 카드)이 의존하는 잔액 집계 값 객체.

```dart
class MakeupCreditBalance {
  final List<MakeupCredit> available;    // 사용 가능한 크레딧 (정렬: expiresAt asc)
  final int availableCount;              // available.length
  final bool hasAny;                     // availableCount > 0
  final DateTime? earliestExpiry;        // available.firstOrNull?.expiresAt

  factory MakeupCreditBalance.fromCredits(
    List<MakeupCredit> credits,
    DateTime now,
  );
}
```

| 필드 | 정책 |
|------|------|
| `fromCredits()` 팩토리 | 입력 list 를 `isAvailable(now)` 필터 + `expiresAt` 오름차순 정렬 후 집계 |
| `earliestExpiry` | UI 가 "곧 만료" 강조용 — D-3/D-1 임박 시 색상 분기 |
| Provider 노출 | `studentMakeupCreditsProvider`, `teacherMakeupCreditsProvider` 가 `MakeupCreditBalance` 반환 |

### 3.2 Subscription 모델 확장

기존 `Subscription` 에 다음 필드 추가:

| 필드 | 타입 | 기본 | 설명 |
|---|---|---|---|
| `scheduledLessons` | `int` | 0 | 실제 잡힌 레슨 수 (`LessonBooking.status in [scheduled, completed]` 카운트) |
| `bonusCount` | `int` | 0 | 5주차 보너스 등 추가 회차 (기존 필드, 명시화) |

기존:
- `remainingLessons` = `totalLessons` + `bonusCount` - `usedLessons`

신규 트랙:
- `scheduledLessons` = `LessonBooking` 중 활성 상태 카운트 (재계산 가능)

> **배선 현황 (2026-08-04 실측, 2026-08-12 재확인, 2026-08-12 §7.3 통합 후 갱신)**:
> §7.3 의 이중 일괄변경 시스템을 하나의 손실 정책으로 통합하면서
> `recalculate_scheduled_lessons` 훅 포인트가 **두 호출부 모두에서 실제로 호출**된다
> — `subscription_service.bulk_change()`(교사 직접 실행)와
> `lesson_request_service._apply_bulk_schedule_change()`(제안-승인 확정, 실사용
> 경로) 양쪽 다 이동/취소 처리 후 해당 subscription 의 `scheduledLessons` 를
> 재계산한다. 다만 API 응답/FE/가드의 라이브 **소비처는 여전히 0**건 — 값은 정확히
> 계산되지만 아직 아무도 읽지 않는다. §3.3 불변식 강제도 미구현. 소비처(§9 카드 등)가
> 생기기 전까지는 증분(+=1) 방식 배선 금지(재계산 SSOT 와 어긋나는 드리프트 발생) —
> 이미 배선된 두 호출부의 recalc 를 그대로 재사용할 것.

### 3.3 일관성 불변식

```
remainingLessons >= 0
scheduledLessons <= remainingLessons + usedLessons
```

위배 시 백엔드 거부 (트랜잭션 롤백).

---

## 4. 적립 트리거

### 4.1 (a) 선생님 휴가 모드

`teacher_vacation_mode.md` 의 처리 옵션 (a) "보강 크레딧 자동 등록" 선택 시.

| 항목 | 값 |
|---|---|
| `reason` | `teacherVacation` |
| `sourceEventId` | `VacationPeriod.id` |
| `expiresAt` | `VacationPeriod.endDate + 30일` |
| 1건 생성 단위 | 영향 받는 `LessonBooking` 1건당 1 크레딧 |

### 4.2 (b) 학생 노쇼 면제

선생님이 노쇼 레슨에 대해 "예외 면제" 선택 시.

| 항목 | 값 |
|---|---|
| `reason` | `noShowExempt` |
| `sourceEventId` | `Lesson.id` |
| `expiresAt` | `createdAt + 30일` |

기존 `LessonStatus.studentAbsent` → 면제 시 `LessonStatus.cancelledMutual` 로 변경 + 크레딧 1건 적립.

> **배선 완료 (2026-08-12)**: 레슨 노쇼 처리 흐름에 "면제(보강 크레딧 지급)" 옵션이
> 추가되어 FE 가 `accrue_for_no_show_exempt` 를 호출하는 API 경로가 연결됐다. 기본값은
> OFF다 — 선생님이 명시적으로 면제를 선택해야 크레딧이 적립되며, 노쇼 처리 자체가
> 자동으로 크레딧을 지급하지 않는다(선생님 재량 원칙 유지).

### 4.3 (c) 정규 일괄변경 손실분

`subscription_schedule_change_spec.md` 의 일괄변경 시:

```
[일괄변경 재계산 로직]

1. 기존 scheduledLessons 의 미래 LessonBooking 식별
2. 새 요일/시간으로 재배치 시도
3. 재배치 가능 → LessonBooking 갱신, 크레딧 적립 없음
4. 재배치 불가 (휴무·휴가·중복 등) → 손실 회차 1건당 크레딧 1건 적립
5. remainingLessons 조정:
   - 손실 회차: usedLessons 감산 (회차 복원) + 크레딧 적립
   - 신규 회차: usedLessons 예약 차감
```

| 항목 | 값 |
|---|---|
| `reason` | `bulkChangeLoss` |
| `sourceEventId` | `SubscriptionScheduleChange.id` |

### 4.4 (d) 수동 지급

선생님이 학생 상세 → 보강 크레딧 → "수동 지급" 으로 직접 발급. 모든 케이스가 자동으로 처리되지 않을 때 안전망.

> **수강권 귀속 선택 추가 (2026-08-12)**: 발급 화면에 학생의 활성 수강권 수에 따른
> 귀속 선택이 추가됐다 — 1개면 `sourceSubscriptionId` 를 자동 첨부, 2개 이상이면
> 선택 UI 를 노출, 0개이거나 선생님이 선택하지 않으면 `null` 로 유지된다. §3.1 의
> `sourceSubscriptionId` nullable 원칙(회계상 크레딧은 특정 수강권에 종속되지 않는다는
> 설계)은 그대로 유지된다 — 이 변경은 "귀속 근거를 남길 수 있는 선택지"를 추가한
> 것이지, 크레딧을 수강권에 강제 귀속시키는 것이 아니다.

---

## 5. 사용 정책

### 5.1 학생 측 예약 시 선택

차시 예약 화면에서 학생이 "이번 예약은 보강 크레딧 사용" 토글 가능.

```
┌─────────────────────────────────────┐
│  레슨 예약                           │
│                                     │
│  바이올린 · 8/15(목) 16:00          │
│                                     │
│  ◉ 정규 수강권 사용                  │
│     남은 회차: 5/8회                 │
│                                     │
│  ○ 보강 크레딧 사용                  │
│     보유 크레딧: 2회                 │
│     (만료: 9/2)                     │
│                                     │
│  [예약하기]                          │
└─────────────────────────────────────┘
```

### 5.2 기본 우선순위

| 상황 | 기본 선택 |
|---|---|
| 정규 잔여 > 0 + 크레딧 > 0 | 정규 (사용자 변경 가능) |
| 정규 잔여 = 0 + 크레딧 > 0 | 크레딧 (자동) |
| 둘 다 = 0 | 예약 불가, 갱신 안내 |

### 5.3 사용 시 처리

크레딧 사용 시:
- `MakeupCredit.usedAt`, `usedLessonId` 기록
- `Subscription.usedLessons` 미차감
- `Subscription.scheduledLessons` 반영 — **booking 경유 경로만** 해당하며, 증분이
  아니라 신규 booking 행이 §3.2 재계산에 잡히는 방식이다 (배선 현황은 §3.2 참조).
  선생님 수동 레슨(POST /lessons, §5.4)은 booking 행이 없으므로 정의상 카운터 밖 —
  J1 관찰 "scheduled_lessons 미증가"는 드리프트가 아니라 정합 (회귀 테스트
  `test_manual_credit_lesson_leaves_scheduled_lessons_untouched` 로 고정).
- `LessonBooking.creditUsed = true` 플래그

### 5.4 선생님측 레슨 추가 시 소비 (2026-08-03)

선생님이 레슨 추가(AddLessonScreen)에서 보강 크레딧 보유 학생을 선택하면
수강권 배너에 크레딧 잔량을 노출하고 **"보강으로 처리" 토글**을 표시한다 (기본 OFF).

- 토글 ON 저장 시: §5.3 과 동일 처리 (크레딧 차감, 정규 회차 미차감).
- 레슨 귀속 우선순위 (2026-08-03 구현 정합 정정 — code critic 대조): **선생님이 명시
  선택한 수강권 > 크레딧의 `sourceSubscriptionId` > 최신 활성 수강권**. 선생님의 명시
  선택이 크레딧 출처보다 우선한다 (선택 UI 가 이미 열린 의도를 존중). 어느 쪽이든
  크레딧 차감·정규 회차 미차감 회계는 동일.
- 잔여 0 상태(S3)에서는 처리 방식 시트의 "보강 레슨" 항목이 이 토글을 대신한다.
- 상태 분기 전체: [subscription_required_spec.md §2.6](subscription_required_spec.md) (S3/S4)

---

## 6. 만료 정책

### 6.1 기본 만료

`createdAt + 30일`. 정규 수강권 만료 정책과 동일.

### 6.2 만료 처리

매일 00:00 cron:
- `expiresAt < now AND usedAt IS NULL` → 상태 `expired`
- 학생 측 알림 발송: D-3, D-1 만료 임박 ("보강 크레딧 N회 곧 만료")

### 6.3 만료 후 복구 불가

만료된 크레딧은 복구하지 않는다. 단, 운영 이슈 시 선생님 수동 지급으로 우회 가능 (§4.4).

---

## 7. 일괄변경 재계산 로직 (핵심)

`subscription_schedule_change_spec.md` 의 `bulkChange` 흐름 수정:

```
[기존]
bulkChange(subscriptionId, newDayOfWeek, newTime)
  → 단순 요일/시간 변경 (실제 잡힌 레슨 재계산 없음)

[신규]
bulkChange(subscriptionId, newDayOfWeek, newTime)
  → 1. 미래 scheduledLessons 식별 (status in [scheduled])
  → 2. 각 레슨에 대해 새 요일/시간으로 후보 슬롯 계산
  → 3. 후보 슬롯 가용성 확인 (TeacherAvailability, 휴가, 중복)
  → 4. 가용 → LessonBooking 갱신
       불가 → cancelledByTeacher + MakeupCredit(reason=bulkChangeLoss) 적립
  → 5. Subscription 재계산:
       - scheduledLessons = 갱신된 LessonBooking 수
       - usedLessons 변경 없음 (이미 차감된 과거 레슨 유지)
  → 6. 학생/학부모 알림: "N건 변경 / M건 보강 크레딧 적립"
```

### 7.1 5주차 보너스 처리

| 상황 | 처리 |
|---|---|
| 일괄변경 결과 새 월에 5주차 발생 | `Subscription.bonusCount += 1` (FifthWeekPolicy=bonus 시) |
| 일괄변경 결과 5주차 제거 | `Subscription.bonusCount -= 1` (재계산 시 일관성 유지) |
| 정책이 skip | bonusCount 변경 없음 |

> **코드-스펙 정합 노트 (2026-08-12)**: 코드의 `MakeupCreditReason` enum 에는 §3.1
> 4종 외에 5번째 값 `fifthWeekBonus` 가 존재했으나, 그 적립 메서드
> (`accrue_fifth_week_bonus`)는 어디서도 호출되지 않는 죽은 코드였다 — 위 표의
> `bonusCount` 직접 조정이 5주차 보너스의 유일한 정식 처리 방식이다. 2026-08-12
> 이 죽은 호출 메서드를 제거했다. enum 값 자체는 과거 데이터 호환을 위해 유지하며,
> 신규 적립 경로로는 사용하지 않는다.

### 7.2 검증 케이스 (테스트 필수)

| 케이스 | 기대 |
|---|---|
| 일괄변경 후 학생-선생님 회차 표시 일치 | `subscription.scheduledLessons == LessonBooking 활성 카운트` |
| 일괄변경으로 손실 회차 N건 | `MakeupCredit 신규 N건 적립` |
| 5주차 정책 bonus + 일괄변경 | `bonusCount` 정확 반영 |
| 일괄변경 후 학생 측 크레딧 사용 가능 | 예약 화면에 크레딧 표시 |

### 7.3 배선 현황 (2026-08-12 통합 완료) — 이중 일괄변경 시스템

> 감사(`audit-makeup-credit.md` #3, `audit-product-intent.md` §2-3)에서 확인된 구조
> 이슈. 오너 결정에 따라 이번 라운드에서 통합했다.

`subscription_service.bulk_change()`(§7 상단 로직, 교사 직접 실행 — `POST
/subscriptions/:id/bulk-change`, 학생 승인 불필요)와 실제 사용자가 쓰는
`ScheduleChangeType.bulkChange` 제안-승인 흐름
(`lesson_request_service._apply_schedule_change_to_lessons` →
`_apply_bulk_schedule_change`)은 이제 **같은 손실 정책**을 공유한다: 개별 충돌은
전체 배치를 막지 않고 그 회차만 취소(`cancelled`) + `MakeupCredit(reason=
bulkChangeLoss)` 1건 적립, 나머지는 계속 이동한다. 처리 후 두 경로 모두
`MakeupCreditService.recalculate_scheduled_lessons` 를 호출한다(§3.2, D4).

두 경로는 여전히 **코드 레벨에서는 분리**되어 있다 — 의도적 결정이다:

- **대상 순회 축이 다르다.** `bulk_change()` 는 `LessonBooking` 을 순회하고
  `Lesson`(캘린더)은 있으면 미러(#1203). 제안-승인 경로는 `Lesson`(캘린더 SSOT)을
  순회하고 `LessonBooking` 은 있으면 미러(#1192) — booking 없이 존재하는 Lesson 도
  항상 이동해야 하므로 이 축을 유지했다(#1192 가 이미 이 이유로 채택한 설계, "target_lesson_id
  스키마 추가"를 거절하고 임박-레슨 추론을 택함). 두 축을 하나의 함수로 강제
  통합하면 booking 없는 Lesson 이 조용히 안 움직이는 회귀가 생긴다.
- **single 서브케이스는 정책을 바꾸지 않았다.** 승인 경로의 단건 변경은 여전히
  충돌 시 409 로 안전 거절한다(#1192 원안 유지) — 일회성 재협상은 보상 장치가
  필요 없다. 오직 **bulk** 서브케이스만 크레딧 보상 정책으로 전환했다.
- 실제로 공유되는 것은 손실 보상의 **정책과 메커니즘**(`MakeupCreditService.
  accrue_for_bulk_change_loss` + `recalculate_scheduled_lessons`)이지, 대상
  순회 루프 자체가 아니다. #1203 커밋은 이미 "충돌정책 상이·서비스 경계 상이로
  조기 공통헬퍼화는 결합만 증가"라고 기록했는데, 이번 통합도 그 전제(대상 선택은
  분리 유지, 손실 정책만 통일)를 지키면서 "충돌정책이 실사용 경로에서 크레딧을
  적립하지 않는다"는 실질적 갭만 해소했다.

`POST /subscriptions/{id}/bulk-change` 라우트는 **유지**한다 — 여전히 FE 호출 0건
이지만, 학생 승인 없이 교사가 즉시 강제로 이동시키는 별개의(협상 없는) 유스케이스를
위한 진입점으로 스펙·테스트가 이미 완비돼 있다(§8.2, `test_subscription_bulk_change.py`).
FE 연동 여부는 별도 기획 결정.

---

## 8. 백엔드 API

### 8.1 신규 엔드포인트

| Method | 경로 | 설명 |
|---|---|---|
| GET | `/api/students/me/makeup-credits` | 학생 측 보유 크레딧 목록 |
| GET | `/api/teachers/me/makeup-credits` | 선생님 측 발급한 크레딧 목록 |
| POST | `/api/teachers/me/makeup-credits` | 수동 지급 (§4.4) |
| DELETE | `/api/teachers/me/makeup-credits/:id` | 미사용 크레딧 회수 (오발급 정리, 이미 사용 시 409) (코드 반영 2026-06-03) |
| POST | `/api/bookings` (확장) | `useCredit: bool` 파라미터 |

### 8.2 일괄변경 엔드포인트 확장

기존 `POST /api/subscriptions/:id/bulk-change` 응답에 추가:

```json
{
  "rescheduledCount": 8,
  "lostCount": 2,
  "creditsAccrued": 2,
  "newExpiresAt": "2026-09-15"
}
```

---

## 9. UI 정의

### 9.1 학생 측 — 보강 크레딧 카드

학생 홈 또는 수강권 상세에 노출:

```
┌─────────────────────────────────────┐
│ 보강 크레딧                          │
│                                     │
│ 보유: 2회                            │
│ 가장 빠른 만료: 9/2(D-15)            │
│                                     │
│ ▼ 내역 (3건)                         │
│   8/3 적립 — 선생님 휴가              │
│   8/10 적립 — 노쇼 면제               │
│   8/20 사용 — 정규 레슨               │
└─────────────────────────────────────┘
```

### 9.2 선생님 측 — 학생별 크레딧 관리

학생 상세 → 보강 크레딧 탭 → 발급/회수/수동 지급.

---

## 10. 측정 기준

| 지표 | 측정 방법 | 목표 |
|---|---|---|
| 일괄변경 후 회차 일치 | `subscription.scheduledLessons == LessonBooking 활성 카운트` | 100% |
| 크레딧 사용률 | `usedAt != null / total` | 50-70% (만료 30-50%) |
| 일괄변경 후 분쟁 신고 | 운영 메트릭 | < 1% |
| 크레딧 적립-사용 격차 | `expiredCount / accrualCount` | < 30% (높으면 만료 정책 재검토) |

### 10.1 정량 검증

```bash
# 백엔드 엔티티 확인
grep -rn "MakeupCredit" backend/app/models/  # ≥ 1
# 프론트 엔티티 확인
grep -rn "MakeupCredit" frontend/lib/features/subscription/domain/entities/  # ≥ 1
# scheduledLessons 트랙 확인
grep -rn "scheduledLessons" backend/app/models/  # ≥ 1
```

---

## 11. 구현 범위 (Phase 별)

### Phase 1: 스펙 + 글로서리 (본 작업)

- 본 스펙 작성
- glossary "보강 크레딧", "스케줄된 회차" 추가 (이미 완료)
- `subscription_master.md §2` 의 `scheduledLessons` 필드 참조 추가 (메인 세션이 처리)

### Phase 2: 백엔드 (2주)

- `MakeupCredit` 엔티티 + repository + 마이그레이션
- `Subscription.scheduledLessons` 필드 추가
- 적립 트리거 4종 (휴가·노쇼 면제·일괄변경·수동)
- 일괄변경 재계산 로직 수정
- 신규 엔드포인트 3개 + bookings 확장
- 만료 cron

### Phase 3: 프론트엔드 (1-2주)

- 학생: 크레딧 카드, 예약 시 사용 토글
- 선생님: 학생별 크레딧 관리, 수동 지급
- 일괄변경 결과 UI ("N건 변경 / M건 크레딧 적립")

### Phase 4: 의존성 통합

- `teacher_vacation_mode.md` 의 처리 옵션 (a) 연동
- 알림: 적립·만료 임박·사용 완료

---

## 12. 의존성

| 의존 스펙 | 의존 항목 |
|---|---|
| [teacher_vacation_mode.md](../schedule/teacher_vacation_mode.md) | 적립 트리거 (a) — 휴가 처리 옵션의 보강 크레딧 자동 등록 |
| [subscription_master.md](subscription_master.md) §2 | `scheduledLessons`, `bonusCount` 필드 확장 |
| [subscription_schedule_change_spec.md](../schedule/subscription_schedule_change_spec.md) | `bulkChange` 재계산 로직 |

---

## 코드 반영 추가 (2026-06-03)

> 코드(`features/subscription`)에 구현되었으나 위 본문에 누락된 항목. 코드→스펙 단방향 반영.

### A. MakeupCreditBalance 집계 (UI 편의)

학생 보유 크레딧 잔액을 요약하는 값 객체. `features/subscription/domain/entities/makeup_credit.dart`.

| 멤버 | 설명 |
|---|---|
| `available: List<MakeupCredit>` | 사용 가능(미사용 + 미만료) 크레딧, 만료 임박 순 정렬 |
| `availableCount: int` | 보유 가능 회차 수 |
| `hasAny: bool` | 보유 여부 |
| `earliestExpiry: DateTime?` | 가장 빠른 만료 시각 (§9.1 카드 "가장 빠른 만료" 표기 근거) |
| `MakeupCreditBalance.fromCredits(credits, now)` | 만료/사용 필터 + 정렬 팩토리 |

MakeupCredit 자체 헬퍼: `isUsed`, `isExpired(now)`, `isAvailable(now)`, `daysUntilExpiry(now)` (§6 만료 정책 판정에 사용).

### B. revokeCredit 회수 메서드

`MakeupCreditRepository.revokeCredit(creditId)` — §9.2 "회수" UI 의 백엔드 계약. 이미 사용된 크레딧은 서버가 409 로 거부. (위 §8.1 DELETE 엔드포인트 참조)

`grantCredit` 시그니처: `studentId`, `sourceSubscriptionId?`, `reasonNote?` (수동 지급은 항상 `reason=manualGrant`).

### C. 라우트

| 라우트 | 화면 | 비고 |
|---|---|---|
| `/subscriptions/makeup-credits` | `MakeupCreditScreen` | `?studentId=` 있으면 선생님 뷰(학생별 발급/회수), 없으면 학생 본인 보유 뷰. `AppRoutes.makeupCredits` |

---

## 13. 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| 1.0 | 2026-06-01 | 초안 — E2E 감사 #7 H-002 대응. Teachworks Make-up bank 패턴 차용. MakeupCredit 별도 엔티티 + Subscription.scheduledLessons 트랙 분리 + 일괄변경 재계산 로직 정의 |
| 1.1 | 2026-08-12 | 수강권 정합성 감사 반영 — §4.2 노쇼 면제 배선 완료(기본 OFF), §4.4 수동 지급에 수강권 귀속 선택 추가, §7.1 fifthWeekBonus 죽은 메서드 제거 노트, §7.3 신설(일괄변경 이중 시스템 — 미해결, 별도 기획 결정 필요), §3.2 배선 현황 재확인 |
