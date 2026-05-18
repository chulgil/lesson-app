# 선생님 추천 시스템 스펙

> 작성일: 2026-05-18
> 상태: 활성 (마스터 SSOT)
> 우선: 🟠 HIGH (출시 후 3개월)
> 관련: [invite_system_v2.md](./invite_system_v2.md), [paywall_spec.md](../../subscription/paywall_spec.md)

---

## 0. 개요

**선생님 → 선생님** 추천 루프. 기존 초대 시스템(`invite_system_v2.md`)은 선생님→학생 단방향이라 바이럴 계수 제한적. 본 스펙은 **B2B 바이럴**을 위한 추가 채널.

---

## 1. 현황 진단

| 항목 | 상태 |
|------|------|
| 학생 초대 시스템 | ✅ `invite_system_v2.md` |
| 학부모 초대 | ✅ 동일 시스템 |
| **선생님 → 선생님 추천** | ❌ 없음 |
| `referral_code` 필드 | ❌ |
| `TeacherReferral` 엔티티 | ❌ |

---

## 2. 도메인 모델

### 2.1 `User` 필드 추가

```python
class User(Base):
    # ... 기존 ...
    referral_code: str | None  # 8자리 영숫자 (선생님만), 본인 추천 코드
    referred_by_code: str | None  # 가입 시 사용한 추천 코드
```

`referral_code`는 선생님 회원가입 시 자동 생성. 학생/학부모는 미생성 (선생님 전용 보상 채널).

### 2.2 `TeacherReferral` 엔티티 (신규)

```python
class TeacherReferral(Base):
    id: int
    referrer_id: int (FK User)
    referred_id: int (FK User)  # 가입 완료 시 채워짐
    referral_code: str  # 사용된 코드
    invited_at: datetime  # 추천 코드 발급/공유 시점
    accepted_at: datetime | None  # 피추천자 가입 시점 = 보상 지급 시점
    reward_type: str = "pro_1_week_free"
    status: str  # "pending" | "rewarded" | "blocked"  # blocked = 어뷰징 감지
```

가입 즉시 양쪽에 Pro 1주가 지급된다. 어뷰징 방지는 §3.5 참조.

---

## 3. 흐름

### 3.1 추천 코드 공유

```
선생님 홈 → "동료 선생님 초대"
  ↓
공유 화면:
  - 추천 코드: ABCD1234 (복사 버튼)
  - 공유 링크: lessonaza.com/r/ABCD1234
  - 카카오톡 / 인스타 / 링크 복사 / QR
```

### 3.2 가입 흐름 (피추천자)

```
공유 링크 클릭
  ↓
앱 설치 후 첫 실행 → 딥링크에서 referral_code 추출
  ↓
회원가입 화면 → "추천인 코드" 필드에 자동 입력 (수정 가능)
  ↓
가입 완료 → TeacherReferral.accepted_at 갱신
```

웹 진입 시 referral_code를 `localStorage` 또는 `Branch.io` 등 deferred deep link로 보관 → 앱 설치 후 첫 실행 시 회수.

### 3.3 보상 (단일 단계)

| 트리거 | 양쪽 보상 |
|--------|----------|
| 피추천자 가입 완료 (`accepted_at` 채워짐) | ✅ 추천자 + 피추천자 각각 **Pro 1주 무료** (기존 구독에 적층) |

가입 즉시 양쪽에 보상. 인지 부담을 최소화해 추천 전환율을 높인다. 어뷰징은 §3.4로 차단.

### 3.4 어뷰징 방지

| 규칙 | 검출 | 처리 |
|------|------|------|
| 동일 디바이스 셀프 추천 | `device_id` 비교 (가입자 + 추천자 일치) | `status=blocked`, 보상 미지급 |
| 동일 IP 대량 가입 | 가입 IP 24시간 내 5건 이상 | 6번째부터 `status=blocked` |
| 추천 횟수 상한 | 추천자당 **월 20명, 분기 50명** | 한도 도달 시 추천 코드 일시 비활성 |
| 가입 후 7일 내 탈퇴 | 피추천자 빠른 탈퇴 = 어뷰징 의심 | 추천자 보상 회수 (Pro 1주 잔여기간 차감) |

---

## 4. UI

### 4.1 진입점

| 위치 | CTA |
|------|-----|
| 선생님 홈 대시보드 (사이드 카드) | "동료 선생님 초대하고 Pro 받기" |
| 프로필 → 보상 | "내 추천 현황" |
| 설정 → 동료 초대 | 영구 진입점 |

### 4.2 추천 현황 화면

```
┌──────────────────────────────────┐
│ 내 추천 현황                       │
├──────────────────────────────────┤
│ 보낸 초대: 12명                    │
│ 가입 완료: 5명                     │
│ 받은 보상: Pro 5주                 │
├──────────────────────────────────┤
│ 김선생님 — 4/2 가입 (Pro 1주 +)    │
│ 박선생님 — 5/10 가입 (Pro 1주 +)   │
│ 이선생님 — 5/15 가입 (Pro 1주 +)   │
└──────────────────────────────────┘
```

### 4.3 보상 알림

가입 즉시 인앱 + 푸시:
- 추천자: "🎉 김선생님이 가입했어요! Pro 1주가 추가되었어요."
- 피추천자 (가입 직후): "환영 선물 — Pro 1주를 받으셨어요."

---

## 5. 백엔드 API

```
GET  /api/v1/teacher/referral/me            # 본인 코드 + 현황
POST /api/v1/teacher/referral/share         # 공유 채널 기록 (analytics)
GET  /api/v1/teacher/referral/list          # 추천 목록
POST /api/v1/auth/signup                    # 기존 + referral_code 파라미터
```

---

## 6. 마케팅 채널

| 채널 | 메시지 |
|------|--------|
| 카카오 | "친한 선생님께 Lessonaza를 추천하고 Pro 1주를 받으세요" |
| 인스타 스토리 | QR + 추천 코드 이미지 |
| URL | `lessonaza.com/r/{code}` |
| 명함 인쇄 | 본인 코드 + QR |

---

## 7. AppStrings 키

| 키 | 한국어 |
|----|--------|
| `referralTitle` | 동료 선생님 초대 |
| `referralSubtitle` | 추천 코드로 Pro 1주를 받으세요 |
| `referralCodeLabel` | 내 추천 코드 |
| `referralShareCta` | 추천 코드 공유하기 |
| `referralRewardEarnedTitle` | 보상 받았어요! |
| `referralRewardEarnedBody` | {name} 선생님이 가입했어요. Pro 1주가 추가되었어요 |
| `referralStatusSignedUp` | 가입 완료 |
| `referralStatusBlocked` | 어뷰징 감지 (보상 미지급) |
| `referralLimitReached` | 이번 달 추천 한도(20명)에 도달했어요 |
| `referralRewardWelcome` | 환영 선물 — Pro 1주를 받으셨어요 |

---

## 8. event_tracking 연동

- `invite_shared` 이벤트의 `channel`에 `referral_kakao`/`referral_qr` 추가
- 신규 이벤트: `referral_rewarded` (가입 직후 보상 지급), `referral_blocked` (어뷰징 감지)

---

## 9. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-18 | 3단계 보상 (가입/자격/전환) 초안 | 어뷰징 방지 + B2B 추천 신중함 가정 |
| 2026-05-18 | **단일 보상으로 단순화 (가입 즉시 Pro 1주 양쪽)** | UX/기획 재검증 결과 4단계 룰의 인지 부담 > 어뷰징 비용. "왜 가입했는데 보상 안 와요?" 컴플레인 회피. 어뷰징은 device_id/IP/한도/7일 회수로 차단 |
| 2026-05-18 | Pro 1개월 → Pro 1주로 축소 | 단일 보상으로 빈도↑ 가능 → 단위 보상은 작게. LTV 보호 |
| 2026-05-18 | 추천자 한도 (월 20명, 분기 50명) | 스팸 방지 |
| 2026-05-18 | 선생님 전용 (학생/학부모 referral_code X) | 학생 추천은 invite_system_v2 채널이 충분 |

---

## 10. 관련 문서

- [invite_system_v2.md](./invite_system_v2.md) — 학생/학부모 초대 (별도 시스템)
- [paywall_spec.md](../../subscription/paywall_spec.md) — Pro 보상 적용 흐름
- [seo_landing_spec.md](../../growth/seo_landing_spec.md) — `lessonaza.com/r/{code}` 랜딩
- [event_tracking_spec.md](../../analytics/event_tracking_spec.md) — referral 이벤트
