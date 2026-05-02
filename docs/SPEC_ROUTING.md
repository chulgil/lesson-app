# Spec Routing — AI 작업 지시용 문서 라우팅

> 최종 업데이트: 2026-05-02
> 목적: Claude에게 작업 지시 시 "어떤 문서를 읽어라/읽지 마라"를 명시하여 토큰 낭비와 상태 모순 방지

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
| 알림 | `notification/notification_master.md` | `notification/notification_system.md` | |
| 스케줄/예약 | `schedule/schedule_master.md` | `booking/unified_lesson_request_spec.md` | `_archive/` |

---

## 2. 마스터 스펙 SSOT 목록 (13개)

> **규칙**: 마스터와 하위 문서가 충돌하면 마스터가 우선

| # | 도메인 | 마스터 | 라인 | 대상 |
|---|--------|--------|:----:|------|
| 1 | 레슨 | `lesson/lesson_master.md` | 1334 | F+B |
| 2 | 연습 | `practice/practice_master.md` | 1713 | F+B |
| 3 | 스케줄 | `schedule/schedule_master.md` | 1503 | F+B |
| 4 | 수강권 | `subscription/subscription_master.md` | 1255 | F+B |
| 5 | 사용자 | `user/user_master.md` | 1753 | F+B |
| 6 | 디자인 | `design/notebook/README.md` | 664 | **F** |
| 7 | 알림 | `notification/notification_master.md` | 516 | B |
| 8 | 메트로놈 | `metronome/metronome_master.md` | 821 | **F** |
| 9 | 온보딩 | `onboarding/onboarding_master.md` | 304 | F |
| 10 | 캘린더 | `calendar/calendar_master.md` | 184 | F |
| 11 | 학생홈 | `student_home/student_home_master.md` | 355 | F |
| 12 | 팔로우 | `follow/follow_master.md` | 324 | F+B |
| 13 | 설정 | `settings/settings_master.md` | 320 | F |

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
| `_archive/` | 폐기된 스펙 (old/ 76개 + phase-log 등) |
| `requirement/requirement.md` | 2025-12 기준, 현재 정책과 충돌 (특히 결제) |
| `requirement/implementation_status.md` | 오래된 상태 추적 |
| `design/design_master.md` | `notebook/README.md`가 최신 디자인 SSOT |
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
- 프론트: `features/[domain]/`
- 백엔드: `backend/routers/[domain].py`
- 스펙: `specs/[domain]/[master].md` §[섹션] 업데이트

### 금지사항
- [특정 금지 사항]
```
