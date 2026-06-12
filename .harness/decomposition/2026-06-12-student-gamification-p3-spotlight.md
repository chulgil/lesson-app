# 학생 게이미피케이션 P3 Spotlight — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> 스펙: `.harness/spec/2026-06-11-student-gamification.md` §5.2 Spotlight + §6.2 SpotlightPrompt + §7 룰/페이스/거절 학습 + §9.1 14세 미만 분기 + §10.2 명절 이벤트 + §17 비기능
> 선행: P1 Foundation 완료 + P2 Visual Growth 완료 (PR #683/#687/#689/#690/#702 머지)
> 스코프: **P3 Spotlight 만** — SpotlightPrompt 큐 + 노출 조건 + 큐 우선순위 + 거절 학습 + 축하 후 1슬롯 prompt. LeaderboardPreferences/비교 보기/글로벌 익명/부모 동의 (P4) 별도.

**Goal:** P1/P2 의 자가 연습 + 시각 진척 위에 "선택적 권유" 1슬롯을 추가. 연습 종료 후 축하 화면(1.5초)에 가끔(주 1-2회) Spotlight prompt 표시. 학생이 "지금 볼래"/"다음에"를 동등한 비중으로 선택. 거절 학습으로 큐레이션 자율성 보존 (SC-9). 푸시 알림 0건 (스펙 §8 KPI).

**Architecture:** PracticeService 의 record 후 (a) SpotlightPrompt.enqueue(if eligible) 호출 — 새로운 prompt 후보 큐잉 (b) 축하 overlay 노출 직전 `currentSpotlightForCelebrationProvider` 가 §7.1 노출 조건 + §7.2 큐 우선순위 평가 후 1개 반환 (c) overlay 가 SpotlightSlot 위젯에 prompt 표시 (d) 학생 "지금 볼래" → ctaRoute 이동 + accepted 기록 / "다음에" → DeclineLearningService.decline 호출 → 큐에서 cooldown 적용. teacher_resource 등록 / 시즌 이벤트 (시즌 토스트 기존) / routine 추천 generator 3개가 큐 시드 공급.

**Tech Stack:** Flutter 3.29.0 / Riverpod (codegen) / Hive (`Box<String>` + JSON, P2 패턴 일관) / json_serializable / flutter_test / integration_test

**진입 게이트**: P2 Visual Growth (#702) 머지 + main clean.

---

## 사전 결정 (O1~O7 — Job 0 진입 결정사항)

본 PLAN 의 추천안. 사용자 검토 시 변경 가능. Job 0 첫 task 에서 글로서리/스펙에 확정 반영.

| # | 항목 | 추천 결정 | 근거 |
|---|---|---|---|
| O1 | SpotlightPrompt 저장소 | Hive `Box<String>` + JSON (key=promptId, value=JSON) — P2 StreakFreeze 패턴 일관 | typeId 충돌 0 + 스키마 진화 단순. JSON bytes 단일 record < 200 bytes |
| O2 | 큐 단일 box | `spotlight_prompt_v1` (전체 학생 통합). key=`{studentId}::{promptId}` prefix scan | 학생별 box 13개 분리 부담 회피. Box 1개 + key prefix 패턴 (학생 수 300명 × 평균 큐 길이 < 30 → 9000 record, scan 부담 없음) |
| O3 | 노출 위치 | `PracticeCelebrationOverlay` 안 SpotlightSlot 위젯 (1.5초 축하 + 5초 prompt 유지) | P1 Job 7 (#690) 의 overlay 확장. 신규 화면 X. SC-1 5초 게이트 회귀 X |
| O4 | "지금 볼래" / "다음에" 동일 비중 | 같은 색·같은 폰트·같은 높이 (스펙 §7.4) | 거절 페널티 메시징 0. Hick's Law 옵션 2 |
| O5 | 거절 학습 카운터 | type별 `declineCount` 추적 (teacherRec 5회 ≠ seasonEvent 5회) | 스펙 §7.3 — 같은 type 5회 거절 → 8주 hide. type별 독립 |
| O6 | 14세 미만 처리 | P3 에서는 "Student.birthDate 있고 14세 미만이면 Spotlight 일괄 hide" — 부모 동의 시스템은 P4 | SC-9 안전 우선. 14세 미만은 P4 에서 부모 동의 흐름 + spotlight 활성 |
| O7 | Spotlight 시드 공급 | Job 8 — teaching_resource 변경 시 즉시 enqueue + 시즌 이벤트 1회 큐레이션 (D-day 마이그레이션과 동일 패턴) + routineSuggestion 은 P3 에서는 placeholder generator (Hardcoded 1종 — "꾸준한 루틴이 7일 이상" → 시드 1개) | P3 범위 최소화. routineSuggestion 의 실제 패턴 분석은 P4 와 함께 |

---

## DAG (Job 의존 관계)

```
Job 0 (사전 결정 + 글로서리 등록)
        │
        ▼
Job 1 (SpotlightPrompt entity + enum)
        │
        ▼
Job 2 (SpotlightPromptRepository — interface + Mock + Hive)
        │
        ├──────────────┬──────────────┐
        ▼              ▼              ▼
Job 3          Job 4          Job 5
(Eligibility   (QueueService  (DeclineLearning
 §7.1)          §7.2)           §7.3)
        │              │              │
        └──────┬───────┴──────────────┘
               ▼
       Job 6 (SpotlightProvider — Riverpod codegen)
               │
               ▼
       Job 7 (PracticeCelebrationOverlay SpotlightSlot 통합)
               │
               ▼
       Job 8 (Seeding — teacher_resource + 시즌 큐레이션 + routine generator)
               │
               ▼
       Job 9 (E2E + 베타 게이트 SC-9)
```

---

## 파일 구조 (P3 범위)

### 신규 파일 (`.dart` 13개 + codegen 5개)

**Domain (gamification feature)**:
- `frontend/lib/features/gamification/domain/entities/spotlight_prompt.dart`
- `frontend/lib/features/gamification/domain/entities/spotlight_type.dart` (enum: teacherRec/seasonEvent/routineSuggestion)
- `frontend/lib/features/gamification/domain/repositories/spotlight_prompt_repository.dart` (interface)
- `frontend/lib/features/gamification/domain/services/spotlight_eligibility_service.dart`
- `frontend/lib/features/gamification/domain/services/spotlight_queue_service.dart`
- `frontend/lib/features/gamification/domain/services/spotlight_decline_learning_service.dart`
- `frontend/lib/features/gamification/domain/services/spotlight_seeding_service.dart` (teacher/season/routine 3 generator)

**Data (Hive)**:
- `frontend/lib/features/gamification/data/repositories/mock_spotlight_prompt_repository.dart`
- `frontend/lib/features/gamification/data/repositories/hive_spotlight_prompt_repository.dart`

**Presentation providers**:
- `frontend/lib/features/gamification/presentation/providers/spotlight_provider.dart` (+ `current_spotlight_for_celebration_provider` 도 같은 파일)

**UI**:
- `frontend/lib/features/gamification/presentation/widgets/spotlight_slot.dart` (overlay 내 표시 위젯)

**테스트 (12개)**:
- entity / repository / 3 service / provider / widget / e2e

### 수정 파일 (4개)

- `frontend/lib/features/gamification/presentation/widgets/practice_celebration_overlay.dart` — SpotlightSlot 통합 (P1 #690 위젯)
- `frontend/lib/features/practice/domain/services/practice_recording_service.dart` — record 후 seeding hook (작은 변경 — `ref.read(spotlightSeedingServiceProvider).afterPracticeRecord(...)`)
- `frontend/lib/features/lessons/...` — teacher_resource 추가 시 SpotlightSeedingService 호출 hook (있다면)
- `.harness/knowledge/glossary.md` — SpotlightPrompt, DeclineCooldown, HideUntil, SpotlightSlot, RoutineSuggestion, 7일 cooldown, 8주 hide, 영구 hide 용어 등록 (+ `docs/specs/glossary.md` 동기화)

---

## Job 0: 사전 결정 + 글로서리 등록

**Files:**
- Modify: `.harness/knowledge/glossary.md`
- Modify: `docs/specs/glossary.md` (동기화)
- Modify: `.harness/spec/2026-06-11-student-gamification.md` (P3 진입 commit hash 추가)

- [ ] **Step 1: P2 머지 hash 기록**

스펙 헤더에 P3 진입 시점 hash 추가 (head of main = `6f7acf3c`).

- [ ] **Step 2: glossary 신규 용어 등록**

`.harness/knowledge/glossary.md` 의 §15 학생 게이미피케이션 안에 "P3 Spotlight 추가 용어 (2026-06-12)" 섹션 추가:
- 엔티티 1종 (SpotlightPrompt)
- 정책 용어 7종 (스포트라이트 종류 3 + cooldown 7일 + 8주 hide + 영구 hide + 노출 슬롯)
- 서비스 메서드 3종 (Eligibility / Queue / DeclineLearning)
- Deprecated 표현 2건 ("필수 알림" / "강제 푸시" → "스포트라이트 권유")

`docs/specs/glossary.md` 동기화.

- [ ] **Step 3: 사전 결정 O1~O7 확정**

본 플랜 표를 사용자 검토 후 확정. 변경 사항 있으면 본문 갱신.

- [ ] **Step 4: Worktree 진입 확인**

```bash
git worktree list | grep p3-spotlight
# /Users/r00360/Dev/personal/development/app/lesson-app-wt-p3-spotlight  [feat/gamif-p3-spotlight]
```

- [ ] **Step 5: 글로서리 동기화 커밋**

```bash
git add .harness/knowledge/glossary.md docs/specs/glossary.md \
        .harness/spec/2026-06-11-student-gamification.md \
        .harness/decomposition/2026-06-12-student-gamification-p3-spotlight.md
git commit -m "docs(gamification): P3 Spotlight 사전 결정 + 글로서리 등록"
```

---

## Job 1: SpotlightPrompt entity + enum (TDD)

### Task 1.1: SpotlightType enum

**Files:**
- Create: `frontend/lib/features/gamification/domain/entities/spotlight_type.dart`
- Test: `frontend/test/features/gamification/domain/entities/spotlight_type_test.dart`

```dart
enum SpotlightType {
  teacherRec,        // 선생님 추천 영상·곡
  seasonEvent,       // 시즌/명절 큐레이션
  routineSuggestion, // 자가 routine 30일+ 추천
}
```

- [ ] **Step 1: 테스트 작성**
  - `name` 직렬화 안정 ("teacherRec" / "seasonEvent" / "routineSuggestion")
  - `SpotlightType.fromName(String)` 역변환 + unknown 시 IllegalArgumentException 또는 fallback
- [ ] **Step 2-5: TDD + Commit**

### Task 1.2: SpotlightPrompt entity (json_serializable)

**Files:**
- Create: `frontend/lib/features/gamification/domain/entities/spotlight_prompt.dart`
- Test: `frontend/test/features/gamification/domain/entities/spotlight_prompt_test.dart`
- 코드 생성: `spotlight_prompt.g.dart`

스펙 §6.2:
```dart
@JsonSerializable()
class SpotlightPrompt {
  final String id;
  final String studentId;
  final SpotlightType type;
  final String title;
  final String? videoId;
  final String? ctaRoute;
  final DateTime queuedAt;
  final int declineCount;       // 0..N
  final DateTime? hideUntil;    // 8주 cooldown 또는 영구 (= year 9999)
  final bool permanentlyHidden; // 8주 후 1회 재시도 → 또 거절 시 true
  final DateTime? lastShownAt;  // 노출 시각 (cooldown 계산용)
}
```

- [ ] **Step 1: 테스트 작성**
  - `copyWith` immutability
  - `isHiddenAt(DateTime now)` — permanentlyHidden true 또는 hideUntil > now → true
  - `priority` getter — type 별 정수 (teacherRec=1, seasonEvent=2, routineSuggestion=3) — Job 4 큐 우선순위 §7.2 와 연동
  - `JSON round-trip` 보존 (DateTime ISO8601 / SpotlightType.name)
- [ ] **Step 2-5: TDD + codegen + Commit**

---

## Job 2: SpotlightPromptRepository (TDD)

### Task 2.1: SpotlightPromptRepository 인터페이스

**Files:**
- Create: `frontend/lib/features/gamification/domain/repositories/spotlight_prompt_repository.dart`

```dart
abstract class SpotlightPromptRepository {
  Future<void> enqueue(SpotlightPrompt prompt);
  Future<List<SpotlightPrompt>> listForStudent(String studentId);
  Future<SpotlightPrompt?> getById(String id);
  Future<SpotlightPrompt> markShown(String id, DateTime now);
  Future<SpotlightPrompt> incrementDecline(String id, DateTime now);
  Future<SpotlightPrompt> setHideUntil(String id, DateTime until);
  Future<SpotlightPrompt> markPermanentlyHidden(String id);
  Future<void> purgeAcceptedOrExpired(String studentId, DateTime now);
}
```

- [ ] **Step 1-3: 인터페이스 + analyze 0 issue + Commit**

### Task 2.2: MockSpotlightPromptRepository (in-memory)

**Files:**
- Create: `frontend/lib/features/gamification/data/repositories/mock_spotlight_prompt_repository.dart`
- Test: `frontend/test/features/gamification/data/repositories/mock_spotlight_prompt_repository_test.dart`

- [ ] **Step 1: 테스트 작성**
  - 모든 8 메서드 round-trip
  - listForStudent 다른 학생 누출 없음
  - incrementDecline N회 → declineCount=N + lastShownAt 갱신
- [ ] **Step 2-5: TDD + Commit**

### Task 2.3: HiveSpotlightPromptRepository

**Files:**
- Create: `frontend/lib/features/gamification/data/repositories/hive_spotlight_prompt_repository.dart`
- Test: `frontend/test/features/gamification/data/repositories/hive_spotlight_prompt_repository_test.dart`

Hive box `spotlight_prompt_v1` (`Box<String>`). key=`{studentId}::{promptId}`. value=jsonEncode.

- [ ] **Step 1: 테스트 작성**
  - 빈 box → listForStudent 반환 [] (empty 안전)
  - enqueue → listForStudent 즉시 반영
  - key prefix scan 다른 학생 누출 X
- [ ] **Step 2-5: TDD + Commit**

---

## Job 3: SpotlightEligibilityService — §7.1 (TDD)

**Files:**
- Create: `frontend/lib/features/gamification/domain/services/spotlight_eligibility_service.dart`
- Test: `frontend/test/features/gamification/domain/services/spotlight_eligibility_service_test.dart`

순수 함수 + value object:

```dart
class SpotlightEligibilityContext {
  final Duration sessionDuration;       // 마지막 세션 길이
  final DateTime now;
  final int promptsShownToday;
  final int promptsShownThisWeek;       // 월요일 시작
  final bool studentIsUnder14;
  final bool studentHasParentConsent;   // P3 에서는 false 가정 가능 (P4 의존)
}

class SpotlightEligibilityResult {
  final bool eligible;
  final String? reason; // ex: "session_too_short", "weekly_cap_hit"
}

class SpotlightEligibilityService {
  SpotlightEligibilityResult evaluate(SpotlightEligibilityContext ctx);
}
```

- [ ] **Step 1: 테스트 작성** (스펙 §7.1 6 조건 매칭)
  - 세션 < 5분 → eligible=false, reason="session_too_short"
  - 오늘 첫 prompt 아님 → eligible=false, reason="daily_cap_hit"
  - 주간 ≥ 2 → eligible=false, reason="weekly_cap_hit"
  - 14세 미만 + 부모 동의 X → eligible=false, reason="parent_consent_required"
  - 14세 이상 + 모든 조건 통과 → eligible=true
  - 14세 미만 + 부모 동의 O → eligible=true (P4 의존, P3 에서는 가정 흐름)
- [ ] **Step 2-5: TDD + Commit `feat(gamification): SpotlightEligibilityService §7.1 (TDD)`**

---

## Job 4: SpotlightQueueService — §7.2 (TDD)

**Files:**
- Create: `frontend/lib/features/gamification/domain/services/spotlight_queue_service.dart`
- Test: `frontend/test/features/gamification/domain/services/spotlight_queue_service_test.dart`

```dart
class SpotlightQueueService {
  SpotlightQueueService(this._repo);
  final SpotlightPromptRepository _repo;

  Future<SpotlightPrompt?> nextPromptableFor(String studentId, DateTime now);
}
```

큐 우선순위 (스펙 §7.2):
1. type=teacherRec + (hideUntil null or expired) + lastShownAt < now - 7일 (cooldown)
2. type=teacherRec 일반 (1주 이내 queued)
3. type=seasonEvent (활성 시즌만 — Job 8 에서 시드)
4. type=routineSuggestion

같은 type 내 oldest queuedAt 우선.

- [ ] **Step 1: 테스트 작성**
  - 빈 큐 → null
  - teacherRec 1개만 → 반환
  - teacherRec + seasonEvent → teacherRec 우선
  - teacherRec hideUntil > now → skip → seasonEvent 반환
  - cooldown 7일 미경과 → skip
  - permanentlyHidden → skip
  - 동일 type 2개 → oldest queuedAt 반환
- [ ] **Step 2-5: TDD + Commit `feat(gamification): SpotlightQueueService §7.2 우선순위 (TDD)`**

---

## Job 5: SpotlightDeclineLearningService — §7.3 (TDD)

**Files:**
- Create: `frontend/lib/features/gamification/domain/services/spotlight_decline_learning_service.dart`
- Test: `frontend/test/features/gamification/domain/services/spotlight_decline_learning_service_test.dart`

```dart
class SpotlightDeclineLearningService {
  SpotlightDeclineLearningService(this._repo);
  final SpotlightPromptRepository _repo;

  /// "다음에" 탭 → cooldown 7일 적용 + declineCount +1
  /// 같은 type 5회 누적 거절 → 8주 hide
  /// 8주 후 1회 재시도 → 또 거절 → 영구 hide
  Future<SpotlightPrompt> decline(String promptId, DateTime now);
}
```

알고리즘 (스펙 §7.3):
1. `prompt = await repo.getById(promptId)`
2. `prompt = await repo.incrementDecline(...)` → declineCount += 1
3. 같은 type 누적 declineCount 계산 (해당 학생 + type)
4. 누적 < 5 → cooldown 7일 (`setHideUntil(now + 7d)`)
5. 누적 == 5 → 8주 hide (`setHideUntil(now + 56d)`)
6. 누적 == 6 (이미 8주 hide 후 1회 재시도 + 거절) → `markPermanentlyHidden`

- [ ] **Step 1: 테스트 작성**
  - 1회 거절 → cooldown 7d 적용
  - 4회 거절 → cooldown 7d
  - 5회 거절 → 8주 hide (= 56d)
  - 6회 거절 → permanentlyHidden true
  - 같은 type 카운터 — 다른 type 의 거절 영향 0 (teacherRec 5회 ≠ seasonEvent 카운터)
- [ ] **Step 2-5: TDD + Commit `feat(gamification): SpotlightDeclineLearningService §7.3 거절 학습 (TDD)`**

---

## Job 6: SpotlightProvider (Riverpod codegen) (TDD)

**Files:**
- Create: `frontend/lib/features/gamification/presentation/providers/spotlight_provider.dart`
- 코드 생성: `spotlight_provider.g.dart`
- Test: `frontend/test/features/gamification/presentation/providers/spotlight_provider_test.dart`

```dart
@Riverpod(keepAlive: true)
SpotlightPromptRepository spotlightPromptRepository(...) {
  return HiveSpotlightPromptRepository(); // test override
}

@Riverpod(keepAlive: true)
SpotlightEligibilityService spotlightEligibilityService(...) => SpotlightEligibilityService();

@Riverpod(keepAlive: true)
SpotlightQueueService spotlightQueueService(SpotlightQueueServiceRef ref) =>
    SpotlightQueueService(ref.read(spotlightPromptRepositoryProvider));

@Riverpod(keepAlive: true)
SpotlightDeclineLearningService spotlightDeclineLearningService(SpotlightDeclineLearningServiceRef ref) =>
    SpotlightDeclineLearningService(ref.read(spotlightPromptRepositoryProvider));

/// 축하 overlay 가 호출 — eligibility + queue 평가 후 1개 반환 (없으면 null)
@riverpod
Future<SpotlightPrompt?> currentSpotlightForCelebration(
  CurrentSpotlightForCelebrationRef ref,
  String studentId,
  Duration sessionDuration,
) async {
  final eligibility = ref.read(spotlightEligibilityServiceProvider);
  final queue = ref.read(spotlightQueueServiceProvider);
  // ctx 계산 (오늘/주간 카운터는 lastShownAt 집계로 도출)
  // ... eligibility.evaluate(ctx) 후 eligible 이면 queue.nextPromptableFor 반환
}
```

- [ ] **Step 1: 테스트 작성** — Provider override 패턴
  - eligibility=false → null
  - eligibility=true + queue empty → null
  - eligibility=true + queue 반환 → 그대로 전달
- [ ] **Step 2-5: TDD + build_runner + Commit**

---

## Job 7: PracticeCelebrationOverlay SpotlightSlot 통합 (TDD)

### Task 7.1: SpotlightSlot 위젯

**Files:**
- Create: `frontend/lib/features/gamification/presentation/widgets/spotlight_slot.dart`
- Test: `frontend/test/features/gamification/presentation/widgets/spotlight_slot_test.dart`

UI (스펙 §7.4):
```
┌─────────────────────────────┐
│  선생님이 추천했어요          │   <- type별 헤더
│  {prompt.title}              │
│                              │
│  [지금 볼래]    [다음에]      │   <- 동일 높이/색/폰트
└─────────────────────────────┘
```

- type 별 헤더:
  - teacherRec → "선생님이 추천했어요"
  - seasonEvent → "이번 달 추천"
  - routineSuggestion → "이거 어때요?"
- 모든 텍스트 `AppStrings` 등록 (하드코딩 금지)

- [ ] **Step 1: 위젯 smoke test (HARD-GATE)**
  - 3 type 헤더 정확
  - "지금 볼래" / "다음에" 버튼 동일 minimumSize (`Size(0, AppSpacing.buttonHeightSmall)`)
  - "지금 볼래" tap → `onAccept(prompt)` 콜백 호출
  - "다음에" tap → `onDecline(prompt)` 콜백 호출
- [ ] **Step 2-5: TDD + Commit `feat(gamification): SpotlightSlot 위젯 (TDD)`**

### Task 7.2: PracticeCelebrationOverlay 통합

**Files:**
- Modify: `frontend/lib/features/gamification/presentation/widgets/practice_celebration_overlay.dart`
- Test: `frontend/test/features/gamification/presentation/widgets/practice_celebration_overlay_test.dart`

흐름:
1. overlay 진입 시 `ref.watch(currentSpotlightForCelebrationProvider(studentId, sessionDuration))`
2. data!=null → SpotlightSlot 표시
3. "지금 볼래" → `repo.markShown(id, now)` + `router.go(prompt.ctaRoute)` (없으면 youtubeId 영상 재생)
4. "다음에" → `spotlightDeclineLearningServiceProvider.decline(id, now)` + overlay 닫기
5. data==null → 기존 1.5초 축하만 (회귀 0)

- [ ] **Step 1: 통합 테스트**
  - 기존 SC-1 (5초 게이트) 회귀 통과
  - prompt 있을 때 SpotlightSlot 렌더 + accept/decline 흐름 spy mock 검증
  - prompt 없을 때 기존 1.5초 축하 표시
  - 14세 미만 분기 — Spotlight 일괄 hide (Job 3 의 evaluate 결과 적용)
- [ ] **Step 2-5: TDD + Commit `feat(gamification): PracticeCelebrationOverlay Spotlight 슬롯 통합 (TDD)`**

---

## Job 8: Spotlight Seeding — generator 3종 (TDD)

### Task 8.1: SpotlightSeedingService (interface + 3 generator)

**Files:**
- Create: `frontend/lib/features/gamification/domain/services/spotlight_seeding_service.dart`
- Test: `frontend/test/features/gamification/domain/services/spotlight_seeding_service_test.dart`

```dart
class SpotlightSeedingService {
  Future<void> seedTeacherRecommendation({
    required String studentId,
    required String teacherResourceId,
    required String title,
    required String? videoId,
    required String? ctaRoute,
  });

  Future<void> seedSeasonEvent({
    required String studentId,
    required String seasonKey, // "추석2026" / "크리스마스2026" / "어린이날2027" / "음악의날2026"
    required String title,
    required String? ctaRoute,
  });

  Future<void> seedRoutineSuggestion({
    required String studentId,
    required int recentStreakDays, // 30+ 이면 시드
  });
}
```

각 메서드는:
1. 중복 체크 (같은 시즌/teacher_resource/routine 이미 enqueued 시 skip)
2. `SpotlightPrompt` 생성 → `repo.enqueue`

routineSuggestion 은 P3 placeholder — `recentStreakDays >= 30` 시 1회만 시드 ("꾸준한 루틴이 한 달 넘었어요. 새로운 루틴 어때요?").

- [ ] **Step 1: 테스트 작성** (3 generator + 중복 차단)
- [ ] **Step 2-5: TDD + Commit `feat(gamification): SpotlightSeedingService 3 generator (TDD)`**

### Task 8.2: PracticeRecordingService 통합 hook

**Files:**
- Modify: `frontend/lib/features/practice/domain/services/practice_recording_service.dart`
- Test: `frontend/test/features/practice/domain/services/practice_recording_service_seeding_test.dart`

흐름: record 후 routineSuggestion 시드 시도 (recentStreakDays 가져와 seedRoutineSuggestion 호출).

- [ ] **Step 1: 통합 테스트** — record 후 30일+ 스트릭 학생 → routine prompt 1회 큐잉
- [ ] **Step 2-5: TDD + provider override**

### Task 8.3: 시즌 큐레이션 + teacher_resource hook (D-day 시드)

**Files:**
- Create: `frontend/lib/features/gamification/data/services/spotlight_season_curator.dart` (활성 시즌 1회 시드)
- Modify: teacher_resource 추가 코드 (있다면) — 호출 hook 1줄

- [ ] **Step 1: 테스트 작성**
  - 활성 시즌 (예: 어린이날 5/1-5/7) — 첫 진입 시 1회 시드
  - 시즌 종료 후 미시드
  - 중복 호출 시 no-op (seasonKey 중복 차단)
- [ ] **Step 2-5: TDD + Commit `feat(gamification): SpotlightSeasonCurator + teacher hook (TDD)`**

---

## Job 9: 통합 테스트 + 베타 출시 게이트

### Task 9.1: End-to-end 통합 시나리오 테스트

**Files:**
- Create: `frontend/integration_test/student_gamification_p3_e2e_test.dart`

시나리오 A (거절 학습 — SC-9 검증):
1. teacherRec 1개 시드
2. 학생 5분+ 연습 → overlay → SpotlightSlot 표시
3. "다음에" tap → cooldown 7d
4. 7일 후 재진입 → 같은 prompt 다시 표시 → 또 "다음에" → repeat
5. 5회 누적 거절 → 8주 hide → overlay 에 다른 prompt or null
6. 8주 후 1회 재시도 → "다음에" → permanentlyHidden=true

시나리오 B (우선순위 큐):
1. teacherRec + seasonEvent + routineSuggestion 3개 시드
2. 1회 연습 → teacherRec 표시
3. "지금 볼래" → ctaRoute 이동 (또는 영상 재생)
4. 2회 연습 (다음 주) → seasonEvent 표시

시나리오 C (노출 조건):
1. 5분 미만 세션 → Spotlight 노출 X
2. 오늘 이미 1회 표시 → 추가 노출 X
3. 14세 미만 학생 → 일괄 hide (Spotlight 비활성)

- [ ] **Step 1-4: 3 시나리오 작성 + e2e 실행 + 통과**
- [ ] **Step 5: Commit `test(gamification): P3 e2e 시나리오 3종`**

### Task 9.2: 베타 출시 게이트 (SC-9 + 비기능)

- [ ] **Step 1: SC-9 검증** — 거절 5회 후 자동 hide + 8주 cooldown (시나리오 A)
- [ ] **Step 2: SC-12 검증** — 신규 엔티티 SpotlightPrompt 추가 — P1(3) + P2(StreakFreeze) + P3(SpotlightPrompt) = 4/5. 잔여 LeaderboardPreferences 는 P4
- [ ] **Step 3: 비기능 검증** — 노출 빈도 주 1-2회 cap + 푸시 알림 0건 (KPI §8)
- [ ] **Step 4: 회귀 검증** — `flutter test` 전체 통과 + `flutter analyze` 0 issue + P1/P2 통합 테스트 회귀
- [ ] **Step 5: 도메인 라벨 grep 검증 (SC-4 잔존)**
  ```bash
  grep -rn -E "Text\(.*origin\.|Text\(.*Origin\." frontend/lib/features/gamification/presentation/
  # 결과 0건
  ```
- [ ] **Step 6: 메시징 규칙 검증 (스펙 §7.4)**
  ```bash
  grep -rn "꼭 해야\|필수입니다" frontend/lib/features/gamification/presentation/
  # 결과 0건
  ```
- [ ] **Step 7: PR 생성**
```bash
gh pr create \
  --title "feat(gamification): 학생 P3 Spotlight — 큐 + 거절 학습 + 축하 슬롯" \
  --body "P2 머지 후속. SC-9 거절 5회 → 8주 hide 충족. SpotlightPrompt 신규 엔티티. 푸시 0건."
```

---

## Job 의존 검증

| Job | 차단 조건 |
|---|---|
| Job 0 | P2 (#702) 머지 완료 + worktree 진입 |
| Job 1 | Job 0 글로서리 등록 |
| Job 2 | Job 1 entity |
| Job 3 | Job 1 (context value object 만 의존) — Job 2 독립 |
| Job 4 | Job 2 repository interface |
| Job 5 | Job 2 repository interface |
| Job 6 | Job 3 + Job 4 + Job 5 |
| Job 7 | Job 6 provider |
| Job 8 | Job 2 repository — Job 6/7 와 병렬 가능 |
| Job 9 | Job 1~8 모두 완료 |

---

## 위험 + 완화

| 위험 | 완화 |
|---|---|
| PracticeCelebrationOverlay 변경 시 SC-1 5초 게이트 회귀 | Job 7 Step 1 통합 테스트에 P1 SC-1 회귀 시나리오 포함 (#690 의 기존 테스트 재실행) |
| 큐 우선순위 알고리즘 type별 카운터 누락 | Job 5 Step 1 — 다른 type 의 거절이 카운터 영향 0 명시 테스트 |
| 14세 미만 부모 동의 시스템 미구현 (P4 의존) | Job 3 evaluate 에서 `studentIsUnder14 && !hasParentConsent → eligible=false` 안전 분기 — P3 에서는 14세 미만 학생 Spotlight 일괄 hide |
| Hive box prefix scan 부담 (학생 300명 × 30 prompt = 9000) | Job 2 Task 2.3 measure — listForStudent P95 < 50ms 검증 (실측 미달 시 학생별 box 분리로 전환) |
| 거절 학습 영구 hide 후 학생 재활성 경로 누락 | 스펙 §7.3 — "학생이 옵션에서 명시적 재활성" — P3 에서 더 보기 화면에 placeholder 추가 (P4 와 함께 실제 옵션 UI). P3 Job 9 게이트는 영구 hide 동작만 검증 |
| 시즌 큐레이션 timezone | KST `Asia/Seoul` 고정 — P2 StreakFreezeService 패턴 일관 |
| 메시징 규칙 위반 (감사 X, 권유형) | Job 9 Step 6 grep 자동 검증 ("꼭 해야" / "필수입니다") |
| SC-9 5회 카운트 boundary edge case | Job 5 테스트 5/6 회 boundary 명시 |
| Spotlight 노출 빈도 cap (주 ≤ 2) bypass | Job 3 SpotlightEligibilityService 가 lastShownAt 집계로 주간 카운터 도출 — repo.listForStudent + count |
| 푸시 알림 0건 (KPI §8) — 실수 발송 위험 | P3 코드에 FCM / push API 호출 0건. Job 9 Step 3 grep 검증 (`grep -rn "FirebaseMessaging\|sendPush" frontend/lib/features/gamification/`) |
| routineSuggestion placeholder 의 의미 부재 | Job 8 Task 8.1 — 30일+ 스트릭 보유 학생만 시드. recentStreakDays < 30 → skip. 학습 패턴 정밀 분석은 P4 |

---

## 후속 (P4) 차단점

| 차단점 | 풀리는 시점 |
|---|---|
| LeaderboardPreferences + 4 레이어 UI | P4 |
| 부모 동의 흐름 + parentConsentAt | P4 — Spotlight 14세 미만 분기 활성화 의존 |
| 글로벌 익명 + 어뷰징 방지 | P4 |
| 비교 보기 UI 활성 | P4 |
| routineSuggestion 정밀 패턴 분석 (자가 routine 30일+ 시) | P4 (현재는 placeholder generator) |
| Spotlight "옵션에서 명시적 재활성" UI | P4 (현재는 영구 hide 동작만 P3 에서 보장) |

---

## 성공 기준 (P3 한정)

| # | 스펙 SC | P3 검증 |
|---|---|---|
| SC-9 | Spotlight prompt 거절 5회 후 자동 hide | Task 9.2 Step 1 시나리오 A + Job 5 단위 테스트 |
| SC-12 (부분) | 신규 엔티티 — P3 에서 SpotlightPrompt 추가 = 누적 4/5 | Job 1 + P1 + P2 누적 (Quest / GrowthHeatmap / StreakFreeze / SpotlightPrompt) |
| 비기능 — 노출 빈도 주 1-2회 cap (§8 KPI) | Task 9.2 Step 3 + Job 3 시나리오 | SpotlightEligibilityService weeklyCap |
| 비기능 — 푸시 알림 0건 (§8 KPI) | Task 9.2 Step 3 grep 검증 | P3 코드에 FCM/push 호출 0건 |

P3 SC 비율: 12/12 중 **1 신규 완전 충족 (SC-9) + SC-12 부분 (4/5)** + 비기능 푸시 0건 + 주 1-2회 cap. P1/P2 의 SC-1, SC-3, SC-4, SC-10, SC-11 회귀 유지.

---

## 변경 이력

| 날짜 | 변경 | 비고 |
|---|---|---|
| 2026-06-12 | 초안 작성 | 스펙 §5.2 + §6.2 + §7 기반. P2 결과물 (#702) 활용 |
