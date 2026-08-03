# 수강권 필수화 스펙 (Plan B)

> 최종 업데이트: 2026-06-16

## 1. 개요

### 문제

현재 레슨은 수강권(Subscription) 없이도 생성할 수 있다. 이로 인해:
- 취소/보강 시 크레딧 추적 불가 ("그림자 레슨")
- 수익 분석에서 누락
- 취소 로직이 이중 분기 (subscriptionId 유무)

### 결정

**모든 레슨은 수강권에 연결한다.** 수강권이 없는 학생에게 레슨을 등록할 때, 시스템이 자동으로 "1회 체험 수강권"을 생성하여 연결한다.

### 설계 원칙

> **선생님은 "수강권"을 의식하지 않는다.** 레슨을 추가하면 시스템이 알아서 연결한다.
> **데이터 모델은 항상 `lesson.subscriptionId != null`이다.** 예외 없음.

### 유사 서비스 근거

| 서비스 | 방식 |
|--------|------|
| 피아노하우스/뮤직메이트 | 월 수강권 필수, 체험도 "1회 체험권"으로 관리 |
| ClassPass | 크레딧 기반, 모든 수업이 크레딧에 연결 |
| TakeLessons | 패키지(수강권) 기반, 단건도 "1-pack" |

## 2. 자동 수강권 생성 규칙

### 2.1 트리거 조건

선생님이 `POST /lessons` (레슨 생성) 호출 시:

```
if subscription_id가 요청에 있음:
    → 해당 수강권에 연결 (기존 동작)
elif 해당 학생에게 활성 수강권이 있음:
    → 가장 최근 활성 수강권에 자동 연결
else:
    → "1회 체험 수강권" 자동 생성 후 연결
```

### 2.2 자동 생성 수강권 스펙

| 필드 | 값 |
|------|-----|
| `type` | `"trial"` |
| `total_lessons` | `1` |
| `used_lessons` | `0` |
| `amount` | `0` |
| `status` | `"active"` |
| `start_date` | 레슨 날짜 |
| `end_date` | 레슨 날짜 + 30일 |
| `payment_confirmed` | `true` (무료) |
| `total_reschedule_allowance` | `0` |
| `billing_type` | `"free"` |

### 2.3 기존 수강권에 보너스 레슨 추가

선생님이 기존 수강권이 있는 학생에게 추가 레슨을 잡는 경우:

| 시나리오 | 예시 | 동작 |
|---------|------|------|
| **보너스 레슨** | 일정 딜레이 보상으로 1회 추가 | 기존 수강권에 연결 + `total_lessons += 1` + `bonus_count += 1` |
| **연장 레슨** | 수강권 4회 중 4회 소진, 추가 1회 | 기존 수강권에 연결 + `total_lessons += 1` + `bonus_count += 1` |
| **예기치 못한 추가** | 당일 시간이 비어 즉석 레슨 | 기존 수강권에 연결 + `total_lessons += 1` + `bonus_count += 1` |

#### 규칙

```
선생님이 레슨 추가 시 subscription_id를 지정하지 않은 경우:
  1. 활성 수강권이 있으면 → 해당 수강권에 연결
     - 수강권의 남은 횟수가 0이면 → total_lessons += 1, bonus_count += 1
     - 수강권의 남은 횟수가 있으면 → 그냥 연결 (추가 처리 없음)
  2. 활성 수강권이 없으면 → 1회 체험 수강권 자동 생성
```

#### `bonus_count` 필드

기존 `Subscription` 모델에 `bonus_count` 필드가 이미 존재한다.
보너스 레슨은 결제 대상이 아닌 무료 추가 회차임을 명시한다.

#### 보너스 레슨의 `bonus_reason`

`bonus_reason` 필드에 사유를 기록한다:
- `"schedule_delay"` — 일정 딜레이 보상
- `"teacher_goodwill"` — 선생님 호의
- `"system_compensation"` — 시스템 보상 (노쇼 등)
- `null` — 사유 미지정 (기본값)

프론트엔드에서 레슨 추가 시 보너스 사유를 선택하는 UI는 2단계에서 구현한다.
1단계에서는 `bonus_reason = "teacher_goodwill"`을 기본값으로 사용한다.

### 2.4 수강권 없는 레슨 (신규 학생)

수강권이 아예 없는 학생에게 레슨을 등록하는 경우:
- 1회 체험 수강권을 자동 생성하여 연결한다
- 선생님이 정식 수강권을 발급하면 이후 레슨은 해당 수강권에 연결된다

### 2.5 다수 활성 수강권 — 선택 UI + 필드 귀속 (2026-06-15 개정)

> 배경: §2.1 의 "가장 최근 활성 수강권 자동 연결"은 학생이 활성 수강권을 **2개 이상** 보유할 때(예: 바이올린 + 피아노, 또는 만료 임박 구권 + 신규권) 선생님 의도와 다르게 귀속될 수 있다.
>
> 악기 모델: **수강권 1개 = 멤버십 1개 = 악기 1개**(`Subscription.membership_id` 는 NOT NULL, `ClassMembership.instrument` 가 SSOT). 한 수강권은 악기 하나로 고정되며, 서로 다른 수강권은 (멤버십이 다르면) 악기가 다를 수 있다.

#### 조건부 선택 (progressive disclosure)

선생님이 수기 레슨을 추가할 때, 해당 학생의 **활성 수강권 수**로 분기한다:

| 활성 수강권 | 동작 | UI |
|:---:|------|-----|
| 0개 | §2.4 — 1회 체험 수강권 자동 생성 | 선택 없음. 악기/패턴은 학생값/수기 입력 |
| 1개 | 그 수강권에 자동 귀속 | 선택 없음. **수강권 정보 배너로 가시화** |
| **2개 이상** | **수강권 선택 시트** 노출 | 각 수강권의 악기·잔여·만료일 표시, 선생님이 선택 |

원칙: **모호할 때만 묻는다.** 활성 수강권 0~1개인 흔한 경우는 Plan B 원칙("선생님은 수강권을 의식하지 않는다")을 유지하고, 2개 이상으로 실제 선택이 필요할 때만 시트를 띄운다. quick_add 의 "최소 탭" 목표(`lesson/quick_add_lesson.md`)도 1개 경우엔 그대로 유지된다.

#### 선택 시트 표시 항목

각 활성 수강권 카드:
- 악기 (membership.instrument)
- 잔여 횟수 (remaining = total + bonus - used) 또는 월정액 표기
- 만료일 (end_date, 임박 시 강조)
- 타입 (체험/패키지/월정액)

기본 강조(권장 선택): **만료 임박 우선** (잔여 소진 전 만료 방지). 최종 선택은 선생님.

#### 필드 귀속 (수강권 -> 수기 폼)

수강권이 정해지면(자동 1개 또는 선택), 그 수강권의 **멤버십에 이미 정의된 필드는 수기 폼에서 재입력받지 않는다**:

| 필드 | 출처 | 수기 폼 처리 |
|------|------|------------|
| 악기 (instrument) | membership.instrument | **상속 고정** (읽기전용 칩, 재선택 불가) |
| 정기 패턴 (day/time/duration) | membership / Student | 자동완성(기존 quick_add 로직), 수정 가능 |
| 학생 | 진입 시 선택됨 | - |

악기는 수강권(멤버십)이 SSOT 이므로 상속받아 고정 표시한다. 0개(체험 자동생성) 경우에만 악기를 학생값/수기 입력에서 가져온다.

#### 데이터 흐름

```
학생 선택
  -> studentSubscriptions(active) 조회
     0개  -> 폼: 악기=학생값, subscription_id 미지정 -> BE 가 체험 자동생성
     1개  -> subscription_id=그 수강권, 악기=membership.instrument 상속(고정)
     2+개 -> 선택 시트 -> subscription_id=선택값, 악기=상속(고정)
  -> POST /lessons { subscription_id }  (BE: §2.1 명시 id 우선 + _assert_subscription_matches_lesson)
```

**BE 변경**: `SubscriptionResponse.instrument` 추가 — `_subscription_response` 에서 이미 조회 중인 멤버십의 `instrument` 를 매핑(추가 쿼리 0). 레거시 멤버십의 빈 문자열(`default=""`)은 **null 로 내려** FE 가 학생값으로 폴백하게 한다. instrument 컬럼은 `class_memberships` 에 이미 존재하므로 **DB 마이그레이션 없음**(코드 배포만). lesson 부착 자체는 §2.1 의 명시 subscription_id 우선 + 학생 소유 검증을 그대로 사용.

**FE 변경**: `Subscription` 엔티티에 `instrument` 필드(BE 응답 매핑), 활성 2+개 시 선택 시트, 악기 상속 고정. `resolveLessonInstrument` 가 instrument 가 null/공백이면 학생값으로 폴백.

### 2.6 레슨 추가 인텐트 분기 (2026-08-03)

> 결정 근거·UX 상세: [lesson_add_intent_redesign.md](../../proposal/lesson_add_intent_redesign.md) (D1~D5 확정)
> 원칙: §2.5 "모호할 때만 묻는다"를 유지하되, **회계에 영향을 주는 무언(silent) 자동 처리 3종**
> (잔여 0 보너스 확장 · 보강 크레딧 미소비 · 체험권 자동 발급)만 명시적 선택/안내로 승격한다.

#### 2.6.1 학생 선택 후 상태별 동작 (S1~S6)

| # | 학생 상태 | 동작 |
|---|---|---|
| S1 | 활성 수강권 1개, 잔여 > 0 | §2.5 유지 — 자동 귀속 + "N/M회차로 차감" 배너. 추가 탭 0 |
| S2 | 활성 수강권 2개 이상 | §2.5 유지 — 선택 시트 |
| S3 | 활성 수강권 있음, **잔여 0** | **처리 방식 시트** (§2.6.2). 무언의 보너스 확장 금지 |
| S4 | 보강 크레딧 보유 (잔여 무관) | 배너에 크레딧 잔량 노출 + **"보강으로 처리" 토글 (기본 OFF — D3)**. ON 시 MakeupCredit 차감, 정규 회차 미차감 ([makeup_credit_spec.md §5.4](makeup_credit_spec.md)) |
| S5 | 활성 수강권 0개, 체험권 발급 이력 없음 | 체험 1회권 자동 발급을 **배너로 명시** + [정식 수강권 먼저 발급] 보조 버튼 (§2.6.3) |
| S6 | 활성 수강권 0개, 체험권 발급 이력 있음 | **가입 학생**: 자동 재발급 차단 (§2.6.5, D2) → [수강권 발급/제안] 유도. **미가입 학생**: 제한 없음 (§2.7, D4 정합) |

#### 2.6.2 잔여 0 처리 방식 시트 (S3)

```
+--- 처리 방식 선택 -------------------------------+
|            {학생} - {수강권명} (0회 남음)         |
|                                                  |
| ( ) 보강 레슨            보강 크레딧 {K}개 보유    |
|     크레딧 1개를 사용합니다                        |
| ( ) 보너스 레슨 (무료 추가)                        |
|     수강권에 +1회 무료 추가됩니다                   |
| (o) 수강권 갱신 제안 보내기          << 기본 강조   |
|     갱신 후 이 시간으로 예약됩니다                  |
|                                                  |
|                 [계속하기]                        |
+--------------------------------------------------+
```

- 기본 강조 = **갱신 제안** (D1 — 보너스 남발로 인한 매출 침식 방지). 보강 크레딧 0개면 첫 항목 숨김.
- 갱신 제안 선택 시: 제안 발송 + 이 레슨은 `Lesson.isPreview = true` 로 캘린더에 미리 표시 (기존 필드 재사용, 신규 모델 없음). 입금 확인 시 정식 회차로 전환.
- 미가입 학생(§2.7)은 제안 수신 불가 → 세 번째 항목이 **[갱신 발급 (입금 직접 확인)]** 으로 대체되어 즉시 발급 화면으로 이동.
- BE: `POST /lessons` 에 잔여 0 처리 방식 파라미터(`overflow_mode: bonus | makeup_credit | renewal_pending`) 추가. 파라미터 없는 레거시 호출은 기존 §2.3 동작(보너스 확장) 유지 — 하위 호환.

#### 2.6.3 발급 연속 플로우 (S5/S6 → 발급 → 복귀)

`issue_subscription_screen` 에 `returnTo=addLesson` 진입을 추가한다 (학생 프리필).

| 발급 경로 | 복귀 동작 |
|---|---|
| 즉시 발급 (입금 확인됨 / 무료 / 앱 전환 / 미가입 학생) | 발급 완료 → AddLessonScreen 자동 복귀 → 새 수강권 자동 귀속(S1 상태) → 날짜/시간 저장 |
| 제안 보내기 (가입 학생) | 복귀 없이 폼 종료 + 안내: "제안 대기 중 — 확정되면 스케줄 확인 카드로 예약됩니다". **레슨 선생성 금지** (기존 확인 카드 플로우 침해 방지) |

#### 2.6.4 신규 학생 인라인 등록

AddLessonScreen 학생 선택 시트 최상단에 **[+ 새 학생 등록]** 항목을 추가한다.
`add_student`(직접 등록) 완료 → 시트 복귀 + 방금 등록한 학생 자동 선택 → S5 배너 → 저장.
이 경로에서는 학생 등록 직후의 "수강권을 발급하시겠습니까?" 다이얼로그를 **스킵**한다
(체험 1회권 자동 발급이 담당, 정식 발급은 S5 보조 버튼으로 유도).

#### 2.6.5 체험권 자동 생성 가드 (D2)

`_find_or_create_subscription` 은 다음 조건에서 체험권을 재생성하지 않는다:
- 동일 (teacher, student) 쌍에 자동 생성 체험권(`type=trial, amount=0`) 이력이 있고,
- 학생이 앱 연결 상태 (`connected_at != null`)

이 경우 에러 코드(`trial_already_used`)를 반환하고 FE 는 S6 발급 유도를 표시한다.
**미가입 학생은 가드 비적용** — 기존 동작 유지 (§2.7, 스케줄 관리 목적의 경량 사용 보호).

#### 2.6.6 배지 표현 — 레슨 유형 필드 미도입

신규 enum/컬럼을 추가하지 않는다 (D 결정, simplicity ladder):
- 체험 배지 = `subscription.type == trial`
- 보강 배지 = MakeupCredit 연결 (`usedLessonId`)
- `LessonType`(booking 도메인 전용)을 `Lesson` 으로 확장하지 않는다.

### 2.7 미가입(수기) 학생 특칙 (D4·D5)

**용어 (D5)**: "수기 학생" = 앱 미가입 상태로 선생님이 직접 등록·관리하는 학생 (`Student.user_id == null`).
"수기 레슨" = 선생님이 레슨 추가 화면에서 직접 등록한 레슨 (`LessonSource.manual`) — **수강권 미귀속을 의미하지 않는다**.

**원칙**: 데이터 경로는 가입 학생과 완전히 동일하다 (모든 레슨 수강권 귀속).
차이는 **학생 확인 절차의 생략**뿐이다. 별도 수기 데이터 경로를 만들지 않는다.

| 항목 | 가입 학생 | 미가입 학생 |
|---|---|---|
| 수강권 발급 | 제안(수락 필요) 또는 즉시 발급 | **즉시 발급만** (제안 UI 숨김) |
| 스케줄 확정 | 학생 확인 카드 | 선생님 저장 = 즉시 확정 |
| 일정 변경 | 수강권 상세 챗 협상 | 선생님 단독 변경 (챗 협상 스킵) |
| 갱신 | 시스템 자동 제안 (학생 액션) | 선생님 수동 갱신 발급 |
| 알림/리마인더 | 앱 푸시 | 없음 (선생님 화면에만 표시) |
| 앱 연결 시 | — | 전화번호 매칭 → 이력·수강권 인계 후 가입 학생 규칙 적용 |

- BE 근거: 제안-수락 API(`POST /subscriptions-proposals/{id}/respond`)만 학생 계정을 전제 — 즉시 발급은 학생 계정 무관.
- **정식 수강권 발급을 강제하지 않는다 (D4)** — 체험 1회권 자동 귀속 허용 유지 + 발급 유도 배너만.

## 3. 취소 분기 로직

### 3.1 현재 문제

```
[모든 레슨] → 직접 PATCH /status → 크레딧 무시 → 알림 없음
```

### 3.2 수정 후 플로우

모든 레슨이 수강권에 연결되므로, 취소는 항상 수강권 이벤트 시스템을 경유한다.

#### 선생님이 취소하는 경우

```
선생님이 "레슨 취소" 탭
    ↓
수강권 상세 화면으로 이동 (subscriptionId로)
    ↓
수강권 이벤트 시스템에서 lessonCancelled 이벤트 생성
    ↓
크레딧 차감 + 학생 알림 + 채팅 말풍선
```

#### 프론트엔드 변경

`lesson_detail_screen.dart`의 `_handleAppBarAction` 'cancel' 분기:

```dart
} else if (value == 'cancel') {
  if (lesson.subscriptionId != null) {
    // 수강권 연결 레슨 → 수강권 상세에서 취소 처리
    context.push(
      AppRoutes.subscriptionDetail.replaceFirst(':id', lesson.subscriptionId!),
      extra: {'viewerRole': 'teacher', 'cancelLessonId': lesson.id},
    );
  } else {
    // subscriptionId가 null인 레거시 레슨 (마이그레이션 전)
    final confirmed = await showCancelLessonConfirmation(context);
    if (confirmed == true) {
      await ref.read(lessonsNotifierProvider.notifier).cancelLesson(lesson.id);
    }
  }
}
```

### 3.3 메뉴 통합

수강권 필수화 이후, "취소"와 "일정 변경" 메뉴를 하나로 통합할 수 있다:

| 현재 | 변경 후 |
|------|--------|
| "레슨 취소" + "일정 변경" (별도 메뉴) | "수강권 관리" (단일 진입점 → 수강권 상세에서 취소/변경 모두 처리) |

단, 1단계에서는 메뉴 통합 없이 취소 분기만 수정한다.

## 4. 백엔드 변경

### 4.1 `lesson_service.create()` 수정

```python
# subscription_id가 없으면 자동 찾기/생성
if not data.subscription_id:
    subscription_id = await self._find_or_create_subscription(
        teacher_id=tid,
        student_id=data.student_id,
        lesson_date=data.date,
    )
else:
    subscription_id = data.subscription_id
```

### 4.2 `_find_or_create_subscription()` 신규 메서드

```python
async def _find_or_create_subscription(
    self, *, teacher_id: str, student_id: str, lesson_date
) -> str:
    """Find active subscription or create a trial one."""
    # 1. 활성 수강권 검색
    active_sub = await self._find_active_subscription(student_id)
    if active_sub:
        return active_sub.id

    # 2. 없으면 1회 체험 수강권 자동 생성
    trial_sub = await self._create_trial_subscription(
        teacher_id=teacher_id,
        student_id=student_id,
        lesson_date=lesson_date,
    )
    return trial_sub.id
```

### 4.3 `update_status()` 가드 추가

수강권 연결 레슨의 직접 취소를 차단:

```python
if new_status == 'cancelled' and lesson.subscription_id:
    raise HTTPException(
        status_code=400,
        detail="수강권 연결 레슨은 수강권 이벤트를 통해 취소해주세요",
    )
```

## 5. 마이그레이션

### 기존 데이터

`subscription_id IS NULL`인 기존 레슨은:
- **완료/보관 레슨**: 그대로 둔다 (과거 데이터)
- **예정 레슨**: 자동 수강권 생성하여 연결 (배치 스크립트)

### 프론트엔드 하위 호환

`subscriptionId == null` 분기를 즉시 제거하지 않고, 레거시 fallback으로 유지한다.
신규 레슨은 모두 `subscriptionId != null`이 보장된다.

## 6. 구현 단계

| 단계 | 범위 | 우선순위 |
|------|------|---------|
| **1단계 (지금)** | 프론트: 취소 분기 로직 (subscriptionId 유무) | CRITICAL |
| **2단계** | 백엔드: `lesson_service.create()`에 자동 수강권 생성 | HIGH |
| **3단계** | 백엔드: `update_status()` 가드 | MEDIUM |
| **4단계** | 마이그레이션 스크립트 | LOW |

## 7. 관련 스펙

| 스펙 | 관계 |
|------|------|
| [lesson_cancellation_flow_spec.md](../schedule/lesson_cancellation_flow_spec.md) | 취소 사유 / 크레딧 규칙 |
| [subscription_schedule_change_spec.md](../schedule/subscription_schedule_change_spec.md) | 일정 변경 협상 플로우 |
| [notification_master.md](../notification/notification_master.md) | 취소 알림 발송 |

## 8. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-05-31 | 초안 작성 — Plan B (수강권 필수 + 자동 생성) 결정 |
| 2026-06-15 | §2.5 추가 — 다수 활성 수강권 시 선택 UI(조건부, 2개+) + 멤버십 악기 상속 고정 + 0개 체험 자동생성 |
| 2026-06-16 | §2.5 정정 — 악기는 BE `SubscriptionResponse.instrument`(membership 매핑, 빈문자열→null)로 제공. 직전 문구 "BE 스키마는 이미 제공"은 오류였음(실제 미제공). DB 마이그레이션 없음(코드 배포만) |
| 2026-08-03 | §2.6 신설 — 레슨 추가 인텐트 분기 (S1~S6, 잔여 0 처리 시트, 발급 연속 플로우, 신규 학생 인라인 등록, 체험권 재생성 가드, 배지 간접 표현). §2.7 신설 — 미가입(수기) 학생 특칙 (즉시 발급만, 학생 확인 생략, D4·D5). 기획: `docs/proposal/lesson_add_intent_redesign.md` |
