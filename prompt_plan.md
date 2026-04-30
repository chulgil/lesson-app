# Notebook × Score §9 아이콘 정책 강제 — Phase 1 plan (현재 진행)

> 작성일: 2026-04-29
> 모드: `/plan --eng` + adaptive-quality **balanced** (정책 신규 + 신규 위젯, 기존 1584건 미터치)
> 사용자 결정 (2026-04-29):
> - **A) A2 정책** — 시그니처 영역(stamp/masthead/empty-state/notebook 프리미티브) 만 ASCII 강제, 일반 navigation/utility 는 Material 허용
> - **B) Phase 1 범위 동의** — 정책 문서 + Adapter + 훅 + 테스트 + 규칙 (6 파일)
> - **C) 추천 매핑으로 자동 진행** — 30개 글리프 매핑 사전 검토 생략

## 배경

- 현황: Material `Icons.*` 1,584건 / 318 파일 사용 (전수 마이그레이션 시 318 파일 churn)
- 사용자 우려: "애플사용자모양" 등 디지털 픽토그램이 노트북 × 스코어 손맛 메타포와 충돌
- 결정: **선택적 강제** — 메타포 진원지(시그니처 영역) 는 ASCII, 시스템 affordance 는 Material 유지

## Phase 1 — 정책 + 인프라 (완료)

### 산출물 6 파일

| # | 파일 | 변경 | 상태 |
|---|------|------|------|
| 1 | `docs/specs/design/notebook/README.md` | §9 아이콘 정책 신규 (9.1~9.8 8 절) | ✅ |
| 2 | `frontend/lib/core/widgets/notebook/notebook_glyph.dart` | NotebookGlyph 위젯 + 31개 글리프 상수 | ✅ |
| 3 | `frontend/test/core/widgets/notebook/notebook_glyph_test.dart` | 10/10 PASS — 기본 렌더 4 + 글리프 상수 2 + 레이아웃 회귀 2 + 시맨틱 2 | ✅ |
| 4 | `.claude/hooks/check-notebook-icon.sh` | PostToolUse stderr 경고 (exit 0). settings.json 등록 완료 | ✅ |
| 5 | `.claude/rules/ux-rules.md` | "Notebook × Score 아이콘 정책 (HARD-GATE)" 섹션 추가 | ✅ |
| 6 | `prompt_plan.md` | 본 plan 아카이브 (기존 백엔드 plan → "이전 계획") | ✅ |

### 정책 요약 (§9)

**시그니처 영역 (강제)**: `core/widgets/notebook/`, `*_stamp.dart`, `*_masthead.dart`, `*empty_state*.dart` → `NotebookGlyph` 사용

**일반 영역 (Material 허용)**: navigation/utility/데이터 인디케이터 — 시스템 affordance 컨벤션 우선

**예외**: `// ignore: notebook-icon` + 사유

**매핑 (31개)**: 음악 6 (♩ ♪ ♫ ♬ 𝄞 𝄢) · 체크 3 (✓ ✗ ✕) · 화살표 7 (→ ← ↑ ↓ › ‹ ») · 별 2 (★ ☆) · 좋아요 2 (♥ ♡) · 점 4 (• · ● ○) · 부호 2 (+ −) · 편집 2 (✎ ✦) · 텍스트 3 (§ ¶ ※)

### 검증 결과

| 항목 | 결과 |
|------|------|
| flutter test (notebook_glyph_test) | ✅ 10/10 PASS |
| flutter analyze (신규 2 파일) | ✅ 0 issues |
| 훅 동작 (like_stamp.dart positive case) | ✅ 2건 경고 검출 (Icons.thumb_up_alt, _outlined) |
| 훅 동작 (notebook_glyph.dart self-exclusion) | ✅ 0건 |
| 훅 동작 (일반 영역 negative case) | ✅ 0건 (profile_visibility_widgets) |

## Phase 2 — Pilot (완료)

**대상**: `like_stamp.dart` (시그니처 영역, 좋아요 도장)

| # | 변경 | 결과 |
|---|------|------|
| 1 | `Icons.thumb_up_alt` (line 55) → `NotebookGlyph.heartFilled` (♥) | ✅ |
| 2 | `Icons.thumb_up_alt_outlined` (line 81) → `NotebookGlyph.heartOutline` (♡) | ✅ |
| 3 | `import 'notebook_glyph.dart';` 추가 | ✅ |
| 4 | `like_stamp_test.dart` 4 라인 갱신 (`find.byIcon` → `find.text('♥/♡')`) | ✅ |

### 검증 결과 (Phase 2)

| 항목 | 결과 |
|------|------|
| flutter test (like_stamp + notebook_glyph) | ✅ 21/21 PASS (LikeStamp 13 + Glyph 8) |
| flutter analyze | ✅ 0 issues |
| 훅 동작 (post-migration) | ✅ 0건 경고 (마이그레이션 완료 확인) |

## Phase 3 — 시그니처 영역 잔재 감사 (완료, 마이그레이션 0건)

**감사 일자**: 2026-04-29
**범위**: §9.4 정의 5개 시그니처 패턴 전수 스캔

| 패턴 | 잔재 | 결과 |
|------|------|------|
| `core/widgets/notebook/**.dart` | 0건 (notebook_glyph.dart 자체 docstring 제외) | ✅ |
| `core/widgets/empty_state_widget.dart` | 0건 | ✅ |
| `**/widgets/*_stamp.dart` | 0건 (Phase 2 like_stamp 마이그레이션 후) | ✅ |
| `**/widgets/*_masthead.dart` | 0건 | ✅ |
| `**/widgets/*empty_state*.dart` | 0건 | ✅ |

**결론**: 시그니처 영역 `Icons.*` 잔재 = **0건**. §9.7 로드맵 "최종 — 시그니처 영역 Icons.* 잔재 0건" 조기 달성. 정책 게이트(check-notebook-icon.sh)가 회귀 방지.

### 별도 결정 게이트 (사용자 확인 필요)

다음은 §9 정책상 강제 대상이 **아니나** 사용자 우려 영역과 인접하므로 별도 결정 필요:

1. **시그니처 영역 외부 emoji 30+ 건** (`🎵` `⭐` 등) — schedule/auth/practice/profile/subscription 도메인
   - 현재 정책: §9.8 NotebookGlyph 상수 추가만 금지, 일반 영역 사용은 미강제
   - 결정 필요: 노트북×스코어 적용 화면(홈, 프로필, 학생카드 등) 의 emoji 도 시그니처로 간주할지
   - 후속 작업 시: 도메인별 grep → 시그니처 vs 일반 분류 → 마이그레이션 PR

2. **시그니처 패턴 확장** (예: `*_card.dart`, `*_section.dart` 중 노트북×스코어 적용 카드)
   - 현재 정책: 강제하지 않음 (A2 선택적 강제)
   - 결정 필요: 훅 적용 범위 확장 여부
   - 상태: **Phase 4 에서 종결 (cherry-pick 채택)**

## Phase 4 — 결정 게이트 2 종결 + cherry-pick (완료)

**일자**: 2026-04-29
**결정 사항**: 훅 패턴 일괄 확장(`*_card.dart` / `*_section.dart`) **지양**.

### 결정 근거

§6.7.3-5 카탈로그 30+ Material `Icons.*` 후보를 전수 분류한 결과:

| 분류 | 비중 | 예시 | A2 정책 적용 |
|------|------|------|-------------|
| 시스템 affordance (navigation) | 60%+ | `chevron_right`, `arrow_back`, `close` | Material 유지 (시스템 컨벤션) |
| Media controls | 20% | `play_arrow`, `pause`, `mic` | Material 유지 (플랫폼 패턴) |
| Data indicators | 15% | `signal_cellular_*`, `wifi_off` | Material 유지 (즉시 인식) |
| 손맛 메타포 후보 | <5% | `Icons.check` (체크리스트 완료) | **cherry-pick 대상** |

→ 훅 일괄 확장 시 60% 이상이 잘못된 경고를 발생시켜 노이즈로 작용. **선택적 cherry-pick** 으로 진행.

### Cherry-pick #1 — `getting_started_card.dart`

| 항목 | 변경 |
|------|------|
| 파일 | `frontend/lib/features/home/presentation/widgets/getting_started_card.dart` |
| 자격 | line 138 주석 명시: "로마숫자 or 체크 — Notebook × Score 시그니처" |
| 변경 | line 143 `Icon(Icons.check, size: 18, color: AppColors.paperOk)` → `NotebookGlyph(NotebookGlyph.check, size: 18, color: AppColors.paperOk)` (체크리스트 완료 ✓) |
| 보존 | line 183 `Icons.chevron_right` (시스템 navigation affordance) — A2 정책 유지 |
| 임포트 | `import '../../../../core/widgets/notebook/notebook_glyph.dart';` 추가 |

### 검증 결과 (Phase 4)

| 항목 | 결과 |
|------|------|
| flutter analyze (lib/features/home/) | ✅ 0 issues |
| flutter test (like_stamp + notebook_glyph) | ✅ 21/21 PASS (회귀 없음) |
| 훅 동작 (시그니처 외부 일반 영역) | ✅ 강제 안 됨 (자발적 cherry-pick) |
| §9.7 README 갱신 | ✅ Phase 4 row 추가 |

### 후속 cherry-pick 후보 (대기)

추후 시그니처 정렬이 명확한 카드/섹션이 발견되면 동일 패턴으로 진행. 현재 우선순위 후보 없음 (A2 정책상 일반 영역은 Material 유지가 기본).

### 결정 게이트 1 (emoji 30+) — 본 series 와 분리

emoji 마이그레이션은 별도 결정 게이트로 미해결 잔존. 사용자 명시 결정 시 별도 plan/이슈로 분기.

## 평가 결과 (Phase 1 자체 채점)

| 기준 | 점수 | 근거 |
|------|------|------|
| 완성도 | 9/10 | 6 산출물 모두 작성 + 검증 5/5 PASS |
| 견고성 | 8/10 | smoke test 10건 (기본·상수·레이아웃·시맨틱) + 훅 positive/negative 검증 |
| 일관성 | 9/10 | §6.7.1 시그니처 프리미티브 폴더 + 기존 like_stamp_test 패턴 정합 |
| 간결성 | 9/10 | NotebookGlyph 70 라인, 단일 책임, BorderRadius 없음 |
| **가중 평균** | **8.75 / PASS** | |

---

## 이전 계획 (Backend 갭 해소)

# 백엔드 갭 해소 — Phase 1~2 plan (완료)

> 작성일: 2026-04-29
> 모드: `/plan --eng` + adaptive-quality **ultra** (마이그레이션 + 27 이벤트 SSOT 정렬)
> 사용자 결정 (2026-04-29):
> - **a) 동시진행 ok** — 백엔드 트랙은 아래 프론트엔드 P2 5-1j 와 병렬 (트랙 분리)
> - **b) 옵션 3** — Phase 1 이슈 등록(17건) + Phase 2 결정 게이트 큐잉 + Plan A Phase 1 진입
> - **c) backend_spec.md 갱신은 별도 이슈로 분리**

## 출처

- `docs/specs/backend/audit/2026-04-28/SUMMARY.md` — 4 도메인 audit, 72 항목 / 13 PASS / 54 갭, 가중 평균 8.6 PASS
- 패치 plan: `patch_plans/A_request_event_ssot.md`, `B_lesson_enum_align.md`, `C_subscription_expiry_cron.md` (모두 미진입)
- 현황: 백엔드 마지막 커밋 1주+ 정체, 프론트는 80+ 커밋 (gap 누적)

## 갭 인벤토리 (이슈 등록 대상 17건)

| # | 우선순위 | 도메인 | 갭 | 패치 plan |
|---|---|---|---|---|
| 1 | P0 | schedule | request_events 테이블 부재 (27 EventType SSOT) | A |
| 2 | P0 | schedule | ScheduleException → 슬롯 차단 미반영 | (신규) |
| 3 | P0 | schedule | Booking overlap 검증 부재 | (신규) |
| 4 | P0 | lesson | BookingStatus enum 7값 정렬 (approved→confirmed) | B |
| 5 | P0 | lesson | NoShowPolicy 4값 통합 | B |
| 6 | P0 | subscription | subscription_expiry_service 부재 | C |
| 7 | P0 | subscription | status 자동 전이 로직 부재 (active→expiring→expired) | C |
| 8 | P1 | schedule | RegularLessonScheduleChange 라우터 미노출 | (신규) |
| 9 | P1 | lesson | LessonService.create pieces 무시 | (신규) |
| 10 | P1 | lesson | RequestEvent SSOT 의존 갭 (Plan A 후속) | A |
| 11 | P1 | student | RosterSummary endpoint 부재 | (신규) |
| 12 | P1 | student | Bulk Teacher Actions (3건) 부재 | (신규) |
| 13 | P1 | subscription | 만료 알림 발송 (FCM/email) | C |
| 14 | P1 | subscription | 자동 연장 옵션 처리 | C |
| 15 | P1 | subscription | 환불/일시정지 정책 미구현 | (신규) |
| 16 | P1 | subscription | 수강권 사용 횟수 동기화 갭 | (신규) |
| 17 | docs | backend | backend_spec.md 154→209 endpoints 갱신 (별도) | (docs) |

## Phase 분해

### Phase 1 — 이슈 등록 ✅ 완료 (2026-04-29)

- [x] P0 7건 등록 (#235~#241)
- [x] P1 9건 등록 (#242~#250)
- [x] backend_spec.md 갱신 1건 등록 (#251)
- [x] prompt_plan.md 본 plan 저장

### Phase 2 — 결정 게이트 ✅ 완료 (2026-04-29, 권장 4건 모두 채택)

| 게이트 | 결정 | 이슈 코멘트 |
|---|---|---|
| Plan B §6.1 BookingStatus.noShow | **A** 제거 → cancelled + NoShowRecord 영속 | #238 |
| Plan B §6.2 BookingStatus.rejected | **A** 제거 → cancelled + decline_reason 컬럼 | #238 |
| Plan B 후속 NoShowPolicy 통합 | 4값 단일 enum | #239 |
| Plan C §7.1 Cron 인프라 | **A** APScheduler in-process + PG advisory lock + dedup table | #240 |
| Plan C §7.2 subscription_settings 스키마 | X 4 컬럼 (Boring) | #240 |
| Plan C §7.3 renewal_alert_days 처리 | 6개월 grace 보존 | #240 |
| Plan C §7.4 만료 알림 수신자 | 학생 + 학부모 (notify_parent flag, 선생님 dashboard 뱃지) | #240 |

차단 해제: alembic `0007_align_booking_status` + `0008_unify_no_show_policy` 진입 가능, `app/core/scheduler.py` + `subscription_expiry_service.py` 진입 가능.

### Phase 3 — Plan A Phase 1 진입 (RequestEvent 모델 + alembic) ✅ 완료 (2026-04-29)

- [x] `backend/app/models/request_event.py` 신규 (27 EventType + 15 column)
- [x] `backend/alembic/versions/20260428_0000_add_request_events.py` 생성
- [x] `backend/app/schemas/request_event.py` Pydantic 스키마
- [x] `backend/app/models/__init__.py` 등록
- [x] TDD: `test_request_event_persists_27_event_types` (Plan A §4.1)
- [ ] alembic upgrade/downgrade 왕복 검증 → **#252 별도 이슈** (사전 체인 단절)

### Phase 4 — 검증 (Phase 3 직후) ✅ 완료 (2026-04-29, alembic 제외)

- [x] `uv run pytest tests/test_request_events_model.py -v` → **4/4 PASS**
- [ ] `uv run alembic upgrade head && uv run alembic downgrade -1 && uv run alembic upgrade head` → **#252 차단**
- [x] `mypy app/models/request_event.py` → Success: no issues found
- [x] Lore-directive 트레일러 포함 커밋 → **1b14e093**

### Phase 5 — Plan B BookingStatus + NoShowPolicy ✅ 완료 (2026-04-29)

- [x] **5a (#238)** BookingStatus 7값 SSOT 코드 정렬 (commit 85f5064e)
  - approved → confirmed (rename), rejected/noShow 제거
  - schedule_service callsites 정리, 192/192 GREEN
- [x] **5b (#238)** alembic 0009_align_booking_status 데이터 마이그레이션 (commit 2f21951a)
  - decline_reason 컬럼 신설, postgres ENUM 재생성, 196/196 GREEN
- [x] **5c (#239)** NoShowPolicy 4값 단일 SSOT (commit b1daec9a)
  - alembic 0010_unify_no_show_policy, IndividualNoShowPolicy → alias, 203/203 GREEN

### Phase 6 — Plan C subscription expiry (#240) ✅ 완료 (2026-04-29)

- [x] **6a** APScheduler in-process + PG advisory lock + cron_dedup 테이블
  - 커밋 `07cc7926`. 215/215 GREEN. alembic 0011 add_sub_expiry_dispatch_log.
- [x] **6b** subscription_expiry_service 만료 전이 로직 (active→expiring→expired)
  - 커밋 `6162a124`. 225/225 GREEN. KST 자정 단일 진원지 + idempotent.
- [x] **6c (P1, #246)** 만료 알림 발송 (FCM + dedup) — email 은 별도 plan
  - 커밋 `1e645264`. 236/236 GREEN. 학생+학부모 dispatch (선생님은 dashboard 뱃지)
  - cron 등록: `register_daily_kst_job(run_subscription_expiry_job, 00:05 KST)`

## 평가 기준 (Rubric, 합격선 7.5)

| 기준 | 가중 | 목표 |
|---|---|---|
| 완성도 | 40% | 9/10 — 17 이슈 등록 + Plan A Phase 1 RequestEvent 모델·migration·스키마·테스트 |
| 견고성 | 30% | 8/10 — TDD Red-Green, alembic 왕복 검증 |
| 일관성 | 20% | 8/10 — Hive entity (typeId 130/131/132) 와 1:1 정합 |
| 간결성 | 10% | 7/10 — 모델 200줄 이내, migration 단일 파일 |

## 리스크

| 등급 | 리스크 | 완화 |
|---|---|---|
| HIGH | enum 7값 정렬이 기존 booking 데이터 깨뜨림 | Plan B 별도 phase, alembic data migration 작성 |
| HIGH | request_events 테이블이 기존 LessonRequest.status 와 SSOT 충돌 | Plan A Phase 5 에서 Outbox 패턴으로 분리 |
| MEDIUM | APScheduler vs docker cron 결정 지연 | Phase 2 게이트로 명시 |
| LOW | 이슈 등록 단순 작업 | gh CLI 검증 (`domain: backend` label 생성 완료) |

## 다음 단계 (실행 순서)

1. ✅ `domain: backend` GitHub label 생성 완료
2. 🔄 prompt_plan.md 갱신 (이 편집)
3. P0 7건 이슈 등록 (Phase 1 본 작업)
4. P1 9건 이슈 등록
5. backend_spec.md 갱신 1건 이슈 등록
6. Plan A Phase 1 진입 — RequestEvent 모델 작성

---

# 추천 액션 순서 P0~P2 — 통합 plan (프론트엔드 트랙, 병렬 진행)

> 작성일: 2026-04-28
> 모드: `/plan --eng` + adaptive-quality **ultra** (스펙 정렬 + 마이그레이션 + 다중 화면 영향)
> 사용자 결정: 추천 순서대로 진행 (P0→P1→P2)

## 요구사항 재정의

5개 우선순위 작업을 단계화해 진행:

| 우선순위 | 작업 | 핵심 변경 |
|---|---|---|
| **P0-1** | 스케쥴변경에 챕터 모델 적용 | `ScheduleChangeSlotScreen` 을 `RequestDetailScreen` 패턴(Masthead+ProgressBar+ChapterSummary+RequestHistoryChat+CurrentRequestBox) 으로 재구성 |
| **P0-2** | ScheduleChangeType/Status dead enum 제거 | `RequestEvent.scheduleChangeType` SSOT 정착, 미사용 잔재 정리 |
| **P1-1** | 스펙 동기화 — 가이드 2색, 확정카드, travel_time | `chat_guide_message_spec` ↔ 코드 매트릭스 정합 + travel_time §7 4 갭 케이스 패치 |
| **P1-2** | 레슨신청 세부 수정 | AppBar 통일, Phase 2 액션박스 3경로 카드, 가이드 색상 분기 정합성 |
| **P2** | i18n AppStrings 마이그레이션 | Phase 5-1h(booking_reschedule) → 5-1i → 5-2 lessons → 5-3 subscription |

## 핵심 발견 (탐색 결과)

- ✅ **공통 위젯 이미 존재**: `core/widgets/chapter_guide_box.dart`, `core/widgets/chapter_summary.dart`, `features/schedule/presentation/widgets/request_history_chat.dart` — 새 위젯 추출 불필요
- ✅ **RequestEvent SSOT 이미 통합**: `RequestEvent.scheduleChangeType` 필드 존재 — dead enum 제거가 핵심
- ✅ **spec 이미 작성됨**: `chat_guide_message_spec.md`, `schedule_confirmation_card_spec.md` — 코드 정합만
- ❌ **travel_time §7 갭 4 케이스**: 부분 차단 / 반차 vacation / 차단경계 incoming travel / 차단직후 outgoing travel — 코드 미구현

## 아키텍처

```
P0-1 (재구성)  →  P0-2 (정리)  →  P1-1 (스펙+travel)  →  P1-2 (UI세부)  →  P2 (i18n)
                                                                        ↑
                                                            (Phase 5-1h 부터 이어서)
```

## P0-1 Phase 분해

### Phase A — 분석 & 매핑 표
- `ScheduleChangeSlotScreen` 현재 구조 라인별 매핑
- `RequestDetailScreen` 의 챕터 패턴 (1410줄) 분해
- 두 화면 공통 차이점 → 재구성 디프 plan

### Phase B — 재구성 적용
- AppBar → Masthead
- Body 를 `CustomScrollView` 또는 `ListView` 로 chapterSummary + history + requestBox 순서로 재구성
- 기존 AlternativeTimeGrid 흐름 보존 (제안 슬롯 선택 로직)

### Phase C — Smoke Test + 회귀
- `test/features/schedule/screens/schedule_change_slot_layout_test.dart` 추가 (BoxConstraints 크래시 방지)
- `flutter analyze` 0 / `flutter test` 통과
- 실기 확인 (학생 경로)

## P0-2 — 완료 (2026-04-28 검증)

phase_a_mapping.md 분석 + 추가 grep 결과:

- frontend: `ScheduleChangeStatus` 호출처 0건 (이미 제거됨)
- frontend: `ScheduleChangeType` 은 `RequestEvent.scheduleChangeType` SSOT 로 정착 (request_event.dart §16-41)
- backend: `ScheduleChangeStatus` 는 `RegularLessonScheduleChange.status` 컬럼에서 active 사용 — dead 아님 (schedule_ext.py §46-50, §181-184)

코드 작업 불필요. P0-2 close.

## P1-1 Phase 분해

### Phase A — 스펙↔코드 정합 ✅ 완료 (commit 0ed0d3c7)
- chat_guide_message_spec 12 상태 ↔ `_getPhaseGuide()` 일치
- schedule_confirmation_card_spec 3타입 ↔ `schedule_confirmation_card_widget` 일치

### Phase B — travel_time §7 4 케이스 패치 ✅ 완료 (2026-04-28)
- `TimeException.containsDateTimeRange(date, slotStart, slotEnd)` 추가
- `_computeSlotsForDate`: 부분 차단 슬롯만 제외 (whole-day 역호환 유지)
- 회귀 테스트 5건 (4 케이스 + 역호환), 5/5 PASS, schedule scope 237/237 통과
- TimeException UI 부분 차단 시간 입력 → 별도 phase 로 분리 (entity 만 준비)

### Phase C — 검증 ✅ 완료
- `flutter analyze lib/features/schedule/ test/features/schedule/` 0 issues
- `flutter test test/features/schedule/` 237/237 PASS
- 스펙 동기화: `travel_time_spec.md` §7.4/7.5 갱신

## P1-2 — 완료 (2026-04-29 검증)

### Phase A — AppBar 통일 ✅ 완료 (commit 99c26539, W2 번들)
- `AllLessonRequestsScreen` (line 60-65) + `SuggestAlternativeScreen` (line 147-152) → `NotebookTypography.appBarTitle` 적용
- `RequestDetailScreen._buildChatAppBar` (line 334) — 기존부터 적용 (§7.27 기준)
- 검증: `flutter analyze` 0 / `flutter test test/features/schedule/` 237/237 PASS

### Phase B — Phase 2 3경로 카드 ✅ 완료 (이미 정렬)
- 3 경로 (선불/후불/무료) 는 `current_request_box.dart` 가 아닌 `proposal_bottom_sheet.dart::_buildPaymentMethodSelector` (line 224-272) 에 위치
- chip 시각 일관성 OK: 선택 시 `paperAccent` bg + `paper` text + w600, 미선택 시 transparent + `inkSecondary`
- `current_request_box.dart::_buildPhase2PaymentChoice` 는 단일 진입 버튼 → BottomSheet 호출

### Phase C — 가이드 색상 2색 분기 ✅ 완료 (검증)
- `request_history_chat.dart::_getPhaseGuide()` 12 상태 전수 확인 → `ChapterGuideVariant.action / .wait` 2색만 사용
- `ChapterGuideVariant.neutral` 은 `_PhaseGuide` default 정의용, 어느 케이스도 사용 안 함 (5색 회피 정합)

## P2 진행 상황

- 5-1a~5-1g 완료 (commits: df846fab, 1a290003, 1accb9d6, b1580850, 5f4d5c2a, b0c96b58, 37090589)
- 5-1h booking_reschedule_screen 완료 (2026-04-29) — 17 신규 키 + 4 재사용 (cancel, cannotLoadData, rescheduleUsageStatusWithColon, rescheduleNoMoreAfter), 20 사이트, schedule scope 237/237 PASS
- 5-1i schedule_tab + lesson_requests + request_detail 완료 (2026-04-29) — 10 신규 키 + 7 재사용 (retry, lessonComplete, statusCompleted, actionLessonCancel, cancel, goBack, errorOccurred), 20 사이트, schedule scope 237/237 PASS
- 5-1j request_completion + unified_lesson_request + my_bookings 완료 (2026-04-29) — 30 신규 키 + 7 재사용 (requestCompleteTitle, lessonTypeLabel, instrumentFallback, teacher, durationMinutesValue, cannotLoadData, statusCompleted, cancel), 30 사이트, schedule scope 237/237 PASS
- 5-2a teacher_attendance + lesson_note_history + quick_feedback_student_list 완료 (2026-04-29) — 19 신규 키 + 2 재사용 (errorOccurred, statusCompleted), 18 사이트, lessons 46/46 + schedule 237/237 PASS
- 5-2b lesson_confirmation_dialog 완료 (2026-04-29) — 11 신규 키 + 9 재사용 (lessonConfirmation, lessonComplete, lessonNotCompleted, selectReason, nonCompletionReason, mon~sun), 18 사이트, lessons 46/46 PASS
- 5-2c-1 bulk_feedback_screen 완료 (2026-04-29) — 17 신규 키 + 3 재사용 (errorOccurred, statusCompleted, statusUpcoming), 17 사이트, lessons 46/46 + schedule 237/237 PASS
- 5-2c-2 lesson_notes_widgets 완료 (2026-04-29) — 18 신규 키 + 7 재사용 (add, delete, modify, no, save, cancelRequestAction, actionLessonCancel), 28 사이트, lessons 46/46 PASS
- 5-2c-3 edit_lesson_screen 완료 (2026-04-29) — 13 신규 키 + 5 재사용 (save, student, actionLessonCancel, deleteLessonTitle, lessonDurationLabel), 19 사이트, lessons 46/46 + schedule 237/237 PASS
- 5-2c-4 quick_feedback_screen 완료 (2026-04-29) — 18 신규 키 + 4 재사용 (add, delete, loadDataFailed, feedbackEditorHint), 22 사이트, lessons 46/46 + schedule 237/237 PASS
- 5-2c-5 add_practice_item_sheet 잔여 + 5-2c 종료 확인 (2026-04-29) — repertoireSectionCount 1 신규 키, 1 사이트. lesson_detail_screen + add_lesson_screen 은 30차 단계에서 이미 한글 0건 (마이그레이션 완료 상태). 5-2c 전체 완료.
- 5-2c-6 레슨 위젯 잔여 11파일 (2026-04-29) — 5-2c 클로즈 후 누락 발견. 자료 첨부(YouTube/녹음/외부링크), 연습 과제, 레슨 폼/편집/취소 다이얼로그, 팁 템플릿 바텀시트 전수. 신규 키 ~50개 + 재사용 다수, lessons 46/46 PASS.
- 5-3a subscription 알림/정책/템플릿 5파일 (2026-04-29) — expiry_monitor + proposal_reminder + skip_reason_dialog + subscription_policy_sheet + template_choice_card. 신규 키 ~25개, subscription 63/63 PASS. 잔여 ~38 파일은 5-3b 이후.
- 5-3b-1 issue_form_type_options 7 사이트 (2026-04-29) — 5-3a 정의 키 (issueFormLessonsTitle/Suffix, issueFormValidityTitle/Suffix, issueFormMonthlySectionTitle, issueFormMonthsLabel, issueFormTrialNotice) 재사용, 신규 키 0건. subscription 63/63 PASS. 5-3a close 커밋(`bba9639e`)에 번들 포함.
- 5-3b-2 subscription_chapter_lessons + selectable_template_card 4 사이트 (2026-04-29) — 신규 키 4개 (sessionBookingRequired, templateRecommendedBadgeStar, templateSummaryLine, templatePerLessonPrice). subscription 63/63 PASS.
- 5-3b-3 issue_form 위젯 3파일 ~37 사이트 (2026-04-29) — issue_form_sections + issue_form_membership_widgets + issue_form_discount_bonus. 신규 키 ~37개 (TypeSection·PaymentSection·AmountSection·StartDate·Membership·Discount·Bonus). flutter analyze — No issues. 커밋 `59607f65` (키) + `4839fc38` (마이그레이션). 잔여 ~32 파일은 5-3b-4 이후.
- 5-3b-4 subscription entities 6파일 ~58 사이트 (2026-04-29) — subscription + subscription_proposal + lesson_policy + subscription_usage + subscription_settings + subscription_template. 도메인 display getter 전수 AppStrings 경유 (결제수단/유형/상태/summary/detail/billing/fifthWeek/policy/usage 라벨 + 시간경과/만료 표시). 신규 키 ~55개 + 재사용 (individual, academy, expired, durationMinutesValue, subscriptionTypeMonthly). subscription 63/63 PASS. 커밋 `fba12be9`.
- 5-3b-5 location_travel_selector 18 사이트 (2026-04-29) — 위치 5종 chip label + 주소 5종(읽기/입력/로딩/실패) + 이동시간 4종 키 신설. 신규 키 16개 (`locationStudentHomeLabel` 등) + 재사용 3건 (`academy`, `lessonLocationLabel`, `durationMinutesValue`). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `2d628cca`. 잔여 ~17 파일은 5-3b-6 이후.
- 5-3b-6 issue_form_summary_widgets 22 사이트 (2026-04-29) — SubscriptionSummaryCard + BatchSummaryCard + BatchInfoBanner + AppliedPolicySection. 신규 키 17개 (issueFormSummaryTitle/BatchTitle, TypeLabel, FinalAmountLabel, AmountLabel, PaymentLabel, EndDateLabel, UnpaidLabel, PaymentConfirmed/DiscountValue/BonusValue/PolicyChangeLine 포매터, LessonsTrial/Package/PackageWithBonus/Monthly, BatchBannerTitle/Body, BatchTargetLabel, BatchStudentCount, BatchPerPersonLabel, BatchTotalLabel) + 재사용 8건 (policyApplied/ChangeCancel/NoShow/Carryover, issueFormAmountSection/Discount/Bonus/StartDate). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `5382bb70` (키) + `98873d88` (마이그레이션).
- 5-3b-6+ expiring_subscriptions_screen 7 사이트 (2026-04-29) — AppBar 3 사이트(loading/error/data) + 학생 수 부제 + 에러 메시지 + 학생 이름 fallback + 빈 상태(title/body) + 발급 버튼. 신규 키 4개(studentsCountSubtitle, studentNameFallback, expiringEmptyTitle, expiringEmptyBody)는 5382bb70 에 이미 존재. 재사용 3건 (subscriptionViewAction, errorTryAgain, issueSubscriptionButton). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `b71e4b53`. 잔여 ~16 파일은 5-3b-7 이후.
- 5-3b-7 proposal_card_widgets 26 사이트 (2026-04-29) — ProposalStatusBanner 5 + ProposalHeaderCard 1 + ProposalDetailsCard 4 + ProposalMessageCard 1 + ProposalDiscountCard 4 + _formatPrice 3 + ProposalPaymentInfoCard 6 + _PaymentInfoRow 2 + ProposalWaitingCard 3. 신규 키 26개 (proposalBanner 5종, proposalHeaderSubtitle, proposalDetailsLessons/Duration/Validity, proposalMessageCardLabel, proposalDiscountReason/Final, proposalPriceManwon/ManRemainder/Won, proposalPaymentBank/Info/AccountNumber/Holder/Change/Copied/Copy 7종, proposalWaitingTitle/Body/ContactCta) + 재사용 5건 (issueFormSummaryAmountLabel, durationMinutesValue, issueFormValidityTitle, issueFormAmountSectionTitle, issueFormDiscountTitle). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `f22c1675` (키) + `cd586ed5` (마이그레이션). 잔여 ~15 파일은 5-3b-8 이후.
- 5-3b-8 subscription_card 14 사이트 (2026-04-29) — 진행바 2 (남음 prefix, 보너스 분해), 상세 헤더 1 (📋 상세), 상세 행 라벨 8 (• 기본/보너스/사용/잔여/변경/유효기간/결제/5주차) + 값 회차 (`usageCountShort`), 보너스 reason fallback, 월정액 이월 경고, 회차권 자유사용 안내. 신규 키 14개 (subscriptionRemainingPrefix/BonusBreakdown, DetailHeader, DetailRow* 8종, BonusReasonFallback, MonthlyCarryoverWarning, PackageFreeUseInfo) + 재사용 5건 (usageCountShort × 3, issueFormSummaryBonusValue, rescheduleCount). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `3a8cfe39` (키) + `52812ec9` (마이그레이션). 잔여 ~14 파일은 5-3b-9 이후.
- 5-3b-9 subscription domain services 7 사이트 (2026-04-29) — auto_proposal_service 3건 (골든타임 할인 사유 + 자동 제안 메시지 인사/시간/할인율/마무리) + subscription_renewal_service 4건 (소진/마지막1회/N회/마무리). 신규 키 9개 (autoProposalGoldenTimeReason 포매터, autoProposalGreeting/GoldenTimeHours/GoldenTimePercent/SelectionPrompt, renewalMessageDepleted/LastOne/Remaining 포매터/Continue). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `8aed2089` (키) + `9928f702` (마이그레이션). **주의**: 커밋 메시지의 `5-3b-8` 라벨은 외부 동시 편집과 충돌 — 본 plan 에서는 5-3b-9 로 등록. 잔여 ~13 파일은 5-3b-10 이후.
- 5-3b-10 issue_subscription_actions 10 사이트 (2026-04-29) — 단건 발급 검증 3건 (membership/startDate/bonusReason) + 단건 발급 성공 snackbar + 단건 발급 실패 snackbar (2회) + discountReason 합성 (단건+일괄 2회) + 일괄 발급 결과 snackbar 2건 (전체 성공/부분 성공) + 선생님 fallback 2건 (registerRegularLesson extra + scheduleConfirmationCard). 신규 키 8개 (chooseLessonValidation/chooseStartDateValidation/chooseBonusReasonValidation, discountPercentReason 포매터, subscriptionIssueSuccess/subscriptionIssueFailRetry, batchSubscriptionIssueSuccess/batchSubscriptionIssuePartial 포매터) + 재사용 1건 (teacher × 2). 신규 키는 8aed2089(parallel sweep)에 이미 추가됨. subscription 63/63 PASS, flutter analyze — No issues. 커밋 `6033fd29` (마이그레이션). 잔여 ~12 파일은 5-3b-11 이후.
- 5-3b-11 proposal_confirm_screen 12 사이트 (2026-04-29) — 기본 파라미터(teacherName) + AppBar(paymentConfirm) + 빈 상태(title/body) + 학생 fallback(loading/error/null) + 입금 알림 포매터 + 템플릿 fallback(error/null) + 템플릿 summary 포매터(회수·시간·유효기간) + 액션 버튼(입금 미확인/입금 확인 → 수강권 발급) + 발급 SnackBar(성공/실패) + 입금 미확인 다이얼로그(제목·본문·메시지 보내기) + 발송 SnackBar + 상대 시간(분/시간/일 전 → timeAgoMinutes/Hours/Days). 신규 키 0건 (8aed2089 parallel sweep 에서 선반영) + 재사용 12건. subscription 63/63 PASS, flutter analyze — No issues. 커밋 `2fd01a64` (마이그레이션). **주의**: 커밋 메시지의 `5-3b-10` 라벨은 6033fd29 와 충돌 — 본 plan 에서는 5-3b-11 로 등록. 잔여 ~11 파일은 5-3b-12 이후.
- 5-3b-12 subscription_list_screen 10 사이트 (2026-04-29) — AppBar 타이틀 + _createPlaceholderMembership instrument + 수강권 0건 빈 상태(title/body 인터폴레이션) + 멤버십 0건 빈 상태(title/body/CTA) + 에러 상태 + lessonClass 로딩/에러 className fallback 2건. 신규 키 7개 (subscriptionListAppBarTitle, noSubscriptionsRegisteredTitle, noSubscriptionsRegisteredBody 포매터, noLessonsRegisteredTitle, noLessonsRegisteredBody, teacherSearchButton, lessonClassErrorFallback) + 재사용 3건 (instrumentFallback, errorOccurred, individualLesson). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `b5910c66` (키) + `07dcc311` (마이그레이션). 잔여 ~10 파일은 5-3b-13 이후.
- 5-3b-13 issue_subscription_screen 10 사이트 (2026-04-29) — 보너스 reason 비교('기타') + AppBar(단건/일괄 분기, 일괄 composite) + 변경/취소 가능 횟수 섹션(제목·설명) + 정책 안내 2건(matches/override composite) + ChoiceChip 라벨(불가/N회) + 하단 발급 버튼(단건/일괄 분기, 일괄 composite) + _PolicyBadge 라벨(기본/조정됨). 신규 키 9개 (batchSubscriptionAppBarTitle/batchIssueButtonLabel 포매터, rescheduleAllowanceTitle/Description/MatchesPolicy/OverridePolicy/None, policyBadgeDefault/Custom) + 재사용 4건 (issueFormBonusReasonOther, proposalTitle × 2, usageCountShort). 신규 키는 456b381a(parallel sweep)에 이미 추가됨. subscription 63/63 PASS, flutter analyze — No issues. 커밋 `105d6195` (마이그레이션). 잔여 ~9 파일은 5-3b-14 이후.
- 5-3b-14 student_proposal_accept_screen 13 사이트 (2026-04-29) — AppBar(수강권 선택) + 에러 상태 + 제안 null 빈 상태 + 선생님 fallback + 헤더(name 포매터·subtitle) + 거절 버튼 + 결제 안내 divider + 결제 캡션 + 복사 버튼 + 수락 SnackBar + 에러 재시도 SnackBar 2건 + 거절 SnackBar + 클립보드 SnackBar. 신규 키 8개 (studentProposalAcceptAppBarTitle, proposalNotFoundEmpty, teacherWithName 포매터, proposalSubmittedSubtitle, proposalDeclineNextTime, paymentDepositInstruction, subscriptionSelectedSnackbar, proposalRejectedNextTimeSnackbar) + 재사용 6건 (teacher, errorOccurred, errorTryAgain × 2, eventPaymentRequested, proposalPaymentCopyLabel, proposalPaymentAccountCopied). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `456b381a` (키, 외부 5-3b-13 keys 번들 포함) + `1e38b2d6` (마이그레이션). **주의**: 외부 세션이 동일 시각에 5-3b-13 진행 중 — staged 키가 working tree 에 있어 본 키 커밋에 함께 번들됨, 본 plan 에서는 5-3b-14 로 재매핑. 잔여 ~8 파일은 5-3b-15 이후.
- 5-3b-15 proposal_create_screen 22 사이트 (2026-04-29) — 기본 파라미터(teacherName=teacher) + AppBar(수강권 제안) + error fallback 2건 + 학생 0건 빈 상태(title/body) + 템플릿 0건 빈 상태(title/body/CTA) + 3-step header (학생 선택 + 수강권 선택 max formatter + 메시지 선택) + student dropdown hint + template info banner(단일/복수) + recommended 안내 + 복수 선택 카운터 formatter + 메시지 입력 hint + 송신 버튼(단/복수 formatter) + 즉시 발급 버튼 + 즉시 발급 help + templateName fallback(수강권) + 송신 SnackBar(단/복수 formatter) + 실패 SnackBar. 신규 키 19개 (proposalCreate AppBarTitle/NoStudents{Title,Body}/NoTemplates{Title,Body}/TemplateButton/StepStudent/StepTemplateMaxFormat/MessageOptional/StudentSelectHint/TemplateInfoBanner/RecommendedHint/MultiSelectInfoFormat/MessageHint/ImmediateIssueHelp/SentMessage/MultiTemplateSendFormat/MultiSentMessageFormat/FailMessage) + 재사용 5건 (proposalSend, proposalTypeDirectIssue, subscription, teacher, errorOccurred × 2). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `53c5ec1e` (키) + `344cdb91` (마이그레이션). **주의**: 외부 세션이 5-3b-12 / 13 / 14 점유 — 본 plan 에서는 5-3b-15 로 재매핑. 잔여 ~7 파일은 5-3b-16 이후.
- 5-3b-15a proposal_create_screen 잔여 2 사이트 패치 (2026-04-29) — 5cac8ad3 클로즈 후 grep 재검증으로 누락 발견: 추천 지정 SnackBar(`'${template.name}을 추천으로 지정했습니다'`) + 선택 카운터 라벨(`'$len/$max개 선택'`). 신규 키 2개 (proposalCreateRecommendedDesignatedFormat 포매터, proposalCreateSelectedCountFormat 포매터). 키+마이그레이션 단일 커밋 `3d9db2df` (2 사이트 follow-up 단위라 surgical). 한글 grep 결과는 doc 주석만 잔존. **교훈**: "한글 grep clean" 클로즈 후에도 교차 grep 필수.
- 5-3b-16 renewal_detail_screen 14 사이트 (2026-04-29) — AppBar(수강권 갱신 제안) + 에러/null 폴백 + 선생님 폴백 + 갱신 헤더(name 포매터) + 템플릿 선택 프롬프트 + 추천 배지 + "지난번과 동일" 힌트 + 입금 알림 SnackBar + 오류 SnackBar × 2 + 수강권 선택 CTA + 나중에 할게요 CTA + 거절 SnackBar. 신규 키 7개 (renewalProposalAppBarTitle, renewalSelectTemplatePrompt, renewalProposedByFormat 포매터, renewalSameAsPreviousHint, renewalSelectButton, renewalDeclineLater, renewalDeclineSnackbar) + 재사용 7건 (errorOccurred, proposalNotFoundEmpty, teacher, templateRecommendedBadge, paymentReminderSent, errorTryAgain × 2). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `6d098429` (키) + `4f8038a8` (마이그레이션). **주의**: 외부 세션이 동시 5-3b-17(proposal_detail_screen) 진행 중 — staged 5-3b-17 키를 잠시 제거 후 본 키 커밋, 즉시 복원하여 외부 세션 작업 보존. 잔여 ~6 파일은 5-3b-17 이후.
- 5-3b-17 proposal_detail_screen 25 사이트 (2026-04-29) — AppBar(수강권 제안) + 에러/null 폴백 + 템플릿 null 폴백 + 다중 선택 헤더 + 헤더 타이틀(2회 재사용) + 자동 발송 배지 + from-teacher subtitle + 추천 배지 + 연락처 시트(title 포매터/call/message) + 프로필 not-found/contact-not-available + 프로필 loading/load-error + 전화번호 복사 SnackBar 포매터(2건) + 선택 필수 힌트 + 입금 완료 CTA + 스킵 CTA + 입금 알림 SnackBar + 오류 SnackBar × 2 + 스킵 SnackBar. 신규 키 17개 (proposalDetailSelectTemplate/SelectTemplateRequired/AutoSentBadge/FromTeacherSubtitle/RecommendedBadge/PaymentDoneAction/SkipAction/SkippedSnackbar, teacherProfileNotFound/ContactNotAvailable/Loading/LoadError, teacherContactSheetTitleFormat 포매터, callTeacherAction, messageTeacherAction, phoneNumberCopiedFormat 포매터) + 재사용 6건 (proposalCreateAppBarTitle × 2, errorOccurred × 2, proposalNotFoundEmpty, templateNotFound, paymentReminderSent, errorTryAgain × 2). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `e12c813e` (키) + `308f1683` (마이그레이션). **주의**: 외부 세션이 5-3b-16(renewal_detail_screen) 점유 → 본 작업은 5-3b-17 로 재매핑. ⭐ emoji 인라인 보존 (다국어 무관). 잔여 ~5 파일은 5-3b-18 이후.
- 5-3b-18 subscription_history_section 7 사이트 (2026-04-29) — 섹션 제목(수강 이력) + stat row 라벨 3건(수강 기간/총 수강/출석률) + 값 포매터 2건(N회 완료, M개월 · N회 완료) + import 추가. 신규 키 6개 (subscriptionHistoryTitle/PeriodLabel/TotalLessonsLabel/AttendanceRateLabel + subscriptionTotalUsedFormat 포매터 + subscriptionMonthsAndUsedFormat 포매터). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `074bdeca` (키) + `4f1e0106` (외부 세션이 5-3b-19 키와 함께 마이그레이션 동시 커밋). **주의**: 외부 세션이 5-3b-19 (proposal_settings_screen) 동시 진행 — Remove-Restore 패턴으로 staged 5-3b-19 키 분리 후 본 키 단독 커밋. 마이그레이션은 외부 세션이 자기 키 커밋 시 함께 포함(commit 4f1e0106). 잔여 ~4 파일은 5-3b-20 이후.
- 5-3b-19 proposal_settings_screen 21 사이트 (2026-04-29) — AppBar 로딩/메인(2회) + 자동 제안 토글(타이틀/서브타이틀/힌트) + 템플릿 섹션(타이틀/힌트/error/empty/info 포매터/추천 배지) + 골든타임 섹션(타이틀/배지/힌트/할인율 라벨/유효시간 라벨/시간 포매터/요약 포매터) + 자동 리마인더 섹션(타이틀×2/힌트/스케줄) + 저장 SnackBar(성공/실패). 신규 키 19개 (proposalSettings AppBarTitle/AutoToggle{Title,Subtitle,Hint}/TemplateSection{Title,Hint}/TemplateEmpty/TemplateInfoFormat 포매터/GoldenTimeTitle/ConversionUpBadge/GoldenTimeHint/DiscountPercentLabel/ValidityHoursLabel/HoursFormat 포매터/GoldenTimeSummaryFormat 포매터/AutoReminder{Title,Hint,Schedule}/SavedSnackbar/SaveFailedSnackbar) + 재사용 2건 (errorOccurred, templateRecommendedBadge). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `4f1e0106` (키) + `1b16c53f` (마이그레이션). **주의**: 외부 세션이 5-3b-18(subscription_history_section) 동시 점유 → 본 작업은 5-3b-19 로 재매핑. ⭐ emoji + `'$v%'` 인라인 보존 (다국어 무관 universal symbol). 잔여 ~4 파일은 5-3b-20 이후.
- 5-3b-22 assignment_dashboard + summary 14 사이트 (2026-04-29) — home/ 도메인 과제 진행률 화면. AppBar 타이틀(이번 주 과제) + 에러 상태(데이터를 불러올 수 없습니다 재사용) + 빈 상태(이번 주 과제가 없습니다) + 미완료/완료 학생 섹션 헤더 × 2 + 학생 수 카운트 포매터(N명) × 2 + 진행률 카드(이번 주 완료율 + N/M 과제 완료 포매터) + Stat 카드 라벨 × 3(전체 과제/완료 학생/미완료) + summary 섹션(전체보기 재사용 + 완료율 라벨 + 미완료 학생 재사용). 신규 키 11개 (weeklyAssignmentTitle/Empty, incompleteStudentsLabel, completedStudentsLabel, weeklyCompletionRate, peopleCount(int) 포매터, assignmentCompletionFormat(int, int) 포매터, totalAssignmentsLabel, completedStudentsShort, incompleteShort, completionRateLabel) + 재사용 2건 (viewAll, cannotLoadData). flutter analyze — No issues. 커밋 `023fe4b0` (키) + `038f40ba` (마이그레이션). **참고**: 외부 세션 5-3b-21 (unified_subscription_sheet) 마이그레이션과 병렬 진행 — surgical staging 으로 충돌 회피. 학생 수 카운트는 도메인 무관 peopleCount(int) 단일 키로 통합. 잔여 ~3 파일은 5-3b-23 이후.
- 5-3b-20 lesson_policy_screen 33 사이트 (2026-04-29) — AppBar 분기(클래스/레슨) + 변경/취소 정책 섹션(헤더/3 chip 타이틀/2 suffix/2 라벨 포매터/toggle) + 노쇼 정책 섹션(헤더/toggle/grace 타이틀+분 suffix) + 이월 정책 섹션(헤더/toggle/2 chip 타이틀+회/개월 suffix) + 정책 요약 섹션(📋 헤더/5 라벨/3 단순값/4 포매터/'무제한'/'불가') + 관련 설정 섹션(헤더/3 항목) + 저장 SnackBar(성공/실패). 신규 키 32개 (policyClass/LessonAppBarTitle, policyChangeCancelHeader, policyMinCancelHoursTitle, policyHoursBeforeSuffix, policyHoursFormat 포매터, policyMonthlyChangesTitle, policyUnlimited, policyTimesFormat 포매터, policyAllowSameDayCancelToggle, policyNoShowHeader, policyGracePeriodTitle, policyCarryoverHeader, policyAllowCarryoverToggle, policyMaxCarryoverTitle, policyCarryoverPeriodTitle, policyMonthsSuffix, policySummaryHeader, policyCancelLabel, policyHoursBeforeFormat 포매터, policyChangeLabel, policyMonthlyChangesFormat 포매터, policyDeductCount, policyKeepCount, policyLatenessLabel, policyLatenessFormat 포매터, policyCarryoverFormat 포매터, policyNotAllowed, policyRelatedHeader, policyTuitionManagement, policyTemplateManagement, policySavedSnackbar) + 재사용 8건 (proposalSettingsSaveFailedSnackbar, policyNoShowDeduct, policyNoShowLabel, policyCarryoverLabel, policyCancelSameDay, minuteLabel, lessonsUnit, lessonTimeSettings). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `3eb97d53` (키) + `57131d4d` (마이그레이션). **참고**: policy* prefix 단일 네임스페이스 유지 (기존 policyChangeCancelLabel/policyCarryover* 키들과 일관). 📋 emoji 인라인 보존. 잔여 ~3 파일은 5-3b-21 이후.
- 5-3b-23b notification_settings_screen 28 사이트 (2026-04-29) — student_home/ 도메인 알림 설정 화면. AppBar 타이틀(알림 설정) + Master 섹션(전체 알림 + toggle title/subtitle) + Lesson 섹션(레슨 알림 + 시작/변경 2 tiles × title/subtitle) + Subscription 섹션(수강권 알림 + 제안/만료 2 tiles × title/subtitle) + Practice 섹션(연습 알림 + 리마인더/피드백 2 tiles × title/subtitle, teacherFeedbackHeader 재사용) + Info banner(푸시 준비 중 multi-line 안내) + Teacher-only expiry auto 섹션(master + D-14/D-7/D-1/D-0 = 5 tiles × title/subtitle). 신규 키 30개 (notificationSettings* prefix 17건 + notificationLessonStart/Change/SubscriptionProposal/SubscriptionExpiry/PracticeReminder/TeacherFeedback Title/Subtitle 12건 + notificationPushPreparingNotice + notificationExpiryAutoMaster/D14/D7/D1/D0 Title/Subtitle 10건 — 외부 세션이 dead key subscriptionPolicyTooltip 정리 commit `08526128` 에서 합쳐짐) + 재사용 1건 (teacherFeedbackHeader). flutter analyze — No issues. 커밋 `08526128` (키, 외부 세션과 합쳐짐) + `369232d5` (마이그레이션). **참고**: 본 작업은 외부 세션 5-3b-23 (subscription glue) 와 병렬 진행되어 키 커밋이 한 묶음으로 picked up 됨 → 마이그레이션 커밋만 분리. notification* 단일 네임스페이스 유지. multi-line const(`notificationPushPreparingNotice`)는 줄바꿈 보존(\\n). subscription 도메인과 무관(student_home/) 하므로 잔여 subscription 파일은 별도 슬롯.
- 5-3b-23 subscription glue 4 사이트 (2026-04-29) — subscription presentation 잔여 소형 배치. subscription_detail_screen AppBar 정책 아이콘 tooltip(적용 정책) 1 site → policyAppliedTitle 재사용 + subscription_proposal_providers templateName fallback('수강권') 3 sites (createMultiChoiceProposal/createSingleChoiceProposal/createProposalFromTemplates) → subscription 재사용. 신규 키 0 + 재사용 2건 (policyAppliedTitle, subscription). subscription_proposal_providers.dart import 추가(app_strings.dart). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `08526128` (키, dead key 추가됐다가 본 커밋에서 제거) + `03ab7dfa` (마이그레이션). **참고**: 키 커밋 시 잠정 추가했던 subscriptionPolicyTooltip 은 마이그레이션에서 기존 policyAppliedTitle 재사용으로 결정되어 dead key 가 됨 → 본 클로즈 커밋에서 정리. mock seed data (proposal/template/settings 리포지토리)는 도메인 정책상 i18n 마이그레이션 제외. 잔여 ~2 파일은 5-3b-24 이후 (subscription_template_list_screen 34 사이트가 가장 큼).
- 5-3b-25 profile_visibility_screen 19 사이트 (2026-04-30) — profile/ 도메인 공개 프로필 설정 화면. 저장 SnackBar 2건 (성공: proposalSettingsSavedSnackbar 재사용 / 실패: 신규 saveErrorSnackbar) + AppBar(공개 프로필 설정) + 에러 상태(오류가 발생했습니다.) + null 상태(프로필을 찾을 수 없습니다) + 섹션 타이틀(항목별 공개 범위) + VisibilityTile × 6항목(이름/프로필 사진/연락처/레슨료/경력/자격증) × title+subtitle (12 sites) + Preview 버튼(공개 프로필 미리보기). 신규 키 18개 (profileVisibilityAppBarTitle/SaveErrorSnackbar/ErrorState/NullState/SectionTitle + Name/Photo/Contact/Fee/Career/Certificate Title+Subtitle 12건 + PreviewButton) + 재사용 1건 (proposalSettingsSavedSnackbar). flutter analyze — No issues. 커밋 `328eec89` (키) + `4222889c` (마이그레이션). **참고**: 외부 세션이 5-3b-24 (subscription_template_list_screen 34 사이트) 동시 진행 → 본 작업은 5-3b-25 로 분기. profile/ 도메인 격리로 충돌 회피.
- 5-3b-24 subscription_template_list_screen 34 사이트 (2026-04-30) — subscription/ 도메인 수강권 관리 화면(선생님). AppBar/FAB 골격 3건(타이틀/자동 제안 설정 tooltip/수강권 추가 라벨) + 빈 상태 3건(헤딩 재사용/힌트/첫 수강권 만들기 CTA) + 에러 1건(데이터를 불러올 수 없습니다 재사용) + 카드 배지 2건(비활성/자동) + 정보 chip 2건 포매터(N회 재사용/N분 재사용) + popup menu 3건(수정/비활성화/활성화 + 삭제 재사용) + 삭제 다이얼로그 2건(타이틀/확인 메시지 포매터) + 바텀시트 헤더 1건 분기(편집/추가) + 이름 필드 3건(라벨/힌트/필수 검증) + 셀렉터 라벨 3건(레슨 횟수/유효기간 재사용/회당 가격 포매터 재사용) + 가격 필드 4건(라벨/힌트/필수/숫자만) + 설명 필드 2건(라벨 재사용/힌트) + 자동 제안 섹션 3건(체크박스/활성 desc multi-line/비활성 desc multi-line) + 저장 버튼 1건 분기(추가하기/수정하기) + 저장 SnackBar 2건 분기(추가됨/수정됨) + 에러 SnackBar 1건(에러 재사용). 신규 키 26개 (templateListAppBarTitle/AddButton/EmptyHint/FirstCreate/InactiveBadge/AutoBadge/MenuDeactivate/MenuActivate/EditSheetTitle/AddSheetTitle/NameLabel/NameHint/NameRequired/PriceLabel/PriceHint/PriceRequired/PriceNumbersOnly/DescHint/SaveEdit/SaveAdd/AutoProposalCheckbox/AutoProposalEnabledDesc/AutoProposalDisabledDesc/UpdatedSnackbar/AddedSnackbar/DeleteDialogTitle + DeleteConfirmFormat 포매터) + 재사용 11건 (cannotLoadData, delete, lessonCountLabel, infoLabelDuration, validityPeriod, errorTryAgain, proposalSettingsAppBarTitle, noSubscriptionsRegisteredTitle, durationMinutesValue 포매터, templateUnitPriceLabel 포매터, descriptionOptional). subscription 63/63 PASS, flutter analyze — No issues. 커밋 `a41839ef` (키) + `2e1cc562` (마이그레이션). **참고**: '수강권 수강권 추가' 중복 단어(templateAddSheetTitle)는 surgical i18n 정책상 원문 보존 — 별도 fix(typo) PR 로 분리. mock seed data 3개 리포지토리(64+ 사이트)는 도메인 정책상 i18n 제외. 잔여 presentation 사이트는 subscription_providers.dart 4건(다음 5-3b-26 후보).
- P2 5-3b subscription 도메인 종결 (2026-04-30) — production presentation 코드 100% 완료. **policy 제외 잔여**: subscription_providers.dart `pendingScheduleChangeRequests` 5 mock 사이트(`'sce_mock_*'` IDs + "Mock data for UI verification — replace with actual API query later" 주석) + mock 리포지토리 3개(mock_subscription_proposal/template/settings_repository.dart) ~64 사이트 — 모두 mock seed data 정책 제외. 다음 워크스트림은 P2 5-3c 또는 다른 도메인.
- 5-3b-26 edit_repertoire_screen 28 사이트 (2026-04-30) — practice/ 도메인 레퍼토리 편집 화면. AppBar(레퍼토리 편집) + 에러 상태(errorOccurred 재사용) + null 상태(레퍼토리를 찾을 수 없습니다) + 기본 정보 섹션(헤더 title/subtitle, 이름 label/hint/validator, 설명 descriptionOptional 재사용 + 영문 hint) + 날짜 picker(시작일/종료일 helpText × 2 + DateRangeSection placeholder "설정 안함") + 저장 버튼(saveChangesButton 재사용) + 저장 실패 SnackBar + 관리 섹션(헤더 title/description) + 아카이브 다이얼로그(title/confirm/cancel/action 4 sites + 버튼 label) + 아카이브 SnackBar(성공/실패) + 삭제 다이얼로그(title/confirm/cancel/delete 4 sites + 버튼 label) + 삭제 SnackBar(성공/실패). 신규 키 21개 (editRepertoire AppBarTitle/BasicInfoSubtitle/NameHint/UpdateFailedRetry, repertoire NotFound/NameLabel/NameRequired/DescriptionHint/ArchivedSnackbar/DeletedSnackbar, basicInfoTitle, managementSectionTitle/Description, selectStartDate/EndDate, endDateNotSetDaily, archiveButton/RepertoireConfirm/FailedRetry, deleteRepertoireTitle/Confirm, deleteFailedRetry) + 재사용 5건 (cancel, delete, descriptionOptional, errorOccurred, saveChangesButton). flutter analyze — No issues. 커밋 `f63a2076` (키) + `2f644f2d` (마이그레이션). **참고**: 외부 세션이 analytics/teacher_dashboard_screen 동시 진행 — practice/ 도메인 격리로 충돌 회피. 📋 / 📅 / 🗄️ emoji 인라인 보존 (universal symbol). doc 주석(3건)은 개발자용 유지.
- 5-3b-27 certificate_edit_screen 36 사이트 (2026-04-30) — profile/ 도메인 자격증 편집 화면(편집/신규 분기). AppBar 분기 2건(자격증 추가/수정) + CertificateType enum 라벨 7건(음악교원/문화예술교육사/학교교원/음악원수료증/음악학위/연주자격증/기타) + 이미지 소스 ListTile 2건(카메라로 촬영/갤러리에서 선택) + 저장/삭제 에러 SnackBar 2건 + 삭제 다이얼로그 4건(title/content/cancel재사용/delete재사용) + 폼 라벨 6건(자격증 종류/자격증명/발급 기관/발급일/자격증 번호/자격증 이미지) + 폼 hint 3건(자격증명/발급 기관/번호 선택사항) + validator 2건(자격증명/발급 기관 필수) + 발급일 표시 1건(formatDateYMDKorean 유틸 도입으로 인라인 표기 제거) + 이미지 영역 5건(이미지 삭제/안내문/빈 placeholder × 2 + tapToChange × 2 재사용) + 저장 버튼 분기 2건(제출하기/수정하기). 신규 키 30개 (certificateEditAppBar Add/Edit, certificateType MusicTeacher/CultureArtsEducator/SchoolTeacher/Conservatory/Degree/Performance/Other, imageSource Camera/Gallery, certificate SaveErrorRetry/DeleteErrorRetry/DeleteDialogTitle/DeleteConfirm/TypeLabel/NameLabel/NameHint/NameRequired/IssuingBodyLabel/IssuingBodyHint/IssuingBodyRequired/IssueDateLabel/NumberLabel/NumberHint/ImageLabel/ImageDeleteLabel/InfoBox/SubmitButton/UpdateButton/ImageEmptyTitle/ImageEmptyHint) + 재사용 3건(cancel, delete, tapToChange). flutter analyze — No issues. 커밋 `3b22921c` (키) + `005079b5` (마이그레이션). **참고**: 발급일 표기를 인라인(`${date.year}년 ${date.month}월 ${date.day}일`)에서 `formatDateYMDKorean()` 유틸로 교체 — 다국어 날짜 포매팅 일원화. doc 주석 3건(L506/L543/L559 '탭하여 변경' 인용) 개발자용 보존.
- 5-3c-1 teacher_dashboard_screen 22 사이트 (2026-04-30) — analytics/ 도메인 첫 진입(P2 5-3c). 선생님 통계 대시보드 화면. AppBar 1건(통계) + 에러 1건(cannotLoadData 재사용) + StatCard 2×2 그리드 4 카드(총 레슨/출석률/학생 수/월 수입) × (title + value 포매터 + subtitle 포매터) = 11 sites + Revenue 섹션 3건(수익 현황 헤더/이번 달 수익 라벨/수익 변화 % sign 포매터) + Student 섹션 6건(학생 현황 헤더/총 학생/신규/이탈 + 3 value 포매터). 신규 키 16개 (analyticsAppBarTitle/TotalLessons/StudentCountLabel/MonthlyRevenue/RevenueSection/ThisMonthRevenue/StudentSection/TotalStudentsLabel/NewLabel/ChurnedLabel + Completed/Cancelled/NewStudents/RevenueChange/NewCount/ChurnedCount Format 포매터) + 재사용 6건 (cannotLoadData × 1, subscriptionAttendanceRateLabel × 1, peopleCount × 3 — 학생 수 카드 + 총 학생 stat + 이탈 0 fallback, usageCountShort × 1). subscription 63/63 PASS (regression gate), flutter analyze — No issues. 커밋 `2aef57d5` (키) + `76610b98` (마이그레이션). **참고**: 부호 + 백분율 포매팅을 단일 포매터(analyticsRevenueChangeFormat) 로 캡슐화 — 다국어에서 부호 위치/소수점 표기 차이 흡수. 잔여 analytics presentation 미정 (mock_analytics_repository.dart 10건은 mock seed data 정책 제외, monthly_trend_chart.dart 1건 + practice_ranking_list.dart 2건 = 3 위젯 사이트 후보).
- 5-3c-2 analytics widgets 4 사이트 (2026-04-30) — analytics/ 도메인 잔여 위젯 2개 마이그레이션. monthly_trend_chart.dart 2건(`'레슨 추이'` 섹션 헤더 + `'${t.month.month}월'` 월별 라벨 포매터) + practice_ranking_list.dart 2건(`'연습률 TOP 5'` 섹션 헤더 + `'연습 데이터가 없습니다'` 빈 상태). 신규 키 4개 (analyticsLessonTrendSection / analyticsMonthLabelFormat 포매터 / analyticsPracticeRankingSection / analyticsNoPracticeData) + 재사용 0건 (모두 위젯 고유 텍스트). flutter analyze lib/features/analytics/ — No issues found. 커밋 `cd6af092` (키) + `464a58a0` (마이그레이션). **참고**: 정수 표기(`'$rank'`, `'$percent%'`)는 i18n 제외 (visual format with literal symbols). 월별 라벨은 단일 포매터로 캡슐화 — 다국어 월 표기 차이 흡수.
- P2 5-3c analytics 도메인 종결 (2026-04-30) — production presentation 코드 100% 완료 (teacher_dashboard_screen + 위젯 2개 = 26 사이트). **policy 제외 잔여**: mock_analytics_repository.dart ~10 mock 사이트 — 도메인 정책상 i18n 마이그레이션 제외. 다음 워크스트림은 P2 5-3d settings/onboarding/home/invite 차도메인 (~30 파일).
- 5-3d-1 backup_settings_screen 2 사이트 (2026-04-30) — settings/ 도메인 첫 진입(P2 5-3d). 녹음 백업 설정 화면. AppBar 1건(`'녹음 백업'`) + 에러 상태 1건(`'오류가 발생했습니다.'` 마침표 포함, errorOccurred 와 미세 차이로 재사용 회피). 신규 키 2개 (backupAppBarTitle, backupErrorState) + 재사용 1건 (AppStrings.retry — 이미 마이그레이션됨). flutter analyze — No issues. subscription 63/63 PASS (regression gate), 한글 grep — 0 잔존 (코드/주석 클린). 커밋 `e46ec53c` (키) + `6d3d817a` (마이그레이션). **참고**: settings/ 도메인 잔여 후보 — backup_service.dart(13 사이트), all_recordings_screen.dart, orphan_recordings_screen.dart 후속 청크.
- 5-3d-2 dashboard_tab 13 사이트 (2026-04-30) — home/ 도메인 첫 진입. 선생님 홈 대시보드 위젯. Programme 마스트헤드(오늘의 레슨/Korean lesson count formatter) + Today's Programme 헤더(일괄 피드백/전체보기) + 통계 카드 2× (오늘 레슨/이번 달 × usageCountShort) + 빈 상태(타이틀/서브타이틀/액션) + 더보기 버튼(N개 레슨 더보기) + Fine. 푸터(통계 더보기) + 에러 카드 + 알림 tooltip. 신규 키 8개 (dashboardProgrammeTitle, dashboardLessonCountFormat — 한국어 서수 0~10편 + count fallback, dashboardLessonsLoadError, dashboardThisMonth, dashboardEmptyTitle/Subtitle, dashboardMoreLessonsFormat, dashboardAnalyticsMoreLink) + 재사용 5건 (notifications, todayLessons, bulkFeedbackTitle, viewAll, lessonAddTitle) + usageCountShort 포매터 도입(`${count}회` 인라인 → 단일 포매터). 부수 변경: `_koreanLessonCount` private 헬퍼 → AppStrings 로 이동(테스트 가능성 + 다국어 단일 진원지). flutter analyze — No issues. 커밋 `3a6f4bd7` (키) + `fba24c75` (마이그레이션). **Notebook × Score 시그니처 보존**: Programme for $dayLabel / Today's Programme / $month月 $day日 / Fine. / LESSONAZA / VOL.$roman·NO.$day — 영문/CJK 브랜드 자산은 i18n 제외 (구체적 디자인 가이드 §1).
- 5-3d-3 getting_started_card 7 사이트 (2026-04-30) — home/ 도메인 온보딩 체크리스트 위젯. 학생 0명일 때 노출되는 3-step Getting Started 카드. 인트로 안내(아래 단계를 따라…) + Step 1~3 × (title + subtitle) = 7 사이트. 신규 키 7개 (gettingStartedIntro, gettingStartedStep1Title/Subtitle 학생 등록하기·첫 학생을 추가해보세요, gettingStartedStep2Title/Subtitle 레슨 일정 만들기·학생 등록 후 레슨을 추가하세요, gettingStartedStep3Title/Subtitle 첫 레슨 완료하기·레슨을 탭해 완료 처리하세요) + 재사용 0건. flutter analyze — No issues. 커밋 `c654e8ff` (키, 외부 세션 backup_service 16 키 동시 번들링됨 — label 5-3d-2 collision 인지) + `82262134` (마이그레이션). **참고**: 'Getting Started' 영문 섹션 헤더는 Notebook × Score 브랜드로 i18n 제외. **외부 세션 동시 작업 감지**: backup_service.dart 키 16개가 동일 5-3d-2 라벨로 외부 세션이 추가했으나 미커밋 상태에서 본 세션 commit 에 함께 포함됨. 키는 추가되어 있으나 backup_service.dart migration 은 외부 세션 처리 대기.
- 5-3d-4 backup_service 16 사이트 (2026-04-30) — settings/ 도메인 데이터 서비스 레이어(backup_service.dart 619줄). 백업/복원 진행 단계 8건(준비/메타데이터/Hive 내보내기/녹음 추가/ZIP 압축/완료/파일 읽기/버전 확인/Hive 복원/녹음 복원/복원 완료) + 진행률 포매터 2건(녹음 추가 N/M, 녹음 복원 N/M) + 에러 메시지 3건(유효하지 않은 파일/지원되지 않는 버전 포매터/복원 오류 포매터) + 완료 메시지 2건(백업/복원). 신규 키 16개 (backupPreparing/MetadataCreating/HiveExporting/RecordingsAdding/RecordingsAddingProgressFormat/ZipCompressing/Complete/FileReading/InvalidFile/VersionChecking/UnsupportedVersionFormat/HiveRestoring/RecordingsRestoring/RecordingsRestoringProgressFormat + restoreComplete/restoreErrorFormat). 재사용 0건. **번호 충돌 처리**: 키 추가는 5-3d-3 키 커밋(c654e8ff)에 외부 세션 번들링 → 5-3d-2/3 슬롯이 병렬 세션에 선점됨. 본 세션은 5-3d-4 슬롯으로 마이그레이션 단독 커밋 `524b3f8c`. flutter analyze backup_service.dart — No issues. subscription regression 63/63 PASS. 한글 grep — 0 잔존. **참고**: 데이터 서비스 레이어는 사용자 노출 문자열(ChangeNotifier `currentStatus`) 직접 진원지로, presentation 레이어에서 `state.currentStatus` 그대로 표시 → i18n 필수.

## 평가 기준 (Rubric, 합격선 7.5)

| 기준 | 가중 | 목표 |
|---|---|---|
| 완성도 | 40% | 8/10 — P0~P1 spec 갭 없음 |
| 견고성 | 30% | 7/10 — 회귀 없음, smoke test |
| 일관성 | 20% | 8/10 — 도메인 린터 통과, 공통 위젯 재사용 |
| 간결성 | 10% | 7/10 — 800줄/50줄 룰 |

## 리스크

| 등급 | 리스크 | 완화 |
|---|---|---|
| HIGH | ScheduleChangeSlotScreen 재구성으로 학생 경로 깨짐 | smoke test + 실기 확인 |
| HIGH | ScheduleChangeStatus 제거 시 Hive 마이그레이션 | grep 0 확인 후 제거, mock 검증 |
| MEDIUM | travel_time 패치가 기존 슬롯 생성 회귀 | unit test 4 케이스 + 회귀 케이스 1 |
| LOW | i18n 회귀 | Phase 5-1a~g 패턴 그대로 |

## 다음 단계

| 작업 | 상태 |
|---|---|
| P0-1 / P0-2 / P1-1 / P1-2 Phase A·B·C | ✅ 완료 (2026-04-29) |
| P2 5-1h booking_reschedule_screen i18n (20 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-1i schedule_tab + lesson_requests + request_detail i18n (20 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-1j request_completion + unified_lesson_request + my_bookings i18n (30 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-2a teacher_attendance + lesson_note_history + quick_feedback_student_list i18n (18 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-2b lesson_confirmation_dialog i18n (18 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-2c-1 bulk_feedback_screen i18n (17 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-2c-2 lesson_notes_widgets i18n (28 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-2c-3 edit_lesson_screen i18n (19 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-2c-4 quick_feedback_screen i18n (22 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-2c-5 add_practice_item_sheet 잔여 + 5-2c 종료 (1 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-2c-6 레슨 위젯 잔여 11파일 (~80 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3a subscription 알림/정책/템플릿 5파일 | ✅ 완료 (2026-04-29) |
| P2 5-3b-1 issue_form_type_options i18n (7 사이트, 키 재사용) | ✅ 완료 (2026-04-29) |
| P2 5-3b-2 chapter_lessons + selectable_template_card i18n (4 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-3 issue_form 3위젯 i18n (~37 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-4 subscription entities 6파일 i18n (~58 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-5 location_travel_selector i18n (18 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-6 issue_form_summary_widgets i18n (22 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-6+ expiring_subscriptions_screen i18n (7 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-7 proposal_card_widgets i18n (26 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-8 subscription_card i18n (14 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-9 subscription domain services i18n (7 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-10 issue_subscription_actions i18n (10 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-11 proposal_confirm_screen i18n (12 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-12 subscription_list_screen i18n (10 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-13 issue_subscription_screen i18n (10 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-14 student_proposal_accept_screen i18n (13 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-15 proposal_create_screen i18n (22 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-16 renewal_detail_screen i18n (14 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-17 proposal_detail_screen i18n (25 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-18 subscription_history_section i18n (7 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-19 proposal_settings_screen i18n (21 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-20 lesson_policy_screen i18n (33 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-21 unified_subscription_sheet i18n (25 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-22 assignment_dashboard + summary i18n (14 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-23 subscription glue (detail tooltip + provider fallback) i18n (4 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-23b notification_settings_screen i18n (28 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-3b-24 subscription_template_list_screen i18n (34 사이트) | ✅ 완료 (2026-04-30) |
| P2 5-3b-25 profile_visibility_screen i18n (19 사이트) | ✅ 완료 (2026-04-30) |
| P2 5-3b subscription 도메인 종결 (mock seed data 5+64 사이트 정책 제외) | ✅ 완료 (2026-04-30) |
| P2 5-3c-1 teacher_dashboard_screen i18n (22 사이트) | ✅ 완료 (2026-04-30) |
| P2 5-3b-26 edit_repertoire_screen i18n (28 사이트) | ✅ 완료 (2026-04-30) |
| P2 5-3c-2 analytics widgets i18n (4 사이트) | ✅ 완료 (2026-04-30) |
| P2 5-3b-27 certificate_edit_screen i18n (36 사이트) | ✅ 완료 (2026-04-30) |
| P2 5-3c analytics 도메인 종결 (mock seed 10 사이트 정책 제외) | ✅ 완료 (2026-04-30) |
| P2 5-3d-1 backup_settings_screen i18n (2 사이트) | ✅ 완료 (2026-04-30) |
| P2 5-3d-2 dashboard_tab i18n (13 사이트) | ✅ 완료 (2026-04-30) |
| P2 5-3d-3 getting_started_card i18n (7 사이트) | ✅ 완료 (2026-04-30) |
| P2 5-3d-4 backup_service i18n (16 사이트) | ✅ 완료 (2026-04-30) |
| **다음** P2 5-3d-5+ settings 도메인 잔여 (all_recordings / orphan_recordings) 또는 home/invite 도메인 진입 | 대기 |
| P1-1 후속 — TimeException UI 부분 차단 시간 입력 | 별도 phase |
| P1-3 schedule_tab 헤더 collapse + sticky week strip (Option C) | 🚧 진행 (2026-04-30) |

> **세션 분할 전략**: 한 세션에 P0-1 한 phase 단위. ultra 모드 검증 강도 유지.

---

## 이전 계획

# 백엔드 API 구현 점검 (Audit Plan)

> 작성일: 2026-04-28
> 모드: `/plan --eng`
> 사용자 결정: yes (전체 4 도메인 audit 진행)

요구사항·범위·Phase 0~2 백엔드 audit 본문은 `docs/specs/backend/audit/2026-04-28/` 폴더와 git history (commit `60f48cef` 이전) 참조.

---

## 더 이전 계획

§7.127 Gaegu 손글씨 4계층 SSOT 정착 — 시스템 자동 뱃지 hand 해제 (Phase 1·2·3·5 완전 적용, Phase 4·6 보류·분리, 가중 평균 9.5 PASS). 본문은 git history 참조.
