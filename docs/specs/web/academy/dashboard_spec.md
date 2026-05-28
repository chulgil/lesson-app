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

## 4. 데이터 SSOT

| 위젯 | API | 데이터 출처 |
|---|---|---|
| Action Box | `GET /api/v1/academies/{id}/dashboard/tasks` | aggregate query |
| KPI | `GET /api/v1/academies/{id}/stats/dashboard` | 미리 계산된 월간 집계 + 캐시 (TTL 5분) |
| 정산 진행 | `GET /api/v1/academies/{id}/billing/progress?period=YYYY-MM` | invoices + payments 집계 |

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
