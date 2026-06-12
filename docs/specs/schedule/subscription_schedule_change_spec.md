# 수강권 일정 변경 — 턴 기반 잠금 흐름 스펙

> 최종 업데이트: 2026-06-12 (launch-readiness audit — §8 요청 만료 정책 추가)
> 관련 이슈: #427
> **일괄변경 후 5주차·보강 재계산 로직 + Make-up Bank**: [../subscription/makeup_credit_spec.md](../subscription/makeup_credit_spec.md) (`Subscription.scheduledLessons` 별도 트랙, MakeupCredit 적립 트리거)

## 1. 개요

수강권 상세화면(SubscriptionDetailScreen)은 **일정 변경 협상 전용** 화면이다.
자유 메시지 전송을 제거하고, 레슨 요청 화면(RequestDetailScreen)과 동일한
**턴 기반 잠금 패턴**을 적용한다.

### 설계 원칙

- **목적 집중**: 이 화면은 일정 변경만을 위한 화면. 일반 대화는 공지 기능으로 분리
- **턴 기반 잠금**: 일정 변경 제안 후 상대방 응답 전까지 UI 잠금
- **레슨 요청과 일관성**: RequestDetailScreen의 myTurn/theirTurn 패턴을 동일하게 적용

## 2. 상태 다이어그램

```mermaid
stateDiagram-v2
    [*] --> Default: 화면 진입

    Default --> Waiting: 일정 변경 제안 전송
    Default --> CanRespond: 상대방 일정 변경 수신

    Waiting --> Default: 상대방 수락
    Waiting --> CanRespond: 상대방 역제안
    Waiting --> Waiting: 결정 변경 → 재제안

    CanRespond --> Waiting: 역제안 전송
    CanRespond --> Default: 수락
    CanRespond --> Default: 거절

    state Default {
        [*] --> 일정변경버튼
        note right of 일정변경버튼
            자유 메시지 입력 없음
            "일정 변경 요청하기" 버튼만 표시
        end note
    }

    state Waiting {
        [*] --> 응답대기
        note right of 응답대기
            "OOO님의 응답을 기다리고 있습니다"
            + "결정 변경" 버튼
        end note
    }

    state CanRespond {
        [*] --> 슬롯선택
        note right of 슬롯선택
            제안된 슬롯 목록 + 메시지 입력
            + "일정 비교" / "수락" 버튼
        end note
    }
```

## 3. 시퀀스 다이어그램 — 일정 변경 흐름

### 3.1 기본 흐름: 제안 → 수락

```mermaid
sequenceDiagram
    participant T as 선생님
    participant S as 학생
    participant UI_T as 선생님 UI
    participant UI_S as 학생 UI

    T->>UI_T: "일정 변경" 버튼 클릭
    UI_T->>UI_T: 타입 선택 (단일/전체)
    UI_T->>UI_T: 일정 비교 화면 (슬롯 선택 + 메시지)
    UI_T->>S: scheduleChangeProposed 이벤트
    UI_T->>UI_T: 상태 → Waiting ("학생 응답 대기")

    UI_S->>UI_S: 상태 → CanRespond (슬롯 목록 표시)
    S->>UI_S: 슬롯 선택 → "수락" 클릭
    UI_S->>T: scheduleChangeAccepted 이벤트
    UI_S->>UI_S: 상태 → Default
    UI_T->>UI_T: 상태 → Default
```

### 3.2 역제안 흐름

```mermaid
sequenceDiagram
    participant T as 선생님
    participant S as 학생
    participant UI_T as 선생님 UI
    participant UI_S as 학생 UI

    T->>UI_T: "일정 변경" 버튼 클릭
    UI_T->>S: scheduleChangeProposed 이벤트
    UI_T->>UI_T: 상태 → Waiting

    UI_S->>UI_S: 상태 → CanRespond
    S->>UI_S: "일정 비교" 클릭
    UI_S->>UI_S: SuggestAlternativeScreen (새 슬롯 선택 + 메시지)
    UI_S->>T: scheduleChangeCountered 이벤트
    UI_S->>UI_S: 상태 → Waiting ("선생님 응답 대기")

    UI_T->>UI_T: 상태 → CanRespond (역제안 슬롯 표시)
    T->>UI_T: 슬롯 선택 → "수락"
    UI_T->>S: scheduleChangeAccepted 이벤트
    UI_T->>UI_T: 상태 → Default
    UI_S->>UI_S: 상태 → Default
```

### 3.3 결정 변경 흐름

```mermaid
sequenceDiagram
    participant T as 선생님
    participant UI_T as 선생님 UI
    participant S as 학생

    T->>UI_T: "일정 변경" 제안
    UI_T->>UI_T: 상태 → Waiting

    T->>UI_T: "결정 변경" 클릭
    UI_T->>UI_T: SuggestAlternativeScreen (재제안)
    UI_T->>S: scheduleChangeProposed 이벤트 (새 슬롯)
    UI_T->>UI_T: 상태 → Waiting (새 제안으로 갱신)
```

## 4. 하단 바 UI 상태별 레이아웃

### 4.1 Default (보류 중인 일정 변경 없음)

```
┌──────────────────────────────────────┐
│ 일정 변경이 필요하면 아래 버튼을      │
│ 눌러 요청하세요                       │
│                                      │
│  ┌──────────────────────────────┐    │
│  │       일정 변경               │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

- 자유 메시지 입력 필드 없음
- 메시지 전송 버튼 없음
- 일정 변경 버튼만 표시 (전체 너비)

### 4.2 Waiting (내가 제안, 상대방 응답 대기)

```
┌──────────────────────────────────────┐
│ 박지호님의 응답을 기다리고 있습니다   │
│                                      │
│  ┌──────────────────────────────┐    │
│  │       결정 변경               │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

- 상대방 이름 + 대기 메시지
- "결정 변경" 버튼 → 클릭 시 SuggestAlternativeScreen으로 재진입

### 4.3 CanRespond (상대방 제안, 내가 응답할 차례)

```
┌──────────────────────────────────────┐
│ 일정을 탭하여 선택하세요              │
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 1. 월 14:00 - 15:00          │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │ 2. 수 10:00 - 11:00          │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 전달할 메시지를 입력하세요     │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌────────────┐  ┌────────────┐     │
│  │  일정 비교  │  │    수락    │     │
│  └────────────┘  └────────────┘     │
└──────────────────────────────────────┘
```

- 제안된 슬롯 목록 (탭하여 선택)
- 메시지 입력 필드 (일정 변경에 대한 메시지만)
- "일정 비교" → SuggestAlternativeScreen에서 역제안
- "수락" → 선택한 슬롯으로 확정

## 5. 이벤트 타입 매핑

| 이벤트 | 트리거 | 결과 상태 |
|--------|--------|----------|
| `scheduleChangeProposed` | 일정 변경 제안 | 본인 → Waiting, 상대 → CanRespond |
| `scheduleChangeAccepted` | 슬롯 수락 | 양쪽 → Default |
| `scheduleChangeRejected` | 거절 | 양쪽 → Default |
| `scheduleChangeCountered` | 역제안 | 본인 → Waiting, 상대 → CanRespond |

## 6. 레슨 요청 화면과의 비교

| 항목 | 레슨 요청 (Phase 1) | 수강권 일정 변경 (Phase 3) |
|------|---------------------|--------------------------|
| 자유 메시지 | 없음 | 없음 |
| 턴 기반 잠금 | myTurn / theirTurn | isWaiting / canRespond |
| 결정 변경 | withdrawApproval → 재협상 | 재제안 (새 scheduleChangeProposed) |
| 메시지 첨부 | 수락/역제안 시 | 제안/수락/역제안 시 |
| 일정 비교 | SuggestAlternativeScreen | SuggestAlternativeScreen (동일) |

## 7. 레슨 취소 흐름

레슨 취소는 일정 변경과 본질적으로 다른 단방향 흐름이다.
별도 스펙 문서로 분리: **[lesson_cancellation_flow_spec.md](lesson_cancellation_flow_spec.md)**

하단 바는 일정 변경(3상태) + 취소 확정(1상태) = **총 4상태**로 동작한다.

| 상태 | 트리거 | 스펙 |
|------|--------|------|
| Default | 보류 이벤트 없음 | 이 문서 §4.1 |
| Waiting | 일정 변경 제안 전송 | 이 문서 §4.2 |
| CanRespond | 상대방 일정 변경 수신 | 이 문서 §4.3 |
| CancellationConfirmed | 학생 취소 자동 확정 | [lesson_cancellation_flow_spec.md](lesson_cancellation_flow_spec.md) §5 |

## 8. 요청 만료 정책

> 추가: 2026-06-12 launch-readiness audit.
> 배경: 기존 스펙은 Waiting/CanRespond 상태의 **시간 제한이 없어** 상대방이
> 응답하지 않으면 영구 대기가 가능했다. 초대(`invite_lifecycle_spec.md`)와
> 수강권 제안(`expired` 7일)은 만료를 정의했으나 일정 변경 요청만 누락.
> 출시 후 "요청했는데 3일째 무응답 → 앱 먹통 의심" 이탈 리스크 차단 목적.

### 8.1 만료 규칙

| 항목 | 값 | 근거 |
|------|-----|------|
| 요청 유효기간 | 생성 시점부터 **72시간** | 수강권 제안 리마인더(24h/48h/72h) 주기와 일관 |
| 리마인드 알림 | 24h 무응답 시 응답자에게 1회 (`scheduleChangeReminder`) | 알림 피로 최소화 — 1회만 |
| 만료 임박 알림 | 60h 경과 시 **요청자에게** 1회 ("12시간 후 자동 만료") | 요청자가 철회/직접 연락 판단 기회 |
| 만료 처리 | 72h 도달 시 자동 `expired` — 양측 Default 복귀 | 서버 배치 (초대 만료 cron 과 동일 인프라) |
| 변경권 복원 | 요청 시점에 차감된 경우 만료 시 **자동 복원** | 무응답 페널티를 요청자가 지지 않음 |
| 만료 후 재요청 | 즉시 가능 (쿨다운 없음) | 단, 동일 회차 3회 연속 만료 시 안내 배너 ("직접 연락을 권장해요") |

### 8.2 상태 다이어그램 보강

§2 다이어그램에 다음 전이가 추가된다:

```
Waiting --> Default: 72h 경과 자동 만료 (expired)
CanRespond --> Default: 72h 경과 자동 만료 (expired)
```

### 8.3 만료 시 채팅 가이드 표시

| 시점 | 표시 ([chat_guide_message_spec.md](chat_guide_message_spec.md) 패턴) |
|------|------|
| 만료 직후 | 시스템 말풍선 "이 변경 요청은 응답 없이 만료되었어요" (양측) |
| 요청자 가이드 | action(primary): "다시 요청하기" 버튼 노출 |
| 응답자 가이드 | wait(grey): 별도 액션 없음 — 히스토리 기록만 |

### 8.4 이벤트 타입 추가 (§5 보강)

| 이벤트 | 트리거 | 결과 상태 |
|--------|--------|----------|
| `scheduleChangeExpired` | 72h 무응답 배치 처리 | 양쪽 → Default, 변경권 복원 |
| `scheduleChangeReminder` | 24h 무응답 | 상태 변화 없음 (알림만) |

> 알림 카테고리: `schedule` ([push_notification_settings_spec.md](../notification/push_notification_settings_spec.md) §3.2 기본 ON) 에 포함.

## 9. 관련 파일

| 파일 | 역할 |
|------|------|
| `subscription_detail_screen.dart` | 수강권 상세 화면 (핸들러) |
| `subscription_bottom_input_bar.dart` | 하단 입력 바 (4상태 UI) |
| `suggest_alternative_screen.dart` | 일정 비교 화면 (공유) |
| `schedule_change_slot_bottom_sheet.dart` | 슬롯 선택 바텀시트 |
| `schedule_change_type_bottom_sheet.dart` | 변경 타입 선택 (단일/전체) |
| `cancel_lesson_bottom_sheet.dart` | 취소 사유 선택 + 제출 |
