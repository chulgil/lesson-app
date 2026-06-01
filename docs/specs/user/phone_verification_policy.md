# 전화인증 정책 스펙 (Phone Verification Policy)

> 작성일: 2026-06-01
> 상태: 스펙 초안
> 출처: E2E 감사 Top 10 #10 A-C2 — `docs/specs/review/2026-06-01-teacher-e2e/30-gap-catalog.md`
> 관련 이슈: #430
> 관련 스펙: [user_master.md §2 가입 흐름](user_master.md), [teacher_onboarding_v3_spec.md §3 Phase C](../onboarding/teacher_onboarding_v3_spec.md), [subscription/subscription_master.md](../subscription/subscription_master.md)
> 글로서리: [glossary.md §8 인증 선생님 배지](../../.harness/knowledge/glossary.md)

---

## 1. 문제 정의

E2E 감사 정성 입증: 가입 흐름의 첫 단계 = SMS 3분 타이머 마찰. v3 spec §1 자체에서 "전화인증이 첫 단계 → 진입 마찰 큼" 으로 인식했으나 미구현.

### 1.1 현재 결함

| # | 문제 | 영향 |
|---|---|---|
| 1 | SSO 직후 즉시 전화인증 강제 | SMS 인증번호 입력 3분 = 가입 직후 최대 마찰 지점 |
| 2 | 약관 동의가 별도 화면 | SSO + 약관 + 전화인증 = 3단계 누적 마찰 |
| 3 | 전화인증 미완료 시 모든 기능 차단 | 가입~D 단계 자유 사용 불가 → "한 번 보고 그만" |
| 4 | 학부모 측 신뢰 신호 부재 | 인증된 선생님과 미인증 선생님 구분 불가 |

### 1.2 영향 범위 (펀넬)

A 단계 이탈 1순위 (가입 직후 3분 내). 카톡 채널(이미 가입됨)·네이버 카페·숨고(약관만) 대비 진입 마찰 최대.

### 1.3 정량 추정

- SSO → 홈 진입 평균 시간: 현재 추정 180초+ (SMS 타이머 포함)
- 가입 후 24h 내 이탈률: 현재 추정 40%+ (SMS 입력 단계 이탈 다수)

---

## 2. 설계 원칙

> **"가입은 60초 안에. 전화인증은 신뢰가 필요할 때만."**

| 원칙 | 의미 |
|---|---|
| 즉시 진입 | SSO → 약관 1탭 → B 단계(이름·악기) → 홈. 전화인증은 가입 흐름 밖 |
| 보상 유도 | 전화인증 = "인증 선생님 배지" 보상 (Phase C 선택 퀘스트) |
| 신뢰 게이트 | 첫 수강권 발급 직전(E3) 에만 강제. 그 전까지는 자유 사용 |
| 학부모 신호 | 인증 배지가 학부모에게 시각적으로 표시 → 자연스러운 인증 유도 |
| 약관은 1탭 | SSO 단계에서 통합 동의 (별도 화면 X) |

---

## 3. 흐름

### 3.1 신규 흐름 (v3)

```
[A 단계 — 60초 목표]
  SSO (카카오/Apple) ─────────────────┐
                                      │ 약관 통합 동의 1탭
                                      ▼
                                B 단계 (이름·악기) ──────► 홈 진입
                                                              │
                                                              ▼
                                                          [자유 사용]
                                                          (전화인증 없이)
                                                              │
                                                              ▼ Phase C 선택 퀘스트
                                                          전화인증 → 인증 선생님 배지
                                                              │
                                                              ▼
                                                          [E3 진입 직전 게이트]
                                                          미인증 시 차단
                                                          "수강권 발급에는 전화인증이 필요해요"
                                                          [지금 인증하기]
```

### 3.2 기존 흐름 (v1) 와 비교

| 단계 | v1 (현재) | v3 (제안) |
|---|---|---|
| SSO 직후 | 약관 화면 | 약관 1탭 동의 |
| 다음 단계 | 전화인증 (SMS 3분) | 이름·악기 (B 단계) |
| 홈 진입 시간 | 평균 180초+ | < 60초 목표 |
| 전화인증 강제 시점 | 가입 직후 | 첫 수강권 발급 직전 (E3) |

---

## 4. 게이트 정책

### 4.1 인증 없이 가능한 행동

| 행동 | 인증 필요? |
|---|---|
| 홈 진입·탐색 | 불필요 |
| 가용시간 설정 | 불필요 |
| 학생 초대 (D 단계) | 불필요 |
| 첫 레슨 등록 | 불필요 |
| 프로필 편집 | 불필요 |

### 4.2 인증 필요한 행동

| 행동 | 인증 필요? | 게이트 시점 |
|---|---|---|
| 첫 수강권 발급 (E3 진입) | **필수** | "발급" 버튼 탭 시 인증 모달 |
| 수강권 제안 송신 (E1) | 선택 (정책 결정) | 본 스펙: **선택** (E3 까지만 강제) |
| 입금 확인 (E3) | 필수 (E3 게이트 통과 후 자동) | 별도 게이트 없음 |

### 4.3 게이트 UX

E3 진입 직전 미인증 시:

```
┌────────────────────────────────────────┐
│                                        │
│   수강권 발급에는 전화인증이 필요해요    │
│                                        │
│  학부모가 신뢰할 수 있는 선생님임을      │
│  확인하기 위해 본인 인증이 필요합니다.   │
│                                        │
│  인증 완료 시:                          │
│  · 인증 선생님 배지                     │
│  · 학부모 화면에서 신뢰 표시            │
│                                        │
│  ┌──────────────────────────────┐      │
│  │       지금 인증하기            │      │
│  └──────────────────────────────┘      │
│                                        │
│  [나중에 — 수강권 발급 보류]            │
└────────────────────────────────────────┘
```

"나중에" 선택 시 수강권 제안은 `paymentRequested` 상태로 유지되나 발급 단계 불가.

---

## 5. 백엔드 영향

### 5.1 User 엔티티 확장

| 필드 | 타입 | 기본 | 설명 |
|---|---|---|---|
| `phoneVerifiedAt` | `DateTime?` | `null` | 전화인증 완료 시각 |
| `phoneNumber` | `String?` | `null` | 인증된 전화번호 (E.164 형식) |

기존 가입 흐름에서 강제로 받던 전화번호는 `null` 허용으로 전환. 마이그레이션 시 기존 가입자는 `phoneVerifiedAt` 을 가입일로 backfill.

### 5.2 약관 동의 처리

`User.termsAcceptedAt` 필드는 SSO 콜백에서 1탭 동의 시 즉시 기록. 별도 화면 불필요.

### 5.3 게이트 미들웨어

```python
# E3 진입 시점 (수강권 발급 직전)
def require_phone_verification(user: User):
    if user.phone_verified_at is None:
        raise PhoneVerificationRequired(
            message="수강권 발급에는 전화인증이 필요해요",
            action="phone_verification_modal",
        )
```

### 5.4 학부모 측 표시

학부모가 선생님 프로필을 조회할 때:

```dart
// FE
if (teacher.phoneVerifiedAt != null) {
  VerifiedTeacherBadge();  // 체크 아이콘 + "인증 선생님" 라벨
}
```

학생/학부모 검색 결과·프로필·수강권 제안 화면 모두에 배지 노출.

### 5.5 메트릭 이벤트

| 이벤트 | 트리거 | 페이로드 |
|---|---|---|
| `auth.sso_completed` | SSO 콜백 완료 | `userId`, `provider`, `timestamp` |
| `auth.home_entered` | 홈 첫 진입 | `userId`, `timeSinceSSO` |
| `auth.phone_verification_gate_shown` | E3 진입 시 게이트 노출 | `userId`, `subscriptionId` |
| `auth.phone_verification_completed` | 전화인증 완료 | `userId`, `trigger`(quest/gate) |

---

## 6. 측정 기준

| 지표 | 측정 방법 | 목표 |
|---|---|---|
| SSO → 홈 진입 평균 시간 | `auth.home_entered.timeSinceSSO` 중앙값 | < 60초 |
| 가입 후 24h 내 이탈률 | `signup ∧ ¬(24h 내 재진입)` / `signup` | 현재 대비 -30%+ |
| 전화인증 완료율 (가입 후 7일) | `phone_verified_at != null` / `signup` | > 70% |
| Phase C 퀘스트 경로 비율 | `trigger=quest` / `phone_verification_completed` | > 50% (게이트 미도달 자발 인증 유도) |
| 학부모 신뢰 효과 | 인증 vs 미인증 선생님의 수강권 제안 수락률 차이 | 인증 측이 +15%+ |

---

## 7. 구현 범위 (Phase 별)

### Phase 1: 스펙 + 글로서리 (본 작업)

- [x] `phone_verification_policy.md` 신규 작성
- [x] `glossary.md` "인증 선생님 배지" 추가 (이미 §8에 반영)
- [x] `teacher_onboarding_v3_spec.md` §3 Phase C 에 본 스펙 참조 추가 (메인 세션 처리)
- [x] `user_master.md` §2 가입 흐름 갱신 (메인 세션 처리)

### Phase 2: 백엔드 (1주)

- `User.phoneVerifiedAt`, `phoneNumber` 필드 추가 (`null` 허용)
- 기존 가입자 마이그레이션 (`phoneVerifiedAt = signup_date` backfill)
- E3 진입 게이트 미들웨어 (`require_phone_verification`)
- 약관 통합 동의 처리 (SSO 콜백)

### Phase 3: 프론트엔드 (1주)

- 가입 흐름 단축: SSO → 약관 1탭 → B 단계 → 홈
- E3 진입 게이트 모달 (`PhoneVerificationGateModal`)
- Phase C 퀘스트 카드: "전화인증 → 인증 선생님 배지"
- `VerifiedTeacherBadge` 위젯 (검색·프로필·제안 화면)

### Phase 4: 메트릭 + 검증 (1-2일)

- 메트릭 이벤트 4종 발송
- 게이트 통합 테스트 (인증 없이 E3 진입 시 차단 확인)
- 학부모 측 배지 노출 테스트

---

## 8. 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| 1.0 | 2026-06-01 | 초안 — E2E 감사 #10 A-C2 대응 (이슈 #430) |
