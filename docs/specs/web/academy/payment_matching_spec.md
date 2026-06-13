# academy/payment_matching_spec — 무통장입금 fuzzy 매칭 (수기 보조)

> 기준일: 2026-06-04
> 경로: `/billing/payments/matching`
> 마일스톤: AC-M3 (수기 입력) / AC-M6 (CSV 임포트) / AC-M9 (OCR — 후속)
> 선행: [billing_settlement_spec.md §4](billing_settlement_spec.md), 옵시디언 `21-academy-요구사항.md` §3.1 R-AO-16
> 시장조사 input: `.harness/research/academy_market_2026.md` §B P0 #1 (1인 학원장 매일 페인)

## 1. 범위 / 원칙

한국 소규모 음악학원의 수강료는 **무통장입금 + 카카오 송금 + 현금**이 혼재한다. 학원장이 매일 통장을 보고 학생을 손으로 매칭하는 잡무가 1인 운영의 가장 큰 일상 페인 (시장조사 P0). 본 스펙은 다음을 정의한다:

- 입금 데이터 입력 경로 (CSV / 수기 / OCR)
- 입금자명 ↔ 학생명 fuzzy 매칭 알고리즘
- 한국 특수 패턴 (가족 호칭, 메모 코드, 부분 입금)
- 학원장 1탭 매칭 확정 UX
- audit + 분쟁 예방

**핵심 원칙 (CRITICAL):**

| 원칙 | 의미 |
|---|---|
| 앱은 송금/결제를 수행하지 않는다 | PG / 오픈뱅킹 자동 결제 도입 금지. 본 스펙은 학원장이 통장에서 본 입금을 앱에 기록하는 보조 도구 |
| 자동 매칭 금지 | 알고리즘은 **제안만** 한다. 매칭 확정은 항상 학원장의 명시적 1탭 |
| 가족명 매칭은 보수적 | "어머니/아버지/이모" 패턴은 매칭 확률을 가산하지만 자동 확정 임계치를 넘지 않게 |
| 분쟁 증거 보존 | 매칭 확정 시 입금자 원문 + 매칭 알고리즘 점수 + 확정 사용자 영구 보존 |

## 2. 데이터 모델

```python
class AcademyBankTransaction(Base):
    """학원장이 입력한 입금 원문 (1 통장 거래 = 1 행). 매칭 전후 보존."""
    id = Column(PK)
    academy_id = Column(FK)
    source = Column(Enum("csv", "manual", "ocr"))
    source_ref = Column(String, nullable=True)        # CSV 행번호 / OCR 캡처 ID
    bank_name = Column(String, nullable=True)         # KB / 신한 / 카뱅 / 토스 등
    tx_at = Column(DateTime)                          # 통장 기록 시각
    amount = Column(Integer)
    depositor_raw = Column(String)                    # 통장 원문 ("김지민 어머니", "0418지민")
    memo_raw = Column(String, nullable=True)          # 통장 메모
    matched_invoice_id = Column(FK academy_invoices, nullable=True)
    matched_at = Column(DateTime, nullable=True)
    matched_by_user_id = Column(FK users, nullable=True)
    match_score = Column(Float, nullable=True)        # 0.0-1.0 알고리즘 점수
    match_features = Column(JSON, nullable=True)      # 어떤 신호로 매칭됐는지
    state = Column(Enum("unmatched", "suggested", "matched", "ignored"))

    __table_args__ = (
        Index("idx_tx_academy_state", "academy_id", "state"),
        Index("idx_tx_academy_unmatched_at", "academy_id", "state", "tx_at"),
    )


class AcademyPaymentMatchSuggestion(Base):
    """알고리즘이 학원장에게 제안하는 매칭 후보 (1 tx × N 후보)."""
    id = Column(PK)
    bank_transaction_id = Column(FK)
    invoice_id = Column(FK)
    score = Column(Float)                             # 0.0-1.0
    features = Column(JSON)                           # {"name_levenshtein": 0.85, "amount_exact": 1.0, ...}
    suggested_at = Column(DateTime, default=func.now())
    user_decision = Column(Enum("accepted", "rejected", "pending"), default="pending")
    decided_at = Column(DateTime, nullable=True)
```

## 3. 매칭 알고리즘

### 3.1 신호(feature) 분리

매칭은 **여러 약한 신호의 가중 합**이다. 단일 신호로 자동 매칭 X.

| 신호 | 가중치 | 산출 |
|---|---|---|
| 금액 정확 일치 (±100원) | 0.40 | invoice.total_amount == tx.amount → 1.0 / 부분 / 0 |
| 입금자명 fuzzy (Levenshtein) | 0.25 | 정규화 후 거리 비율 (1 - dist/max_len) |
| 학생명 토큰 포함 | 0.15 | depositor_raw 에 학생 또는 학부모 이름 토큰 포함 → 1.0 |
| 가족 호칭 패턴 | 0.10 | "어머니/엄마/아버지/아빠/이모/할머니" + 학생 이름 토큰 인접 → 1.0 |
| 메모 코드 일치 | 0.05 | memo_raw 에 학생 생일 / 학번 코드 일치 → 1.0 |
| 입금 시각 ↔ 청구 발송 근접 (≤7d) | 0.05 | 7d 이내 → 1.0 / 14d 이내 → 0.5 / 그 외 → 0 |

**총점 임계치:**

| 점수 | 분류 | UX |
|---|---|---|
| ≥ 0.85 | 강한 제안 | 매칭 후보 상단 + 학원장 1탭 확정 |
| 0.60 ~ 0.84 | 약한 제안 | 후보 리스트에 표시 (다른 후보와 비교) |
| < 0.60 | 미제안 | 매칭 안 함, 학원장이 수동 검색 |

### 3.2 정규화 규칙 (입금자명 fuzzy 비교 전)

```python
def normalize_depositor(raw: str) -> str:
    """매칭 비교용 정규화. 원문은 audit 보존."""
    # 1. 공백 제거
    s = re.sub(r"\s+", "", raw)
    # 2. 한글만 추출 (숫자/영문 제거 — 학번/메모 코드는 별도 신호로)
    s = re.sub(r"[^가-힣]", "", s)
    # 3. 가족 호칭 접미사 제거 (별도 신호로 처리)
    for suffix in ("어머니", "엄마", "아버지", "아빠", "이모", "고모", "삼촌",
                   "할머니", "할아버지", "외할머니", "외할아버지"):
        if s.endswith(suffix):
            s = s[:-len(suffix)]
            break
    return s
```

**예시:**

| 원문 | 정규화 | 매칭 대상 |
|---|---|---|
| `"김지민 어머니"` | `"김지민"` | 학생 또는 학부모 |
| `"0418지민"` | `"지민"` | 학생 (메모 코드 별도 신호) |
| `"김아버지"` | `"김"` | 학부모 (성씨만) — 약한 매칭 |
| `"KIM JIMIN"` | `""` (영문 제거) | 폴백: 영문 별도 비교 |

### 3.3 가족 호칭 신호

학생 이름 토큰 + 가족 호칭이 같은 입금자명에 나타나면 +0.10:

- `"김지민 어머니"` → 학생 "김지민" 의 청구서에 +0.10
- `"지민이엄마"` → 학생 "김지민" 청구서에 +0.10 (성씨 누락도 토큰 매칭)

### 3.4 학생명 토큰 매칭

입금자명이 학부모 이름(`AcademyStudent.parent_name`)이 아니어도 학생 이름 토큰이 포함되면 매칭 확률 부여:

- `"이지수아빠"` 의 토큰 `["이지수", "아빠"]` → 학생 "이지수" 청구서에 +0.15 + 가족호칭 +0.10

### 3.5 메모 코드

학원장이 미리 학생별 코드를 설정할 수 있음 (선택):
- `AcademyStudent.deposit_code = "0418"` (학생 생일)
- 통장 메모에 `"0418"` 포함 → +0.05

학원장 화면: `/students/{id}/edit` → "입금 메모 코드" 필드.

## 4. 한국 특수 패턴 매트릭스

| 패턴 | 예 | 처리 |
|---|---|---|
| 가족 호칭 | `"김지민 어머니"` | §3.3 호칭 신호 + 정규화로 학생명 추출 |
| 학생명 포함 입금자 | `"이지수엄마"` | §3.4 토큰 매칭 |
| 메모 코드 | 메모 `"0418지민"` | §3.5 메모 신호 |
| 단축 이름 | `"이수"` (학생 이름 "이지수") | Levenshtein 약한 매칭 (가족명 + 학생명 토큰 모두 점수 부여) |
| 부분 입금 | tx.amount = 100,000 / invoice = 200,000 | 금액 신호 0.5 + 학원장 부분 매칭 옵션 (§7.2) |
| 한 통장 다중 학생 | 한 학부모가 형제 2명 1회 입금 | 후보 리스트에 형제 invoice 모두 표시 + 학원장 분할 매칭 |
| 영문 입금 (외국인) | `"KIM JIMIN"` | 영문 별도 fuzzy 비교 (낮은 가중치) |
| 익명 입금 | `"무통장입금"` | 매칭 불가, 학원장 직접 학생 선택 |
| 다른 학원과 동명이인 | "김지민" 학생 2명 | 후보 둘 다 표시 + 학원장 선택 |

## 5. 입력 흐름

### 5.1 CSV 임포트 (AC-M6)

[billing_settlement_spec.md §4.2](billing_settlement_spec.md) 와 동일 흐름. 추가:
- 업로드 시 자동으로 `AcademyBankTransaction` 행 생성 + `state="unmatched"`
- 매칭 알고리즘 백그라운드 실행 → 점수별 `state="suggested"` 또는 `unmatched` 유지

### 5.2 수기 입력 (AC-M3, 1인 학원장 기본)

`/billing/payments/matching/new`:

```
┌──────────────────────────────────────────┐
│ 입금 1건 입력                            │
├──────────────────────────────────────────┤
│ 통장 캡처 [업로드]   또는              │
│ 입금자명: [           ]                  │
│ 금액:     [           ]                  │
│ 입금시각: [2026-05-03 14:30]            │
│ 통장 메모: [           ] (선택)          │
│ 은행:     [▼ KB]                        │
│                                          │
│           [매칭 제안 ▶]                  │
└──────────────────────────────────────────┘
```

"매칭 제안" → 알고리즘 실행 → §6 결과 화면.

### 5.3 OCR (AC-M9, 후속)

통장 캡처 (사진 / 스크린샷) 업로드 → OCR 로 입금자명/금액/시각 추출 → §5.2 수기 입력 폼 자동 채움. 학원장이 검토 후 "매칭 제안" 클릭. 정확도 80% 목표 (한국 은행 통장 폰트 다양 → 학원장 검토 필수).

## 6. 매칭 제안 UX

### 6.1 1건 매칭 화면

```
┌──────────────────────────────────────────────────────┐
│ 입금 확인                                            │
├──────────────────────────────────────────────────────┤
│ 입금: 김지민 어머니   200,000원  5/3 14:30 (KB)    │
├──────────────────────────────────────────────────────┤
│ 강한 제안 (0.92)                                     │
│ ▸ 김지민 (5월 청구 200,000원)  ✓ 금액일치 ✓ 가족호칭│
│                                       [이 학생으로]  │
├──────────────────────────────────────────────────────┤
│ 약한 제안 (0.68)                                     │
│ ▸ 김지호 (5월 청구 200,000원)  ✓ 금액 ✗ 이름        │
│                                       [이 학생으로]  │
├──────────────────────────────────────────────────────┤
│ [수동 검색]                            [무시]        │
└──────────────────────────────────────────────────────┘
```

- **자동 확정 금지** — 학원장 클릭만 매칭 확정
- 강한 제안도 후보 박스 형태로 표시 (학원장이 한눈에 근거 확인)
- 매칭 근거를 신호 단위로 시각화 (`✓ 금액일치`, `✓ 가족호칭` 등)

### 6.2 일괄 매칭 화면 (CSV 또는 누적 unmatched)

`/billing/payments/matching` — `state="suggested"` 행 리스트. 학원장이 각 행을 빠르게 처리:

```
┌─────────────────────────────────────────────────────────────────┐
│ 미매칭 입금: 12건                                               │
├─────────────────────────────────────────────────────────────────┤
│ 김지민어머니  200,000  5/3   →  김지민 (0.92)  [✓확정][후보▼] │
│ 0418지민      200,000  5/4   →  김지민 (0.81)  [✓확정][후보▼] │
│ 이수엄마      180,000  5/5   →  이지수 (0.76)  [✓확정][후보▼] │
│ 무통장입금    200,000  5/5   →  (없음)         [학생 선택▼]    │
└─────────────────────────────────────────────────────────────────┘
```

- 한 행 = 1탭 확정 (강한 제안)
- 약한 제안은 후보 펼침 → 비교 → 확정
- 미제안은 학생 셀렉터로 수동 매칭
- 학원장이 "이번 회기는 무시" → `state="ignored"` (다음 마감에서 자동 제외)

### 6.3 매칭 확정 시 처리

```
POST /api/v1/academies/{id}/billing/match-transaction
{
  "bank_transaction_id": 42,
  "invoice_id": 87,
  "paid_amount": 200000  # 부분 매칭 시 < total_amount 허용
}

처리:
1. AcademyPayment 행 생성 (source="manual", bank_tx_ref=tx.id)
2. AcademyInvoice.status='paid' (paid_amount >= total)
                      또는 'sent' 유지 + 잔액 (부분)
3. AcademyBankTransaction.state='matched', matched_invoice_id, match_score
4. 학부모 알림: "납부 확인 완료"
5. AuditLog (user_id, tx_id, invoice_id, score, decided)
```

## 7. 엣지케이스

### 7.1 한 입금 → 여러 학생 (형제 합산)

학원장이 "이 입금을 분할" → 형제 invoice 별로 분할 금액 입력 → 각각 `AcademyPayment` 행 생성. `bank_tx_ref` 동일.

### 7.2 부분 입금

`paid_amount < invoice.total_amount` → invoice status='sent' 유지 + `paid_amount` 누적. 학원장 화면에 잔액 표시. 다음 입금으로 누적.

### 7.3 초과 입금

`paid_amount > invoice.total_amount` → 잔액을 "선납" 으로 다음 달 차감 또는 환불 메모. 학원장 선택.

### 7.4 중복 입금

같은 학부모가 같은 invoice 에 2회 입금 → 학원장 알림 + 환불 처리 또는 다음 달 차감.

### 7.5 영업일 외 입금

매칭 시각이 통장 기록 시각 ↔ 청구 발송 시각 차이로만 판단 (영업시간 무관).

### 7.6 잘못된 매칭 취소

`POST /api/v1/academies/{id}/billing/match-transaction/{tx_id}/revert` — 7일 이내 매칭 취소 가능. `AcademyPayment` 행 삭제 + 학부모 알림 (정정).

## 8. 매칭 점수 튜닝 / 학습

- 학원장 행동을 audit 로 기록 (`match_features` 포함). 분기별 분석으로 가중치 조정.
- 학원장이 자주 무시하는 약한 제안 (점수 0.6-0.7 대) 패턴 → 학원별 가중치 자동 미세조정 (선택, AC-M9 이후).
- ML 모델 도입 X (소규모 학원 데이터로 과적합 위험). 룰 기반 유지.

## 9. 권한 / 보안

- 모든 매칭 액션은 `Depends(current_academy_owner)` + academy_id 검증
- 학생 PII 노출 — signed URL TTL 1h
- 통장 캡처 (OCR) 는 학원장 own S3 prefix 저장. 처리 후 24h 삭제 옵션.
- audit 영구 보존 (분쟁 시 운영자 어드민 조회)

## 10. 실패 / 예외

| 상황 | 처리 |
|---|---|
| CSV 파싱 실패 (포맷 다른 은행) | 에러 + 형식 가이드 + 수기 입력 fallback |
| OCR 인식 실패 (필드 부재) | 학원장 수기 입력 폼으로 전환 |
| 후보 0건 + 학원장 수동 검색 시 학생 검색 결과 0 | 신규 학생 추가 안내 또는 "잘못된 입금" 메모 |
| 알고리즘 점수 모두 0.85 이상 (강한 제안 2+) | UI 에 "유사한 후보 여러 건 — 확인 필요" 강조 |

## 11. 변경 이력

- 2026-06-04: 초안 (시장조사 P0 #1 응답 + 한국 무통장입금 특수 패턴 매트릭스 + fuzzy 알고리즘 신호 분리 + 1인 학원장 모바일 수기 입력 흐름)
- 2026-06-05: §2 데이터 모델 BE 추가. `AcademyBankTransaction` (1 통장 거래 = 1 행, depositor_raw/memo_raw 원문 영구 보존 + match_score/match_features JSON) + `AcademyPaymentMatchSuggestion` (1 tx × N 후보, user_decision audit) 2 테이블 + 3 enum (`source` 3종 csv/manual/ocr, `state` 4단계 unmatched→suggested→matched/ignored, `decision` 3단계 pending/accepted/rejected). FK 관계: academy_id, matched_invoice_id, matched_by_user_id (audit), suggestion → bank_transaction + invoice. 인덱스 6종 (academy×state, academy×state×tx_at, matched_invoice 역참조, suggestion tx×score 정렬, suggestion invoice 역참조, UNIQUE per pair). Alembic migration (`ac_m3_payment_matching`, revises `ac_m3_academy_announcements`). models/__init__ export. fuzzy 알고리즘 (§3) / endpoint / OCR / CSV 파싱 / fraud 신호는 별도 후속 작업. AC-M3 payment matching 진입 첫 스텝.
- 2026-06-05: §3 fuzzy 알고리즘 pure function 추가. 6 신호 가중 합 — 금액 정확 (0.40, ±100원 / 부분 0.5 / 그 외 0) / 입금자명 Levenshtein (0.25, 정규화 후 거리 비율) / 학생명 substring (0.15) / 가족 호칭 (0.10, 학생명 토큰 + 11 호칭 접미사 인접 — 외할머니/외할아버지/할아버지/할머니/어머니/아버지/아빠/엄마/이모/고모/삼촌) / 메모 코드 (0.05) / 시각 근접 (0.05, ≤7d 1.0 / ≤14d 0.5). 정규화: 공백 제거 → 한글만 추출 → 가족 호칭 접미사 제거. 임계치: ≥0.85 강한 제안 / ≥0.60 약한 제안 / <0.60 미제안. 단위 테스트 23 시나리오 (정규화 6 / 가족 호칭 감지 3 / 금액 4 / Levenshtein 3 / 학생명 토큰 2 / 메모 코드 1 / 시각 근접 2 / 종합 점수 2). DB / fixture 없는 pure function. §6.1 suggestion endpoint 와 wiring 은 별개 PR.
- 2026-06-05: §4 수기 입력 + 1탭 확정 + §6.1 fuzzy suggestion endpoint 추가 (AC-M3). 7 endpoint: `POST /bank-transactions` (수기 입력, source=manual, state=unmatched), `GET /bank-transactions?state=` (미매칭/제안/매칭/무시 필터), `POST /bank-transactions/{tx_id}/match` (1탭 확정 — AcademyPayment 생성 + invoice 상태 갱신 + tx state=matched + 매칭된 suggestion accepted + 나머지 pending → rejected), `POST /bank-transactions/{tx_id}/ignore` (state=ignored), `POST /bank-transactions/{tx_id}/revert` (§7.6 매칭 취소 — payment 삭제 + invoice paid→sent 회귀 + tx unmatched), `POST /bank-transactions/{tx_id}/suggest` (§6.1 fuzzy 호출 → 0.60+ 후보 AcademyPaymentMatchSuggestion 저장 + top-1 match_score/features 캐싱 + tx.state=suggested), `GET /bank-transactions/{tx_id}/suggestions` (저장된 후보 조회). 권한: `require_owner_context` + `assert_owner` (콘솔 owner 전용). 부분 매칭 시 invoice sent 유지 (§7.2). suggest 재호출 시 pending suggestion 만 삭제 후 재계산 — decided(accepted/rejected) 보존. 검증 17 시나리오 (전액/부분 매칭, ignore/revert, 강/약/미제안, 동명이인 다중, paid 제외, matched suggest 409, confirm 후 다른 suggestion rejected, list 조회, cross-academy 400, non-owner 403). CSV(§5.1) / OCR(§5.3) / 학원장 학생 deposit_code 화면(§3.5) 은 후속.
- 2026-06-05: §6.2 일괄 매칭 화면 inbox endpoint 추가. `GET /billing/payments/matching/inbox` — 처리 대기 tx (state=unmatched/suggested) + 각 tx 의 top-1 pending suggestion + invoice 요약 (`top_invoice_id`, `top_invoice_total`, `top_invoice_period` "YYYY-MM") + 학생 이름 (`top_student_name`) 을 1회 호출로 묶음 반환 (N+1 회피 — tx 1쿼리 / 후보 1쿼리 / invoice+student 1쿼리). 응답 집계: `total_count`, `suggested_count`, `unmatched_count`. matched/ignored 행은 제외 (§6.2 "각 행을 빠르게 처리"). 권한: owner 전용. 검증 4 시나리오 (suggested+unmatched 묶음 반환 / top-1 점수 최고 후보 / matched/ignored 제외 / non-owner 403).
- 2026-06-05: §7.1 형제 합산 분할 매칭 endpoint 추가. `POST /bank-transactions/{tx_id}/split-match` (JSON body `{splits: [{invoice_id, paid_amount}, ...]}`). 한 학부모가 형제 2~N명 동시 입금 시 한 통장 행을 N invoice 에 분할. 각 AcademyPayment 행은 같은 `bank_tx_ref` 공유 (분쟁 시 원천 추적). 분할 시 `matched_invoice_id` 는 NULL 유지 (단일 FK 의미 없음), `matched_by_user_id`/`matched_at` 만 설정. suggestion audit: splits 에 포함된 invoice → `accepted`, 나머지 pending → `rejected`. `revert_match` 도 다중 invoice 대응 — `bank_tx_ref` 의 distinct invoice_id 수집 후 각각 paid→sent/draft 재계산. 검증 7 시나리오 (전액 분할 두 형제 paid / 부분 분할 invoice sent 유지 / 중복 invoice 400 / empty splits 422 / cross-academy 400 / already matched 409 / revert split 모든 invoice 회귀).
- 2026-06-05: §5.1 CSV 일괄 임포트 endpoint 추가 (AC-M3 선반영 — 1인 학원장 월 1회 통장 일괄 업로드 페인 해소). `POST /billing/payments/matching/csv-import` (multipart UploadFile). pure parser `academy_payment_matching_csv.parse_csv` — 한국 은행 한글 헤더 (거래일시/입금일시/입금자명/송금인/금액/입금액/메모/적요/은행/은행명) + 영문 헤더 모두 매핑, 다양한 날짜 포맷 (ISO 8601, `YYYY-MM-DD HH:MM[:SS]`, `YYYY/MM/DD`, `YYYY.MM.DD`) 지원, 쉼표 금액 (`"200,000"`) 처리, 음수/0 금액 거부 (출금 행 제외), UTF-8 BOM 자동 처리 (Excel 저장 CSV 대응), 빈 행 skip. graceful 행 단위: 1행 실패해도 정상 행은 처리되어 `created_count` 에 반영되고 실패 행은 `error_rows` (row_number + reason) 로 별도 보고. 필수 헤더 (거래일시/입금자명/금액) 누락만 전체 422. 행 INSERT 후 각 tx 에 fuzzy `suggest_matches` 자동 호출 → state=suggested/unmatched 자동 분류. 응답 집계: `created_count`, `suggested_count`, `unmatched_count`, `error_rows`. 권한: owner 전용. 검증 16 시나리오 (단위 10: 한/영 헤더 / 헤더 변형 / 쉼표 금액 / 다양한 날짜 / graceful 부분 실패 / 빈 행 skip / 필수 헤더 누락 / 빈 입력 / 음수 거부 + 통합 6: unmatched 일괄 생성 / fuzzy 자동 suggested 카운트 / error_rows 분리 보고 / 필수 헤더 누락 422 / UTF-8 BOM 처리 / non-owner 403). 비범위 (후속): 은행별 raw 포맷 어댑터 (KB/신한/카뱅 고유 CSV 변환), 대용량 백그라운드 매칭(현재 동기), 중복 행 dedup.
