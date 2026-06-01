# 초대 코드 라이프사이클 스펙 (Invite Lifecycle)

> 작성일: 2026-06-01
> 상태: 스펙 초안
> 출처: E2E 감사 Top 10 #5 D-G3 — `docs/specs/review/2026-06-01-teacher-e2e/30-gap-catalog.md`
> 관련 스펙: [user_master.md §초대 시스템](user_master.md), [lesson/invite/](../lesson/invite/)
> 글로서리: [glossary.md §2.4](../glossary.md#24-초대-코드-라이프사이클-invite-code-lifecycle)

---

## 1. 문제 정의

E2E 감사 정량 입증: `grep reinvite|resendInvite frontend/lib/features/ backend/app/` = **0건**.

### 1.1 현재 결함

| # | 문제 | 영향 |
|---|---|---|
| 1 | 학생이 초대 코드/QR 받고 미설치 시 선생님 측 **재발송 트리거 없음** | 학생을 영영 잃음 |
| 2 | `InviteCode.expiresAt` 후 자동 만료되지만 **선생님은 인지 못 함** | 7일 후 silently 코드 무효 |
| 3 | `RelationshipStatus.trialBooked` vs `ConnectionStatus.inviteSent` **이중 상태 충돌** | UI에서 어느 게 보여야 하는지 모름 |
| 4 | 선생님이 학생을 잘못 초대한 후 **회수 경로 부재** | Recovery 부재 — 신뢰 상실 |

### 1.2 영향 범위 (펀넬)

D (학생 초대·연결) → E1 (수강권 제안 송신) 전이 게이트 깨짐.
학생 미진입 시 선생님이 손쓸 방법 없음 → 가입 후 매출 0 가능성.

---

## 2. 설계 원칙

> **"초대는 보냈으면 끝이 아니다. 학생이 들어올 때까지 추적한다."**

| 원칙 | 의미 |
|---|---|
| 단일 SSOT | `RelationshipStatus` 가 레슨 관계의 유일한 상태. `ConnectionStatus` 는 deprecate |
| 적극적 추적 | 초대 전송 후 D-3, D-1 만료 임박 알림으로 선생님이 능동 행동 |
| 1탭 재발송 | 학생 리스트의 "초대 대기" 그룹에서 직접 재발송 가능 |
| 회복 가능 | 잘못 초대한 경우 명시적 회수 (revoked) 가능, RelationshipStatus 롤백 |

---

## 3. 상태 머신

```
[선생님 액션]            [상태]                  [전이 조건]
                                                   
  코드 생성 ─────────────► created
                            │ 학생에게 전송 (QR/URL/SMS)
                            ▼
                          sent ───────────► expired (D+7)
                            │ ▲
                            │ │ D-1, D-3 만료 임박 알림 → 선생님 재발송 → 만료 갱신
                            │ │
                            │ ▼
                            │ revoked ◄────── 선생님이 명시적 회수
                            │
                            │ 학생이 링크/QR 접근
                            ▼
                          opened
                            │ 학생 가입 + 연결 완료
                            ▼
                          joined ─────► RelationshipStatus.trialBooked 또는 active
```

### 3.1 InviteCode 엔티티 확장

기존 `InviteCode` 에 다음 필드 추가:

| 필드 | 타입 | 기본 | 설명 |
|---|---|---|---|
| `status` | `InviteCodeStatus` enum | `created` | 위 상태 머신 |
| `sentAt` | `DateTime?` | `null` | 전송 시각 |
| `openedAt` | `DateTime?` | `null` | 학생 첫 접근 시각 |
| `joinedAt` | `DateTime?` | `null` | 가입·연결 완료 시각 |
| `revokedAt` | `DateTime?` | `null` | 선생님 회수 시각 |
| `resendCount` | `int` | 0 | 재발송 횟수 (분석용) |

> 기존 `expiresAt` 필드 유지. 재발송 시 7일 갱신.

### 3.2 InviteCodeStatus enum

```dart
enum InviteCodeStatus {
  created,    // 생성됨, 미전송
  sent,       // 학생에게 전송됨
  opened,     // 학생이 링크/QR 접근
  joined,     // 학생 가입·연결 완료
  expired,    // 7일 경과로 자동 만료
  revoked,    // 선생님이 명시적 회수
}
```

---

## 4. RelationshipStatus 통합

### 4.1 신규 상태: `invitePending`

`RelationshipStatus` enum 에 신규 상태 추가:

```dart
enum RelationshipStatus {
  invitePending,  // 신규 — 초대 전송됨, 학생 미진입
  trialBooked,
  active,
  expired,
  past,
}
```

### 4.2 ConnectionStatus deprecate

| 기존 (ConnectionStatus) | 통합 후 (RelationshipStatus) |
|---|---|
| `offline` | 영역 분리 (네트워크 영역, 레슨 관계 무관) |
| `inviteSent` | `invitePending` |
| `inviteAccepted` | `trialBooked` |
| `connected` | `active` 또는 팔로우 영역 |

> 마이그레이션: 기존 `ConnectionStatus.inviteSent` 레코드를 1회 batch 작업으로 `RelationshipStatus.invitePending` 으로 이관. ConnectionStatus 코드는 단계적 제거 (6개월 grace period).

---

## 5. 알림 정책

### 5.1 선생님 측 알림

| 시점 | 트리거 | 메시지 |
|---|---|---|
| D-3 | `expiresAt - 3d` cron | "○○○ 학생 초대가 3일 후 만료됩니다. 다시 보내시겠어요?" |
| D-1 | `expiresAt - 1d` cron | "○○○ 학생 초대가 내일 만료됩니다. [재발송]" |
| D+0 | `expiresAt` 도달 | "○○○ 학생 초대가 만료되었습니다. [새로 초대]" |

채널: 인앱 알림 + 앱 푸시. 알림톡은 선생님 측 미사용 (선생님은 앱 항상 사용 가정).

### 5.2 학생 측 알림 (신규 — 알림톡 연동, G2 #2와 연결)

| 시점 | 템플릿 | 발송 채널 |
|---|---|---|
| 초대 전송 직후 | LNZ_INVITE_INITIAL | 카톡 알림톡 (학생 휴대폰 번호 기준) |
| D-1 | LNZ_INVITE_REMINDER | 카톡 알림톡 + SMS 폴백 |
| 재발송 시 | LNZ_INVITE_RESENT | 카톡 알림톡 |

> 학생이 앱 미설치 상태일 때 알림톡이 유일한 도달 채널. G2 #2 (카카오 알림톡) 의존.

---

## 6. UI 정의

### 6.1 학생 리스트의 "초대 대기" 그룹

학생 리스트 화면에서 다음 그룹핑.

```
┌─────────────────────────────────────────┐
│ 학생                                     │
├─────────────────────────────────────────┤
│ ▼ 초대 대기 (3)                         │
│   ┌───────────────────────────────────┐ │
│   │ 김민수  D-2 만료 임박  [재발송]    │ │
│   │ 박서연  D-5             [재발송]   │ │
│   │ 이지원  D+0 만료됨   [새로 초대]   │ │
│   └───────────────────────────────────┘ │
│                                         │
│ ▼ 수강 중 (12)                          │
│   ...                                   │
└─────────────────────────────────────────┘
```

- 만료 D-3 이내는 빨간 점 표시
- 만료 후는 회색 + "새로 초대" 버튼
- [재발송] 탭 시 같은 코드 만료일 갱신 + 알림톡 재발송

### 6.2 회수 경로 (Recovery)

학생 리스트의 "초대 대기" 항목에서 long-press 또는 우측 스와이프 → "초대 회수" 옵션 노출.

- 회수 확인 다이얼로그: "이 학생 초대를 회수하시겠습니까? 학생에게는 알림이 가지 않습니다."
- 회수 시 InviteCode.status = revoked, RelationshipStatus 삭제

---

## 7. 백엔드 API

### 7.1 신규 엔드포인트

| Method | 경로 | 설명 |
|---|---|---|
| POST | `/api/invites/:id/resend` | 같은 코드 재발송 + expiresAt 갱신 |
| POST | `/api/invites/:id/revoke` | 명시적 회수 |
| GET | `/api/invites/pending` | 선생님의 초대 대기 목록 (status in [sent, expired]) |

### 7.2 cron 작업

| Job | 주기 | 처리 |
|---|---|---|
| `invite_reminder_d3` | 매일 09:00 | `expiresAt - 3d` 매칭 시 선생님 알림 |
| `invite_reminder_d1` | 매일 09:00 | `expiresAt - 1d` 매칭 시 선생님 알림 + 학생 알림톡 |
| `invite_expire` | 매일 00:00 | `expiresAt < now` 매칭 시 status = expired |

---

## 8. 측정 기준

| 지표 | 측정 방법 | 목표 |
|---|---|---|
| 초대 회수율 | `joined / sent` | > 60% (현재 추정 < 30%) |
| 재발송 사용률 | `resendCount > 0 / sent` | 10-20% (이상치 모니터링) |
| 만료 후 재초대 비율 | `expired → new_code / expired` | < 40% (재발송으로 살리는 게 우선) |
| ConnectionStatus 잔존율 | 코드 grep 카운트 | 6개월 내 0건 |

---

## 9. 구현 범위 (Phase 별)

### Phase 1: 스펙 + 글로서리 (본 작업)

- ✅ `invite_lifecycle_spec.md` 신규 작성
- ✅ `glossary.md` (양쪽) RelationshipStatus.invitePending 추가
- ✅ ConnectionStatus deprecate 명시

### Phase 2: 백엔드 (1주)

- InviteCode 엔티티 필드 확장
- 신규 엔드포인트 3개
- cron 작업 3개
- 마이그레이션: ConnectionStatus.inviteSent → RelationshipStatus.invitePending

### Phase 3: 프론트엔드 (1주)

- "초대 대기" 그룹 UI
- 재발송 버튼·회수 스와이프 액션
- D-3/D-1 알림 처리

### Phase 4: 알림톡 연동 (G2 #2 의존)

- LNZ_INVITE_INITIAL, LNZ_INVITE_REMINDER, LNZ_INVITE_RESENT 템플릿
- G2 #2 (kakao_alimtalk_spec) 와 동시 진행

---

## 10. 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| 1.0 | 2026-06-01 | 초안 — E2E 감사 #5 D-G3 대응 |
