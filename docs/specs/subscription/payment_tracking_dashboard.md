# 입금 추적 대시보드 스펙 (Payment Tracking Dashboard)

> 작성일: 2026-06-01
> 상태: 스펙 초안
> 출처: E2E 감사 Top 10 #3 E2-C1 — `docs/specs/review/2026-06-01-teacher-e2e/30-gap-catalog.md`
> 관련 이슈: #424
> 관련 스펙: [subscription_master.md §4](subscription_master.md), [home_master.md](../home/home_master.md), [notification_master.md](../notification/notification_master.md), [alimtalk_templates.md](../notification/alimtalk_templates.md)
> 글로서리: [glossary.md](../../../.harness/knowledge/glossary.md) — "입금 대기", "입금 추적"

---

## 1. 문제 정의

E2E 감사 정량 입증: 선생님 홈에 `paymentRequested` 상태 집계 카드 = **0건**. `subscription_master.md §4` 입금 정책은 학생측 D+N 알림만 부분 정의.

### 1.1 현재 결함

| # | 문제 | 영향 |
|---|---|---|
| 1 | 선생님이 입금 안 됨을 **능동적으로 인지 못함** | 7일 자동 expired 까지 침묵 → 묵시적 포기 |
| 2 | 학생별 D+N 경과 시각화 부재 | 어느 학생 우선 챙겨야 할지 불명 |
| 3 | 1탭 재발송 액션 부재 | 재안내 시 학생을 직접 찾아 채팅 — 마찰 |
| 4 | 선생님 측 D+1/D+3/D+7 푸시 부재 | 카톡 단톡방 대비 압도적 가시성 열세 |

### 1.2 영향 범위 (펀넬)

E2 (입금 추적) 전 구간 + 선생님 매출 누락 인지 실패.
카톡 채널은 선생님이 단톡방에서 일별 확인 → 우리는 일별 대시보드 0 → 운영 신뢰 붕괴.

### 1.3 범위 명시 — 송금 자동화 아님

> **본 스펙은 송금 자동화를 포함하지 않는다.**
>
> lesson-app 원칙 (`subscription_master.md §1.2`): **"돈은 앱 밖에서, 상태는 앱 안에서"**
>
> - 학부모는 외부 무통장입금/계좌이체 그대로
> - 선생님은 통장에서 입금 확인 후 [입금 확인] 1탭
> - 본 대시보드는 **입금 미확인 가시화 + 안내 재발송**만 자동화
> - 카드 결제·Stripe·토스 등 PG 도입은 **명시적으로 거절됨**

---

## 2. 설계 원칙

> **"입금은 단톡방보다 잘 보여야 한다."**

| 원칙 | 의미 |
|---|---|
| 홈 1탭 도달 | 선생님 홈 상단 카드 → 1탭으로 입금 대기 리스트 진입 |
| D+N 시각화 | 학생별 며칠 경과인지 한 눈에 — 우선순위 자동 판단 |
| 1탭 재발송 | 리스트에서 즉시 알림톡 + 앱 푸시 동시 재발송 |
| Notebook × Score 시스템 준수 | 별도 디자인 시스템 만들지 않음 — 기존 시각 언어 재사용 |
| 자동 + 수동 양립 | D+1/D+3/D+7 cron 자동 발송 + 선생님 수동 재발송 모두 지원 |

---

## 3. 집계 정의

### 3.1 [입금 대기] 카운트

선생님 홈 상단 카드의 N건 = 다음 조건을 만족하는 `SubscriptionProposal` 카운트:

```
SubscriptionProposal WHERE
  teacherId = currentUser
  AND status IN [paymentRequested, paymentNotified]
  AND expiresAt > now()  -- 만료 전만 집계
```

| 상태 | 의미 |
|---|---|
| `paymentRequested` | 선생님이 제안 송신 직후 — 학부모 응답 대기 |
| `paymentNotified` | 학생이 [입금했어요] 탭 후 — 선생님 통장 확인 대기 |

### 3.2 D+N 계산

각 학생별 경과일:

```
daysSinceSent = floor((now() - proposal.createdAt) / 1 day)
```

| 구간 | 표시 라벨 | 색상 (Notebook × Score) |
|---|---|---|
| D+0 ~ D+1 | "방금" / "어제" | `AppColors.scheduleMutedAccent` (회색) |
| D+2 ~ D+3 | "D+N" | `AppColors.warningAccent` (주황 #F4A460) |
| D+4 ~ D+6 | "D+N" | `AppColors.warningAccent` + 굵게 |
| D+7 (오늘 만료) | "오늘 만료" | `AppColors.criticalAccent` (강조 빨강 단, 빨강 미사용 원칙 보류 → primary 색상 + 굵게 + 점멸 1회) |

> 빨강 미사용 원칙 (`subscription_master.md §2.4`) 준수. D+7 은 강조 표현 사용하되 색상은 primary 단색.

---

## 4. UI 정의

### 4.1 선생님 홈 — [입금 대기] 카드

위치: 선생님 홈 상단, [오늘 레슨] 카드 다음.

```
┌────────────────────────────────────────┐
│  입금 대기  3건             [>]        │
│  ─────────────────────────────────     │
│  · 김민수  D+5  150,000원              │
│  · 박서연  D+2  120,000원              │
│  · 이지원  오늘 만료  200,000원         │
└────────────────────────────────────────┘
```

| 항목 | 사양 |
|---|---|
| 카드 위치 | 홈 상단 — `home_master.md` 의 상단 카드 슬롯 |
| 카드 노출 조건 | `N >= 1` — 0건일 때는 숨김 |
| 미리보기 행 수 | 최대 3개 (D+N 큰 순) |
| 탭 동작 | [입금 대기 리스트] 화면 진입 |
| 색상 | `AppColors.primary` 헤더, 미리보기는 D+N 색상 정책 |
| 디자인 시스템 | Notebook × Score 시그니처 — `core/widgets/notebook/` 글리프 사용 |

### 4.2 [입금 대기 리스트] 화면

홈 카드 탭 후 진입하는 풀 리스트.

```
┌────────────────────────────────────────┐
│  ← 입금 대기                            │
├────────────────────────────────────────┤
│  D+7 만료 임박                          │
│  ┌──────────────────────────────────┐  │
│  │ 이지원  오늘 만료                │  │
│  │ 8회권 · 200,000원                │  │
│  │ [재발송]            [입금 확인]  │  │
│  └──────────────────────────────────┘  │
│                                        │
│  D+3 이상                              │
│  ┌──────────────────────────────────┐  │
│  │ 김민수  D+5                      │  │
│  │ 4회권 · 150,000원                │  │
│  │ [재발송]            [입금 확인]  │  │
│  └──────────────────────────────────┘  │
│                                        │
│  D+0 ~ D+2                             │
│  ┌──────────────────────────────────┐  │
│  │ 박서연  D+2                      │  │
│  │ 8회권 · 120,000원                │  │
│  │ [재발송]            [입금 확인]  │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

| 항목 | 사양 |
|---|---|
| 그룹핑 | D+7 만료 임박 / D+3 이상 / D+0 ~ D+2 (3개 섹션) |
| 정렬 | 각 그룹 내 D+N 큰 순 |
| 행 액션 (1탭) | [재발송] · [입금 확인] |
| 스와이프 액션 | 좌측 스와이프 → [회수] (SwipeActionTile 사용 — `core/widgets/swipe_action_tile.dart`) |
| 비어있는 그룹 | "이 구간 없음" 회색 라벨 (요일/카테고리 그룹 유지 원칙 준수) |

### 4.3 [재발송] 액션

행의 [재발송] 1탭 시:

| 동시 발송 | 채널 |
|---|---|
| 알림톡 | `LNZ_PAYMENT_REMINDER_D{N}` (D+N 값에 따라 자동 선택) |
| 앱 푸시 | 학생/학부모 측 — `notification_type = paymentReminder` |

발송 후 SnackBar: "알림톡 + 푸시 재발송 완료"

재발송 쿨다운: 같은 학생 30분 내 재발송 차단 (회색 비활성). 사유: 알림 폭격 방지.

### 4.4 [입금 확인] 액션

행의 [입금 확인] 1탭 시:

- `SubscriptionProposal.status = paymentConfirmed`
- `LNZ_PAYMENT_CONFIRM` 알림톡 발송 (`alimtalk_templates.md §3.6`)
- 24시간 Undo 윈도우 활성화 (`subscription_master.md §4 입금 확인 Undo`, E2E 감사 #6 의존)

---

## 5. 자동 리마인드 (cron)

### 5.1 학생 측 알림톡 (G2 #2 의존)

`alimtalk_templates.md §3.1` 트리거 매핑 그대로:

| 시점 | 템플릿 | 채널 |
|---|---|---|
| 송신 직후 | `LNZ_INVOICE` | 알림톡 → 앱 푸시 → SMS |
| D+1 | `LNZ_PAYMENT_REMINDER_D1` | 알림톡 → 앱 푸시 |
| D+3 | `LNZ_PAYMENT_REMINDER_D3` | 알림톡 → 앱 푸시 → SMS |
| D+7 | `LNZ_PAYMENT_REMINDER_D7` | 알림톡 → 앱 푸시 → SMS |

### 5.2 선생님 측 푸시 (신규)

`notification_master.md` 에 다음 3종 추가 (메인 세션이 처리):

| `notification_type` | 시점 | 메시지 |
|---|---|---|
| `payment.pending_d1` | D+1 cron | "○○○ 학생 입금 대기 1일째" |
| `payment.pending_d3` | D+3 cron | "○○○ 학생 입금 대기 3일째. 재안내 권장" |
| `payment.pending_d7_final` | D+7 cron | "○○○ 학생 입금 오늘 만료 — 마지막 안내" |

채널: 앱 푸시 (선생님은 앱 항상 사용 가정). 알림톡 미사용.

탭 동작: [입금 대기 리스트] 화면 직접 진입 + 해당 학생 행 하이라이트.

### 5.3 cron 실행 시간

| Job | 주기 | 시각 |
|---|---|---|
| `payment_pending_d1_remind` | 매일 | 09:00 KST |
| `payment_pending_d3_remind` | 매일 | 09:00 KST |
| `payment_pending_d7_final` | 매일 | 09:00 KST |

알림톡 발송 가능 시간 (08:00-20:00) 준수.

---

## 6. 백엔드 API

### 6.1 신규 엔드포인트

| Method | 경로 | 설명 |
|---|---|---|
| GET | `/api/teacher/payment-pending` | 입금 대기 리스트 (D+N 포함) |
| GET | `/api/teacher/payment-pending/count` | 홈 카드 카운트 |
| POST | `/api/subscription-proposals/:id/resend` | 알림톡 + 푸시 재발송 (쿨다운 30분) |
| POST | `/api/subscription-proposals/:id/revoke` | 제안 회수 (선생님 실수 회복) |

### 6.2 응답 스키마

```json
GET /api/teacher/payment-pending
{
  "pending": [
    {
      "proposalId": "uuid",
      "studentName": "김민수",
      "amount": 150000,
      "lessonCount": 4,
      "daysSinceSent": 5,
      "expiresAt": "2026-06-08T00:00:00Z",
      "lastReminderSentAt": "2026-06-04T09:00:00Z",
      "canResend": true
    }
  ],
  "totalCount": 3
}
```

---

## 7. 측정 기준

| 지표 | 측정 방법 | 목표 |
|---|---|---|
| 홈 카드 노출률 | `paymentRequested >= 1` 인 선생님 / 전체 | 일일 가시성 보장 |
| 1탭 재발송 사용률 | 수동 재발송 / 전체 재발송 | 20-30% (자동 70-80% + 수동 20-30%) |
| **입금 회수율** | E1 송신 → E3 paymentConfirmed | **+20-30%** (대시보드 + 알림톡 통합 효과, E2E 감사 #2·#3 합산) |
| 만료율 | expired / E1 전체 | < 10% (현재 추정 30-40%) |
| 7일 평균 입금 일수 | 송신부터 paymentConfirmed 까지 평균 | < 3일 (현재 추정 5-7일) |
| 회수 (revoke) 사용률 | 회수 / E1 전체 | < 5% (회수는 실수 회복 — 빈번하면 UX 문제) |

---

## 8. 구현 범위 (Phase 별)

### Phase 1: 스펙 + 글로서리 (본 작업)

- 본 파일 작성
- glossary 에 "입금 대기", "입금 추적" 추가 (메인 세션)
- `subscription_master.md §4` 에 본 스펙 참조 추가 (메인 세션)
- `home_master.md` 에 [입금 대기] 카드 슬롯 명시 (메인 세션)
- `notification_master.md` 에 선생님 푸시 3종 추가 (메인 세션)

### Phase 2: 백엔드 (1주)

- 4개 신규 엔드포인트
- cron 3개 (D+1, D+3, D+7)
- 쿨다운 로직 (`last_reminder_sent_at` 기준 30분)

### Phase 3: 프론트엔드 (1-2주)

- 홈 [입금 대기] 카드 위젯
- [입금 대기 리스트] 화면
- 행 [재발송] / [입금 확인] / [회수] 액션
- SwipeActionTile 적용 (`core/widgets/swipe_action_tile.dart`)
- 푸시 탭 후 화면 진입 + 행 하이라이트

### Phase 4: 알림톡 연동 (G2 #2 의존)

- `alimtalk_templates.md` 의 5종 발송 트리거와 결합
- D+1/D+3/D+7 학생측 자동 알림톡 발송

### Phase 5: 측정 + 튜닝 (1주)

- 입금 회수율 대시보드 (관리자용)
- 도입 전후 비교 리포트

---

## 9. 의존성

| 의존 항목 | 상태 |
|---|---|
| `alimtalk_templates.md` 5종 템플릿 | 본 세션 신규 작성 (병행) |
| 카카오 사업자 등록 + 딜러사 계약 | Phase 2 선행 (운영팀) |
| 입금 확인 Undo (E2E 감사 #6) | Phase 2 이후 (`subscription_master.md §4` 추가 예정) |
| `core/widgets/swipe_action_tile.dart` | 이미 존재 — 재사용 |
| `core/widgets/notebook/` 글리프 | 이미 존재 — 재사용 |

---

## 10. 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| 1.0 | 2026-06-01 | 초안 — E2E 감사 #3 E2-C1 대응 |
