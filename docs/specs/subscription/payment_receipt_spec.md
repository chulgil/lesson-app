# 결제 영수증 / 청구서 시스템 스펙

> 작성일: 2026-05-07
> 상태: 신규 스펙 (미구현)
> 관련 스펙: [subscription_master.md](./subscription_master.md), [payment_architecture.md](./payment_architecture.md)
> 관련 엔티티: Subscription, SubscriptionProposal, Teacher, Student, Parent

---

## 목차

1. [개요](#1-개요)
2. [범위 경계](#2-범위-경계)
3. [데이터 모델](#3-데이터-모델)
4. [영수증 생성 흐름](#4-영수증-생성-흐름) (§4.4 PG 결제 흐름 포함)
5. [청구서(결제 안내서) 흐름](#5-청구서결제-안내서-흐름) (§5.3 알림톡, §5.4 교육비 증빙서 포함)
6. [PDF 템플릿](#6-pdf-템플릿)
7. [API 계약](#7-api-계약)
8. [프론트엔드 화면](#8-프론트엔드-화면)
9. [경쟁사 분석](#9-경쟁사-분석)
10. [구현 단계](#10-구현-단계)
11. [변경 이력](#11-변경-이력)

---

## 1. 개요

### 1.1 배경

Lessonaza는 **무통장입금** 방식으로 운영된다. 앱이 결제를 중개하지 않고, 선생님이 학생/학부모에게 수강료를 안내하면 외부에서 입금하고 선생님이 입금을 확인한다.

이 흐름에서 두 가지 문서가 필요하다:

| 문서 | 시점 | 발행자 | 수신자 | 목적 |
|------|------|--------|--------|------|
| **청구서 (Invoice)** | 입금 **전** (수강권 제안 확정 시) | 선생님 | 학생/학부모 | 입금 안내 — 계좌번호, 금액, 기한 |
| **영수증 (Receipt)** | 입금 **후** (선생님 입금 확인 시) | 선생님 | 학생/학부모 | 입금 증빙 — 세금 공제, 학원비 증빙 |

### 1.2 사용자 가치

| 역할 | 니즈 |
|------|------|
| **선생님** | 월별 수납 내역 정리 / 학생별 수납 현황 / 세금 신고 시 증빙 |
| **학부모** | 교육비 세액공제 (연말정산) / 학원비 가계부 관리 / 환불 요청 시 증빙 |
| **학생** | 나의 수강 내역 + 금액 확인 |

### 1.3 핵심 원칙

- **영수증 = 수강권 단위** — 수강권 1개당 영수증 1개. 분할/복수 발행 없음.
- **청구서 ≠ 결제 요청** — 앱은 결제를 처리하지 않는다. 청구서는 입금 안내 문서일 뿐.
- **PDF 저장 위치** — Vultr S3 (S3-compatible). URL은 Presigned URL로 임시 제공.
- **현금영수증 / 세금계산서는 범위 밖** — 앱이 발행하는 문서는 내부 영수증이며, 법적 세금 문서가 아님. 상단에 "본 영수증은 법적 세금계산서가 아닙니다" 명시.

---

## 2. 범위 경계

### 2.1 포함 (In Scope)

- 수강권 입금 확인 시 영수증 자동 생성 및 Vultr S3 저장
- 청구서(결제 안내서) 수동 발송 (선생님 → 학생/학부모)
- 영수증 목록 조회 (선생님: 전체, 학생/학부모: 본인)
- PDF 다운로드 (Presigned URL, 만료 1시간)
- 앱 내 영수증 공유 (Share Sheet)
- 영수증 번호 자동 채번 (연도-선생님ID-순번)

### 2.2 제외 (Out of Scope)

> [payment_architecture.md §2.3](./payment_architecture.md) 비범위 항목과 완전히 일치.

- 법적 세금계산서 발행 (국세청 연동 불가)
- 현금영수증 발행 (국세청 API 불필요)
- 카드영수증, PG 영수증
- 이메일 자동 발송 (Phase 2 후보)
- 앱 내 결제 처리 / 정산
- 환불 처리 / 부분 취소
- 학원 연합 정산서

---

## 3. 데이터 모델

### 3.1 PaymentReceipt (영수증)

```sql
CREATE TABLE payment_receipts (
    id              VARCHAR(36) PRIMARY KEY,  -- UUID
    receipt_number  VARCHAR(30) NOT NULL UNIQUE,  -- "2026-TCH001-0042"
    subscription_id VARCHAR(36) NOT NULL REFERENCES subscriptions(id),
    teacher_id      VARCHAR(36) NOT NULL,
    student_id      VARCHAR(36) NOT NULL,

    -- 발행 정보
    issued_at       TIMESTAMP NOT NULL,          -- 영수증 발행 시각
    payment_date    DATE NOT NULL,               -- 입금 확인 날짜 (선생님이 확인한 날)

    -- 금액
    amount          INTEGER NOT NULL,            -- 수강료 (원)
    currency        VARCHAR(3) DEFAULT 'KRW',

    -- 수강 내용 스냅샷 (발행 시점 기준 고정)
    lesson_type     VARCHAR(30) NOT NULL,        -- "regular" | "trial" | "package"
    lesson_count    INTEGER,                     -- 총 레슨 횟수 (패키지)
    period_start    DATE,                        -- 수강 시작일
    period_end      DATE,                        -- 수강 종료일
    instrument      VARCHAR(50),                 -- 악기 (스냅샷)

    -- 선생님 정보 스냅샷
    teacher_name    VARCHAR(100) NOT NULL,
    teacher_bank    VARCHAR(200),               -- 은행명 + 계좌번호
    teacher_phone   VARCHAR(20),

    -- 학생 정보 스냅샷
    student_name    VARCHAR(100) NOT NULL,

    -- PDF
    pdf_key         VARCHAR(500),               -- Vultr S3 object key
    pdf_generated   BOOLEAN DEFAULT FALSE,

    -- 상태
    status          VARCHAR(20) DEFAULT 'issued',  -- issued | cancelled
    cancelled_at    TIMESTAMP,
    cancel_reason   VARCHAR(200),

    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_receipt_teacher ON payment_receipts(teacher_id, issued_at DESC);
CREATE INDEX idx_receipt_student ON payment_receipts(student_id, issued_at DESC);
CREATE INDEX idx_receipt_subscription ON payment_receipts(subscription_id);
```

### 3.2 PaymentInvoice (청구서)

```sql
CREATE TABLE payment_invoices (
    id                  VARCHAR(36) PRIMARY KEY,
    invoice_number      VARCHAR(30) NOT NULL UNIQUE,  -- "INV-2026-TCH001-0012"
    subscription_proposal_id VARCHAR(36) REFERENCES subscription_proposals(id),
    teacher_id          VARCHAR(36) NOT NULL,
    student_id          VARCHAR(36) NOT NULL,

    -- 금액
    amount              INTEGER NOT NULL,

    -- 결제 안내 정보
    bank_name           VARCHAR(50),            -- "국민은행"
    account_number      VARCHAR(50),            -- "012-3456-789012"
    account_holder      VARCHAR(100),           -- 예금주
    due_date            DATE,                   -- 입금 기한

    -- 수강 내용 스냅샷
    lesson_type         VARCHAR(30) NOT NULL,
    lesson_count        INTEGER,
    period_start        DATE,
    period_end          DATE,
    instrument          VARCHAR(50),

    -- 선생님/학생 스냅샷
    teacher_name        VARCHAR(100) NOT NULL,
    student_name        VARCHAR(100) NOT NULL,

    -- 전달 상태
    sent_at             TIMESTAMP,              -- 학생/학부모에게 전달된 시각
    viewed_at           TIMESTAMP,              -- 최초 열람 시각

    -- PDF
    pdf_key             VARCHAR(500),
    pdf_generated       BOOLEAN DEFAULT FALSE,

    -- 링크
    receipt_id          VARCHAR(36) REFERENCES payment_receipts(id),  -- 입금 후 연결

    status              VARCHAR(20) DEFAULT 'pending',  -- pending | paid | cancelled | overdue

    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);
```

### 3.3 글로사리 등록 (신규 용어)

| 한글 | 영문 | FE 클래스 | BE 클래스 |
|------|------|-----------|-----------|
| 영수증 | Receipt | `PaymentReceipt` | `PaymentReceipt` |
| 청구서 | Invoice | `PaymentInvoice` | `PaymentInvoice` |
| 영수증 번호 | Receipt Number | `receiptNumber` | `receipt_number` |

---

## 4. 영수증 생성 흐름

### 4.1 자동 생성 (선생님 입금 확인 시)

```
선생님 앱: [입금 확인] 버튼 탭
    │
    ▼
subscription_service.confirm_payment(subscription_id)
    │
    ├── subscription.payment_confirmed = True
    ├── subscription.payment_date = today
    ├── 수강권 상태 → active
    │
    ▼
receipt_service.auto_generate(subscription_id)
    │
    ├── 영수증 번호 채번: f"{year}-{teacher_code}-{seq:04d}"
    ├── 선생님/학생/수강권 데이터 스냅샷 (발행 시점 고정)
    ├── PaymentReceipt DB 저장 (pdf_generated=False)
    │
    ▼ (백그라운드 작업)
pdf_service.generate_receipt_pdf(receipt_id)
    │
    ├── HTML → PDF 렌더링 (WeasyPrint 또는 ReportLab)
    ├── Vultr S3 업로드: receipts/{teacher_id}/{year}/{receipt_id}.pdf
    ├── pdf_key, pdf_generated=True 업데이트
    │
    ▼
notification_service.send_receipt_ready(receipt_id)
    │
    └── 학생/학부모에게 인앱 알림: "영수증이 발행되었습니다"
```

### 4.2 영수증 번호 채번 규칙

```python
# 형식: YYYY-TXXXXXXXX-NNNN
# YYYY: 연도 (4자리)
# T: Teacher 접두어
# XXXXXXXX: teacher_id 앞 8자리
# NNNN: 해당 선생님의 당해연도 순번 (4자리 zero-padding)

# 예시: 2026-T3fa8b2c1-0042

def generate_receipt_number(teacher_id: str, year: int, seq: int) -> str:
    short_id = teacher_id.replace("-", "")[:8]
    return f"{year}-T{short_id}-{seq:04d}"
```

### 4.3 상태 전이

```
[수강권 입금 확인]
      │
      ▼
 issued ──→ (취소 가능: 선생님만, 발급 24시간 이내) ──→ cancelled
```

취소된 영수증은 논리 삭제(cancelled 상태), 실제 레코드는 보존한다.

### 4.4 PG 결제(Toss Payments) 연계 시 자동 영수증

> Toss PG 연동이 활성화되면 아래 흐름으로 영수증이 자동 생성된다.
> 무통장입금 흐름(§4.1)과 최종 영수증 생성 단계는 동일하다.

```
[Toss Payments 결제 완료]
    │
    ▼
POST /api/v1/webhooks/toss  (Toss 웹훅 수신)
    │
    ├── 결제 검증 (idempotency_key 중복 방지)
    ├── 수강권 자동 발급 (subscription.status → active)
    ├── subscription.payment_confirmed = True
    ├── subscription.payment_method = "pg_toss"
    ├── subscription.pg_payment_key = toss_payment_key
    │
    ▼
receipt_service.auto_generate(subscription_id)
    │  (§4.1 자동 생성 흐름과 동일)
    │
    ▼ (백그라운드)
pdf_service.generate_receipt_pdf(receipt_id)
    │
    ▼
notification_service.send_receipt_ready(receipt_id)
    │
    ├── 앱 푸시: "영수증이 발행되었습니다" + 다운로드 링크
    └── 카카오 알림톡: PDF 다운로드 링크 포함 (앱 미설치자 대응) — §5.3 참조
```

**무통장입금과 비교:**

| 항목 | 무통장입금 | PG 결제 |
|------|-----------|---------|
| 입금 확인 주체 | 선생님 수동 확인 | Toss 웹훅 자동 |
| 수강권 발급 | 선생님 확인 후 | 결제 완료 즉시 |
| 영수증 생성 | 동일 | 동일 |
| payment_method | `bank_transfer` | `pg_toss` |

> **참조**: Toss 웹훅 상세 처리 흐름은 [payment_architecture.md](./payment_architecture.md) 참조.

---

## 5. 청구서(결제 안내서) 흐름

### 5.1 발송 흐름

```
선생님: 수강권 제안 확정 또는 청구서 수동 생성
    │
    ▼
InvoiceSendSheet (선생님 앱)
    │
    ├── 수강 내용 확인 (레슨 유형, 횟수, 금액)
    ├── 계좌 정보 입력/확인 (선생님 설정에서 자동 채움)
    ├── 입금 기한 설정 (기본: 7일 후)
    │
    ▼
POST /api/v1/invoices
    │
    ├── PaymentInvoice 생성
    ├── PDF 생성 (백그라운드)
    │
    ▼
학생/학부모 앱: 인앱 알림 수신
    │
    └── ReceiptDetailScreen 에서 청구서 열람 + 입금 안내
```

### 5.2 청구서 상태 전이

```
pending ──→ (학생 열람) ──→ viewed
                               │
            ┌──────────────────┤
            │                  │
            ▼                  ▼
          paid               overdue
       (선생님 입금확인)     (기한 초과)
```

### 5.3 카카오 알림톡 연동

영수증/청구서 발행 시 카카오 알림톡으로 발송한다.

| 문서 | 템플릿 | 내용 | 발송 시점 |
|------|--------|------|---------|
| 청구서 | `LNZ_INVOICE` | 수강료 금액, 입금 계좌, 납부 기한 + PDF 다운로드 링크 | 청구서 발송 즉시 |
| 영수증 | `LNZ_RECEIPT` | 수납 금액, 발행일 + PDF 다운로드 링크 | 영수증 생성 후 |

**발송 우선순위:**
1. 카카오 알림톡 (전화번호 등록 + 카카오계정 연동 시)
2. 앱 푸시 알림 (카카오 알림톡 미지원 시 fallback)

**알림톡 미지원 조건:** 수신자의 전화번호가 카카오 계정에 미등록된 경우 — 이 경우 앱 푸시만 발송하고 에러 무시(silent fail).

> 카카오 알림톡 연동 API 상세: [notification 스펙](../notification/) 참조 (Phase 3 후보).

### 5.4 교육비 세액공제 증빙서

한국 학부모는 연말정산 시 자녀 교육비 세액공제(15%)를 신청한다.
Lessonaza는 교육비납입증명서를 자동 생성하여 학부모에게 제공한다.

| 항목 | 내용 |
|------|------|
| 발행 시점 | 매년 1월 (전년도 납부 내역 집계) |
| 형식 | PDF (국세청 양식 준수) |
| 필수 필드 | 교육기관명, 사업자번호, 학생 이름, 보호자 이름, 납부 기간, 총 납부액 |
| 발송 경로 | 학부모 앱 내 다운로드 + 카카오 알림톡 |

**발행 전제 조건:**
- 선생님이 사업자 등록을 한 경우에만 발행 가능 (사업자번호 필수 필드)
- 개인 과외 선생님(사업자 미등록)은 발행 불가 — 이 경우 일반 영수증만 제공하며, 교육비납입증명서 요청 시 "사업자 등록 선생님만 발행 가능합니다" 안내

**범위:** Phase 3 구현 대상 (§10 참조)

---

## 6. PDF 템플릿

### 6.1 Notebook × Score 디자인

모든 PDF 문서는 앱의 디자인 시스템([Notebook × Score](../design/notebook/README.md))을 따른다.

```
┌─────────────────────────────────────────────────────┐
│  [왼쪽 여백선 - Vermillion #A83E3A]                    │
│                                                       │
│  ♩ LESSONAZA              [Playfair Display, 18pt]   │
│  ─────────────────────────────────────────────────   │
│                                                       │
│  수 강 료 영 수 증                [Playfair, 24pt bold] │
│  RECEIPT OF PAYMENT         [캡션, 11pt, Pretendard] │
│                                                       │
│  No. 2026-T3fa8b2c1-0042              [모노, 12pt]   │
│  발행일: 2026년 5월 7일                                │
│                                                       │
│  ─────────────────────────────────────────────────   │
│  수 신                     공 급 자                   │
│  학생: 홍길동               선생님: 김선생              │
│  (보호자: 홍부모)           연락처: 010-1234-5678      │
│  ─────────────────────────────────────────────────   │
│                                                       │
│  항 목                수 량        금 액              │
│  ─────────────────────────────────────────────────   │
│  바이올린 정기 레슨      8회       320,000원           │
│  수강 기간: 2026.05.07 ~ 2026.06.06                   │
│                                                       │
│  ─────────────────────────────────────────────────   │
│  합    계                         320,000원           │
│                                                       │
│  * 본 영수증은 법적 세금계산서가 아닙니다.                 │
│  * 환급 및 취소는 선생님에게 직접 문의하세요.              │
│                                                       │
│  [선생님 서명 영역 - 선택적]                            │
│                                                       │
│       Powered by Lessonaza                            │
└─────────────────────────────────────────────────────┘
```

### 6.2 청구서 템플릿 (Invoice)

```
┌─────────────────────────────────────────────────────┐
│  [Vermillion 왼쪽 여백선]                              │
│                                                       │
│  ♩ LESSONAZA                                         │
│  ─────────────────────────────────────────────────   │
│                                                       │
│  수 강 료 납 부 안 내              [Playfair, 22pt]   │
│  PAYMENT NOTICE                                      │
│                                                       │
│  No. INV-2026-T3fa8b2c1-0012                        │
│  발행일: 2026년 5월 7일   납부기한: 2026년 5월 14일     │
│                                                       │
│  ─────────────────────────────────────────────────   │
│  수신: 홍길동 학생 (보호자: 홍부모)                      │
│  발신: 김선생 선생님                                     │
│                                                       │
│  ─────────────────────────────────────────────────   │
│  항 목                수 량        금 액              │
│  ─────────────────────────────────────────────────   │
│  바이올린 정기 레슨      8회       320,000원           │
│  수강 기간: 2026.05.07 ~ 2026.06.06                   │
│  ─────────────────────────────────────────────────   │
│  납부 금액                        320,000원           │
│                                                       │
│  ── 입금 계좌 안내 ────────────────────────────────   │
│  은 행: 국민은행                                        │
│  계좌번호: 123-456-789012                             │
│  예금주: 김선생                                         │
│                                                       │
│  * 입금 후 앱에서 '입금 완료' 알림을 보내주세요.            │
└─────────────────────────────────────────────────────┘
```

### 6.3 PDF 생성 기술 스택

| 옵션 | 장점 | 단점 | 결정 |
|------|------|------|------|
| WeasyPrint | HTML/CSS → PDF, 한글 폰트 | 서버 의존성 많음 | **1순위 후보** |
| ReportLab | 순수 Python, 빠름 | 코드베이스 복잡 | 2순위 |
| Gotenberg (Docker) | 헤드리스 Chrome | 별도 컨테이너 필요 | 3순위 |

> **결정**: WeasyPrint 채택. 한글 폰트(Pretendard, Gaegu)와 CSS 기반 레이아웃이 디자인 시스템과 가장 잘 맞음. 서버에 libpango 설치 필요 (Dockerfile에 추가).

### 6.4 S3 저장 경로

```
# 영수증
receipts/{teacher_id}/{YYYY}/{receipt_id}.pdf

# 청구서
invoices/{teacher_id}/{YYYY}/{invoice_id}.pdf
```

---

## 7. API 계약

### 7.1 엔드포인트 목록

| Method | Path | 역할 | 권한 |
|--------|------|------|------|
| `POST` | `/api/v1/receipts/generate` | 영수증 수동 생성 | 선생님 |
| `GET` | `/api/v1/receipts` | 영수증 목록 | 선생님/학생/학부모 |
| `GET` | `/api/v1/receipts/{id}` | 영수증 상세 | 관련자 |
| `GET` | `/api/v1/receipts/{id}/download` | PDF Presigned URL | 관련자 |
| `DELETE` | `/api/v1/receipts/{id}` | 영수증 취소 | 선생님 (24h 이내) |
| `POST` | `/api/v1/invoices` | 청구서 생성/발송 | 선생님 |
| `GET` | `/api/v1/invoices` | 청구서 목록 | 선생님/학생/학부모 |
| `GET` | `/api/v1/invoices/{id}` | 청구서 상세 | 관련자 |
| `GET` | `/api/v1/invoices/{id}/download` | PDF Presigned URL | 관련자 |

### 7.2 영수증 목록 (`GET /api/v1/receipts`)

**쿼리 파라미터:**

| 파라미터 | 타입 | 기본값 | 설명 |
|---------|------|--------|------|
| `student_id` | string | — | 특정 학생 필터 (선생님만) |
| `year` | int | 현재 연도 | 연도 필터 |
| `month` | int | — | 월 필터 (1-12) |
| `status` | string | — | `issued` \| `cancelled` |
| `page` | int | 1 | 페이지 |
| `size` | int | 20 | 페이지 크기 (최대 50) |

**응답 (200):**

```json
{
  "items": [
    {
      "id": "uuid",
      "receipt_number": "2026-T3fa8b2c1-0042",
      "subscription_id": "uuid",
      "teacher_name": "김선생",
      "student_name": "홍길동",
      "amount": 320000,
      "payment_date": "2026-05-07",
      "issued_at": "2026-05-07T14:30:00Z",
      "lesson_type": "regular",
      "lesson_count": 8,
      "period_start": "2026-05-07",
      "period_end": "2026-06-06",
      "instrument": "바이올린",
      "pdf_generated": true,
      "status": "issued"
    }
  ],
  "total": 42,
  "page": 1,
  "size": 20,
  "pages": 3
}
```

### 7.3 PDF 다운로드 (`GET /api/v1/receipts/{id}/download`)

**응답 (200):**

```json
{
  "download_url": "https://storage.vultr.com/...",
  "expires_at": "2026-05-07T15:30:00Z",
  "filename": "영수증_2026-T3fa8b2c1-0042.pdf"
}
```

> Presigned URL 유효시간: 1시간

### 7.4 청구서 생성 (`POST /api/v1/invoices`)

**요청 바디:**

```json
{
  "subscription_proposal_id": "uuid",
  "bank_name": "국민은행",
  "account_number": "123-456-789012",
  "account_holder": "김선생",
  "due_date": "2026-05-14",
  "memo": "5월 수강료입니다 :)"
}
```

**응답 (201):**

```json
{
  "id": "uuid",
  "invoice_number": "INV-2026-T3fa8b2c1-0012",
  "amount": 320000,
  "due_date": "2026-05-14",
  "status": "pending",
  "pdf_generated": false,
  "created_at": "2026-05-07T14:00:00Z"
}
```

### 7.5 영수증 자동 생성 훅 (내부)

> 이 엔드포인트는 `subscription_service.confirm_payment()` 내부에서만 호출. 외부 직접 호출 불가.

```python
# backend/app/services/receipt_service.py

async def auto_generate_on_payment_confirmed(
    subscription_id: str,
    db: AsyncSession,
) -> PaymentReceipt:
    """수강권 입금 확인 시 자동으로 영수증 생성."""
    subscription = await _get_subscription(subscription_id, db)

    # 스냅샷 수집
    teacher = await _get_teacher(subscription.teacher_id, db)
    student = await _get_student(subscription.student_id, db)

    receipt_number = await _next_receipt_number(teacher.id, db)

    receipt = PaymentReceipt(
        receipt_number=receipt_number,
        subscription_id=subscription_id,
        teacher_id=teacher.id,
        student_id=student.id,
        issued_at=datetime.utcnow(),
        payment_date=date.today(),
        amount=subscription.amount,
        lesson_type=subscription.lesson_type,
        lesson_count=subscription.total_lessons,
        period_start=subscription.start_date,
        period_end=subscription.end_date,
        instrument=student.instrument,
        teacher_name=teacher.display_name,
        teacher_bank=teacher.bank_account_info,
        student_name=student.display_name,
        pdf_generated=False,
    )
    db.add(receipt)
    await db.flush()

    # 백그라운드 PDF 생성 (APScheduler 또는 BackgroundTasks)
    background_tasks.add_task(generate_pdf_and_notify, receipt.id)

    return receipt
```

---

## 8. 프론트엔드 화면

### 8.1 화면 목록

| 화면 | 경로 | 진입점 | 역할 |
|------|------|--------|------|
| `ReceiptListScreen` | `/receipts` | 설정 메뉴 / 학생 상세 | 영수증/청구서 목록 |
| `ReceiptDetailScreen` | `/receipts/:id` | 목록 탭 | 단일 영수증 상세 + 다운로드 |
| `InvoiceSendSheet` | Bottom Sheet | 수강권 제안 확정 후 | 청구서 발송 설정 |

### 8.2 ReceiptListScreen

```
┌──────────────────────────────────────┐
│  ← 수납 내역           [필터 ▼]       │
│                                      │
│  [영수증] [청구서]    ← 탭           │
│                                      │
│  2026년 5월                          │
│  ┌────────────────────────────────┐  │
│  │ 홍길동          320,000원      │  │
│  │ 바이올린 8회권  2026.05.07    │  │
│  │ No. 2026-T3fa8b2c1-0042  [↓] │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ 이학생          250,000원      │  │
│  │ 피아노 월정액   2026.05.01    │  │
│  └────────────────────────────────┘  │
│                                      │
│  2026년 4월                          │
│  ...                                 │
└──────────────────────────────────────┘
```

**탭별 내용:**
- **영수증 탭**: 발행 완료된 영수증 (status: issued)
- **청구서 탭**: 발송된 청구서 (status: pending/paid/overdue)

**학생/학부모 뷰**: 본인 관련 영수증/청구서만 표시

### 8.3 ReceiptDetailScreen

```
┌──────────────────────────────────────┐
│  ← 영수증 상세                        │
│                                      │
│  ┌──── [영수증 PDF 미리보기] ──────┐  │
│  │  ♩ LESSONAZA                   │  │
│  │  수 강 료 영 수 증              │  │
│  │  ...                           │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌─────────────────────────────────┐ │
│  │       [↓ PDF 다운로드]          │ │
│  │         [공유하기]              │ │
│  └─────────────────────────────────┘ │
│                                      │
│  영수증 번호: 2026-T3fa8b2c1-0042    │
│  발행일: 2026년 5월 7일               │
│  금액: 320,000원                     │
└──────────────────────────────────────┘
```

**PDF 미리보기**: `flutter_pdfview` 또는 `syncfusion_flutter_pdfviewer` 사용

### 8.4 InvoiceSendSheet (Bottom Sheet)

```
┌──────────────────────────────────────┐
│  ▔▔▔▔▔▔                              │
│  결제 안내서 발송                       │
│                                      │
│  수신: 홍길동 (보호자: 홍부모)           │
│                                      │
│  ── 수강 내용 ──                       │
│  바이올린 정기 8회 · 320,000원          │
│  2026.05.07 ~ 2026.06.06             │
│                                      │
│  ── 입금 계좌 ──                       │
│  은행   [국민은행        ▼]            │
│  계좌번호 [123-456-789012     ]       │
│  예금주  [김선생              ]       │
│                                      │
│  입금 기한  [2026-05-14     📅]       │
│                                      │
│  메모 (선택)                          │
│  [5월 수강료입니다 :)             ]   │
│                                      │
│  ┌─────────────────────────────────┐ │
│  │         청구서 발송              │ │
│  └─────────────────────────────────┘ │
└──────────────────────────────────────┘
```

---

## 9. 경쟁사 분석

| 앱 | 결제 방식 | 영수증 | 청구서 | 특이점 |
|-----|---------|--------|--------|-------|
| **My Music Staff** | 여러 방식 | 자동 발행 | 자동 인보이싱 | 입금 추적 대시보드 |
| **Fons** | Stripe 연동 | 자동 발행 | 자동 결제 청구 | 선생님 카드 대금 자동 청구 |
| **StudioMate** | 자체 PG | 월정산서 | 월별 청구 | 학원 중심, 대량 처리 |
| **한국 학원** | 무통장/현금 | 현금영수증 + 세금계산서 | 수기 or ERP | 국세청 연동 |

**Lessonaza 포지션:** 무통장입금 특화, 앱 내 입금 안내 + 증빙 PDF 발행. PG 없이도 학부모 연말정산 증빙 지원.

---

## 10. 구현 단계

### Phase 1 (MVP) — 자동 영수증

**대상:** 입금 확인 시 자동 영수증 생성 + 조회

| # | 작업 | 예상 공수 |
|---|------|---------|
| 1-1 | DB 마이그레이션: `payment_receipts` 테이블 | 0.5일 |
| 1-2 | `receipt_service.py` — 자동 생성 + 채번 로직 | 1일 |
| 1-3 | `subscription_service.confirm_payment()` 훅 연결 | 0.5일 |
| 1-4 | PDF 생성 (WeasyPrint, HTML 템플릿) | 2일 |
| 1-5 | Vultr S3 업로드 + Presigned URL | 0.5일 |
| 1-6 | `GET /api/v1/receipts` + `GET /api/v1/receipts/{id}/download` | 1일 |
| 1-7 | `ReceiptListScreen` + `ReceiptDetailScreen` (Flutter) | 2일 |
| 1-8 | 테스트 (백엔드 시나리오 테스트) | 1일 |

### Phase 2 — 청구서 발송

| # | 작업 | 예상 공수 |
|---|------|---------|
| 2-1 | DB 마이그레이션: `payment_invoices` 테이블 | 0.5일 |
| 2-2 | `invoice_service.py` | 1일 |
| 2-3 | `POST /api/v1/invoices` + `GET` 엔드포인트 | 1일 |
| 2-4 | `InvoiceSendSheet` (Flutter) | 1일 |
| 2-5 | 청구서 상태 전이 (paid 연결: 수강권 입금 확인과 연동) | 0.5일 |

### Phase 3 (미래 후보)

- 이메일 발송 (SMTP 연동)
- 현금영수증 안내 (국세청 직접 신청 안내 링크)
- 연간 수납 통계 리포트
- 카카오 알림톡 연동 (§5.3) — 청구서/영수증 PDF 링크 발송
- 교육비납입증명서 (§5.4) — 사업자 등록 선생님 대상 연말정산 증빙서 자동 발행
- Toss PG 결제 연동 (§4.4) — 웹훅 기반 수강권 자동 발급 + 영수증 자동 생성

---

## 11. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|---------|-------|
| 2026-05-07 | 최초 작성 | Claude |
| 2026-05-31 | PG 결제(Toss) 자동 영수증 흐름 §4.4 추가, 카카오 알림톡 §5.3 추가, 교육비납입증명서 §5.4 추가, Phase 3 항목 보완 | Claude |
