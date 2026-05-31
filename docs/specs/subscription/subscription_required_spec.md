# 수강권 필수화 스펙 (Plan B)

> 최종 업데이트: 2026-05-31

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
