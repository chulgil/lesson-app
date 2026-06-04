# academy/billing_settlement_spec — 수강료 청구 / 수금 / 강사 배분

> 기준일: 2026-05-19
> 경로: `/billing/invoices`, `/billing/payments`, `/billing/settlement`
> 마일스톤: AC-M3 (정산 MVP), AC-M6 (CSV 자동 매칭, 세금계산서)
> 선행: [console_overview_spec.md](console_overview_spec.md), [student_management_spec.md](student_management_spec.md), [teacher_management_spec.md](teacher_management_spec.md), 옵시디언 `21-academy-요구사항.md` §3.1, §6.3

## 1. 범위

학원장(R-AO) 매월 정산 사이클:
- **청구** (R-AO-15): 매달 25일 학생별 PDF 청구서 자동 생성 + 학부모 발송
- **수금** (R-AO-16): 학원장이 통장 확인 후 1클릭 또는 CSV 임포트
- **미수금 관리** (R-AO-17): 3·7·14일 자동 리마인더
- **강사 배분** (R-AO-18): 학원 단위 배분 규칙 적용 → PDF 명세서
- **세금계산서/현금영수증** (R-AO-19): 발행 정보 폼 (NTS API 연동은 Year 2)

원칙:
- **Stripe / 자동 결제 강제 X** — 한국 학원 현실 (계좌이체/현금/카드 혼용) 수용
- **자동 송금 X** — 강사 송금은 학원장이 외부 은행에서 처리 (계좌정보는 학원장 보유)
- 수금/배분은 **학원장 명시 확정** 후 진행 (자동 처리 금지)

## 2. 데이터 모델

```python
class AcademyBillingRule(Base):
    """학원 단위 청구·배분 규칙 (학원 1행)"""
    academy_id = Column(FK, PK)
    invoice_issue_day = Column(Integer, default=25)        # 매월 며칠 발행
    payment_due_days = Column(Integer, default=7)           # 발행 후 며칠 내 납부
    payment_methods = Column(JSON)                          # ["transfer", "cash", "card"]
    bank_account_name = Column(String)                      # 학원 입금 계좌
    bank_account_number = Column(String)
    teacher_distribution_type = Column(Enum("hourly", "revenue_share", "per_student"))
    teacher_distribution_config = Column(JSON)              # {hourly_rate, share_pct, per_student_rates}
    tax_invoice_enabled = Column(Boolean, default=False)    # 세금계산서 발행
    cash_receipt_enabled = Column(Boolean, default=True)

class AcademyInvoice(Base):
    id = Column(PK)
    academy_id = Column(FK)
    academy_student_id = Column(FK)
    period_year = Column(Integer)                           # 2026
    period_month = Column(Integer)                          # 5
    issued_at = Column(DateTime, nullable=True)
    sent_at = Column(DateTime, nullable=True)
    base_amount = Column(Integer)                           # 기본 레슨료
    extra_amount = Column(Integer, default=0)               # 추가 (휴일·보강)
    discount_amount = Column(Integer, default=0)
    total_amount = Column(Integer)
    status = Column(Enum("draft", "sent", "paid", "overdue", "cancelled"))
    due_date = Column(Date)
    pdf_url = Column(String, nullable=True)
    line_items = Column(JSON)                               # [{date, type, amount, memo}]
    tax_invoice_issued = Column(Boolean, default=False)
    cash_receipt_issued = Column(Boolean, default=False)

class AcademyPayment(Base):
    id = Column(PK)
    academy_id = Column(FK)
    invoice_id = Column(FK)
    paid_amount = Column(Integer)
    paid_at = Column(DateTime)
    method = Column(Enum("transfer", "cash", "card"))
    confirmed_by_user_id = Column(FK users)                 # 수금 확인한 학원장
    source = Column(Enum("manual", "csv_import"))           # 1클릭 vs CSV
    bank_tx_ref = Column(String, nullable=True)             # CSV 매칭 시 거래번호

class AcademySettlement(Base):
    """월간 강사 배분 명세 (강사 1명 × 월 = 1행)"""
    id = Column(PK)
    academy_id = Column(FK)
    teacher_member_id = Column(FK academy_members)
    period_year = Column(Integer)
    period_month = Column(Integer)
    calculated_amount = Column(Integer)                     # 자동 계산값
    adjusted_amount = Column(Integer, nullable=True)        # 학원장 수정 후
    final_amount = Column(Integer)                          # 확정값
    status = Column(Enum("draft", "confirmed", "transferred"))
    confirmed_at = Column(DateTime, nullable=True)
    transferred_at = Column(DateTime, nullable=True)        # 학원장이 송금 완료 표시
    pdf_url = Column(String, nullable=True)
    breakdown = Column(JSON)                                # 학생별 기여 내역
```

## 3. 청구 사이클 (R-AO-15)

### 3.1 자동 청구서 생성 (24일 23:59)

```
크론: AcademyBillingRule.invoice_issue_day - 1, 23:59
대상: AcademyStudent.status='active' 학생 전체

각 학생별로:
1. 이번 달 레슨 횟수 조회 (지난달 26일 ~ 이번 달 25일 기준)
2. base_amount = 기본 레슨료 × 횟수 (학원 설정 + 학생별 단가)
3. extra_amount = 보강·휴일 추가 레슨 합계
4. discount_amount = 할인 (예: 형제 할인)
5. AcademyInvoice 행 생성 (status='draft', PDF 렌더링 → S3)
```

### 3.2 일괄 발송 (25일 09:00 — 학원장 명시 확정)

```
1. 학원장 콘솔 알림 "이번 달 청구서 87건 준비 완료"
2. /billing/invoices → 학생별 청구서 미리보기 + 수정 가능
   - 학생별: 금액·항목 수정 / 미발송 처리
   - 일괄: "전체 발송" 클릭
3. POST /api/v1/academies/{id}/billing/invoices/send
   {invoice_ids: [...]}
   → status='sent', sent_at
   → 학부모 카톡 (deep link: lessonaza.app/billing/invoice/{id})
   → 학부모 lesson-app 인박스 알림
   → 청구서 PDF 첨부 (이메일도 옵션)
```

### 3.3 청구서 PDF 내용

- 학원 로고 + 이름 + 사업자번호 + 연락처
- 학생명 + 기간 (`2026-05`)
- 레슨 회차 표 (날짜 / 강사 / 시간 / 금액)
- 추가 항목 (보강, 휴일)
- 할인
- **합계 + 입금 안내 (학원 계좌)**
- 납부 기한 (issued + due_days)
- 학원장 도장 이미지 (선택)

## 4. 수금 확인 (R-AO-16)

`/billing/payments`

### 4.1 1클릭 방법

```
1. /billing/payments?status=sent (발송됐지만 미수금)
2. 학생별 행에 "수금 완료" 버튼
3. POST /api/v1/academies/{id}/billing/payments
   {invoice_id, paid_amount, method, paid_at}
   → AcademyPayment 행 생성
   → AcademyInvoice.status='paid'
   → 학부모에게 "납부 완료" 알림
```

### 4.2 CSV 임포트 (AC-M6)

> 상세 매칭 알고리즘 / 한국 특수 패턴 / 수기 입력 / OCR 흐름은 [payment_matching_spec.md](payment_matching_spec.md) SSOT.

```
1. /billing/payments → "은행 거래내역 CSV 업로드"
2. POST /api/v1/academies/{id}/billing/payments/csv-import
   파일 형식: 날짜, 입금자명, 금액, 거래번호
3. 자동 매칭:
   - 입금자명 == 학부모 이름 → 학생 추정
   - 금액 == 청구 금액 (±1원 허용)
   - 매칭률 > 95% 후보를 표 형태로 표시
4. 학원장 검토:
   - 매칭 OK / 수동 매칭 / 무시
5. POST /api/v1/academies/{id}/billing/payments/bulk-confirm
   → 일괄 확정
```

지원 은행 (M6): KB, 신한, 우리, 농협, IBK + 카카오뱅크, 토스뱅크.

### 4.3 부분 수금 / 초과 수금

- `paid_amount < total_amount` → status='sent' 유지, 잔액 표시
- `paid_amount > total_amount` → 다음 달 청구서 차감 옵션 또는 환불 메모

## 5. 미수금 관리 (R-AO-17)

자동 리마인더 크론:

| 시점 | 액션 |
|---|---|
| sent + 3d 미수금 | 학부모 카톡 (정중) |
| sent + 7d 미수금 | 학부모 카톡 (재안내) + lesson-app 인박스 |
| sent + 14d 미수금 | 학원장 알림 "14일 미수금" + 강사 알림 (레슨 일시 중단 협의) |
| sent + 30d 미수금 | AcademyInvoice.status='overdue' + 학원장 액션 박스 |

학원장이 학부모와 합의 후 일정 연기 / 분할 결제 옵션 (수동 입력):
`PATCH /api/v1/academies/{id}/billing/invoices/{id}` `{due_date, memo}`

## 6. 강사 배분 (R-AO-18)

### 6.1 배분 규칙 (학원 단위, AcademyBillingRule)

세 가지 모드:

**(a) hourly (시간당)**
```json
{
  "type": "hourly",
  "config": { "default_hourly_rate": 30000, "per_teacher_overrides": {"7": 35000} }
}
```

**(b) revenue_share (수강료 %)**
```json
{
  "type": "revenue_share",
  "config": { "default_share_pct": 0.6, "per_teacher_overrides": {"7": 0.7} }
}
```

**(c) per_student (학생별 단가)**
```json
{
  "type": "per_student",
  "config": { "rates": { "student_id_42": 200000, "student_id_43": 180000 } }
}
```

### 6.2 자동 계산 (수금 완료 80% 시점)

조건: 이번 달 paid 학생 비율 ≥ 80% → 학원장 대시보드 액션 "강사 배분 명세 확정 필요"

```
각 강사별:
1. 이번 달 담당 학생의 paid invoice 조회
2. 배분 규칙 적용:
   - hourly: 강사 레슨 시간 × hourly_rate
   - revenue_share: 학생 수강료 합계 × share_pct
   - per_student: 학생별 단가 합계
3. AcademySettlement 행 생성 (status='draft', calculated_amount)
4. breakdown JSON: 학생별 기여 내역 (강사가 PDF에서 확인 가능)
```

### 6.3 학원장 검토 + 확정

`/billing/settlement?period=2026-05`

표:
| 강사 | 학생 수 | 자동 계산 | 수정 | 최종 | 송금 상태 |
|---|---|---|---|---|---|
| 이선생 | 12 | ₩1,800,000 | [수정▼] | ₩1,800,000 | 미송금 |
| 박선생 | 8 | ₩1,200,000 | ₩1,250,000 | ₩1,250,000 | 미송금 |

```
1. 학원장이 강사별 금액 검토 (사유 메모 가능)
2. "전체 확정" 클릭
3. POST /api/v1/academies/{id}/billing/settlement/confirm
   {period_year, period_month}
   → status='confirmed', confirmed_at
   → 각 강사별 PDF 명세서 생성 (S3) → 강사 lesson-app 인박스
   → 학원장 화면에 송금 정보 (강사명, 계좌, 금액) 표
4. 학원장이 외부 은행에서 강사별 송금 처리 (앱이 송금 X)
5. 학원장이 강사별 "송금 완료" 클릭 → status='transferred', transferred_at
```

### 6.4 강사 PDF 명세서 내용

- 학원 정보 + 강사명
- 기간 (`2026-05`)
- 학생별 기여 내역 (학생명·레슨 횟수·금액)
- 합계
- 학원장 메모 (선택)
- 송금 안내 (예: 계좌이체 예정)

### 6.5 강사별 모드 혼합 (소규모 학원 현실)

`AcademyBillingRule.teacher_distribution_*` 은 학원 단위 기본값이지만, 강사별 override 가 가능해야 한다. 소규모 음악학원에서 흔한 패턴:

- 학원장 본인(겸직 강사): `revenue_share` 100% (자기 학생은 자기 매출)
- 고용 강사 A (정규): `hourly` 30,000/시간
- 외주 강사 B (파트타임): `revenue_share` 60%
- 입시 전담 강사 C: `per_student` 단가 (학생당 30만원)

데이터 모델 확장:

```python
class AcademyTeacherPayoutOverride(Base):
    """강사별 정산 모드 override. 학원 기본값과 다른 경우만 행 생성."""
    academy_id = Column(FK, PK1)
    teacher_member_id = Column(FK, PK2)
    distribution_type = Column(Enum("hourly", "revenue_share", "per_student"))
    distribution_config = Column(JSON)               # 모드별 파라미터
    effective_from = Column(Date)                    # 이 정책 시작일
    effective_until = Column(Date, nullable=True)    # 변경 전까지 유효
    note = Column(String, nullable=True)             # 계약 변경 사유
```

원칙:
- override 행이 없으면 `AcademyBillingRule` 기본값 적용
- 정책 변경 시 새 override 행 생성 + 이전 행에 `effective_until` 설정 (히스토리 보존)
- 정산 계산 시 `period_year-month` 의 1일 기준 활성 override 선택

UI: `/billing/settlement/policies` — 강사별 행. 학원장이 "기본값 사용" 토글 또는 모드/단가 override.

### 6.6 정산 기준 + 엣지케이스

**계산 베이스 선택** (학원 단위, `AcademyBillingRule.settlement_base`):

| 베이스 | 정의 | 권장 |
|---|---|---|
| `attendance` | 실제 출석 완료된 레슨만 (status=`completed`) | 시간당/학생당 모드 |
| `invoiced` | 학생 청구액 기준 (출결 무관) | 수강료% 모드 |
| `completed_invoice` | 출석 완료 AND 청구 발생한 레슨 (교집합) | 보수적 — 분쟁 최소 |

**엣지케이스 매트릭스:**

| 상황 | hourly | revenue_share | per_student |
|---|---|---|---|
| 학생 결석 (`no_show`) | 강사가 대기했으면 carry (학원 정책 토글) | 청구 발생 시 share 적용 | carry (월 단위 단가는 동일) |
| 강사 사유 휴강 → 보강 | 보강 시 hourly 적용 (중복 X) | 원래 청구는 그대로, 보강은 추가 없음 | carry |
| 학원장 휴원 (bulk closure) | hourly 미적용 (강사가 없음) | 청구 시 share 적용 (보강 시 carry) | carry (월 단가 보장) |
| 학생 중도 휴원 (월 중) | 출석한 회차만 hourly | 청구된 부분만 share (일할) | 일할 계산 (월×일수/총일수) |
| 노쇼 면제 (`MakeupCredit` 발급) | hourly 미적용 (강사 시간 보상 X) | 청구 발생 시 share | carry |

**기본값:** `settlement_base=attendance`. 학원장이 정책 변경 시 강사들에게 알림 + 다음 달부터 적용 (소급 금지).

### 6.7 강사 서명 + 분쟁 audit trail

명세서 신뢰성 = 학원 운영 분쟁의 핵심. `AcademySettlement` 확장:

```python
class AcademySettlement(Base):
    # ... 기존 필드 ...
    teacher_acknowledged_at = Column(DateTime, nullable=True)  # 강사 확인
    teacher_dispute_note = Column(Text, nullable=True)         # 강사 이의 메모
    adjustment_log = Column(JSON, default=list)                # 학원장 수정 이력
    # adjustment_log 항목: {at, by_user_id, from_amount, to_amount, reason}
```

흐름:
1. `status=confirmed` 시점 → 강사 lesson-app 인박스에 명세서 + "확인" CTA
2. 강사 "확인" 클릭 → `teacher_acknowledged_at` 기록
3. 강사 이의 시 → "이의 제기" → `teacher_dispute_note` 입력 + 학원장 알림
4. 학원장이 수정 시 → `adjusted_amount` + `adjustment_log` 항목 추가 (이전값/사유 보존)
5. 학원장 "재확정" → 강사에게 재확인 요청
6. 송금 후 → `status=transferred` + `transferred_at`

**audit trail 보존:** `adjustment_log` 는 영구 보존 (3.4.3 노트 일시 접근 audit 와 동일 정책). 분쟁 시 운영자 어드민이 조회 가능.

UI: 정산 표 행 클릭 → 사이드패널 → 학원장 수정 이력 + 강사 확인 상태 시각화.

## 7. 세금계산서 / 현금영수증 (R-AO-19, Year 2 NTS 연동)

### 7.1 발행 정보 폼

각 학생별 학부모 정보:
- 사업자번호 (사업자) / 주민번호 (개인)
- 세금계산서 / 현금영수증 / 미발행 선택
- 이메일 (사업자) / 휴대폰 (개인)

### 7.2 발행 처리 (Year 2)

NTS API 연동 후 자동 발행. Year 1 은 학원장이 직접 NTS 홈택스에서 발행 (앱은 정보 폼만 제공).

### 7.3 Year 1 현금영수증 수기 발급 보조 (학원법 의무)

**배경:** 학원법(학원의 설립·운영 및 과외교습에 관한 법률) 시행령에 따라 학원은 수강료 결제 시 현금영수증을 의무 발급해야 한다. NTS 자동 발급 (Year 2) 전까지 학원장이 홈택스에서 수기 발급하는데, 발급 누락 = 가산세 위험. 한국 음악학원 SaaS 중 발급 보조 도구를 제공하는 곳이 없어 차별화 기회.

**보조 도구 (앱은 발급 대행 X, 보조만):**

1. **발급 대상 자동 식별** — `AcademyPayment.method='cash'` 또는 `method='transfer'` 의 모든 행을 "발급 대상" 으로 표시. `cash_receipt_issued=false` 행은 액션 박스에 누적.
2. **발급 체크리스트 (월말)** — `/billing/cash-receipts?period=YYYY-MM` 화면. 학생별 행:
   - 학부모 휴대폰/사업자번호 (사전 입력)
   - 발급 금액 (수금액 자동)
   - "홈택스 발급 → 완료 체크" 버튼
3. **발급 안내 카드** — 학원장이 홈택스 페이지 캡처 또는 발급번호 입력 → `cash_receipt_issued=true`, `cash_receipt_ref` (선택적 발급번호 메모)
4. **누락 경고** — 매월 5일 (전월분 발급 기한 직전) 미발급 행이 있으면 학원장 알림: "5월분 현금영수증 12건 미발급 — 가산세 위험"
5. **세무사 export 와 연동** — 발급 누락 행은 §12 export CSV 에 별도 컬럼으로 표시 (세무사가 확인 후 일괄 처리 가능)

**데이터 모델 확장:**

```python
class AcademyInvoice(Base):
    # ... 기존 ...
    cash_receipt_issued_at = Column(DateTime, nullable=True)  # 발급 완료 시각
    cash_receipt_ref = Column(String, nullable=True)           # 홈택스 발급번호 (선택)
    cash_receipt_target_no = Column(String, nullable=True)     # 휴대폰/사업자번호 (발급 대상)
```

**원칙:** 앱이 NTS API 를 호출하지 않는다 (Year 2 까지). 단순 발급 추적 + 누락 방지 알림으로 차별화. 학원장이 홈택스에서 발급한 사실을 앱에 기록만 한다.

## 8. 통계 / 매출 (R-AO-20)

`/stats` 또는 `/billing` 헤더:

- 월별 매출 추이 (차트)
- 강사별 매출 기여 (Settlement 합계)
- 악기별 / 요일별 매출
- 신규 학생 vs 기존 학생 매출 비율
- 미수금 현황 (총 ₩, 학생 수)

`GET /api/v1/academies/{id}/stats/revenue?from=YYYY-MM&to=YYYY-MM`

## 9. 권한 / 보안

- `Depends(current_academy_owner)` + academy_id 검증
- 수금 확인 / 배분 확정은 AuditLog (user_id, amount, timestamp)
- 청구서 PDF S3 URL 은 학원장·해당 학부모만 접근 (signed URL, TTL 1h)
- 강사 PDF 명세서는 해당 강사 + 학원장만 접근

## 10. 실패 / 예외

| 상황 | 처리 |
|---|---|
| 청구서 생성 시 학생 status='paused' | 청구 스킵, 학원장 알림 |
| 카톡 발송 실패 (학부모 비즈톡 차단) | 이메일 폴백 + 학원장 알림 |
| CSV 매칭 0건 (포맷 불일치) | 에러 표시 + 형식 가이드 링크 |
| 배분 합계 > 수금 합계 (계산 오류) | 학원장에게 경고 + 확정 차단 |

## 11. 한 달 마감 워크플로우 (학원장 모바일 우선)

소규모 음악학원 학원장의 매월 말일 ~ 5일 사이 최대 부담. 5단계를 모바일에서 3-5분 안에 마칠 수 있도록 통합 화면 제공.

**진입:** `/billing/monthly-close?period=2026-05` (모바일 우선 디자인). 학원장 대시보드 액션 박스 "5월 마감 시작" → 진입.

### 11.1 5단계 진행 모델

```
┌─────────────────────────────────────────────┐
│ 5월 마감                              [닫기] │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│ ① 청구  ② 수금  ③ 미수금  ④ 정산  ⑤ 세무 │
│   ✓      ✓      45/50   12 강사  3 발급  │
└─────────────────────────────────────────────┘
```

각 단계는 **명시적 "다음" 클릭으로만 전진** (자동 진행 금지). 학원장이 어느 단계에서든 중단·재개 가능.

| 단계 | 의미 | 차단 조건 | 액션 |
|---|---|---|---|
| ① 청구 | `AcademyInvoice` 전체 발송 완료 | draft 행 있음 | "발송 확정" |
| ② 수금 | paid 학생 비율 ≥ 80% | sent 행 > 20% | "수금 확정 (현재 X%)" |
| ③ 미수금 | overdue 행 처리 | overdue 행 있고 학원장 미확인 | "분할/연기 메모" 또는 "다음 달로 carry" |
| ④ 정산 | `AcademySettlement` 전체 transferred | confirmed 후 미송금 | "강사별 송금 완료 체크" (외부 송금 후) |
| ⑤ 세무 | 현금영수증·세금계산서 발급 완료 | cash_receipt_issued=false 있음 | "발급 체크 (홈택스 외부)" |

### 11.2 모바일 화면 흐름

- 한 화면에 한 단계 (스와이프 또는 "다음")
- 각 단계 상단 "체크리스트" + 하단 "다음" 버튼
- 단계 내 액션은 모두 1탭 단위 (예: ② 의 "전체 수금" 일괄 마킹)
- 끝나면 "5월 마감 완료" + 다음 달 청구 예약일 표시 (예: "6월 청구는 6월 24일 23:59 자동 생성")

### 11.3 마감 후 잠금

`AcademyMonthlyCloseLog` 행 생성. 잠금된 기간(period)의 데이터 변경 시 학원장 재확인 다이얼로그 ("5월은 마감되었습니다. 데이터 변경은 6월 정산에 carry 됩니다."). 강제 차단 X — 학원장 재량.

```python
class AcademyMonthlyCloseLog(Base):
    academy_id = Column(FK, PK1)
    period_year = Column(Integer, PK2)
    period_month = Column(Integer, PK3)
    closed_at = Column(DateTime)
    closed_by_user_id = Column(FK users)
    step_completion = Column(JSON)  # {invoice: at, payment: at, ...} 단계별 완료 시각
```

### 11.4 학원장 외출 시 (모바일 마감)

데이터/네트워크가 끊겨도 단계 진행 가능하도록 각 단계 액션은 멱등성 보장 (이미 paid 행에 "수금 확정" 재요청 시 200). 학원장이 지하철·카페에서 마감하는 시나리오.

## 12. 세무사 Export (Year 1 ~ 영구)

**배경:** 한국 음악학원장은 분기/연간 세무사에게 자료 전달. 현재 학원장은 수기로 엑셀 작성 → 평균 1-2시간 잡무. CSV/엑셀 자동 export 로 차별화.

### 12.1 export 종류

| 종류 | 엔드포인트 | 포맷 | 용도 |
|---|---|---|---|
| 청구·수금 명세 | `GET /api/v1/academies/{id}/billing/export/invoices?from=&to=` | CSV / XLSX | 부가세 신고 (매출 자료) |
| 강사 정산 명세 | `GET /.../billing/export/settlements?from=&to=` | CSV / XLSX | 사업소득 원천징수 자료 |
| 현금영수증 발급 명세 | `GET /.../billing/export/cash-receipts?from=&to=` | CSV / XLSX | 발급 누락 점검 + 세무사 일괄 처리 |
| 통합 (Zip) | `GET /.../billing/export/all?from=&to=` | ZIP (위 3개 + 학원 정보 PDF) | 분기 세무 전달 |

### 12.2 컬럼 표준 (KSI — Korean Studio Invoice)

세무사가 받아 즉시 사용 가능한 컬럼 (한국 음악학원 SaaS 공통 표준 부재 → Lessonaza 표준 정의):

**청구·수금 명세 (invoices.csv):**

| 컬럼 | 예 | 비고 |
|---|---|---|
| 기간 | 2026-05 | YYYY-MM |
| 학생 ID | acdst_42 | 내부 ID |
| 학생명 | 김지민 |  |
| 학부모명 | 김아버지 | 발급 대상 |
| 사업자/주민번호 | 010-1234-5678 | 발급 대상 식별 |
| 청구금액 | 200000 | 원 |
| 수금금액 | 200000 |  |
| 미수금 | 0 |  |
| 수금일 | 2026-05-03 |  |
| 수금방법 | transfer | transfer/cash/card |
| 영수증 종류 | cash_receipt | cash_receipt/tax_invoice/none |
| 영수증 발급 | true |  |
| 영수증 발급일 | 2026-05-04 |  |
| 영수증 발급번호 | (선택) | 홈택스 발급번호 |

### 12.3 학원장 화면

`/billing/export` — 분기 선택 + 종류 토글 → "내려받기" → 학원장 PC 다운로드 (또는 이메일 발송 옵션). 세무사에게 이메일 첨부.

### 12.4 권한 / 감사

- `Depends(current_academy_owner)` — 강사 access 차단
- export 요청은 `AuditLog` (user_id, period, type, downloaded_at)
- export 파일에 PII 포함 — TTL signed URL (1h) 또는 즉시 stream download

## 13. 변경 이력

- 2026-05-19: 초안
- 2026-06-04: §6.5 강사별 모드 혼합 / §6.6 정산 기준 + 엣지케이스 / §6.7 강사 서명 + audit / §7.3 현금영수증 Year 1 보조 / §11 한 달 마감 워크플로우 / §12 세무사 export 추가 (시장조사+갭분석 결과 반영, 소규모 음악학원 학원장 모바일 마감 우선)
