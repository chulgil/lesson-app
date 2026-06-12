# 학생 게이미피케이션 P2 Visual Growth — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> 스펙: `.harness/spec/2026-06-11-student-gamification.md` §6.3 GrowthHeatmap + §6.5 StreakFreeze + §14 안티-피로 + §17 비기능 + §18.1/18.3 P2 + D-day 마이그레이션
> 선행: P1 Foundation 완료 — PR #683/#687/#689/#690 머지 (`.harness/decomposition/2026-06-11-student-gamification-p1-foundation.md`)
> 스코프: **P2 Visual Growth 만** — 1년 히트맵 UI + Trophy 모음 + StreakFreeze 시스템 + 휴식 권고. SpotlightPrompt (P3) / Leaderboard (P4) 별도.

**Goal:** 학생이 자기 진척을 시각적으로 확인할 수 있는 "성장의 캘린더 + 트로피 모음" + 스트릭 안티-피로 (자동 freeze 발급/적용) + 30분 휴식 권고 토스트 구축. P1 의 GrowthHeatmap mock 을 Hive 30일 chunk × 13 box 캐시로 승격하여 1년 데이터 P95 < 500ms 응답 보장.

**Architecture:** P1 의 `PracticeRecordingService` 가 이미 GrowthHeatmap 갱신. P2 는 (a) Hive 캐시 + 13 box chunk 로 1년 조회 최적화 (b) StreakFreeze entity + 일요일 자동 발급 worker + 결석일 자동 적용 (c) 점점점 → 더 보기 화면 = 1년 히트맵 (GitHub 7×52) + Trophy 모음 카드 (d) 세션 30분/누적 3시간 휴식 권고 토스트 추가. UI 1화면 추가 (`StudentGrowthDetailScreen`).

**Tech Stack:** Flutter 3.29.0 / Riverpod (codegen) / Hive (30일 chunk box × 13) / json_serializable / flutter_test / integration_test

**진입 게이트**: P1 Foundation 시리즈 #683/#687/#689/#690 머지 + main clean.

---

## 사전 결정 (O1~O7 — Job 0 진입 결정사항)

본 PLAN 의 추천안. 사용자 검토 시 변경 가능. Job 0 첫 task 에서 글로서리/스펙에 확정 반영.

| # | 항목 | 추천 결정 | 근거 |
|---|---|---|---|
| O1 | StreakFreeze 저장소 | Hive 로컬 박스 `streak_freeze_v1` (학생별 1 record) | P2 = 로컬 우선, BE 동기화는 P4 와 함께. 시험 모드 부여만 P4 BE 의존 |
| O2 | GrowthHeatmap chunk 전략 | Hive 13 box × 30일 = 390일 (1년 + 25일 버퍼). key=`heatmap_chunk_{studentId}_{chunkIndex}` | 스펙 §17 P95<500ms 만족 + chunk 단위 invalidation. 사용 시점 단위 lazy load |
| O3 | 1년 히트맵 UI 그리드 | 7행 × 52열 (가로 스크롤 가능) — 일요일 시작, 좌→우 = 과거→오늘 | GitHub contribution graph 패턴, 모바일 가로 스크롤 자연 |
| O4 | 색 농도 단계 | 5단계 (0분 / 1-15 / 16-30 / 31-60 / 61+ 분) | Wordle 단순 색 농도 — Hick's Law 준수, 색맹 친화 패턴 추가 (§17) |
| O5 | Trophy 카테고리 분류 노출 | 카테고리 X — "모음" 1 카드 (스펙 §16) | "성장 마커" 메시징, 보상심리 회피 |
| O6 | 더 보기 화면 진입점 | 홈 PracticeStartCard 의 "· · ·" 점점점 탭 → 화면 push | P1 UI 와 일관. Hick's Law (옵션 1) |
| O7 | D-day 마이그레이션 시점 | P2 PR 배포 D-day (Sunday 00:00 KST 자동 발급 첫 회와 동시) | timezone 정렬 1회 + freeze balance=2 + 안내 토스트 1회 |

---

## DAG (Job 의존 관계)

```
Job 0 (사전 결정 + 글로서리 등록)
        │
        ▼
Job 1 (StreakFreeze entity + Hive adapter)
        │
        ├──────────────┐
        ▼              ▼
Job 2          Job 3
(GrowthHeatmap (StreakFreeze
 Hive chunk    Repository
 캐시 캐싱)     + Mock + Hive)
        │              │
        └──────┬───────┘
               ▼
       Job 4 (StreakFreezeService — 자동 발급/적용 + 시험 모드)
               │
               ▼
       Job 5 (practice_streak_provider 통합 + D-day 마이그레이션)
               │
               ▼
       Job 6 (1년 히트맵 UI 7×52 그리드)
               │
               ├──────────────┐
               ▼              ▼
       Job 7         Job 8
       (Trophy       (휴식 권고
        모음 카드)    토스트 SC-11)
               │              │
               └──────┬───────┘
                      ▼
              Job 9 (더 보기 화면 통합 — StudentGrowthDetailScreen)
                      │
                      ▼
              Job 10 (E2E + 베타 출시 게이트 SC-10, SC-11)
```

---

## 파일 구조 (P2 범위)

### 신규 파일 (`.dart` 12개 + codegen 6개)

**Domain (gamification feature)**:
- `frontend/lib/features/gamification/domain/entities/streak_freeze.dart`
- `frontend/lib/features/gamification/domain/repositories/streak_freeze_repository.dart` (interface)
- `frontend/lib/features/gamification/domain/services/streak_freeze_service.dart`

**Data (Hive)**:
- `frontend/lib/features/gamification/data/repositories/hive_streak_freeze_repository.dart`
- `frontend/lib/features/gamification/data/repositories/mock_streak_freeze_repository.dart` (테스트용)
- `frontend/lib/features/gamification/data/repositories/hive_growth_heatmap_repository.dart` (P1 mock 대체)
- `frontend/lib/features/gamification/data/services/growth_heatmap_chunk_cache.dart` (30일 chunk 직렬화 헬퍼)

**Presentation providers**:
- `frontend/lib/features/gamification/presentation/providers/streak_freeze_provider.dart`
- `frontend/lib/features/gamification/presentation/providers/growth_heatmap_year_provider.dart` (1년 조회 전용)

**UI**:
- `frontend/lib/features/gamification/presentation/screens/student_growth_detail_screen.dart` (더 보기 화면)
- `frontend/lib/features/gamification/presentation/widgets/year_heatmap_grid.dart` (GitHub 7×52)
- `frontend/lib/features/gamification/presentation/widgets/trophy_collection_card.dart`
- `frontend/lib/features/practice/presentation/widgets/rest_recommendation_toast.dart`

### 수정 파일 (5개)

- `frontend/lib/features/practice/presentation/providers/practice_streak_provider.dart` — StreakFreeze 의식 + D-day 마이그레이션 1회
- `frontend/lib/features/gamification/presentation/widgets/practice_start_section.dart` — 점점점 진입점 + 더 보기 라우팅
- `frontend/lib/features/practice/presentation/widgets/practice_tools_modal.dart` — 30분 세션 토스트 hook
- `frontend/lib/core/router/app_router.dart` — `/student/growth-detail` 라우트 추가
- `.harness/knowledge/glossary.md` — StreakFreeze, FreezeBalance, ExamMode, ComebackBonus 용어 등록 (+ `docs/specs/glossary.md` 동기화)

### 테스트 파일 (12개)

각 entity / repository / service / provider / widget 마다 단위 + 위젯 smoke test + E2E 1개.

---

## Job 0: 사전 결정 + 글로서리 등록

**Files:**
- Modify: `.harness/knowledge/glossary.md`
- Modify: `docs/specs/glossary.md` (동기화)
- Modify: `.harness/spec/2026-06-11-student-gamification.md` (P2 진입 commit hash 추가)

- [ ] **Step 1: P1 머지 시리즈 commit hash 기록**

스펙 헤더에 P2 진입 시점 hash 추가 (head of main):
```
> P2 진입: main @ {HASH} (P1 Foundation 시리즈 완료)
```

- [ ] **Step 2: glossary 신규 용어 등록**

`.harness/knowledge/glossary.md` 에 추가:
```markdown
### 학생 게이미피케이션 P2 (2026-06-12)
| 용어 (한글) | 영문 | 정의 |
|---|---|---|
| 스트릭 동결 | StreakFreeze | 학생 결석일에 자동 적용되어 streak 유지. 일요일 00:00 KST 자동 +2, max 4 |
| 동결 잔액 | FreezeBalance | 학생 보유 freeze 개수 (0-4) |
| 시험 모드 | ExamMode | 학부모/선생님이 N일 발급. 모드 활성 동안 freeze 차감 0 |
| 복귀 보너스 | ComebackBonus | 7일+ 미사용 후 복귀 시 첫 세션 보너스 P (FOMO 없는 환영) |
| 1년 히트맵 | YearHeatmap | GitHub contribution graph 스타일 7×52 그리드, 일별 연습 시각화 |
| 트로피 모음 | TrophyCollection | badge_award_provider 재사용, 카테고리 분류 X |
| 30일 chunk | HeatmapChunk | Hive 13 box × 30일 = 390일 분량 캐시 단위 |
```

`docs/specs/glossary.md` 동기화.

- [ ] **Step 3: 사전 결정 O1~O7 확정**

본 플랜 표를 사용자 검토 후 확정. 변경 사항 있으면 본문 갱신.

- [ ] **Step 4: 브랜치/Worktree 생성** (worktree-parallel-workflow 규칙)

```bash
git worktree add ../lesson-app-wt-gamification-p2 -b feat/student-gamification-p2 main
cd ../lesson-app-wt-gamification-p2
```

- [ ] **Step 5: 글로서리 동기화 커밋**

```bash
git add .harness/knowledge/glossary.md docs/specs/glossary.md .harness/spec/2026-06-11-student-gamification.md
git commit -m "docs(glossary): 학생 게이미피케이션 P2 용어 등록"
```

---

## Job 1: StreakFreeze entity + Hive adapter (TDD)

### Task 1.1: StreakFreeze entity (json_serializable + Hive)

**Files:**
- Create: `frontend/lib/features/gamification/domain/entities/streak_freeze.dart`
- Test: `frontend/test/features/gamification/domain/entities/streak_freeze_test.dart`
- 코드 생성: `streak_freeze.g.dart`

스펙 §6.5:
```dart
class StreakFreeze {
  final String studentId;
  final int balance; // 0-4
  final List<DateTime> usedAt;
  final DateTime? examModeUntil;
}
```

- [ ] **Step 1: 테스트 작성**
  - `balance` clamp 0-4 검증
  - `canApply` getter — examMode 활성 동안 false (차감 0)
  - `apply(date)` — balance -1 + usedAt 추가
  - `grantWeekly(amount: 2)` — balance + clamp 4
  - `json round-trip` 보존
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: 구현** (immutable + copyWith + json_serializable. Hive annotation 은 별도 Task 1.2 어댑터에서 처리)
- [ ] **Step 4: Run codegen + tests** (5/5 PASS)
- [ ] **Step 5: Commit**
```bash
git commit -m "feat(gamification): StreakFreeze entity (TDD)"
```

### Task 1.2: Hive 직렬화 전략 결정 — Box<String> + JSON

> **결정 변경 (Job 1 진입 시)**: TypeAdapter 패턴 → Box<String> + json_serializable JSON 직렬화 채택.
> **이유**: (a) Task 2.1 (GrowthHeatmapChunkCache) 도 JSON bytes 패턴 채택 — 일관성 (b) 학생당 1 record ≈ <100 bytes → 직렬화 비용 무시 가능 (c) typeId 관리 부담 0 (d) 데이터 마이그레이션 단순 (스키마 변경 시 JSON 필드 추가만)

**Files:**
- 코드 변경 0 (이 Task 자체는 정책 결정 + 본 decomposition 갱신만)

- [ ] **Step 1: Box 키 정책 정의 (본 문서)**
  - Box name: `streak_freeze_v1` (`Box<String>`)
  - Key: `studentId`
  - Value: `jsonEncode(StreakFreeze.toJson())`
- [ ] **Step 2: 실제 Box 작업은 Job 3 Task 3.3 (HiveStreakFreezeRepository) 로 위임**
  - 구현 시 `Hive.openBox<String>('streak_freeze_v1')` + `jsonEncode`/`jsonDecode`
  - 빈 box (첫 진입) → `StreakFreeze.empty(studentId)` 반환
- [ ] **Step 3: 신규 TypeAdapter 등록 0 — `app_bootstrap.dart` 수정 0**

**근거**: Hive TypeAdapter 패턴은 (a) DateTime list 직렬화 boilerplate (b) typeId 충돌 위험 (c) 스키마 진화 시 마이그레이션 어댑터 추가 부담. P2 에서는 StreakFreeze 1종만 추가하므로 JSON 단순 직렬화가 trade-off 우위.

---

## Job 2: GrowthHeatmap Hive 30일 chunk 캐시 (TDD)

### Task 2.1: GrowthHeatmapChunkCache 헬퍼

**Files:**
- Create: `frontend/lib/features/gamification/data/services/growth_heatmap_chunk_cache.dart`
- Test: `frontend/test/features/gamification/data/services/growth_heatmap_chunk_cache_test.dart`

핵심 책임:
- 30일 chunk 단위 직렬화/역직렬화
- `chunkIndex(date)` — 절대 일자 → chunk index 매핑 (epoch 기준 안정)
- `loadYear(studentId, asOf)` — 13 chunk 병합 → `Map<DateTime, DailyPractice>`
- `upsertDay(studentId, date, evidence)` — 해당 chunk만 invalidate + 재저장

- [ ] **Step 1: 테스트 작성**
  - "chunkIndex 는 epoch 기준 30일 단위로 결정적"
  - "30일 boundary 정확 (day 29 → chunk N, day 30 → chunk N+1)"
  - "loadYear 는 최대 13 chunk read, P95 < 500ms (mock Hive on Future.delayed)"
  - "upsertDay 는 단일 chunk 만 write — invalidation 격리 검증"
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: 구현** (Hive `Box<List<int>>` JSON bytes 저장 — typed adapter 미사용. lazy box 사용)
- [ ] **Step 4: Verify pass + perf 측정 mock**
- [ ] **Step 5: Commit `feat(gamification): GrowthHeatmapChunkCache 30일 chunk 직렬화 (TDD)`**

### Task 2.2: HiveGrowthHeatmapRepository (P1 mock 대체)

**Files:**
- Create: `frontend/lib/features/gamification/data/repositories/hive_growth_heatmap_repository.dart`
- Test: `frontend/test/features/gamification/data/repositories/hive_growth_heatmap_repository_test.dart`
- Modify: `frontend/lib/features/gamification/presentation/providers/growth_heatmap_provider.dart` — 환경 분기 (test=mock, runtime=hive)

- [ ] **Step 1: 테스트 작성**
  - `getHeatmap(studentId, yearsBack: 1)` — 13 chunk 병합 결과 확인
  - `recordPractice` 는 단일 chunk 만 invalidate
  - 첫 진입 (빈 box) → empty GrowthHeatmap
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: 구현** (ChunkCache 위에 repository interface)
- [ ] **Step 4: Verify pass + provider 분기**
- [ ] **Step 5: Commit `feat(gamification): HiveGrowthHeatmapRepository 1년 캐시 (TDD)`**

---

## Job 3: StreakFreezeRepository (TDD)

### Task 3.1: StreakFreezeRepository 인터페이스

**Files:**
- Create: `frontend/lib/features/gamification/domain/repositories/streak_freeze_repository.dart`

```dart
abstract class StreakFreezeRepository {
  Future<StreakFreeze> getOrCreate(String studentId);
  Future<StreakFreeze> grantWeekly(String studentId, {int amount = 2});
  Future<StreakFreeze> apply(String studentId, DateTime date);
  Future<StreakFreeze> setExamMode(String studentId, DateTime until);
}
```

- [ ] **Step 1-2: 인터페이스 작성 + flutter analyze 0 issue**
- [ ] **Step 3: Commit `feat(gamification): StreakFreezeRepository interface`**

### Task 3.2: MockStreakFreezeRepository

같은 TDD 5단계. 메모리 저장소 + 모든 4 메서드 검증.

- [ ] **Step 1-5: TDD + Commit `feat(gamification): MockStreakFreezeRepository (TDD)`**

### Task 3.3: HiveStreakFreezeRepository

**Files:**
- Create: `frontend/lib/features/gamification/data/repositories/hive_streak_freeze_repository.dart`
- Test: `frontend/test/features/gamification/data/repositories/hive_streak_freeze_repository_test.dart`

Hive box `streak_freeze_v1` 사용. 학생별 단일 record (key=studentId).

- [ ] **Step 1: 테스트 작성** (Hive in-memory 또는 임시 directory)
  - `getOrCreate` 빈 box → balance=0, usedAt=[], examModeUntil=null
  - `grantWeekly(2)` clamp 4
  - `apply` — examMode 활성 시 변경 없음 검증
- [ ] **Step 2-5: TDD**
- [ ] **Step 5: Commit `feat(gamification): HiveStreakFreezeRepository (TDD)`**

---

## Job 4: StreakFreezeService — 자동 발급/적용 (TDD)

### Task 4.1: StreakFreezeService

**Files:**
- Create: `frontend/lib/features/gamification/domain/services/streak_freeze_service.dart`
- Test: `frontend/test/features/gamification/domain/services/streak_freeze_service_test.dart`

핵심 메서드:
- `weeklyGrantIfDue(studentId, now)` — KST Sunday 00:00 이후 마지막 grant 이전이면 +2
- `applyOnAbsence(studentId, missedDate)` — 결석일에 freeze 1개 차감 (examMode 시 skip)
- `setExamMode(studentId, durationDays)` — 학부모/선생님 호출

- [ ] **Step 1: 테스트 작성**
  - "Sunday 00:00 KST 이전이면 grant 안 함"
  - "Sunday 00:00 KST 지났고 마지막 grant 이번 주 외면 +2"
  - "이미 이번 주 grant 했으면 추가 grant 안 함"
  - "examModeUntil 활성 동안 applyOnAbsence 는 no-op"
  - "freeze balance=0 + 결석 → no-op (스트릭 끊김은 practice_streak_provider 책임)"
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: 구현** (KST 변환 = `Asia/Seoul` 고정 timezone. `intl.dart` 또는 dart:io 의존)
- [ ] **Step 4: Verify pass + 시간대 edge case (자정 직전/직후)**
- [ ] **Step 5: Commit `feat(gamification): StreakFreezeService 자동 발급/적용 (TDD)`**

### Task 4.2: streakFreezeProvider (Riverpod codegen)

**Files:**
- Create: `frontend/lib/features/gamification/presentation/providers/streak_freeze_provider.dart`
- 코드 생성: `streak_freeze_provider.g.dart`

```dart
@Riverpod(keepAlive: true)
StreakFreezeRepository streakFreezeRepository(...) {
  return HiveStreakFreezeRepository(); // 환경 분기는 test override
}

@riverpod
class StreakFreezeNotifier extends _$StreakFreezeNotifier {
  @override
  Future<StreakFreeze> build(String studentId) async {
    final repo = ref.read(streakFreezeRepositoryProvider);
    return repo.getOrCreate(studentId);
  }
  // grantWeekly, apply, setExamMode 메서드
}
```

- [ ] **Step 1-5: TDD + build_runner + Commit**

---

## Job 5: practice_streak_provider 통합 + D-day 마이그레이션 (TDD)

### Task 5.1: practice_streak_provider 가 StreakFreeze 의식

**Files:**
- Modify: `frontend/lib/features/practice/presentation/providers/practice_streak_provider.dart`
- Test: `frontend/test/features/practice/presentation/providers/practice_streak_provider_test.dart`

흐름:
1. 일별 활동 확인 시 어제 결석이면 `StreakFreezeService.applyOnAbsence` 호출
2. 차감 성공 → streak 유지 + "freeze 사용" 마커
3. 차감 실패 (balance=0) → streak 끊김 (기존 동작)

- [ ] **Step 1: 테스트 작성**
  - "어제 활동 + freeze balance=2 → freeze 차감 X, streak +1"
  - "어제 결석 + freeze balance=2 → freeze 차감 1, streak 유지"
  - "어제 결석 + freeze balance=0 → streak 끊김"
  - "어제 결석 + examMode 활성 → freeze 차감 X, streak 유지 (시험 모드 동결)"
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: 구현** — **방식 변경 (사전 결정 보강)**: 기존 `practice_streak_provider` 변경 0. surgical 원칙. 신규 추가:
  - 순수 함수 `StreakWithFreezeCalculator.compute({raw, freeze, now})` — 4 시나리오 분기
  - 신규 provider `effectiveStreakProvider(studentId)` — raw + freeze 조회 + compute 호출 (side-effect 0)
  - 자동 freeze 적용 trigger (`recordPractice` 진입 시 어제 결석이면 `service.applyOnAbsence` 호출) 는 **별도 Task 5.3** 으로 분리 (Job 5 Task 5.1 의 4 시나리오는 calculator 단위 테스트로 검증)
- [ ] **Step 4: Verify pass + 기존 streak 테스트 모두 회귀 통과**
- [ ] **Step 5: Commit `feat(gamification): StreakWithFreezeCalculator + effectiveStreakProvider (TDD)`**

### Task 5.1.b: 자동 freeze 적용 trigger (recordPractice 진입 시)

**Files:**
- Modify: `frontend/lib/features/practice/domain/services/practice_recording_service.dart` (또는 그 호출처)
- Test: 신규 통합 테스트 1개

흐름: 학생이 연습 기록 시점에 (a) 어제 결석 + (b) freeze 적용 가능 → `applyOnAbsence` 자동 호출.

- [ ] **Step 1-5: TDD + provider override 패턴**

### Task 5.2: D-day 마이그레이션 1회 실행

**Files:**
- Create: `frontend/lib/features/gamification/data/services/streak_freeze_migration.dart`
- Test: `frontend/test/features/gamification/data/services/streak_freeze_migration_test.dart`

스펙 §18.3:
- 기존 모든 학생 → `StreakFreeze.balance = 2`, `usedAt = []`, `examModeUntil = null`
- 신규 학생도 가입 시 동일
- 마이그레이션 flag (Hive `migration_v2_streak_freeze` = true) — 중복 실행 방지
- 학생에게 "스트릭 동결 시스템 시작" 안내 토스트 1회 (다음 홈 진입 시)

- [ ] **Step 1: 테스트 작성**
  - "마이그레이션 미실행 → 모든 학생 balance=2"
  - "마이그레이션 flag set → 재실행 시 no-op"
  - "마이그레이션 후 토스트 1회 표시 후 flag dismiss"
- [ ] **Step 2-5: TDD + 첫 홈 진입 시 자동 실행 wiring**
- [ ] **Step 5: Commit `feat(gamification): StreakFreeze D-day 마이그레이션 + 안내 토스트 (TDD)`**

---

## Job 6: 1년 히트맵 UI (TDD)

### Task 6.1: YearHeatmapGrid 위젯 (7×52)

**Files:**
- Create: `frontend/lib/features/gamification/presentation/widgets/year_heatmap_grid.dart`
- Test: `frontend/test/features/gamification/presentation/widgets/year_heatmap_grid_test.dart`

스펙 §4.4:
```
┌─────────────────────────────────────┐
│  1년 동안                              │
│  [GitHub 스타일 히트맵 7×52]            │
└─────────────────────────────────────┘
```

핵심:
- 가로 스크롤 (모바일)
- 7행 × ~52열 (실제 일수 / 7)
- 5단계 색 농도 (`AppColors.heatmapEmpty / heatmapL1 / heatmapL2 / heatmapL3 / heatmapL4`) — `AppColors` 에 5색 신규 추가
- 색맹 친화: 단계별 텍스처/dot 마커 (§17)
- 셀 tap → 일별 detail BottomSheet (해당 일 metronome/tuner/youtube/manual 분 + 녹음 수)

- [ ] **Step 1: 위젯 smoke test** (`design-principles.md` HARD-GATE 위젯 smoke test 필수)
  - 12달 = 365 칸 정확 렌더
  - 가로 스크롤 가능
  - 빈 GrowthHeatmap → 모든 칸 L0 색
  - 5단계 색 매핑 정확 (0/1-15/16-30/31-60/61+ 분)
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: 구현 (`CustomScrollView` + `SliverGrid` 가로 정렬. AppColors/AppTypography/AppSpacing 만 사용)**
- [ ] **Step 4: Verify pass + 색맹 패턴 추가**
- [ ] **Step 5: Commit `feat(gamification): YearHeatmapGrid 1년 히트맵 7×52 (TDD)`**

### Task 6.2: HeatmapDayDetailSheet (셀 tap 상세)

**Files:**
- Create: `frontend/lib/features/gamification/presentation/widgets/heatmap_day_detail_sheet.dart`
- Test: smoke test

해당 일자의 DailyPractice 분해:
- 메트로놈 N분 / 튜너 N분 / YouTube N분 / 수동 N분 / 녹음 N건
- 합계 분
- `swipe-rules` 미적용 (단순 정보 표시 시트)

- [ ] **Step 1-5: TDD + BottomSheet 패턴**

---

## Job 7: Trophy 모음 카드 (TDD)

### Task 7.1: TrophyCollectionCard

**Files:**
- Create: `frontend/lib/features/gamification/presentation/widgets/trophy_collection_card.dart`
- Test: `frontend/test/features/gamification/presentation/widgets/trophy_collection_card_test.dart`

스펙 §4.4 + §16:
```
│  내 트로피 ({N})                      │
│  🏆 🏆 🏆 ...                         │
```

- 기존 `badge_award_provider` 재사용
- 카테고리 분류 노출 X (단일 "모음" 카드)
- 9개 이상 시 "더 보기" 탭 → 전체 grid 화면

- [ ] **Step 1: 위젯 smoke test**
  - badge 0개 → "곧 첫 트로피!" 빈 상태 (Hick's Law)
  - badge 1-8개 → 인라인 표시
  - badge 9+ → 8개 표시 + 더보기
  - 카테고리 라벨 / origin 라벨 / "보상" 단어 미노출 (grep 검증)
- [ ] **Step 2-5: TDD**
- [ ] **Step 5: Commit `feat(gamification): TrophyCollectionCard (badge_award_provider 재사용)`**

### Task 7.2: TrophyGridScreen (전체 grid, badge 9+)

**Files:**
- Create: `frontend/lib/features/gamification/presentation/screens/trophy_grid_screen.dart`
- Test: smoke test

전체 trophy grid (4열) + 빈 슬롯 표시. 카테고리 라벨 X.

- [ ] **Step 1-5: TDD + 라우트 등록**

---

## Job 8: 휴식 권고 토스트 (SC-11) (TDD)

### Task 8.1: RestRecommendationToast

**Files:**
- Create: `frontend/lib/features/practice/presentation/widgets/rest_recommendation_toast.dart`
- Test: smoke test + 트리거 검증

스펙 §9.4:
- 단일 세션 30분 도달 → "잠깐 쉬는 게 어때요?" 토스트 1회 (같은 세션 내 반복 X)
- 일일 누적 3시간 도달 → 차분한 종료 권유 (강제 X)
- 14세 미만 = 15분 도달 시 강화 (§9.1)

- [ ] **Step 1: 테스트 작성**
  - 세션 timer 30분 → 토스트 1회 (29분 / 30분 / 31분 호출 → 1회만)
  - 일일 누적 3시간 도달 → 별도 차분 토스트 1회
  - 같은 날 재진입 시 누적 토스트 재표시 X (Hive `lastShownDate` 기록)
  - 14세 미만 분기 → 15분 임계값
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: 구현** (StreamController + Timer 기반. PracticeToolsModal 의 메트로놈 timer 와 연동)
- [ ] **Step 4: Verify pass + 세션 30분 회귀 시나리오**
- [ ] **Step 5: Commit `feat(practice): RestRecommendationToast (SC-11, TDD)`**

### Task 8.2: PracticeToolsModal 통합

**Files:**
- Modify: `frontend/lib/features/practice/presentation/widgets/practice_tools_modal.dart`
- Test: 통합 위젯 테스트

메트로놈 timer tick 마다 RestRecommendationToast.checkAndShow 호출.

- [ ] **Step 1-5: TDD + 기존 PracticeToolsModal 회귀 (PR #687/#689/#690) 통과 확인**

---

## Job 9: 더 보기 화면 통합 — StudentGrowthDetailScreen (TDD)

### Task 9.1: StudentGrowthDetailScreen

**Files:**
- Create: `frontend/lib/features/gamification/presentation/screens/student_growth_detail_screen.dart`
- Test: `frontend/test/features/gamification/presentation/screens/student_growth_detail_screen_test.dart`

스펙 §4.4 전체 화면:
```
┌─────────────────────────────────────┐
│  1년 동안                              │
│  [YearHeatmapGrid]                   │
│                                       │
│  내 트로피 ({N})                      │
│  [TrophyCollectionCard]              │
│                                       │
│  추천 ({N}) ●          (P3 placeholder)│
│                                       │
│  비교 보기   [OFF]    (P4 placeholder)│
└─────────────────────────────────────┘
```

- P3/P4 placeholder 영역은 빈 상태 (NO-OP 버튼 금지 — ux-rules.md). 단순 "곧 추가" 텍스트.
- 점점점 진입 → AppBar 단순 (← 뒤로)
- 14세 미만 → 비교 보기 행 자동 hide

- [ ] **Step 1: 위젯 smoke test + 통합**
  - YearHeatmapGrid + TrophyCollectionCard 렌더 확인
  - P3/P4 placeholder 영역에 NO-OP 버튼 0개 (grep `onTap: () {}`, `onPressed: null`)
  - 14세 미만 분기 — 비교 보기 hide
- [ ] **Step 2-5: TDD**

### Task 9.2: PracticeStartSection 점점점 → 라우팅

**Files:**
- Modify: `frontend/lib/features/gamification/presentation/widgets/practice_start_section.dart`
- Modify: `frontend/lib/core/router/app_router.dart` — `/student/growth-detail` 라우트 등록

- [ ] **Step 1: 통합 테스트** (spy mock 패턴 — feedback_spy_mock_for_router_tests.md)
  - 점점점 탭 → `context.go('/student/growth-detail')` 호출
  - 진입 → StudentGrowthDetailScreen 렌더
- [ ] **Step 2-5: TDD + Commit `feat(gamification): 점점점 → 더 보기 라우팅`**

---

## Job 10: 통합 테스트 + 베타 출시 게이트

### Task 10.1: End-to-end 통합 시나리오 테스트

**Files:**
- Create: `frontend/integration_test/student_gamification_p2_e2e_test.dart`

시나리오 A (스트릭 freeze 자동 적용):
1. 학생 가입 → 마이그레이션 → balance=2
2. 7일 연속 연습 → streak=7
3. 8일째 결석 → freeze 차감 → balance=1, streak=8 유지
4. 9일째 활동 → 정상 streak=9

시나리오 B (1년 히트맵 + 트로피):
1. 학생 1년 활동 데이터 fixture 로드
2. 홈 → 점점점 → 더 보기 화면
3. 1년 히트맵 365 칸 렌더 + P95 < 500ms 측정
4. 트로피 표시 + 카테고리 라벨 0건 grep

시나리오 C (휴식 권고):
1. 메트로놈 시작 → 30분 timer
2. 토스트 1회 노출
3. 같은 세션 35분 → 토스트 추가 X
4. 14세 미만 분기 → 15분에 노출

- [ ] **Step 1-4: 3 시나리오 작성 + e2e 실행 + 모든 step 통과**
- [ ] **Step 5: Commit `test(gamification): P2 e2e 시나리오 3종`**

### Task 10.2: 베타 출시 게이트 (SC-10, SC-11, SC-12 부분)

- [ ] **Step 1: SC-10 검증** — Sunday 00:00 KST 자동 +2, max 4 (시나리오 A + 단위 테스트)
- [ ] **Step 2: SC-11 검증** — 30분 토스트 1회 + 14세 미만 15분 (시나리오 C)
- [ ] **Step 3: SC-12 부분 검증** — StreakFreeze 추가로 신규 엔티티 4개 (P1 의 3개 + P2 의 1개). 잔여 SpotlightPrompt, LeaderboardPreferences 는 P3/P4
- [ ] **Step 4: 성능 검증** — 히트맵 1년 P95 < 500ms / P99 < 1000ms 측정 (스펙 §17)
- [ ] **Step 5: 회귀 검증** — `flutter test` 전체 통과 + `flutter analyze` 0 issue + 기존 P1 통합 테스트 회귀 통과
- [ ] **Step 6: 도메인 라벨 grep 검증** (SC-4 잔존 검증)
  ```bash
  grep -rn -E "Text\(.*origin\.|Text\(.*Origin\." frontend/lib/features/gamification/presentation/
  # 결과 0건
  ```
- [ ] **Step 7: PR 생성**
```bash
gh pr create \
  --title "feat(gamification): 학생 P2 Visual Growth — 1년 히트맵 + StreakFreeze + 휴식 권고" \
  --body "P1 머지 시리즈 후속. SC-10/SC-11 충족 + GrowthHeatmap 1년 캐시 P95 500ms. Hive 13 box chunk."
```

---

## Job 의존 검증

| Job | 차단 조건 |
|---|---|
| Job 0 | P1 시리즈 (#683/#687/#689/#690) 머지 완료 |
| Job 1 | Job 0 글로서리 등록 + worktree 진입 |
| Job 2 | Job 1 entities — 병렬 가능 (chunk 캐시는 P1 entity 사용) |
| Job 3 | Job 1 StreakFreeze entity |
| Job 4 | Job 3 StreakFreezeRepository |
| Job 5 | Job 4 StreakFreezeService + 기존 practice_streak_provider |
| Job 6 | Job 2 HiveGrowthHeatmapRepository |
| Job 7 | (Job 6 후 권장 — 같은 화면 통합 효율) |
| Job 8 | Job 4 (StreakFreezeService 와 무관, 독립 작업 — Job 4 후 순서만 위해) |
| Job 9 | Job 6 + Job 7 + Job 8 (Growth Detail 화면 통합) |
| Job 10 | Job 1~9 모두 완료 |

---

## 위험 + 완화

| 위험 | 완화 |
|---|---|
| 기존 `practice_streak_provider` 변경 시 회귀 | streak 회귀 테스트 전체 사전 실행 + Job 5 Step 4 마다 회귀 검증. P1 e2e (#690) 도 함께 |
| Hive 13 box 첫 진입 크래시 | Hive lazy box 사용 + try/catch + 빈 box 시 empty GrowthHeatmap 반환 (Task 2.2 Step 3) |
| KST timezone 자정 boundary | `Asia/Seoul` 고정 timezone 사용. 학생 디바이스 timezone 무시. D-day 1회 정렬 (스펙 §18.3) — 자정 차이 < 24h 학생 안내 X |
| StreakFreeze D-day 마이그레이션 중복 실행 | Hive flag `migration_v2_streak_freeze` 검사 — 재진입 idempotent (Task 5.2 Step 1) |
| 1년 365 칸 렌더 jank | `SliverGrid` + viewport 밖 칸 지연 빌드. `RepaintBoundary` 셀 단위 |
| 30일 chunk 직렬화 size 폭증 | DailyPractice = 5 필드 int — 30일 chunk ≈ 600 bytes JSON. 13 box 전체 ≈ 8KB. 부담 없음 |
| 휴식 권고 토스트 SC-11 trigger 누락 | RestRecommendationToast.checkAndShow 가 메트로놈 timer 의존 → 단위 + 통합 + e2e 3중 검증 |
| 색맹 친화 5단계 색 검증 누락 | 시각 회귀 — frontend-verify 의 스크린샷 회귀 + 단계별 색 + 패턴 텍스처 grep 검증 |
| 트로피 카테고리 라벨 누출 | Task 7.1 Step 1 grep 자동 검증. 추가로 SC-4 origin 라벨도 grep (Task 10.2 Step 6) |
| 마이그레이션 토스트 누락 / 중복 표시 | Hive flag `streak_freeze_migration_toast_shown` 별도 관리. 학생당 1회 보장 (Task 5.2 Step 2 테스트) |

---

## 후속 (P3~P4) 차단점

| 차단점 | 풀리는 시점 |
|---|---|
| SpotlightPrompt 큐 + 거절 학습 | P3 |
| YouTube 정밀 polling (P1 = onEnded 만) | P3 |
| LeaderboardPreferences + 4 레이어 UI | P4 |
| 부모 동의 흐름 (14세 미만) | P4 |
| 글로벌 익명 어뷰징 방지 | P4 |
| 비교 보기 UI 실제 활성 (P2 = placeholder) | P4 |

P2 만으로 베타 출시 확장 가능 (스펙 §18.2 — P1 단독으로도 가능했음. P2 는 시각 진척 강화).

---

## 성공 기준 (P2 한정)

| # | 스펙 SC | P2 검증 |
|---|---|---|
| SC-10 | Streak freeze 자동 발급 주 2회 | Task 10.2 Step 1 시나리오 A + StreakFreezeService 단위 테스트 |
| SC-11 | 연습 30분 초과 휴식 권고 토스트 (푸시 X) | Task 10.2 Step 2 시나리오 C |
| SC-12 (부분) | 신규 엔티티 — P2 에서 StreakFreeze 추가 = 누적 4/5 | Job 1 + P1 누적 — SpotlightPrompt, LeaderboardPreferences 는 P3/P4 |
| 비기능 — 히트맵 P95 < 500ms | Task 10.2 Step 4 perf 측정 | 13 box chunk 캐시 |

P2 SC 비율: 12/12 중 **2 신규 완전 충족 (SC-10, SC-11) + SC-12 부분 (4/5)** + 비기능 P95. P1 의 SC-1, SC-3, SC-4 회귀 유지.

---

## 변경 이력

| 날짜 | 변경 | 비고 |
|---|---|---|
| 2026-06-12 | 초안 작성 | 스펙 §18.1 P2 Visual Growth 기반. P1 결과물 (#683/#687/#689/#690) 활용 |
