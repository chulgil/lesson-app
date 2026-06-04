# academy/parent_referral_spec — 학부모 추천 시스템

> 기준일: 2026-06-04
> 경로: `/settings/referral`, `/referral/leaderboard`
> 마일스톤: AC-M8 (Growth 신규 마일스톤 — 갭분석 권고)
> 선행: [public_page_spec.md](public_page_spec.md), [billing_settlement_spec.md](billing_settlement_spec.md), [student_management_spec.md](student_management_spec.md)
> 갭분석 input: `.harness/research/academy_spec_gap_2026.md` H#8
> 시장조사 input: `.harness/research/academy_market_2026.md` (소규모 음악학원 신규 학생 유입 60-70% 가 "지인 추천")

## 1. 배경 / 범위

소규모 음악학원의 가장 큰 신규 학생 유입 채널은 **현 재학생 학부모 추천** (시장조사). 그러나 현재 스펙은 추적·보상 시스템 부재. 학원장은 "어느 학부모가 누구를 데려왔는지" 수기로 기억 → 보상 누락 또는 자의적 처리 → 신뢰 저하.

**본 스펙 범위:**
- 학부모 추천 코드/링크 발급 + 공유
- 신규 가입 시 추천 코드 입력 + 검증
- 학원장 보상 정책 (추천인 + 신규 학생)
- 보상 자동 적립 (수강료 할인, 보강 크레딧)
- 부정 방지 (다중 계정, 즉시 이탈, 학부모↔본인 자녀)
- 추천 ROI 분석 / 학부모 랭킹

**경계:**
- 보상은 **수강권 할인 / 보강 크레딧 / 학원 자체 굿즈** 등 학원 내부 자산만. 현금/포인트 환급 X (정책)
- 학원장이 추천 시스템을 끄거나 보상 정책을 조정할 수 있음 (전체 학원 토글)

## 2. 데이터 모델

```python
class AcademyReferralProgram(Base):
    """학원 단위 추천 프로그램 설정 (1 학원 = 1 행)."""
    academy_id = Column(FK, PK)
    enabled = Column(Boolean, default=False)
    referrer_reward_type = Column(Enum(
        "subscription_discount",   # 수강권 할인 (₩)
        "subscription_discount_pct", # 수강권 할인 (%)
        "makeup_credit",           # 보강 크레딧 N회
        "goods",                   # 학원 자체 굿즈 (선택)
    ))
    referrer_reward_value = Column(Integer)              # 할인액 / %  / 횟수
    referrer_reward_max_count = Column(Integer, default=12)  # 학부모당 연간 최대 보상 횟수
    referee_reward_type = Column(Enum(
        "first_month_discount",    # 첫 달 할인 (₩)
        "first_month_discount_pct",
        "free_trial_extension",    # 무료 체험 연장 (회)
        "none",                    # 신규 학생 보상 없음
    ))
    referee_reward_value = Column(Integer, default=0)
    verification_days = Column(Integer, default=30)      # 신규 학생 등록 후 N일 유지 → 보상 확정
    min_invoice_count = Column(Integer, default=1)       # 신규 학생 N회 청구 발생 후 보상
    fraud_check_enabled = Column(Boolean, default=True)
    created_at = Column(DateTime)
    updated_at = Column(DateTime)


class AcademyReferralCode(Base):
    """학부모별 추천 코드. 학부모당 영구 1개."""
    id = Column(PK)
    academy_id = Column(FK)
    referrer_user_id = Column(FK users)                  # 학부모
    code = Column(String, unique=True)                   # 예: "PIANO-KIM-7A2X"
    share_url = Column(String)                           # https://academy.lessonaza.app/{slug}?ref={code}
    issued_at = Column(DateTime)
    state = Column(Enum("active", "revoked"), default="active")
    revoked_reason = Column(String, nullable=True)


class AcademyReferral(Base):
    """추천 1건 = referrer ↔ referee 매핑."""
    id = Column(PK)
    academy_id = Column(FK)
    referrer_user_id = Column(FK users)                  # 추천한 학부모
    referee_user_id = Column(FK users)                   # 추천받아 가입한 학부모
    referee_student_id = Column(FK academy_students)
    code_used = Column(String)                           # 사용된 코드 (audit)
    referred_at = Column(DateTime)                       # 코드 입력 시각
    state = Column(Enum(
        "pending",      # 코드 입력됨, 검증 대기 (verification_days 내)
        "verified",     # 등록 유지 + 청구 발생 → 보상 확정
        "rewarded",     # 보상 지급 완료
        "rejected",     # 부정 / 즉시 이탈 / 학원장 거절
    ))
    verified_at = Column(DateTime, nullable=True)
    rewarded_at = Column(DateTime, nullable=True)
    rejected_reason = Column(Enum(
        "referee_left_within_verification",
        "same_household",            # 동일 가구 (부모-자녀, 형제)
        "duplicate_phone",
        "owner_rejected",
        "fraud_suspected",
    ), nullable=True)
    fraud_score = Column(Integer, default=0)             # 0-100
    fraud_signals = Column(JSON)


class AcademyReferralReward(Base):
    """지급된 보상 (audit)."""
    id = Column(PK)
    referral_id = Column(FK)
    recipient_type = Column(Enum("referrer", "referee"))
    recipient_user_id = Column(FK users)
    reward_type = Column(String)                          # subscription_discount 등
    reward_value = Column(Integer)
    applied_to_invoice_id = Column(FK academy_invoices, nullable=True)  # 할인 적용된 청구서
    applied_to_credit_id = Column(FK makeup_credits, nullable=True)
    issued_at = Column(DateTime)
    expires_at = Column(DateTime, nullable=True)         # 일부 보상은 유효기간 있음
```

## 3. 추천 코드 발급 + 공유

### 3.1 학부모 코드 발급

학부모가 lesson-app 학원 페이지 진입 시 "추천 코드" 메뉴 (학원이 referral_program.enabled=true 일 때만 노출).

```
┌──────────────────────────────────────────────┐
│ 친구에게 우리 학원 소개하기                  │
├──────────────────────────────────────────────┤
│ 내 코드: PIANO-KIM-7A2X                     │
│                                              │
│ [공유하기 ▼]                                 │
│   ▸ 카톡으로 보내기                         │
│   ▸ 링크 복사                                │
│   ▸ QR 다운로드                              │
│                                              │
│ 추천 보상:                                   │
│ • 추천 성공 시 다음 달 수강권 1만원 할인    │
│ • 친구는 첫 달 1만원 할인                   │
│                                              │
│ 이번 해 추천: 2명 / 12명 (최대)              │
└──────────────────────────────────────────────┘
```

### 3.2 코드 형식

`{INSTRUMENT_HINT}-{FAMILY_NAME}-{HASH}` 예: `PIANO-KIM-7A2X`. 사람이 입력 가능한 길이 (8-16자). 영문+숫자 (헷갈리는 O, 0, I, l 제외).

### 3.3 공유 채널 가시화

학부모가 어떤 채널로 공유했는지 추적 (UTM 호환):
- `?ref={code}&via=kakao` → 카톡 공유
- `?ref={code}&via=link` → 링크 복사
- `?ref={code}&via=qr` → QR 코드

추적은 §6 분석에서 활용.

## 4. 신규 가입 시 코드 입력

### 4.1 학원 공개 페이지

`academy.lessonaza.app/{slug}` 가입 폼:

```
┌──────────────────────────────────────────────┐
│ 학원 등록 문의                              │
├──────────────────────────────────────────────┤
│ 자녀명: [           ]                        │
│ 학부모명: [           ]                      │
│ 연락처: [           ]                        │
│ 악기: [▼ 피아노]                            │
│                                              │
│ 추천 코드 (선택): [PIANO-KIM-7A2X    ]      │
│ ↑ 친구 추천 받았다면 입력. 신규 가입자도   │
│   첫 달 1만원 할인 혜택을 받습니다.         │
│                                              │
│        [등록 문의 보내기]                    │
└──────────────────────────────────────────────┘
```

URL 의 `?ref={code}` 가 있으면 코드 필드 자동 채움 + 안내 강조.

### 4.2 코드 검증

```
POST /api/v1/public/academies/{slug}/referral/validate
{ code }

응답:
- 200 { valid: true, referrer_name: "김지민 어머니" }  # PII 부분 노출 (성씨만)
- 404 { valid: false, reason: "code_not_found" }
- 400 { valid: false, reason: "code_revoked" }
```

부정 방지 (실시간):
- 동일 IP 에서 같은 코드 5분 내 3번 검증 → temporary block (429)
- 코드 사용 횟수가 학원 정책 limit 초과 → "이번 달 추천 가득 찼습니다" (referrer 보호)

### 4.3 가입 처리 → AcademyReferral 행 생성

학부모 가입 + 학생 등록 완료 후 `AcademyReferral` 행 (state='pending') 생성. verification_days 카운트다운 시작.

## 5. 검증 + 보상 지급

### 5.1 검증 트리거 (cron 매일 01:00 KST)

```python
def verify_pending_referrals():
    """verification_days 경과 + min_invoice_count 충족 → state='verified'"""
    for referral in db.query(AcademyReferral).filter(state='pending'):
        program = get_program(referral.academy_id)

        # 1. 시간 검증
        if (now - referral.referred_at).days < program.verification_days:
            continue

        # 2. 학생 유지 검증
        student = db.get(AcademyStudent, referral.referee_student_id)
        if student.status in ('alumni', 'paused'):
            referral.state = 'rejected'
            referral.rejected_reason = 'referee_left_within_verification'
            continue

        # 3. 청구 발생 검증
        invoice_count = db.query(AcademyInvoice).filter(
            academy_student_id=referral.referee_student_id,
            status='paid',
        ).count()
        if invoice_count < program.min_invoice_count:
            continue

        # 4. 부정 검증
        fraud_score = compute_fraud_score(referral)
        if fraud_score >= 70:
            referral.state = 'rejected'
            referral.rejected_reason = 'fraud_suspected'
            referral.fraud_score = fraud_score
            notify_owner_fraud(referral)
            continue

        # 5. verified
        referral.state = 'verified'
        referral.verified_at = now
        queue_reward_issuance(referral)
```

### 5.2 보상 자동 지급 (verified → rewarded)

```
1. referrer (추천한 학부모):
   - subscription_discount: 다음 청구서에 자동 차감 (AcademyInvoice.discount_amount 추가)
   - makeup_credit: MakeupCredit 행 생성 (reason='referral_reward', source_event_id=referral.id)

2. referee (추천받은 학부모):
   - first_month_discount: 첫 청구서에 자동 차감
   - free_trial_extension: 무료 체험 회수 증가

3. AcademyReferralReward 행 생성 (audit)
4. state='rewarded', rewarded_at
5. 양쪽에 카톡 알림 (LNZ_REFERRAL_REWARDED)
```

### 5.3 학원장 수동 개입

학원장이 `/settings/referral/pending` 에서 pending/verified 행 검토 가능:
- 강제 승인 (verification_days 단축)
- 강제 거절 (suspect 행 → rejected 마킹 + 사유)
- 보상 조정 (특정 추천에 추가 보상)

모든 수동 개입은 `AuditLog` (학원장 user_id, action, reason).

## 6. 부정 방지

### 6.1 부정 신호 (fraud_score 합산, 0-100)

| 신호 | 점수 | 검출 |
|---|---|---|
| 동일 연락처 prefix (010-1234-XXXX) | +30 | referrer.phone[:8] == referee.phone[:8] |
| 동일 주소 | +25 | referrer.address == referee.address |
| 학부모 성씨 동일 + 자녀 성씨 동일 | +15 | 가족 추천 의심 |
| 가입 후 즉시 이탈 (verification_days 내) | +40 | referee.status='alumni' |
| referrer 가 같은 달 5명+ 추천 | +20 | 비정상 패턴 |
| 코드 검증 후 30일 내 가입 (정상 흐름은 1-2주) | -10 (정상 시그널, 감점) | |
| referee 의 첫 청구 미납 | +20 | 가입만 하고 결제 안 함 |

fraud_score ≥ 70 → 자동 rejected + 학원장 알림. 50-69 → 학원장 검토 큐.

### 6.2 동일 가구 보호

`AcademyStudent.parent_user_id` 가 같으면 자동 same_household 거절 (자기 자녀 추천 차단).

### 6.3 학원장 신뢰 정책 override

학원장이 "이 학부모는 신뢰" 토글 → fraud_score 가산 무시. (예: 학원장 본인의 동생이 학원장의 자녀 학원에 등록 — 정상 시나리오)

## 7. 학원장 화면

### 7.1 추천 프로그램 설정 (`/settings/referral`)

```
┌──────────────────────────────────────────────────┐
│ 추천 프로그램                                    │
├──────────────────────────────────────────────────┤
│ 활성화 [ON ⚪]                                   │
│                                                  │
│ 추천인 보상:                                     │
│   종류: [▼ 수강권 할인 (정액)]                  │
│   금액: [10000] 원                              │
│   학부모당 연간 최대: [12] 회                   │
│                                                  │
│ 신규 학생 보상:                                  │
│   종류: [▼ 첫 달 할인]                          │
│   금액: [10000] 원                              │
│                                                  │
│ 검증 조건:                                       │
│   등록 후 [30] 일 유지                          │
│   최소 [1] 회 청구 + 수금 완료                  │
│                                                  │
│ 부정 방지: [ON ⚪]  [검토 큐 ⚙]                │
│                                                  │
│         [정책 변경 저장]                        │
└──────────────────────────────────────────────────┘
```

정책 변경 시 기존 pending 추천은 변경 전 정책 적용 (소급 금지).

### 7.2 추천 현황 화면 (`/referral`)

```
┌────────────────────────────────────────────────────┐
│ 추천 현황 (2026)                                  │
├────────────────────────────────────────────────────┤
│ 이번 해 추천 가입: 18명 (지난해 12명, +50%)       │
│ 지급된 보상 합계: ₩540,000                        │
│ 추천 학부모 활성: 8명 (전체 학부모의 12%)         │
├────────────────────────────────────────────────────┤
│ 학부모 랭킹 (이번 해):                            │
│ 1. 김지민 어머니   5명 추천   ₩150,000 보상      │
│ 2. 이지수 아버지   3명 추천   ₩90,000           │
│ 3. 박지호 어머니   2명 추천   ₩60,000           │
│                                                    │
│ [학부모에게 감사 인사 보내기 →]                   │
├────────────────────────────────────────────────────┤
│ 검토 대기: 2건                                    │
│ • 박학부모 → 김학부모 (fraud_score 55, 검토)     │
│ • 이학부모 → 한학부모 (검증 진행 D-5)            │
└────────────────────────────────────────────────────┘
```

### 7.3 학부모에게 감사 인사 (수기)

학원장이 상위 추천 학부모에게 카톡 알림톡 발송 (수기 트리거):
- `LNZ_REFERRAL_THANKS` 템플릿
- 본문: "{owner} 학원장입니다. 지난해 {count} 분을 추천해 주셔서 정말 감사합니다."

## 8. ROI 분석

`/referral/analytics`:

- 추천 학생 vs 비추천 학생 평균 LTV (retention 비교)
- 추천 → verified 전환률 (학원 평균 / 학부모별)
- 채널별 (kakao / link / qr) 효율
- 추천 후 검증 기간 단축 가능성 분석

학원장 의사결정용:
- "추천 학생이 LTV 1.5배 높음 → 보상 인상 검토"
- "QR 채널 전환율 가장 높음 → QR 인쇄물 비치"

## 9. 알림 / 카톡 템플릿

| 템플릿 | 시점 | 본문 |
|---|---|---|
| `LNZ_REFERRAL_CODE_ISSUED` | 코드 발급 | "[Lessonaza] 추천 코드 발급. 친구에게 공유 → 보상 받기" |
| `LNZ_REFERRAL_PENDING` | 신규 가입 코드 입력 시 referrer 에게 | "{academy} 에 {referee} 가입. 등록 유지 시 D-30 후 보상 지급" |
| `LNZ_REFERRAL_REWARDED` | 보상 지급 시 양쪽 | 추천인: "보상 적용됨", 신규: "첫 달 할인 적용됨" |
| `LNZ_REFERRAL_REJECTED` | rejected 시 referrer | "추천 보상이 적용되지 않았습니다. ({사유 요약})" |
| `LNZ_REFERRAL_THANKS` | 학원장 수기 발송 | 상위 추천 학부모 감사 인사 |

## 10. 권한 / 보안

- 추천 프로그램 설정: `Depends(current_academy_owner)`
- 코드 발급/조회: 학부모 본인 (`Depends(current_parent)`) + academy_id 검증
- 검증/보상 지급: 시스템 (cron) — `Depends(current_internal_api_key)`
- 분석 화면: 학원장 전용 + AuditLog
- 학부모 PII 노출: 추천 화면에서 다른 학부모는 성씨만 (`김지민 어머니` → `김** 어머니`)

## 11. 비기능

- 코드 검증 < 200ms (공개 페이지 가입 폼 응답성)
- 보상 지급 cron: 학부모 1만 명 학원 < 1분
- fraud_score 계산: 학생당 < 50ms

## 12. 실패 / 예외

| 상황 | 처리 |
|---|---|
| 코드 입력 시 학원 추천 비활성 | "이 학원은 추천 프로그램이 없습니다" 안내 |
| 보상 적용할 청구서 없음 (다음 달까지 청구 없을 경우) | 보상 carry — 첫 청구 발생 시 자동 적용 |
| referrer 가 학원 떠난 후 보상 지급 시점 | 보상 carry 옵션 또는 학원장 결정 (정책 토글) |
| 동일 학부모에 보상 중복 (같은 청구서) | 가장 큰 보상 1개만 적용 + audit |
| 학원장이 추천 프로그램 비활성 후 pending | 변경 시점 기준 정책으로 보상 (소급 거절 금지) |

## 13. 변경 이력

- 2026-06-04: 초안 (갭분석 H#8 응답 + 시장조사 "지인 추천 60-70%" 응답. 추천 코드 발급/공유/검증 + 학원장 보상 정책 토글 + fraud 7신호 + 동일 가구 보호 + 학부모 랭킹 + ROI 분석. 현금/포인트 환급 금지, 학원 내부 자산만)
