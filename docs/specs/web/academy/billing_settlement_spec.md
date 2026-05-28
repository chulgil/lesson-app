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

## 7. 세금계산서 / 현금영수증 (R-AO-19, Year 2 NTS 연동)

### 7.1 발행 정보 폼

각 학생별 학부모 정보:
- 사업자번호 (사업자) / 주민번호 (개인)
- 세금계산서 / 현금영수증 / 미발행 선택
- 이메일 (사업자) / 휴대폰 (개인)

### 7.2 발행 처리 (Year 2)

NTS API 연동 후 자동 발행. Year 1 은 학원장이 직접 NTS 홈택스에서 발행 (앱은 정보 폼만 제공).

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

## 11. 변경 이력

- 2026-05-19: 초안
