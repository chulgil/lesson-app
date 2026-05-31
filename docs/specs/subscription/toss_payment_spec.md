# Toss Payments PG 연동 스펙

> 작성일: 2026-05-31
> 상태: **폐기 (정책 위반)** — 아래 사유 참조
> 관련: [payment_architecture.md](./payment_architecture.md) — 현행 무통장입금 정책 SSOT
> 관련: [subscription_master.md](./subscription_master.md) — 수강권 시스템
> 관련: [payment_receipt_spec.md](./payment_receipt_spec.md) — 영수증 스펙
>
> ## ⚠️ 폐기 사유 (2026-05-31)
>
> **이 스펙은 "선생님-학생 수강료를 PG로 결제"하는 내용으로 작성되었으나,
> Lessonaza 정책에 위반됩니다.**
>
> | 정책 | 내용 |
> |------|------|
> | **수강료 흐름** | 선생님/학원 ↔ 학생/학부모 간 수강료는 **앱 밖**(무통장입금/현금)에서 처리. 앱은 수강권 상태만 기록 |
> | **앱 과금 모델** | Lessonaza는 **사용자(선생님/학원)에게만 앱 사용료를 과금** (B2B SaaS 모델) |
> | **PG 용도** | 향후 PG가 필요하면 "앱 사용료 과금" 전용으로 별도 스펙 작성 |
>
> 아래 본문은 참고 자료로만 보존합니다. 구현 대상이 아닙니다.
>
> ---

---

## 목차

1. [개요](#1-개요)
2. [범위 경계](#2-범위-경계)
3. [정책 설계](#3-정책-설계)
4. [결제 흐름](#4-결제-흐름)
5. [백엔드 설계](#5-백엔드-설계)
6. [프론트엔드 설계](#6-프론트엔드-설계)
7. [보안](#7-보안)
8. [테스트 계획](#8-테스트-계획)
9. [비용 분석](#9-비용-분석)
10. [구현 단계](#10-구현-단계)
11. [의사결정 로그](#11-의사결정-로그)
12. [관련 스펙 / 변경 이력](#12-관련-스펙--변경-이력)

---

## 1. 개요

### 1.1 배경

Lessonaza는 현재 **무통장입금**만 지원한다. 이 방식은 다음 불편을 야기한다:

| 역할 | 불편 |
|------|------|
| 선생님 | 매월 학생별 입금 여부를 통장에서 직접 확인해야 함 / 미입금 학생에게 독촉 연락 |
| 학생/학부모 | 매달 은행 앱 열어서 계좌번호 복사 후 이체 / 이체 후 앱에서 별도로 "입금 완료" 알림 전송 |

**PG(Payment Gateway) 연동**을 추가하면:
- 학생/학부모가 앱 안에서 카드·간편결제로 즉시 결제
- 결제 성공 시 수강권이 **자동 발급** (선생님 확인 불필요)
- 정기 결제로 매월 자동 갱신 가능

### 1.2 Toss Payments 선택 이유

| 기준 | 내용 |
|------|------|
| 한국 시장 점유율 | 국내 간편결제 1위 (2025 기준), 개인사업자·프리랜서 계약 가능 |
| 개인사업자 지원 | 개인 과외 선생님(개인사업자 또는 사업자등록 없는 프리랜서)도 가맹점 가입 가능 |
| SDK 완성도 | Flutter WebView 연동 레퍼런스 다수, 공식 문서 양질 |
| 빌링(정기결제) | 카드 자동이체 API 제공 (`/v1/billing`) |
| 테스트 모드 | 별도 테스트 키로 실결제 없이 전 흐름 검증 가능 |

### 1.3 지원 결제 수단

| 결제 수단 | 설명 |
|----------|------|
| 신용/체크카드 | 국내 모든 카드사 |
| 카카오페이 | 간편결제 |
| 네이버페이 | 간편결제 |
| 토스페이 | 간편결제 |
| 계좌이체 | 실시간 계좌이체 |
| 가상계좌 | 무통장입금 자동화 (입금 감지 → 웹훅) |

> **가상계좌**는 기존 무통장입금 워크플로우를 자동화하는 방식으로,
> PG 도입 초기 선생님 저항을 줄이는 브릿지 전략으로 활용할 수 있다.

---

## 2. 범위 경계

### 2.1 포함 (In Scope)

| 항목 | 설명 |
|------|------|
| 학생/학부모 → 선생님 수강료 결제 | 수강권 제안 수락 후 PG 결제 |
| 선생님 PG 활성화 설정 | 선생님이 선택적으로 온라인 결제 활성화 |
| 선생님 정산 계좌 연결 | Toss 가맹점 등록 후 정산 계좌 설정 |
| 수강권 자동 발급 | 결제 성공 웹훅 수신 후 자동 처리 |
| 정기 결제 (빌링) | 학생이 카드 등록 후 매월 자동 결제 |
| 환불 | 미사용 또는 부분 사용 수강권 환불 |
| 영수증 자동 생성 | 결제 성공 시 [payment_receipt_spec.md](./payment_receipt_spec.md) 흐름 연동 |

### 2.2 제외 (Out of Scope)

| 항목 | 근거 |
|------|------|
| **앱 사용료(B2B) 과금** | [payment_architecture.md](./payment_architecture.md) §3 — 별도 스펙에서 정의 |
| **Lessonaza 플랫폼 수수료 정산** | 초기에는 0%. 도입 시 별도 스펙 |
| **에스크로** | 현행 정책 범위 밖 |
| **세금계산서 / 현금영수증 법적 발행** | 앱 발행 문서는 내부 영수증에 한함 |
| **인앱결제 (App Store / Google Play)** | 앱 사용료 과금 확정 시 별도 검토 |
| **해외 결제 수단** | 국내 사용자 한정 |

> **핵심 경계**: 이 스펙은 [payment_architecture.md](./payment_architecture.md)의 **흐름 A** (선생님 ↔ 학생/학부모 수강료)에 PG 결제를 추가하는 것이다. 흐름 B(앱 사용료)와 혼용하지 않는다.

---

## 3. 정책 설계

### 3.1 선생님 선택 모델 (Opt-in)

**기존 무통장입금은 기본값으로 유지**하고, PG 결제는 선생님이 명시적으로 활성화해야 한다.

```
[결제 방식 선택]
무통장입금 (기본, 항상 사용 가능)
    ↕
온라인 결제 (선생님이 설정에서 활성화)
    → Toss 가맹점 등록 필요
    → 정산 계좌 설정 필요
```

| 상태 | 학생/학부모 화면 |
|------|---------------|
| PG 비활성화 (기본) | 무통장입금 안내만 표시 |
| PG 활성화 | 무통장입금 + 온라인 결제 중 선택 |

### 3.2 가맹점 등록 요건

Toss Payments 가맹점 가입 시 선생님 유형별 요건:

| 선생님 유형 | 가입 유형 | 필요 서류 |
|-----------|----------|----------|
| 사업자등록 없는 개인 | 개인 가맹점 | 신분증, 계좌 |
| 사업자등록 보유 | 개인사업자 가맹점 | 사업자등록증, 신분증, 계좌 |
| 학원 운영 | 법인/개인사업자 가맹점 | 사업자등록증, 법인서류(법인의 경우) |

> Lessonaza 앱 내에서 가맹점 등록 처리를 하지 않는다.
> 선생님이 Toss Payments 사이트에서 직접 가맹점 등록 후, 앱에서 API 키만 연결한다.

### 3.3 수수료 정책

#### Toss Payments 기본 수수료율 (2025년 기준)

| 결제 수단 | 수수료율 | 비고 |
|----------|---------|------|
| 신용카드 | 1.5% ~ 3.3% | 카드사별 상이. 개인사업자 기본 3.3% |
| 체크카드 | 1.0% ~ 2.0% | |
| 카카오페이 | 2.5% | 간편결제 |
| 네이버페이 | 2.5% | 간편결제 |
| 토스페이 | 1.8% | 간편결제 |
| 실시간 계좌이체 | 1.0% ~ 1.5% | |
| 가상계좌 | 건당 300원 | 발급 건당 고정 |

> 실제 수수료는 가맹점 유형, 거래 규모, 계약 조건에 따라 다름.
> Toss Payments 가맹점 계약 시 확정.

#### 수수료 부담 선택

선생님이 설정에서 결정:

| 옵션 | 설명 | 학생 화면 |
|------|------|---------|
| 선생님 부담 | 수강료에서 수수료 차감 후 정산 수령 | "수강료: 100,000원" |
| 학생 부담 | 수강료에 수수료 추가 청구 | "수강료: 100,000원 + 결제 수수료: 3,300원" |

### 3.4 환불 정책

| 상황 | 환불 금액 | 처리 방식 |
|------|---------|---------|
| 수강권 전혀 미사용 | 결제 금액 전액 | Toss API 전체 취소 |
| 수강권 일부 사용 | 잔여 회차 × 1회 단가 | Toss API 부분 취소 |
| 결제일로부터 3개월 초과 | Toss 정책에 따라 불가 또는 제한 | 별도 협의 |

환불 수수료:
- 결제 취소(전액): Toss 수수료 환급 (선생님 부담 수수료인 경우)
- 부분 취소: 취소 금액 비율만큼 수수료 정산 조정

---

## 4. 결제 흐름

### 4.1 일반 결제 (수강권 제안 → 결제)

```
선생님: 수강권 제안 전송
    ↓
학생/학부모: 제안 수락
    ↓
결제 안내 화면 표시
    ├─ [무통장입금] → 기존 흐름 유지
    └─ [온라인 결제] → Toss 결제 위젯 (WebView)
           ↓
    결제 수단 선택 (카드/간편결제/계좌이체)
           ↓
    결제 완료 → 딥링크로 앱 복귀
           ↓
    백엔드: POST /payments/confirm (결제 승인)
           ↓
    Toss: 결제 성공 웹훅 → POST /webhooks/toss
           ↓
    수강권 자동 발급 (paymentConfirmed = true)
           ↓
    영수증 자동 생성 (payment_receipt_spec.md 흐름)
           ↓
    선생님/학생 푸시 알림 발송
```

### 4.2 가상계좌 결제 흐름

```
학생/학부모: 가상계좌 선택
    ↓
Toss: 가상계좌 발급 (은행별 고유 계좌번호)
    ↓
학생/학부모: 외부 은행 앱에서 입금
    ↓
Toss: 입금 감지 → 웹훅 전송 POST /webhooks/toss
    ↓
백엔드: 수강권 자동 발급
    ↓
기존 무통장입금과 동일한 영수증 발행
```

> 가상계좌는 기존 무통장입금 경험을 유지하면서 입금 감지를 자동화한다.
> 선생님이 직접 통장 확인하는 과정이 사라진다.

### 4.3 정기 결제 (자동 빌링)

```
[카드 등록 단계 — 최초 1회]
학생/학부모: 카드 등록 → Toss 빌링 위젯 (WebView)
    ↓
Toss: 카드 인증 → billingKey 발급
    ↓
백엔드: billingKey 저장 (PaymentMethod 테이블)

[자동 결제 단계 — 매월]
백엔드 스케줄러: 매월 N일 자동 실행
    ↓
Toss API: POST /v1/billing/{billingKey} (자동 결제 요청)
    ↓
결제 성공 → 수강권 자동 갱신
    ↓
영수증 자동 생성 + 알림 발송

[결제 실패 처리]
결제 실패 → 다음 날 재시도 (최대 3회)
    ↓
3회 모두 실패 → 선생님 + 학생 알림 발송
    ↓
수동 입금 안내 또는 카드 변경 요청
```

### 4.4 환불 흐름

```
선생님: 환불 요청 (앱 내 수강권 관리 화면)
    ↓
백엔드: 잔여 회차 계산 → 환불 금액 산정
    ↓
Toss API: POST /v1/payments/{paymentKey}/cancel
    ↓
환불 완료 → 수강권 상태 변경 (cancelled)
    ↓
영수증 취소 기록 생성
    ↓
선생님 + 학생 알림 발송
```

---

## 5. 백엔드 설계

### 5.1 환경 변수

```
TOSS_CLIENT_KEY=test_ck_...   # 프론트엔드용 (공개)
TOSS_SECRET_KEY=test_sk_...   # 백엔드 전용 (비밀)
TOSS_WEBHOOK_SECRET=...       # 웹훅 서명 검증용
```

> Secret Key는 절대 프론트엔드 코드에 포함하지 않는다.
> 백엔드 `.env` 파일에만 저장하며 git에는 커밋하지 않는다.

### 5.2 Toss Payments API 엔드포인트

| 용도 | 메서드 | 엔드포인트 |
|------|--------|-----------|
| 결제 승인 | POST | `https://api.tosspayments.com/v1/payments/confirm` |
| 결제 조회 | GET | `https://api.tosspayments.com/v1/payments/{paymentKey}` |
| 주문 ID로 결제 조회 | GET | `https://api.tosspayments.com/v1/payments/orders/{orderId}` |
| 결제 취소 (환불) | POST | `https://api.tosspayments.com/v1/payments/{paymentKey}/cancel` |
| 빌링키 발급 | POST | `https://api.tosspayments.com/v1/billing/authorizations/issue` |
| 빌링키로 결제 | POST | `https://api.tosspayments.com/v1/billing/{billingKey}` |
| 빌링키 삭제 | DELETE | `https://api.tosspayments.com/v1/billing/{billingKey}` |

**인증 방식**: HTTP Basic Auth — `Authorization: Basic base64(secretKey:)`

### 5.3 DB 모델

#### Payment (결제 이력)

```sql
CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id),
    teacher_id      UUID NOT NULL REFERENCES users(id),
    student_id      UUID NOT NULL REFERENCES users(id),
    amount          INTEGER NOT NULL,          -- 결제 금액 (원)
    fee_amount      INTEGER DEFAULT 0,         -- 수수료 금액 (원)
    method          VARCHAR(50),               -- CARD / VIRTUAL_ACCOUNT / TRANSFER / EASY_PAY
    status          VARCHAR(30) NOT NULL,      -- PENDING / DONE / CANCELED / PARTIAL_CANCELED / ABORTED / EXPIRED
    toss_payment_key VARCHAR(200) UNIQUE,      -- Toss paymentKey (결제 승인 후 발급)
    toss_order_id   VARCHAR(64) UNIQUE NOT NULL, -- 내부 주문 ID (UUID 기반)
    toss_receipt_url VARCHAR(500),             -- Toss 영수증 URL
    virtual_account_number VARCHAR(50),        -- 가상계좌 번호 (가상계좌 방식일 때)
    virtual_account_bank   VARCHAR(20),        -- 가상계좌 은행 코드
    virtual_account_due_date TIMESTAMPTZ,      -- 가상계좌 입금 기한
    paid_at         TIMESTAMPTZ,               -- 결제 완료 시각
    canceled_at     TIMESTAMPTZ,               -- 취소 시각
    cancel_reason   TEXT,                      -- 취소 사유
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);
```

#### PaymentMethod (저장된 결제수단 — 빌링용)

```sql
CREATE TABLE payment_methods (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    teacher_id      UUID NOT NULL REFERENCES users(id),  -- 어떤 선생님 결제용 카드인지
    billing_key     VARCHAR(200) NOT NULL,               -- Toss billingKey
    card_company    VARCHAR(50),                         -- 카드사 코드
    card_number_masked VARCHAR(20),                      -- 마스킹된 카드번호 (예: 1234-****-****-5678)
    card_type       VARCHAR(20),                         -- CREDIT / CHECK
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT now(),
    deleted_at      TIMESTAMPTZ
);
```

#### TeacherPaymentConfig (선생님 PG 설정)

```sql
CREATE TABLE teacher_payment_configs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id      UUID UNIQUE NOT NULL REFERENCES users(id),
    pg_enabled      BOOLEAN DEFAULT FALSE,               -- PG 결제 활성화 여부
    fee_bearer      VARCHAR(20) DEFAULT 'TEACHER',       -- TEACHER / STUDENT (수수료 부담 주체)
    toss_merchant_id VARCHAR(100),                       -- Toss 가맹점 ID (활성화 후 입력)
    billing_enabled BOOLEAN DEFAULT FALSE,               -- 정기결제 허용 여부
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);
```

### 5.4 API 엔드포인트 (Lessonaza 백엔드)

| 용도 | 메서드 | 경로 | 인증 |
|------|--------|------|------|
| 결제 시작 (주문 ID 발급) | POST | `/v1/payments/initiate` | 학생/학부모 |
| 결제 승인 | POST | `/v1/payments/confirm` | 학생/학부모 |
| 결제 조회 | GET | `/v1/payments/{paymentId}` | 관련 당사자 |
| 결제 취소 (환불) | POST | `/v1/payments/{paymentId}/cancel` | 선생님 |
| 웹훅 수신 | POST | `/v1/webhooks/toss` | 없음 (서명 검증) |
| 빌링키 등록 | POST | `/v1/payment-methods/billing` | 학생/학부모 |
| 빌링키 삭제 | DELETE | `/v1/payment-methods/{methodId}` | 학생/학부모 |
| 내 결제수단 목록 | GET | `/v1/payment-methods` | 학생/학부모 |
| 선생님 PG 설정 조회 | GET | `/v1/teacher/payment-config` | 선생님 |
| 선생님 PG 설정 변경 | PATCH | `/v1/teacher/payment-config` | 선생님 |

### 5.5 웹훅 이벤트 처리

Toss는 결제 상태 변경 시 웹훅을 발송한다.

| 이벤트 타입 | 처리 |
|-----------|------|
| `Payment.Done` | 수강권 자동 발급, 영수증 생성, 알림 발송 |
| `Payment.Canceled` | 수강권 취소 처리, 영수증 취소 기록 |
| `Payment.VirtualAccountDone` | 가상계좌 입금 완료 → 수강권 발급 |
| `Payment.VirtualAccountExpired` | 가상계좌 기한 만료 → 학생에게 알림 |
| `Billing.BillingKeyDeleted` | 저장된 결제수단 비활성화 |

**웹훅 서명 검증**:

```python
import hmac
import hashlib
import base64

def verify_toss_webhook(secret: str, payload: bytes, signature: str) -> bool:
    """
    Toss Payments 웹훅 서명 검증.
    X-TOSS-SIGNATURE 헤더값을 HMAC-SHA256으로 검증한다.
    """
    expected = base64.b64encode(
        hmac.new(secret.encode(), payload, hashlib.sha256).digest()
    ).decode()
    return hmac.compare_digest(expected, signature)
```

### 5.6 결제 승인 흐름 (백엔드)

```python
# POST /v1/payments/confirm
async def confirm_payment(
    payment_key: str,
    order_id: str,
    amount: int,
    current_user: User,
    db: AsyncSession,
) -> PaymentResponse:
    # 1. 내부 주문 검증 (amount 위변조 방지)
    pending = await db.get(Payment, order_id)
    if pending.amount != amount:
        raise HTTPException(400, "금액 불일치")

    # 2. Toss 결제 승인 API 호출
    response = await toss_client.confirm_payment(
        payment_key=payment_key,
        order_id=order_id,
        amount=amount,
    )

    # 3. DB 업데이트
    pending.toss_payment_key = response["paymentKey"]
    pending.status = "DONE"
    pending.paid_at = now()

    # 4. 수강권 자동 발급
    await subscription_service.activate(pending.subscription_id)

    # 5. 영수증 생성
    await receipt_service.create_from_payment(pending)

    return PaymentResponse.from_orm(pending)
```

---

## 6. 프론트엔드 설계

### 6.1 결제 수단 선택 화면

수강권 제안 수락 후 결제 방식 선택:

```
[결제 방법 선택]
─────────────────────────────────
○ 무통장입금   (기존 방식)
   계좌: 국민은행 123-456-789 홍길동

● 온라인 결제  (Toss Payments)
   카드, 카카오페이, 토스페이, 계좌이체 등

[결제하기]
─────────────────────────────────
```

선생님이 PG를 비활성화한 경우 "온라인 결제" 옵션을 표시하지 않는다.

### 6.2 Toss 결제 위젯 (WebView)

Flutter WebView로 Toss 결제창 표시:

```
[결제 화면 — WebView]
──────────────────────
Toss Payments 결제 위젯
  - 결제 수단 선택
  - 카드 정보 입력 (Toss 처리)
  - 간편결제 인증
──────────────────────
[취소]
```

**딥링크 콜백**:
- 성공: `lessonaza://payment/success?paymentKey=xxx&orderId=xxx&amount=xxx`
- 실패: `lessonaza://payment/fail?code=xxx&message=xxx`
- 취소: `lessonaza://payment/cancel`

**iOS/Android 설정**:
- iOS: `Info.plist`에 딥링크 스킴 등록, 결제 앱 URL 스킴 허용 (`kakaokompassauth`, `naversearchapp` 등)
- Android: `AndroidManifest.xml`에 Intent Filter 등록

### 6.3 정기 결제 카드 등록 화면

```
[카드 등록 — WebView]
──────────────────────
Toss 빌링 위젯
  - 카드 번호 입력
  - 카드 인증
──────────────────────
```

등록 완료 후:
- `PaymentMethod` 생성 (마스킹된 카드 정보 + billingKey 저장)
- 학생/학부모 화면: "등록된 카드: 국민 ****-****-****-1234"

### 6.4 선생님 PG 설정 화면

위치: 선생님 설정 > 결제 관리

```
[온라인 결제 설정]
─────────────────────────────────
온라인 결제 받기          [토글: OFF → ON]

[활성화 시 추가 항목]
Toss 가맹점 ID: [______________]
정산 계좌: 국민은행 123-456-789
수수료 부담: ○ 내가 부담  ● 학생이 부담
정기 결제 허용:            [토글: OFF]
─────────────────────────────────
[저장]
```

### 6.5 결제 완료 화면

```
[결제 완료]
────────────────────────
✓ 결제가 완료되었습니다

수강권: 월 4회 (2026.06 ~ 2026.06)
결제 금액: 100,000원
결제 수단: 신한카드 (1234)
결제 일시: 2026-05-31 14:32

[영수증 보기]   [홈으로]
────────────────────────
```

---

## 7. 보안

### 7.1 민감 데이터 처리

| 항목 | 정책 |
|------|------|
| Toss Secret Key | 백엔드 환경변수만. 코드/git 절대 포함 금지 |
| 카드 정보 | Toss가 직접 처리 (PCI-DSS 적용). 앱/백엔드는 카드 번호 수집 불가 |
| BillingKey | DB에 암호화 저장 (`Fernet` 또는 AWS KMS) |
| 웹훅 Endpoint | 서명 검증 필수 (HMAC-SHA256). 검증 실패 시 400 응답 |

### 7.2 결제 위변조 방지

```
[서버 사이드 검증 필수]
1. 결제 시작 시 서버에서 amount 기록
2. 결제 승인 요청 시 서버가 기록된 amount와 비교
3. 불일치 시 즉시 거부 (프론트엔드 amount 신뢰 금지)
```

### 7.3 웹훅 중복 처리 방지

```
[멱등성 보장]
- paymentKey 기반 중복 체크 (DB UNIQUE 제약)
- 같은 paymentKey 웹훅이 2회 이상 수신 시 두 번째부터 무시
- 분산 환경에서 Redis distributed lock 활용 검토
```

### 7.4 체크리스트

- [ ] `TOSS_SECRET_KEY`가 코드/로그에 노출되지 않는가
- [ ] 결제 승인 전 서버 측 금액 검증을 하는가
- [ ] 웹훅 서명 검증을 하는가
- [ ] BillingKey DB 저장 시 암호화하는가
- [ ] 다른 사용자의 결제 정보 접근 차단 (teacher_id/student_id 매칭)

---

## 8. 테스트 계획

### 8.1 테스트 환경

Toss Payments는 테스트 키를 제공한다:

```
TOSS_CLIENT_KEY=test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq
TOSS_SECRET_KEY=test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R
```

테스트 카드 번호: `4330123412341234` (전 금액 결제 성공)
실패 카드 번호: `4000000000000002` (잔액 부족)

### 8.2 시나리오 테스트

```python
@pytest.mark.asyncio
async def test_fw_pg_카드_결제_성공(teacher: TeacherActions, student: StudentActions):
    """수강권 제안 → 카드 결제 → 수강권 자동 발급."""
    sid = await teacher.create_student("테스트학생")
    lid = await teacher.create_subscription_proposal(sid, amount=100000)
    await student.accept_proposal(lid)
    # Toss 결제 승인 Mock
    await student.confirm_payment(lid, method="CARD", amount=100000)
    subscription = await student.get_subscription(lid)
    assert subscription.payment_confirmed is True
    assert subscription.status == "ACTIVE"

@pytest.mark.asyncio
async def test_fw_pg_결제_금액_위변조_차단(teacher: TeacherActions, student: StudentActions):
    """결제 금액 위변조 시 거부."""
    sid = await teacher.create_student("테스트학생")
    lid = await teacher.create_subscription_proposal(sid, amount=100000)
    await student.accept_proposal(lid)
    with pytest.raises(HTTPException, match="금액 불일치"):
        await student.confirm_payment(lid, method="CARD", amount=50000)  # 위변조

@pytest.mark.asyncio
async def test_fw_pg_환불_부분취소(teacher: TeacherActions, student: StudentActions):
    """수강권 2회 사용 후 잔여 2회 환불."""
    sid = await teacher.create_student("테스트학생")
    lid = await teacher.create_subscription_proposal(sid, amount=100000, total_count=4)
    await student.accept_proposal(lid)
    await student.confirm_payment(lid, method="CARD", amount=100000)
    await teacher.complete_lesson(lid)  # 1회 사용
    await teacher.complete_lesson(lid)  # 2회 사용
    refund = await teacher.cancel_payment(lid, reason="학생 요청")
    assert refund.cancel_amount == 50000  # 잔여 2회 × 25,000원

@pytest.mark.asyncio
async def test_fw_pg_가상계좌_입금_자동처리(teacher: TeacherActions, student: StudentActions):
    """가상계좌 발급 → 입금 웹훅 수신 → 수강권 자동 발급."""
    sid = await teacher.create_student("테스트학생")
    lid = await teacher.create_subscription_proposal(sid, amount=100000)
    await student.accept_proposal(lid)
    va = await student.initiate_virtual_account_payment(lid, amount=100000)
    assert va.account_number is not None
    # 웹훅 시뮬레이션
    await simulate_toss_webhook("Payment.VirtualAccountDone", va.order_id)
    subscription = await student.get_subscription(lid)
    assert subscription.payment_confirmed is True

@pytest.mark.asyncio
async def test_fw_pg_정기결제_자동_갱신(teacher: TeacherActions, student: StudentActions):
    """빌링키 등록 → 수강권 만료 → 자동 갱신 결제."""
    sid = await teacher.create_student("테스트학생")
    await student.register_billing_key(teacher_id=teacher.id, billing_key="test_billing_key")
    # 수강권 만료 시뮬레이션 후 자동 결제 트리거
    await trigger_auto_billing(student_id=student.id, teacher_id=teacher.id)
    subscription = await student.get_latest_subscription(teacher.id)
    assert subscription.status == "ACTIVE"
```

### 8.3 체크리스트

- [ ] 카드 결제 정상 흐름
- [ ] 간편결제 (카카오페이, 토스페이) 흐름
- [ ] 가상계좌 발급 + 입금 웹훅
- [ ] 결제 금액 위변조 거부
- [ ] 전액 환불
- [ ] 부분 환불
- [ ] 정기 결제 (빌링키 등록 → 자동 결제)
- [ ] 정기 결제 실패 재시도
- [ ] 웹훅 서명 검증 (유효/위변조)
- [ ] 웹훅 중복 수신 멱등성

---

## 9. 비용 분석

### 9.1 수수료 시뮬레이션 (수강료 100,000원 기준)

| 결제 수단 | 수수료율 | 수수료 (원) | 선생님 수령 (선생님 부담 시) |
|----------|---------|-----------|--------------------------|
| 신용카드 (개인사업자 기본) | 3.3% | 3,300원 | 96,700원 |
| 카카오페이 | 2.5% | 2,500원 | 97,500원 |
| 네이버페이 | 2.5% | 2,500원 | 97,500원 |
| 토스페이 | 1.8% | 1,800원 | 98,200원 |
| 실시간 계좌이체 | 1.5% | 1,500원 | 98,500원 |
| 가상계좌 (건당) | 300원 | 300원 | 99,700원 |

### 9.2 Lessonaza 플랫폼 수수료

**초기: 0%** — 선생님 유입 및 신뢰 확보 우선.

수수료 도입 시 별도 정책 결정 필요:
- 수수료율 (예: 1~3%)
- 적용 대상 (PG 결제만 vs 무통장 포함)
- 수익 배분 모델

### 9.3 손익분기 분석

| 항목 | 내용 |
|------|------|
| Toss Payments 초기 비용 | 0원 (월 고정 수수료 없음, 거래 건당 수수료만) |
| 개발 비용 | 약 4~6주 (§10 구현 단계 참조) |
| 선생님 혜택 | 입금 독촉 시간 감소, 수납 자동화 |
| 학생/학부모 혜택 | 이체 번거로움 제거, 즉시 결제 |

---

## 10. 구현 단계

| 단계 | 범위 | 예상 공수 | 의존성 |
|------|------|---------|------|
| **1** | Toss 가맹점 등록 + 테스트/운영 API 키 발급 | 1주 | 사업자 서류 준비 |
| **2** | Payment / PaymentMethod / TeacherPaymentConfig DB 모델 + 마이그레이션 | 3일 | 없음 |
| **3** | Toss API 클라이언트 모듈 (`toss_client.py`) | 2일 | 단계 2 |
| **4** | `/v1/payments/*` API 엔드포인트 (결제 시작/승인/조회/취소) | 4일 | 단계 3 |
| **5** | `/v1/webhooks/toss` 웹훅 수신 + 서명 검증 + 수강권 자동 발급 | 3일 | 단계 4 |
| **6** | Flutter 결제 화면 (WebView + 딥링크 콜백) | 5일 | 단계 4 |
| **7** | 선생님 PG 설정 화면 | 3일 | 단계 2 |
| **8** | 빌링 API (`/v1/payment-methods/billing`) + Flutter 카드 등록 화면 | 4일 | 단계 4 |
| **9** | 자동 정기 결제 스케줄러 (APScheduler 또는 Celery) | 3일 | 단계 8 |
| **10** | 영수증 연동 (payment_receipt_spec.md 흐름 확장) | 2일 | 단계 5 |
| **11** | 베타 테스트 (테스트 키로 전 시나리오 검증) | 1주 | 단계 1~10 |
| **12** | 운영 키 전환 + 모니터링 설정 | 3일 | 단계 11 |

**총 예상 공수: 약 7~8주**

> 단계 1 (가맹점 등록)은 개발과 병행 가능. 가맹점 심사 기간 (1~2주) 동안 단계 2~5 개발.

---

## 11. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-31 | 무통장입금 유지 + PG는 Opt-in | payment_architecture.md 정책 존중. 선생님 이탈 방지 |
| 2026-05-31 | Toss Payments 선택 | 한국 시장 점유율 1위, 개인사업자 지원, SDK 완성도 |
| 2026-05-31 | 앱 내 가맹점 등록 처리 않음 | 선생님이 Toss 직접 등록 후 API 키만 연결 (심사 프로세스 앱이 대신 할 수 없음) |
| 2026-05-31 | 가상계좌 포함 | 기존 무통장 경험 유지하면서 입금 자동화. 선생님 저항 최소화 |
| 2026-05-31 | Lessonaza 플랫폼 수수료 초기 0% | 선생님 유입 우선. 도입 시 별도 정책 결정 |
| 2026-05-31 | 카드 정보 직접 수집 금지 | PCI-DSS. Toss WebView가 직접 처리 |

---

## 12. 관련 스펙 / 변경 이력

### 관련 스펙

- [payment_architecture.md](./payment_architecture.md) — 현행 무통장입금 정책 (이 스펙의 상위 정책)
- [subscription_master.md](./subscription_master.md) — 수강권 도메인 SSOT
- [payment_receipt_spec.md](./payment_receipt_spec.md) — 영수증/청구서 시스템 (PG 결제 후 영수증 자동 생성 연동)
- Toss Payments 공식 문서: https://docs.tosspayments.com

### 변경 이력

| 일자 | 버전 | 내용 |
|------|------|------|
| 2026-05-31 | v1.0 | 초안 작성 |
