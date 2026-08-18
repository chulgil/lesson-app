# Spec Routing — AI 작업 지시용 문서 라우팅

> 최종 업데이트: 2026-06-26 (0절 방향 SSOT 신설 / 직전 2026-05-02)
> 목적: Claude에게 작업 지시 시 "어떤 문서를 읽어라/읽지 마라"를 명시하여 토큰 낭비와 상태 모순 방지

---

## 0. 방향 SSOT — 음악 단일 포커스 (작업 시작 시 먼저 읽기)

> 이 절은 클로드가 어떤 작업이든 시작할 때 1분 안에 현재 정체성과 손대도 되는 문서를 구분하게 하는 가드레일 색인이다.

### 0.1 현재 상태 (확정)

레슨앱은 **음악 단일 카테고리 앱**이다 (2026-08-18 사용자 확정 — 옵시디언 55). 멀티 Discipline(헬스/필라테스/어학) 방향은 **폐기**: fitness·language 등록 카테고리·게이트 코드는 제거됐고, 그룹레슨은 음악(앙상블/반/특강) 형태만 지원한다. 마스터 스펙·glossary 는 음악 전제를 최종 상태로 유지한다.

### 0.2 방향 SSOT 포인터

전환 결정 기록 = 옵시디언 `55-음악-단일-포커스-전환-2026-08-18`. 구 북극성 `36-멀티카테고리-Discipline-플랫폼-설계`(및 이슈 #962~#980)는 **역사 문서** — 재착수 시에만 참조. `Discipline` 값객체와 `disciplineId` wire 필드는 데이터 호환을 위해 music 단독 등록 상태로 **휴면 유지**(신규 카테고리 등록 금지). repo 결정 기록은 커밋 trailer(bare key: Directive/Constraint/Rejected).

### 0.3 용어 충돌 경고 (Category 동음이의)

`카테고리/Category` 는 glossary §14 의 **선생님 설정 5묶음(= SettingGroup)** 만 지칭. 폐기된 "분야" 개념(`Discipline`)의 의미로 `카테고리`를 신규 코드/스펙에서 쓰지 말 것. glossary 수정은 `.harness/knowledge/glossary.md` 가 SSOT, `docs/specs/glossary.md` 는 단방향 미러.

### 0.4 음악 전제 문서 (최종 상태 — 일반화 편집 불필요)

practice 마스터 / practice_screen / youtube_loop / backup / practice_journal_master / metronome_master / avaudioengine_guide / tuner / 분석 대시보드 — 음악 전제가 **최종 상태**다. 과거의 "Phase 일반화 대기" 표기는 폐기됐으며 일반화 편집을 하지 않는다.

### 0.6 stale 주의 (재구현 방지)

옵시디언 `35-선생님휴가...` §8 의 "빈곳" 표는 0622 검토가 코드로 반증 — **A1/A2/A3/A5 구현완료, A4만 미구현**. 구현완료 기능 재구현 금지. (repo `teacher_vacation_mode.md` §8 은 TimeException 구분 — stale 아님, 정상). `payment.md`(레거시) ≠ `subscription_master`(현행).

### 0.7 참조 금지 (archive)

`docs/specs/_archive/`, `docs/requirement/requirement.md`(폐기), `implementation_status.md`, `design_master.md`(SSOT=notebook/README), `schema/entities/payment.md`(레거시), `.claude/rules/archive/` — 역사 링크만, 작업 근거 비대상.

---

## 사용법

작업 지시 시 아래 양식으로 참조 문서를 지정한다:

```
[작업 내용]
참조: docs/specs/lesson/lesson_master.md §3
보조: docs/specs/schedule/schedule_master.md §2.1
금지: docs/specs/_archive/, docs/requirement/
```

---

## 1. 작업 유형별 라우팅

### 프론트엔드 UI 작업

| 작업 | 필수 참조 (1-2개) | 보조 | 금지 |
|------|------------------|------|------|
| 홈화면 수정 | `design/notebook/README.md` | `design/ux_guidelines.md`, `home/home_master.md` | `_archive/`, `design/design_master.md` (중복) |
| 레슨 화면 | `lesson/lesson_master.md` 해당 섹션 | `schedule/schedule_master.md` | `_archive/` |
| 학생 화면 | `student_home/student_home_master.md` | `practice/practice_master.md` | |
| 학부모 화면 | `user/parent_system.md` | `user/parent_dashboard_spec.md` | |
| 수강권 UI | `subscription/subscription_master.md` | | `_archive/` |
| 디자인 토큰 변경 | `design/notebook/README.md` | `design/ux_guidelines.md` | `_archive/` |

### 백엔드 API 작업

| 작업 | 필수 참조 | 보조 | 금지 |
|------|----------|------|------|
| API 엔드포인트 추가 | 해당 도메인 마스터 §API 섹션 | `backend/backend_spec.md` | `_archive/` |
| DB 스키마 변경 | 해당 도메인 마스터 §모델 섹션 | `backend/backend_spec.md` | |
| 시나리오 테스트 | `backend/scenario_testing_guide.md` | | |
| 시드 데이터 | `.claude/rules/seed-data.md` | | |

### 크로스 도메인 작업

| 작업 | 필수 참조 | 보조 | 금지 |
|------|----------|------|------|
| 새 기능 기획 | 해당 도메인 마스터 | `feature_hub.md` §2-3 | `requirement/requirement.md` (2025-12 기준, 오래됨) |
| 결제/수강권 | `subscription/subscription_master.md` | `subscription/payment_architecture.md` | `requirement/requirement.md` (PG 정책 충돌) |
| 초대/관계 | `lesson/invite/invite_system_v2.md` | `lesson/invite/subscription_based_relationship.md` | `_archive/` |
| 학생 설치 웹 랜딩/요약 공유 | `lesson/invite/student_install_web_landing_spec.md` | `lesson/invite/invite_system_v2.md`, `backend/backend_spec.md` | `_archive/`, FastAPI Jinja2 랜딩 직접 구현 |
| 알림 | `notification/notification_master.md` | `notification/notification_system.md` | |
| 스케줄/예약 | `schedule/schedule_master.md` | `schedule/unified_lesson_request_spec.md`(Phase 1~4 라이프사이클), `booking/unified_lesson_request_spec.md`(Phase 1 신청 폼 UX), `schedule/schedule_change_unification_spec.md`(검토 대기 — 일정변경 3계열 통합 제안) | `_archive/` |
| 계측/분석 이벤트 | `analytics/event_instrumentation.md` (이벤트 정의·KPI 산식) | `analytics/event_tracking_spec.md` (수집 인프라) | `analytics/analytics_dashboard_spec.md` (인앱 학생 화면, 사내 지표 아님) |

---

## 2. 마스터 스펙 SSOT 목록 (17개)

> **규칙**: 마스터와 하위 문서가 충돌하면 마스터가 우선

| # | 도메인 | 마스터 | 대상 |
|---|--------|--------|------|
| 1 | 레슨 | `lesson/lesson_master.md` | F+B |
| 2 | 연습 | `practice/practice_master.md` | F+B |
| 3 | 스케줄 | `schedule/schedule_master.md` | F+B |
| 4 | 수강권 | `subscription/subscription_master.md` | F+B |
| 5 | 사용자 | `user/user_master.md` | F+B |
| 6 | 디자인 | `design/notebook/README.md` | **F** |
| 7 | 알림 | `notification/notification_master.md` | B |
| 8 | 메트로놈 | `metronome/metronome_master.md` | **F** |
| 9 | 온보딩 | `onboarding/onboarding_master.md` | F |
| 10 | 캘린더 | `calendar/calendar_master.md` | F |
| 11 | 학생홈 | `student_home/student_home_master.md` | F |
| 12 | 팔로우 | `follow/follow_master.md` | F+B |
| 13 | 설정 | `settings/settings_master.md` | F |
| 14 | 홈 | `home/home_master.md` | F |
| 15 | 프로필 | `profile/profile_master.md` | F |
| 16 | 게이미피케이션 | `gamification/gamification_master.md` | F |
| 17 | 관계 | `relationship/relationship_master.md` | F+B |

**F** = 프론트엔드, **B** = 백엔드, **F+B** = 양쪽

### 백엔드/프론트엔드 분리 원칙

```
프론트엔드 작업 → 마스터 스펙의 UI/화면/상태 섹션만 참조
백엔드 작업   → 마스터 스펙의 API/모델/비즈니스 로직 섹션만 참조
양쪽 동시     → 마스터 스펙 전체 + backend/backend_spec.md
```

마스터 스펙은 도메인 전체를 담고 있어 크다. **TOC를 보고 필요한 섹션만 읽는다.**

---

## 3. 읽지 말아야 할 문서

| 경로 | 이유 |
|------|------|
| `_archive/` | 폐기된 스펙. **AI 작업 시 참조 금지**. 활성 문서에서 역사 참고 링크는 `(아카이브됨)` 표기로 허용 |
| `requirement/requirement.md` | 2025-12 기준, 현재 정책과 충돌 (특히 결제) |
| `requirement/implementation_status.md` | 오래된 상태 추적 |
| `design/design_master.md` | `notebook/README.md`가 최신 디자인 SSOT. 파일 상단에 폐기 배너 추가됨 |
| `dev/implementation_roadmap.md` (v1) | v2로 대체됨 → `_archive/`로 이동 완료 |

---

## 4. 문서 신뢰도 등급

| 등급 | 의미 | 문서 |
|------|------|------|
| **A** (코드 동기화됨) | 최근 코드 변경과 함께 업데이트됨 | `notebook/README.md`, `schedule_master`, `subscription_master` |
| **B** (대체로 정확) | 핵심은 맞지만 세부 수치 오래됨 | `lesson_master`, `practice_master`, `user_master` |
| **C** (참고만) | 방향은 맞지만 현재 코드와 불일치 가능 | `backend_spec`, `follow_master`, `student_home_master` |
| **X** (사용 금지) | 폐기됨 | `_archive/*`, `requirement/*` |

---

## 5. 작업 지시 템플릿

```markdown
## 작업: [제목]

**목표**: [한 줄 설명]
**대상 역할**: 선생님 / 학생 / 학부모
**대상 레이어**: 프론트엔드 / 백엔드 / 양쪽

### 참조 문서
- 필수: `specs/[domain]/[master].md` §[섹션]
- 보조: `specs/[domain]/[file].md`
- 금지: `_archive/`, `requirement/`

### 수정 범위
- 프론트: `frontend/lib/features/[domain]/`
- 백엔드: `backend/app/api/v1/[domain].py` + `backend/app/services/` + `backend/app/schemas/`
- 스펙: `specs/[domain]/[master].md` §[섹션] 업데이트

### 금지사항
- [특정 금지 사항]
```
