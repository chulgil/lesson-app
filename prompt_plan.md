# 백엔드 갭 분석 + 결제 정책 명시 + Phase 0~1 계획

> 작성일: 2026-05-01
> 모드: `/plan` + adaptive-quality **balanced** (스펙 보강은 fast / 백엔드 코드 변경은 별도 ultra)
> 사용자 결정 (2026-05-01):
> - 결제 모듈 = 무통장입금 + 수동 2단계 확인 (PG 미채택)
> - 향후 PG 도입 시 = 앱 관리자 ↔ 선생님 ↔ 학생 양방향 결제 신규 설계 필요
> - 결제 아키텍처 = **옵시디언 vault + 프로젝트 docs 양쪽에 md 파일** 로 관리

## 배경

프론트엔드 features (20개 도메인) + docs/specs (13개 master) 와 백엔드 (26 라우터 / 64 테이블) 를 매트릭스로 비교한 결과, **9개 영역**이 갭으로 식별됨. 그중 P1-A로 잡았던 **PG 연동**은 사용자 정정으로 **삭제** — 현재 정책은 무통장입금 + 수동 확인이며, 이는 `subscription_master.md` §4.1 에 이미 명시되어 있음. 다만 다음 2가지가 누락:

1. **"PG 미채택"이 정책상 의도된 상태** 라는 점이 백엔드 작업자에게 전달되지 않음
2. **"향후 PG 도입 시 양방향 결제 신규 설계 요건"** 이 정의되지 않음

## 갭 분석 결과 (요약)

```
백엔드 라우터 26개:
  완성     → 23 (lessons / students / schedule / subscriptions / practice 등)
  스텁     → 2  (ai_notes, payments)
  미존재   → 1  (analytics)

부분 구현:
  - 그룹 레슨 출석/대기자 자동화
  - 수강권 만료 dispatcher 연결 (테이블/모델 존재, 스케줄러 트리거 미연결)
  - 온보딩 상태 추적
  - 선생님 검색 필터/정렬
  - 알림 환경설정 적용
```

## 갭 우선순위 (정정 후)

| # | 영역 | 가치 | 의존성 | 복잡도 | Phase |
|---|------|:----:|:------:|:------:|:-----:|
| 1 | **결제 정책 스펙 보강** (PG 미채택 + 미래 설계) | HIGH | 없음 | LOW | **P0** |
| 2 | **payments.py 수동 워크플로우 점검** (6개 API 갭 식별) | HIGH | 1 | LOW-MED | **P1-A** |
| 3 | **Analytics 라우터 신설** | HIGH | 없음 | MED | **P1-B** |
| 4 | **Expiry Dispatcher 스케줄러 연결** | HIGH | Notification, FCM | MED | **P1-C** |
| 5 | AI Notes (Whisper + 요약) | MED | OpenAI, Recording | HIGH | **P2** |
| 6 | 그룹 레슨 자동화 | MED | GroupClass | MED | **P2** |
| 7 | 선생님 검색 고도화 | MED | Teacher | LOW-MED | **P2** |
| 8 | 온보딩 상태 관리 | LOW-MED | User | LOW | **P3** |
| 9 | 알림 환경설정 적용 | LOW-MED | Notification | LOW | **P3** |

## Phase 0 — 결제 아키텍처 스펙 보강 (이번 PR)

### 산출물 (4개 파일)

| # | 파일 | 작업 |
|---|------|------|
| 1 | `docs/specs/subscription/payment_architecture.md` | **신규**. 현행 정책 + 미래 PG 설계 요건 단일 진원지 |
| 2 | `docs/specs/subscription/subscription_master.md` | §4.1.1 (PG 미채택) + §4.1.2 (미래 설계 요건) 추가, 신규 파일 참조 |
| 3 | `docs/specs/backend/backend_spec.md` | "다음 단계" 갱신 — payments 라우터 PG 미진행 정책 명시 |
| 4 | `~/Dev/mybrain/10 Projects/레슨앱/결제-아키텍처.md` | **신규**. 옵시디언 vault 사본. 프로젝트 docs 와 동기화 |

### 결제 아키텍처 핵심 포인트

```
┌─ 현행 (PG 미채택) ──────────────────────────────────────┐
│                                                          │
│  학생 ──외부 은행 앱── 송금 ──▶ 선생님 계좌              │
│   │                                  │                   │
│   └─ [입금완료] ──────────────────▶ Lessonaza            │
│       (학생 자가 신고)               │                   │
│                                      ▼                   │
│                              [입금확인] ─▶ confirmed     │
│                              (선생님 통장 대조 후)        │
└──────────────────────────────────────────────────────────┘

┌─ 미래 (PG 도입 시 — Out of Scope) ──────────────────────┐
│                                                          │
│  학생 ──결제──▶ [앱 관리자 = 에스크로] ──정산──▶ 선생님 │
│                       │                                   │
│                       └── 플랫폼 수수료 N%               │
│                                                          │
│  미정 항목:                                              │
│  - 정산 주기 (실시간 vs 월 1회)                          │
│  - 수수료 모델 (선생님 부담 / 학생 부담 / 분담)          │
│  - 사업자/개인 구분 (세금계산서, 원천징수)               │
│  - 환불 흐름 (관리자 승인 필수 여부)                     │
│  - 에스크로 보유 기간                                    │
│  - PG 선택 (Toss / Portone / 카카오페이 / 이니시스)      │
└──────────────────────────────────────────────────────────┘
```

### Lore Trailer (커밋 시 첨부)

```
Lore-directive: 결제 모듈 PG 미채택 — 무통장입금 + 수동 2단계 확인만 유지
Lore-constraint: 1:1 레슨 시장 수수료 회피 + 선생님 자율성 우선
Lore-rejected: Toss/Portone PG 즉시 도입 — 양방향 정산 설계 미완 상태에서 도입 시 환불/세금/에스크로 정책 누수
```

## Phase 1 — 백엔드 코드 작업 (다음 세션)

### P1-A — payments.py 수동 워크플로우 점검 (진단 → 코드)

| API | 필요 여부 | 현재 상태 | 비고 |
|-----|:---------:|----------|------|
| `POST /payments/{id}/student-confirm` | 필수 | 진단 필요 | 학생이 입금완료 표시 |
| `POST /payments/{id}/teacher-confirm` | 필수 | 진단 필요 | 선생님이 통장 확인 → 수강권 활성화 |
| `POST /payments/{id}/teacher-reject` | 필수 | 진단 필요 | 선생님이 반려 → pending 복귀 |
| `POST /payments/{id}/refund` | 필수 | 진단 필요 | 환불 기록 (외부 송금은 별개) |
| `GET /payments/overdue` | 필수 | 진단 필요 | 미수금 목록 |
| `POST /payments/{id}/remind` | 필수 | 진단 필요 | 수동 입금 알림 발송 |

→ 진단 결과로 **누락 API 정확히 N개** 확정 후 사용자 컨펌 → 구현.

### P1-B — Analytics 라우터 신설

```
GET /analytics/teacher/monthly         (수익/레슨 수/출석률)
GET /analytics/students/{id}/report    (월별 진도/연습률)
GET /analytics/practice-ranking        (학생 랭킹)
```

- 신규 모델 없음, 기존 테이블 read-only 집계
- ORM CTE / window function 사용
- 인덱스 EXPLAIN 검증

### P1-C — Expiry Dispatcher 스케줄러 연결

- `subscription_expiry_dispatcher.py` + `dispatch_log` 마이그레이션 이미 존재
- APScheduler / cron 진입점만 추가 (`scheduler.py` 라우터)
- D-7/D-1 알림 → `notification_service` + `fcm_service`
- 만료 30일 후 `expired` → `past` 자동 전환

## ASCII 아키텍처 (P1 완성 시)

```
┌─ Frontend ──────────────────────────────────────────────────┐
│  payment_card  미수금탭  analytics_screen  expiry_banner    │
└──┬──────┬──────────┬──────────────────────┬─────────────────┘
   │ POST │ POST     │ GET                  │ FCM subscribe
   │ student│ teacher│ /analytics/...      │
   │-confirm│-confirm│                      │
   ▼       ▼          ▼                    ▼
┌─ FastAPI app/api/v1/ ───────────────────────────────────────┐
│  payments.py (수동 only)   analytics.py (NEW)               │
│   ├── student-confirm       ├── /teacher/monthly             │
│   ├── teacher-confirm       ├── /students/{id}/report        │
│   ├── teacher-reject        └── /practice-ranking            │
│   ├── refund (기록)                                           │
│   ├── overdue list          subscriptions.py                 │
│   └── remind                 └── expiry-dispatch (APScheduler)│
│                                                              │
│  ✗ NO PG SDK   ✗ NO webhook   ✗ NO 카드토큰                 │
└──────────────────────────────────────────────────────────────┘
```

## 위험 / 결정사항

| 항목 | 결정 |
|------|------|
| PG 연동 | **하지 않음** (정책 명시) |
| 결제 시크릿 | 없음 (시크릿 노출 위험 0) |
| Analytics N+1 | EXPLAIN 측정 후 인덱스, balanced 모드 |
| Dispatcher 중복 | `dispatch_log` UNIQUE 로 idempotent |
| 옵시디언/프로젝트 동기화 | 양쪽 md 파일 동일 내용, 변경 시 양쪽 갱신 |

## 평가 기준 (rubric)

| 기준 | P0 합격선 | P1 합격선 |
|---|:--:|:--:|
| 완성도 | 9/10 (4파일 모두 산출) | 8/10 (P1-A/B/C 모두 PR) |
| 견고성 | 7/10 (스펙 모순 0) | 7/10 (테스트 추가) |
| 일관성 | 9/10 (Lore trailer + 양쪽 동기화) | 8/10 (도메인 린터 통과) |
| 간결성 | 8/10 (마스터 본문 비대화 없음) | 7/10 |

## 다음 행동

1. **이번 세션**: Phase 0 4파일 작성 + payments.py 진단 (코드 변경 없음)
2. **다음 세션**: P1-A 누락 API 구현 (사용자 컨펌 후) → P1-B → P1-C

---

## 이전 계획

### 선생님 피드백 템플릿 시스템 — Profile 등록 / Lesson 적용 (2026-05-01)

> 모드: `/plan` + adaptive-quality **ultra** (~12 파일 / HiveType 신규 / Mock 데이터 변경 #1 위험)
> 사용자 결정:
> - Q1 = A — 신규 `FeedbackTemplate` 엔티티 (TipTemplate 분리 유지)
> - Q2 = A — 칩 라인 완전 제거, "템플릿 선택" 버튼만 남김
> - Q3 = A — 본문 전체 교체 (기존 입력 있으면 confirm dialog)
> - Q4 = A — 태그는 메타데이터 only (검색/필터, 본문엔 미포함)

#### 요약

선생님이 학생 레슨 피드백을 작성할 때 **개인화된 긴 본문 템플릿** 을 프로필에서 미리 등록하고, 피드백 화면에서는 1탭으로 선택해 본문을 채우는 시스템.

- Phase 1: `FeedbackTemplate` 엔티티 + Hive Box `feedback_templates` + Mock 시드 9개
- Phase 2: `@riverpod` AsyncNotifier + 라우트 `/profile/feedback-templates`
- Phase 3: 관리 화면 (TipTemplateManagementScreen 패턴 미러) + ProfileScreen 메뉴 1행
- Phase 4: `quick_feedback_screen.dart` 칩 라인 제거 + 템플릿 선택 버튼 + ConfirmReplaceDialog
- Phase 5: 정리 + 문서

상세는 `.claude/archive/prompt_plan_20260501_feedback_template.md` 로 이동 (필요 시 재참조).

### 스케줄 탭 UX 재설계 (Phase A 완료, 2026-04-30)

`.claude/archive/prompt_plan_20260501_archive.md` 로 이동.
