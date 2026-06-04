# academy/dashboard_spec — 학원장 콘솔 대시보드

> 기준일: 2026-05-19
> 경로: `/` (콘솔 진입점)
> 마일스톤: AC-M3 (콘솔 MVP)
> 선행: [console_overview_spec.md](console_overview_spec.md), 옵시디언 `21-academy-요구사항.md` §3.1, §7

## 1. 범위

학원장(R-AO) 콘솔 첫 화면. **오늘 처리해야 할 일** + **이번 달 학원 건강 지표** 한 화면 요약.

원칙:
- 개별 학생 노트/녹음 노출 금지 (NFR-A-5)
- 클릭 시 상세 화면으로 이동 (대시보드는 요약만)
- 학원장이 "오늘 무엇을 해야 하나" 5초 안에 파악

## 2. 화면 구성

```
┌─────────────────────────────────────────────────────┐
│ [학원 이름] 학원장 모드 ▼      🔔 12  내 정보 ▼     │
├──────────────┬──────────────────────────────────────┤
│ 사이드바     │ 오늘의 할 일 (Action Box)            │
│              │ • 신규 등록 3건 → 강사 매칭 필요     │
│              │ • 미수금 학생 7명 → 알림 발송        │
│              │ • 강사 결근 1건 → 대강 협의          │
│              │                                      │
│              │ ─────── 이번 달 (3월) ───────        │
│              │ ┌─────────┬─────────┬─────────┐      │
│              │ │ 매출    │ 학생수  │ 강사수  │      │
│              │ │ ₩12.4M  │ 87명    │ 8명     │      │
│              │ │ +12% MoM│ +5명    │ -1명    │      │
│              │ └─────────┴─────────┴─────────┘      │
│              │                                      │
│              │ ─────── 정산 진행 (D-5) ───────      │
│              │ 청구 발송 ████████░░ 80% (70/87명)   │
│              │ 수금 완료 ████░░░░░░ 40% (35/87명)   │
│              │ 강사 배분 ▢ 미정 (수금 완료 후)      │
└──────────────┴──────────────────────────────────────┘
```

## 3. 위젯 정의

### 3.1 오늘의 할 일 (Action Box)

표시 조건 (각 항목 0건이면 숨김):

| 항목 | 표시 조건 | 클릭 시 이동 |
|---|---|---|
| 신규 등록 N건 → 강사 매칭 | `AcademyStudent.status='waiting'` 그룹 카운트 | `/students/waiting` |
| 미수금 학생 N명 → 알림 | `AcademyInvoice.status='unpaid' AND issued_at < now-3d` | `/billing/payments?filter=unpaid` |
| 강사 결근 N건 → 대강 협의 | 오늘 강사 결근 신고된 레슨 | `/teachers?filter=absent_today` |
| 학원 페이지 검토 요청 응답 | `Academy.status='review' AND review_responded_at IS NOT NULL` | `/page` |
| 학부모 문의 N건 | `inbox_messages WHERE replied_at IS NULL` | `/inbox` |
| 강사 배분 명세 확정 필요 | 매월 28일 ~ 말일 + 수금 완료 학생 ≥ 80% | `/billing/settlement` |

### 3.2 이번 달 KPI

3개 카드 (매출 / 학생 수 / 강사 수). 각 카드:
- 큰 숫자 (이번 달 현재 값)
- MoM 변화 (전월 대비 +/-%, 색상: 증가=초록, 감소=빨강)

**API**: `GET /api/v1/academies/{id}/stats/dashboard?period=current_month`

```json
{
  "revenue": { "value": 12400000, "mom_pct": 12.3 },
  "students": { "value": 87, "delta_count": 5 },
  "teachers": { "value": 8, "delta_count": -1 }
}
```

### 3.3 정산 진행 (D-N 표시)

매월 25일 ~ 다음 달 5일 표시. 그 외 기간에는 "다음 정산: D-N" 만 표시.

| 단계 | 진행률 계산 |
|---|---|
| 청구 발송 | `발송된 청구서 / 전체 active 학생` |
| 수금 완료 | `paid 학생 / 발송된 청구서` |
| 강사 배분 | `paid 비율 80% 이상이면 활성` |

각 단계 클릭 시 `/billing/{invoices,payments,settlement}` 이동.

### 3.4 경영 인사이트 KPI (4개 카드, §3.2 다음 행)

기본 KPI(§3.2 매출/학생수/강사수)는 빠른 진단용. 본 §3.4 는 학원장이 의사결정에 쓰는 경영 지표.

| 카드 | 값 | 계산 | 클릭 시 |
|---|---|---|---|
| **미수금** | ₩X (N명) | `SUM(invoice.total - paid_amount) WHERE status IN (sent, overdue)` + 학생 카운트 | `/billing/payments?filter=unpaid` |
| **강사 평균 ROI** | ₩X / 시간 | `이번 달 강사 발생 매출 합계 / 강사 레슨 시간 합계`. 강사별 ROI 는 [teacher_management_spec.md](teacher_management_spec.md) 강사 상세에서 | `/teachers?sort=roi_desc` |
| **신규 학생 (이번 달)** | N명 | `AcademyStudent.registered_at` 이번 달 + status != alumni | `/students?filter=new_this_month` |
| **이탈 학생 (이번 달)** | N명 | `AcademyStudent.status='alumni' AND status_changed_at` 이번 달 | `/students?filter=churned_this_month` |

**원칙:**
- 모든 카드는 MoM 변화 동반 (`+12%` / `-3명` 등)
- 미수금이 ₩0 / 이탈 0명 등 호전 시그널은 초록, 악화는 빨강
- 큰 숫자는 천 단위 콤마 (₩12,400,000), 모바일은 단축 (₩12.4M)

### 3.5 출석 추세 (차트 위젯)

12주 (3개월) sparkline + 학원 평균 출석률 큰 숫자.

```
┌─────────────────────────────────────────┐
│ 출석률   93%  (▲2.1%p MoM)               │
│ ▁▂▃▅▄▃▄▅▆▅▆▇   ← 주별 학원 평균       │
│ 임계치 < 80% → 위험 표시 (전체 평균만)  │
└─────────────────────────────────────────┘
```

- 학원 평균만 표시 (학생 개별 출석은 NFR-A-5 위반 — 차단)
- 임계치 80% 미만이면 카드 테두리 빨강 + 액션 박스에 "이번 주 출석률 X%" 표시
- 강사별 출석률은 [teacher_management_spec.md](teacher_management_spec.md) 강사 상세에서

**API:** `GET /api/v1/academies/{id}/stats/attendance?weeks=12`
```json
{
  "current_pct": 93.2,
  "mom_delta_pct": 2.1,
  "weekly_series": [88.5, 89.2, ..., 93.2]
}
```

### 3.6 학생 LTV (Lifetime Value, 코호트 요약)

```
┌─────────────────────────────────────────────────┐
│ 평균 LTV   ₩2,840,000   /  평균 재학  14.2개월 │
│ ─────────────────────────────────────────────── │
│ 코호트별 (등록월) — 위험 코호트만 빨강:         │
│ 2026-03  ₩820,000  3.1개월  ⚠️ 평균 미달        │
│ 2026-02  ₩1,400,000  4.0개월                    │
└─────────────────────────────────────────────────┘
```

**계산:**
- 학생 LTV = `SUM(해당 학생의 모든 paid invoice)` (등록 ~ 현재)
- 평균 LTV = 활성 + alumni 합산 평균
- 평균 재학 = `현재시각 - registered_at` 평균 (alumni 는 `status_changed_at`)
- 코호트 = 등록월 단위. 평균 미달 (이전 코호트의 평균 LTV 대비 70% 미만) 코호트는 빨강 표시 + 학원장 알림 ("3월 등록 학생 이탈률 높음 — 강사 매칭 점검")

**원칙:**
- 학생 PII 노출 X — 코호트 집계만
- 클릭 시 `/students?filter=cohort_2026_03` (학생 이름만, 노트/녹음 X)
- 학원장 의사결정용: "어느 시점부터 이탈이 늘었나" 시각적 파악

**API:** `GET /api/v1/academies/{id}/stats/ltv?cohort_months=6`

## 4. 데이터 SSOT

| 위젯 | API | 데이터 출처 |
|---|---|---|
| Action Box | `GET /api/v1/academies/{id}/dashboard/tasks` | aggregate query |
| KPI (§3.2 기본) | `GET /api/v1/academies/{id}/stats/dashboard` | 미리 계산된 월간 집계 + 캐시 (TTL 5분) |
| 정산 진행 | `GET /api/v1/academies/{id}/billing/progress?period=YYYY-MM` | invoices + payments 집계 |
| 경영 KPI (§3.4) | `GET /api/v1/academies/{id}/stats/insights` | 미수금 + 강사 ROI + 신규/이탈 학생, 캐시 TTL 30분 |
| 출석 추세 (§3.5) | `GET /api/v1/academies/{id}/stats/attendance?weeks=12` | 주별 출석률 + 학원 평균 |
| LTV 코호트 (§3.6) | `GET /api/v1/academies/{id}/stats/ltv?cohort_months=6` | 등록월 코호트 LTV + 평균 재학 |

## 5. 성능 (NFR-A-2)

- LCP < 2.5s (학생 300명 학원 기준)
- 통계 쿼리 < 1s → Redis 캐시 TTL 5분
- 캐시 무효화: invoice 생성/수정, payment 확인 시

## 6. 빈 상태

| 시점 | 표시 |
|---|---|
| 가입 직후 (학생 0명) | "온보딩 위저드로 첫 학생을 등록하세요" + CTA |
| 이번 달 첫 로그인 | "이번 달 첫 청구일까지 D-N" |
| 모든 task 완료 | "오늘 할 일이 없습니다. 학원 운영이 순조롭게 진행 중입니다." (Notebook 시그니처 영역 일러스트) |

## 7. 권한 / 보안

- `Depends(current_academy_owner)` + `academy_id = current_user.active_academy_id` 강제
- 학원장 모드 외에서 접근 시 403 + AuditLog
- 학생 개별 노트/녹음 데이터는 **이 화면에서 절대 노출 금지** — task 항목에서 학생 이름만 표시 (등록 시점 정보)

## 8. 변경 이력

- 2026-05-19: 초안
- 2026-06-04: §3.4 경영 KPI 4개 카드 (미수금/강사 ROI/신규·이탈 학생) / §3.5 출석 추세 sparkline / §3.6 학생 LTV 코호트 위젯 추가 (갭분석 H#2, H#7 응답)
