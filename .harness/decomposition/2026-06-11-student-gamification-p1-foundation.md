# 학생 게이미피케이션 P1 Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> 스펙: `.harness/spec/2026-06-11-student-gamification.md` (locked, PR #680 머지 후 commit hash 기록)
> 형식: writing-plans 스킬 표준 + cg-harness Phase 4 decomposition 융합
> 스코프: **P1 Foundation 만** (StudentQuest + GrowthHeatmap + PracticeService + 홈 1화면). P2 Visual Growth / P3 Spotlight / P4 Competition 은 별도 플랜.

**Goal:** 학생이 메트로놈/튜너/YouTube/녹음/수동 4 경로로 연습할 때 자동으로 기록되고, 홈에서 [연습 시작] 1버튼만으로 진입 가능한 자가 연습 게이미피케이션 기반 구축.

**Architecture:** PracticeService 단일 진입점이 모든 evidence 를 받아 GrowthHeatmap 갱신 + StudentQuest 진척 체크 → UI는 1.5초 축하만. 4-Phase 점진 출시 중 첫 단계로 P1 만으로 베타 출시 가능.

**Tech Stack:** Flutter 3.29.0 / Riverpod (codegen) / Hive / json_serializable (프로젝트 컨벤션, freezed 미사용) / youtube_player_iframe / flutter_test

**진입 게이트**: PR #680 (스펙) **머지 완료** 후 본 플랜 시작. Job 0 Step 1 의 commit hash 고정은 머지된 commit 기록.

---

## 사전 결정 (O1~O7 — Job 0 진입 결정사항)

본 PLAN 의 추천안. 사용자 검토 시 변경 가능. Job 0 첫 task 에서 글로서리/스펙에 확정 반영.

| # | 항목 | 추천 결정 | 근거 |
|---|---|---|---|
| O1 | StudentQuest 저장소 | Mock 우선 (Hive 로컬) → P2 시점에 BE | P1 베타 출시 가능 우선, BE 의존 회피 |
| O2 | GrowthHeatmap 1년 캐시 전략 | Hive 30일 chunk × 13 box | 스펙 §17 P95<500ms 만족, 메모리 효율 |
| O3 | PracticeService 위치 | `features/practice/domain/services/practice_recording_service.dart` (신규) | 기존 metronome/tuner provider 와 분리, 단일 책임 |
| O4 | YouTube 트래킹 polling 간격 | 1초 (스펙 §11.1) — 단, P1 에서는 onEnded 만 트리거 | P1 최소 범위, 정밀 트래킹은 P3 와 함께 |
| O5 | "오늘 한 가지" 추천 알고리즘 | P1 = routine 추천 1개 (어제 연습한 곡 또는 디폴트 스케일) | 학생 패턴 분석 알고리즘은 P3 SpotlightPrompt 와 함께 |
| O6 | 학생 홈 진입점 | 기존 `StudentHomeScreen` 의 `StudentDashboardTab` 안 GamificationHeader 자리 활용 | 별도 라우트 신설 X, 기존 UI 위에 incremental |
| O7 | Onboarding 1화면 진입 시점 | 학생 첫 로그인 + StudentQuest 0개 시 | 기존 학생 로그인 후 자동 트리거 |

---

## DAG (Job 의존 관계)

```
Job 0 (사전 결정 + 글로서리 등록 + 스펙 commit hash 고정)
        │
        ▼
Job 1 (신규 엔티티 5종 + freezed/codegen)
        │
        ▼
Job 2 (Repository 인터페이스 + Mock 구현)
        │
        ▼
Job 3 (PracticeService 통합 + 4경로 wiring)
        │
        ├──────────────┬──────────────┐
        ▼              ▼              ▼
Job 4         Job 5          Job 6
(Provider     (홈 UI:        (Onboarding
 codegen)      [연습 시작]     1화면)
              + 1.5초 축하)
        │
        ▼
Job 7 (통합 테스트 + 베타 출시 게이트)
```

---

## 파일 구조 (P1 범위)

### 신규 파일 (`.dart` 11개 + codegen 6개)

**Domain (gamification feature)**:
- `frontend/lib/features/gamification/domain/entities/student_quest.dart`
- `frontend/lib/features/gamification/domain/entities/quest_origin.dart` (enum)
- `frontend/lib/features/gamification/domain/entities/growth_heatmap.dart`
- `frontend/lib/features/gamification/domain/entities/daily_practice.dart` (value object)
- `frontend/lib/features/gamification/domain/repositories/student_quest_repository.dart` (interface)
- `frontend/lib/features/gamification/domain/repositories/growth_heatmap_repository.dart` (interface)

**Data (mock 우선)**:
- `frontend/lib/features/gamification/data/repositories/mock_student_quest_repository.dart`
- `frontend/lib/features/gamification/data/repositories/mock_growth_heatmap_repository.dart`

**Practice service (신규 도메인 서비스)**:
- `frontend/lib/features/practice/domain/services/practice_recording_service.dart`
- `frontend/lib/features/practice/domain/entities/practice_evidence.dart` (value object)

**Presentation providers (Riverpod codegen)**:
- `frontend/lib/features/gamification/presentation/providers/student_quest_provider.dart`
- `frontend/lib/features/gamification/presentation/providers/growth_heatmap_provider.dart`
- `frontend/lib/features/gamification/presentation/providers/practice_recording_provider.dart`

**UI**:
- `frontend/lib/features/gamification/presentation/widgets/practice_start_card.dart` (홈 1버튼 카드)
- `frontend/lib/features/gamification/presentation/widgets/practice_celebration_overlay.dart` (1.5초 축하)
- `frontend/lib/features/gamification/presentation/screens/student_gamification_onboarding_screen.dart` (1화면 onboarding)

### 수정 파일 (4개)

- `frontend/lib/features/students/domain/entities/student.dart` — nickname, parentConsentAt 등 nullable 필드 추가
- `frontend/lib/features/students/domain/entities/student.g.dart` — codegen 갱신
- `frontend/lib/features/student_home/presentation/screens/student_home_screen.dart` — DashboardTab 의 GamificationHeader 위치에 PracticeStartCard 통합
- `frontend/lib/features/practice/presentation/providers/metronome_provider.dart` — PracticeService 호출 wiring
- `.harness/knowledge/glossary.md` — 신규 용어 (StudentQuest, GrowthHeatmap, DailyPractice 등) 등록

### 테스트 파일 (11개)

각 entity / repository / service / provider / widget 마다 단위 + 위젯 smoke test.

---

## Job 0: 사전 결정 + 글로서리 등록

**Files:**
- Modify: `.harness/knowledge/glossary.md`
- Modify: `docs/specs/glossary.md` (동기화)
- Modify: `.harness/spec/2026-06-11-student-gamification.md` (PR #680 commit hash 추가)

- [ ] **Step 1: PR #680 머지 후 commit hash 기록**

스펙 헤더에 머지된 commit hash 추가:
```
> 스펙: locked at commit {HASH}
```

- [ ] **Step 2: glossary 신규 용어 등록**

`.harness/knowledge/glossary.md` 에 추가:
```markdown
### 학생 게이미피케이션 (2026-06-11)
| 용어 (한글) | 영문 | 정의 |
|---|---|---|
| 학생 자가 quest | StudentQuest | 학생이 작성/채택한 연습 목표. origin: ambient/selfCreated/systemRoutine/lessonDerived/teacherRec/seasonEvent |
| Quest 출처 | QuestOrigin | StudentQuest 의 출처 enum (6종) |
| 성장 히트맵 | GrowthHeatmap | 1년 캘린더, 일별 연습 evidence 통합 |
| 일일 연습 evidence | DailyPractice | 메트로놈/튜너/YouTube/녹음/수동 분 단위 통합 value object |
| 연습 기록 서비스 | PracticeRecordingService | 모든 연습 evidence 단일 진입점 |
```

`docs/specs/glossary.md` 도 동기화.

- [ ] **Step 3: 사전 결정 O1~O7 확정**

본 플랜 표를 사용자 검토 후 확정. 변경 사항 있으면 본문 갱신.

- [ ] **Step 4: 브랜치 생성**

```bash
git checkout -b feat/student-gamification-p1-foundation main
```

- [ ] **Step 5: 글로서리 동기화 커밋**

```bash
git add .harness/knowledge/glossary.md docs/specs/glossary.md
git commit -m "docs(glossary): 학생 게이미피케이션 P1 용어 등록"
```

---

## Job 1: 신규 엔티티 5종 (TDD)

### Task 1.1: QuestOrigin enum

**Files:**
- Create: `frontend/lib/features/gamification/domain/entities/quest_origin.dart`
- Test: `frontend/test/features/gamification/domain/entities/quest_origin_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/quest_origin.dart';

void main() {
  test('QuestOrigin has 6 values', () {
    expect(QuestOrigin.values.length, 6);
  });

  test('QuestOrigin has all spec-defined origins', () {
    expect(QuestOrigin.values, containsAll([
      QuestOrigin.ambient,
      QuestOrigin.selfCreated,
      QuestOrigin.systemRoutine,
      QuestOrigin.lessonDerived,
      QuestOrigin.teacherRec,
      QuestOrigin.seasonEvent,
    ]));
  });
}
```

- [ ] **Step 2: Verify failure**

```bash
flutter test test/features/gamification/domain/entities/quest_origin_test.dart
```
Expected: FAIL — file/class not defined.

- [ ] **Step 3: Implement enum**

```dart
enum QuestOrigin {
  ambient,
  selfCreated,
  systemRoutine,
  lessonDerived,
  teacherRec,
  seasonEvent,
}
```

- [ ] **Step 4: Verify pass**

```bash
flutter test test/features/gamification/domain/entities/quest_origin_test.dart
```
Expected: 2/2 PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/gamification/domain/entities/quest_origin.dart \
        test/features/gamification/domain/entities/quest_origin_test.dart
git commit -m "feat(gamification): QuestOrigin enum (6종)"
```

### Task 1.2: StudentQuest entity (json_serializable, 프로젝트 컨벤션)

**Files:**
- Create: `frontend/lib/features/gamification/domain/entities/student_quest.dart`
- Test: `frontend/test/features/gamification/domain/entities/student_quest_test.dart`
- 코드 생성: `student_quest.g.dart`
- **외부 의존**: 기존 `frontend/lib/features/gamification/domain/entities/challenge.dart` 의 `ChallengeType` enum 재사용 (스펙 §5.1.b). 신규 파일 X.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/student_quest.dart';
import 'package:lessonaza/features/gamification/domain/entities/quest_origin.dart';
import 'package:lessonaza/features/gamification/domain/entities/challenge.dart';

void main() {
  group('StudentQuest', () {
    final base = StudentQuest(
      id: 'q1',
      studentId: 's1',
      origin: QuestOrigin.selfCreated,
      title: '스케일 5분',
      type: ChallengeType.practiceMinutes,
      targetValue: 5,
      currentValue: 0,
      startDate: DateTime(2026, 6, 11),
      endDate: DateTime(2026, 6, 18),
    );

    test('progress = currentValue / targetValue', () {
      expect(base.progress, 0.0);
      expect(base.copyWith(currentValue: 3).progress, 0.6);
      expect(base.copyWith(currentValue: 5).progress, 1.0);
      expect(base.copyWith(currentValue: 10).progress, 1.0); // clamp
    });

    test('isCompleted false by default, true when manually set', () {
      expect(base.isCompleted, false);
      expect(base.copyWith(isCompleted: true).isCompleted, true);
    });

    test('json round-trip preserves all fields', () {
      final json = base.toJson();
      final restored = StudentQuest.fromJson(json);
      expect(restored.id, base.id);
      expect(restored.origin, base.origin);
    });
  });
}
```

- [ ] **Step 2: Verify failure**

```bash
flutter test test/features/gamification/domain/entities/student_quest_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Implement entity**

```dart
import 'package:json_annotation/json_annotation.dart';
import 'quest_origin.dart';
import 'challenge.dart';

part 'student_quest.g.dart';

@JsonSerializable()
class StudentQuest {
  final String id;
  final String studentId;
  final QuestOrigin origin;
  final String title;
  final ChallengeType? type;
  final int targetValue;
  final int currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final DateTime? completedAt;

  const StudentQuest({
    required this.id,
    required this.studentId,
    required this.origin,
    required this.title,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    this.completedAt,
  });

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  StudentQuest copyWith({
    int? currentValue,
    bool? isCompleted,
    DateTime? completedAt,
  }) => StudentQuest(
    id: id, studentId: studentId, origin: origin, title: title,
    type: type, targetValue: targetValue,
    currentValue: currentValue ?? this.currentValue,
    startDate: startDate, endDate: endDate,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt ?? this.completedAt,
  );

  factory StudentQuest.fromJson(Map<String, dynamic> json) =>
      _$StudentQuestFromJson(json);
  Map<String, dynamic> toJson() => _$StudentQuestToJson(this);
}
```

- [ ] **Step 4: Run codegen + tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/gamification/domain/entities/student_quest_test.dart
```
Expected: 3/3 PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/gamification/domain/entities/student_quest.dart \
        lib/features/gamification/domain/entities/student_quest.g.dart \
        test/features/gamification/domain/entities/student_quest_test.dart
git commit -m "feat(gamification): StudentQuest entity (TDD)"
```

### Task 1.3: DailyPractice value object

**Files:**
- Create: `frontend/lib/features/gamification/domain/entities/daily_practice.dart`
- Test: `frontend/test/features/gamification/domain/entities/daily_practice_test.dart`

같은 TDD 5단계 패턴. 5필드: metronomeMinutes, tunerMinutes, youtubeMinutes, recordingCount, manualMinutes. totalMinutes 계산 prop.

- [ ] **Step 1: 테스트 작성** (totalMinutes 계산 검증)
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: 구현 (immutable + copyWith)**
- [ ] **Step 4: Verify pass**
- [ ] **Step 5: Commit `feat(gamification): DailyPractice value object`**

### Task 1.4: GrowthHeatmap entity

같은 패턴. `Map<DateTime, DailyPractice>` 보유 + `weekTotal(weekStart)`, `streakDays(asOf)` 헬퍼.

- [ ] **Step 1-5**: TDD 5단계. 핵심 테스트:
  - "weekTotal sums 7 days"
  - "streakDays counts consecutive days backward from asOf"
  - "empty heatmap returns 0 for both"

### Task 1.5: Student 엔티티 확장 (nickname + parentConsent fields)

**Files:**
- Modify: `frontend/lib/features/students/domain/entities/student.dart`
- Modify: `frontend/test/features/students/domain/entities/student_test.dart` (기존 테스트 확장)

- [ ] **Step 1: 테스트 추가** — nickname, parentConsentAt, parentConsentRevokedAt, parentConsentToken, comparisonViewEnabled 5 필드의 nullable + copyWith 검증
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: 필드 5개 추가 + copyWith 갱신 (모두 nullable, default null/false)**
- [ ] **Step 4: build_runner + Verify pass + 기존 student 사용처 컴파일 확인** (`flutter analyze`)
- [ ] **Step 5: Commit `feat(students): nickname + parentConsent fields (P1 prep)`**

---

## Job 2: Repository 인터페이스 + Mock 구현 (TDD)

### Task 2.1: StudentQuestRepository 인터페이스

**Files:**
- Create: `frontend/lib/features/gamification/domain/repositories/student_quest_repository.dart`

abstract class 정의:

```dart
abstract class StudentQuestRepository {
  Future<List<StudentQuest>> getActiveQuests(String studentId);
  Future<StudentQuest> createQuest(StudentQuest quest);
  Future<StudentQuest> updateProgress(String questId, int currentValue);
  Future<void> markCompleted(String questId);
  Future<List<StudentQuest>> getQuestsByOrigin(String studentId, QuestOrigin origin);
}
```

- [ ] **Step 1-2: 인터페이스 작성** (테스트 없음 — abstract)
- [ ] **Step 3: `flutter analyze` 통과 확인**
- [ ] **Step 4: Commit `feat(gamification): StudentQuestRepository interface`**

### Task 2.2: MockStudentQuestRepository

**Files:**
- Create: `frontend/lib/features/gamification/data/repositories/mock_student_quest_repository.dart`
- Test: `frontend/test/features/gamification/data/repositories/mock_student_quest_repository_test.dart`

- [ ] **Step 1: 테스트 작성** — CRUD 5 메서드, 메모리 저장소 검증
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: `Map<String, StudentQuest>` 내부 저장소로 구현. await Future.delayed(milliseconds: 100) 으로 비동기 시뮬레이션**
- [ ] **Step 4: Verify pass (5/5)**
- [ ] **Step 5: Commit `feat(gamification): MockStudentQuestRepository (TDD)`**

### Task 2.3: GrowthHeatmapRepository 인터페이스 + Mock

같은 패턴. 인터페이스:

```dart
abstract class GrowthHeatmapRepository {
  Future<GrowthHeatmap> getHeatmap(String studentId, {int yearsBack = 1});
  Future<void> recordPractice(String studentId, DateTime date, DailyPractice evidence);
}
```

- [ ] **Step 1-5: 인터페이스 + Mock 구현 TDD**

---

## Job 3: PracticeRecordingService 통합

### Task 3.1: PracticeEvidence value object

**Files:**
- Create: `frontend/lib/features/practice/domain/entities/practice_evidence.dart`
- Test: `frontend/test/features/practice/domain/entities/practice_evidence_test.dart`

```dart
enum PracticeSource { metronome, tuner, youtube, recording, manual }

class PracticeEvidence {
  final PracticeSource source;
  final int durationMinutes;
  final String? videoId; // youtube 일 때만
  final Map<String, dynamic> metadata;
  final DateTime occurredAt;
  
  // ... fromJson, toJson, copyWith
}
```

- [ ] **Step 1-5: TDD 5단계**

### Task 3.2: PracticeRecordingService

**Files:**
- Create: `frontend/lib/features/practice/domain/services/practice_recording_service.dart`
- Test: `frontend/test/features/practice/domain/services/practice_recording_service_test.dart`

핵심 메서드: `recordPractice(String studentId, PracticeEvidence evidence)` 가 GrowthHeatmapRepository 갱신 + StudentQuestRepository 진척 체크 두 곳 호출.

- [ ] **Step 1: 테스트 작성** — `recordPractice` 호출 시 의존성 둘 다 호출되는지 mock 검증

```dart
test('recordPractice updates heatmap and checks quest progress', () async {
  final mockHeatmap = MockGrowthHeatmapRepository();
  final mockQuest = MockStudentQuestRepository();
  final service = PracticeRecordingService(
    heatmapRepository: mockHeatmap,
    questRepository: mockQuest,
  );
  
  final evidence = PracticeEvidence(
    source: PracticeSource.metronome,
    durationMinutes: 5,
    occurredAt: DateTime(2026, 6, 11),
    metadata: {},
  );
  
  await service.recordPractice('s1', evidence);
  
  expect(mockHeatmap.lastRecordedDate, DateTime(2026, 6, 11));
  expect(mockHeatmap.lastRecordedMinutes, 5);
  expect(mockQuest.progressUpdatedCount, greaterThan(0));
});
```

- [ ] **Step 2: Verify fail**
- [ ] **Step 3: 구현 (의존성 주입 + 단방향 호출 — 스펙 §6.0 의존성 그래프 준수)**
- [ ] **Step 4: Verify pass**
- [ ] **Step 5: Commit `feat(practice): PracticeRecordingService 단일 진입점 (TDD)`**

### Task 3.3: 기존 metronome_provider 와 wiring

**Files:**
- Modify: `frontend/lib/features/practice/presentation/providers/metronome_provider.dart`
- Test: `frontend/test/features/practice/presentation/providers/metronome_provider_test.dart`

메트로놈 stop 시 누적 시간을 PracticeService 에 전달.

- [ ] **Step 1: 테스트 작성** — 메트로놈 5분 사용 후 stop 시 PracticeService.recordPractice 가 호출되는지 검증
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: provider 에 PracticeService 의존 추가 + onStop hook**
- [ ] **Step 4: Verify pass + 기존 메트로놈 테스트 모두 통과**
- [ ] **Step 5: Commit `feat(practice): metronome_provider PracticeService wiring`**

### Task 3.4: 튜너 wiring

**Files:**
- Modify: `frontend/lib/features/practice/presentation/providers/tuner_provider.dart`
- Test: `frontend/test/features/practice/presentation/providers/tuner_provider_test.dart`

튜너 stop 시 누적 시간을 PracticeService 에 전달.

- [ ] **Step 1-5: TDD 5단계** (메트로놈 패턴과 동일)

### Task 3.5: YouTube wiring (P1 = onEnded 만)

**Files:**
- Modify: `frontend/lib/features/lessons/presentation/widgets/youtube_player_widget.dart` (또는 사용처)
- Test: 위젯/통합 테스트

P1 범위: `onEnded` 콜백 1회 → PracticeService.recordPractice (영상 길이 분 단위). 정밀 polling 은 P3.

- [ ] **Step 1-5: TDD 5단계**

### Task 3.6: 수동 입력 폼 + wiring

**Files:**
- Create: `frontend/lib/features/practice/presentation/widgets/manual_practice_entry_dialog.dart`
- Test: 위젯 smoke test

"오늘 N분 연습했어요" 수동 입력 폼 (시간 선택 picker + 메모 옵션).

- [ ] **Step 1-5: TDD 5단계** + Hick's Law (선택지 5분/15분/30분/직접입력 4개)

---

## Job 4: Provider codegen (Riverpod)

### Task 4.1: studentQuestProvider

**Files:**
- Create: `frontend/lib/features/gamification/presentation/providers/student_quest_provider.dart`
- 코드 생성: `student_quest_provider.g.dart`
- Test: `frontend/test/features/gamification/presentation/providers/student_quest_provider_test.dart`

```dart
@Riverpod(keepAlive: true)
StudentQuestRepository studentQuestRepository(StudentQuestRepositoryRef ref) {
  return MockStudentQuestRepository(); // P1: mock, P2+: 환경 분기
}

@riverpod
Future<List<StudentQuest>> activeQuests(ActiveQuestsRef ref, String studentId) {
  return ref.watch(studentQuestRepositoryProvider).getActiveQuests(studentId);
}
```

- [ ] **Step 1-5: TDD + build_runner**

### Task 4.2: growthHeatmapProvider, practiceRecordingProvider

같은 패턴.

- [ ] 각 Task 5 step TDD.

---

## Job 5: 학생 홈 UI ([연습 시작] + 1.5초 축하)

### Task 5.1: PracticeStartCard 위젯

**Files:**
- Create: `frontend/lib/features/gamification/presentation/widgets/practice_start_card.dart`
- Test: `frontend/test/features/gamification/presentation/widgets/practice_start_card_test.dart`

스펙 §4.1 와이어프레임 구현:

```
┌─────────────────────────────────────┐
│       🎵 {이름}의 연습                │
│        🔥 {N}일 (작은 텍스트)          │
│      ┌───────────────────┐           │
│      │   ▶ 연습 시작        │           │
│      └───────────────────┘           │
│      어제 {N}분 했어요                 │
│      · · ·  (더 보기, 작게)            │
└─────────────────────────────────────┘
```

- [ ] **Step 1: 위젯 smoke test** (스펙 design-principles 룰)
  - 큰 [연습 시작] 버튼 단 1개 존재 확인
  - 스트릭 표시 (`Text` 위젯 안에 일수 + 🔥)
  - "어제 N분 했어요" 표시
  - 큰 버튼 thumb-zone (하단) 위치 (Fitts' Law)
- [ ] **Step 2: Verify fail**
- [ ] **Step 3: 위젯 구현** (AppColors / AppTypography / AppSpacing 만 사용, 하드코딩 금지 — `ux-rules.md` 준수)
- [ ] **Step 4: Verify pass + flutter analyze 0 issue**
- [ ] **Step 5: Commit `feat(gamification): PracticeStartCard 홈 1버튼 위젯`**

### Task 5.2: PracticeCelebrationOverlay (1.5초 fade)

**Files:**
- Create: `frontend/lib/features/gamification/presentation/widgets/practice_celebration_overlay.dart`
- Test: `frontend/test/features/gamification/presentation/widgets/practice_celebration_overlay_test.dart`

스펙 §4.3:

```
┌─────────────────────────────────────┐
│              ✨                       │
│         12분 했어요!                   │
│         🔥 3일 연속                    │
│   (1.5초 후 자동 fade → 홈)            │
└─────────────────────────────────────┘
```

- [ ] **Step 1: 위젯 smoke test** + Timer 검증 (`pumpAndSettle` + 1.5초 후 dismiss)
- [ ] **Step 2-5: TDD**
- [ ] Note: feedback_spy_mock_for_router_tests.md 패턴 적용 — `Future.delayed` 위험 회피, AnimationController 사용

### Task 5.3: StudentDashboardTab 에 PracticeStartCard 통합

**Files:**
- Modify: `frontend/lib/features/student_home/presentation/screens/student_home_screen.dart` (또는 dashboard_tab.dart)
- Test: 통합 위젯 테스트

기존 `GamificationHeader` 위치에 `PracticeStartCard` 추가 또는 교체.

- [ ] **Step 1-5: TDD + 기존 통합 위젯 회귀 테스트 통과 확인**

---

## Job 6: Onboarding 1화면

### Task 6.1: StudentGamificationOnboardingScreen

**Files:**
- Create: `frontend/lib/features/gamification/presentation/screens/student_gamification_onboarding_screen.dart`
- Test: 위젯 smoke test

스펙 §4.6:

```
┌─────────────────────────────────────┐
│   안녕! 무슨 악기 해?                  │
│                                       │
│   [🎻]  [🎹]  [🎸]  [기타...]         │
│                                       │
│   오늘 한 가지 추천해줄게:              │
│   "스케일 5분"                         │
│                                       │
│      [좋아! 시작하기]                  │
│      [내가 정할래]                     │
└─────────────────────────────────────┘
```

- [ ] **Step 1: 위젯 smoke test** + 두 CTA 버튼 검증
- [ ] **Step 2-5: TDD + AppColors/AppTypography/AppSpacing 만 사용 + Hick's Law (선택지 4 악기 + 기타 = 5개 max)**

### Task 6.2: 학생 첫 로그인 시 onboarding 자동 트리거

**Files:**
- Modify: `frontend/lib/features/student_home/presentation/screens/student_home_screen.dart`

학생의 StudentQuest 가 0개일 때 자동으로 Onboarding 화면 첫 진입.

- [ ] **Step 1: 통합 테스트** — 신규 학생 가입 → 홈 진입 → onboarding 자동 노출
- [ ] **Step 2-5: TDD**

---

## Job 7: 통합 테스트 + 베타 출시 게이트

### Task 7.1: End-to-end 통합 시나리오 테스트

**Files:**
- Create: `frontend/integration_test/student_gamification_p1_e2e_test.dart`

시나리오:
1. 신규 학생 로그인
2. Onboarding 1화면 진입 → 악기 선택 → "좋아! 시작하기"
3. 홈 진입 → PracticeStartCard 보임
4. [연습 시작] 탭 → 메트로놈 자동 시작
5. 5분 사용 후 stop
6. 1.5초 축하 화면
7. 홈 복귀 → 스트릭 "🔥 1일" 표시
8. 히트맵 (더 보기 안) 에 오늘 칸 갱신

- [ ] **Step 1-3: 시나리오 작성 + e2e 실행 + 모든 step 통과**
- [ ] **Step 4: Performance 검증** — 메트로놈 시작 < 200ms, 축하 fade-in < 100ms
- [ ] **Step 5: Commit `test(gamification): P1 e2e 시나리오`**

### Task 7.2: 베타 출시 게이트 (SC-1, SC-3, SC-4 검증)

- [ ] **Step 1: SC-1 검증** — 홈 첫 탭 후 5초 안에 연습 시작 가능 (e2e 측정)
- [ ] **Step 2: SC-3 검증** — PracticeService 단일 진입점, 4 경로 모두 통합 (코드 review + grep "PracticeRecordingService" 사용처 검증)
- [ ] **Step 3: SC-4 검증** — 학생 UI 에 origin 라벨 0개. 정밀 grep:
  ```bash
  # widget 안에서 origin 값을 텍스트로 노출하는 패턴 검색 (단순 enum 사용은 제외)
  grep -rn -E "Text\(.*origin\.|Text\(.*Origin\.|Text\(.*selfCreated|Text\(.*teacherRec|Text\(.*ambient" \
    frontend/lib/features/gamification/presentation/widgets/ \
    frontend/lib/features/gamification/presentation/screens/
  # 결과 0건이어야 함 (detail view 제외 — 디버그·테스트 화면은 허용)
  ```
- [ ] **Step 4: 회귀 테스트 전체 통과** (`flutter test`)
- [ ] **Step 5: PR 생성 + 사용자 검토 요청**

```bash
gh pr create \
  --title "feat(gamification): 학생 P1 Foundation — Strava 모델 + 자가 quest" \
  --body "..." 
```

---

## Job 의존 검증

| Job | 차단 조건 |
|---|---|
| Job 0 | PR #680 (스펙) 머지 완료 |
| Job 1 | Job 0 글로서리 등록 + 스펙 commit hash 고정 완료 |
| Job 2 | Job 1 entities 완료 (typed interface) |
| Job 3 | Job 2 Mock repositories 완료 (의존성 주입) + Job 1 PracticeEvidence value object |
| Job 4 | Job 2~3 도메인 완료 |
| Job 5 | Job 3 (모든 Task 3.x 완료) + Job 4 providers (회귀 위험 회피) |
| Job 6 | Job 4 + Job 5 완료 (기존 학생 home 통합 충돌 방지) |
| Job 7 | Job 1~6 모두 완료 + **법무 review 게이트** (14세 미만 P1 자동 처리 합법성 확인) |

---

## 위험 + 완화

| 위험 | 완화 |
|---|---|
| 기존 `metronome_provider` 변경 시 회귀 | 메트로놈 회귀 테스트 전체 (35건+) 사전 실행 + Step 4 마다 회귀 검증 |
| Hive box 신규 추가 시 첫 진입 크래시 | Hive 초기화 wrapper 에 newBox try/catch + 마이그레이션 안내 메모리 |
| `youtube_player_iframe` polling 미구현 (P1) → 시청 시간 정확도 ↓ | onEnded 만 카운트 → P3 SpotlightPrompt 와 함께 정밀 polling 도입 |
| StudentQuest 0개 신규 학생 빈 상태 처리 | Onboarding 자동 트리거 (Job 6) — Job 6 미완료 시 P1 출시 불가 |
| 14세 미만 학생 — P1 에서 부모 동의 분기 없음 | P1 = 자가 연습만 (외부 데이터 수집·공유 0) — 비교 보기·글로벌 익명·디바이스 식별자 trakcing 모두 P4 와 함께. **법무 review 게이트** (Job 7 진입 전) 필수: 자가 연습 + 시각 진척만 표시하는 P1 범위가 KISA + 정보통신망법 §50의5 + COPPA-K 의 "개인정보 수집·처리" 정의에 해당하는지 1회 검토. 결과 따라 P4 까지 부모 동의 차단 OR P1 도 부모 동의 흐름 fast-track 결정. |
| `Student.nickname` 추가 후 기존 student 직렬화 깨짐 | nullable + json_serializable default 활용 + 마이그레이션 테스트 (Task 1.5 Step 4) |

---

## 후속 (P2~P4) 차단점

| 차단점 | 풀리는 시점 |
|---|---|
| Streak freeze 시스템 | P2 |
| Trophy 모음 UI | P2 |
| SpotlightPrompt 큐 | P3 |
| 거절 학습 알고리즘 | P3 |
| YouTube 정밀 polling | P3 |
| LeaderboardPreferences + 4 레이어 UI | P4 |
| 부모 동의 흐름 | P4 |
| 글로벌 익명 어뷰징 방지 | P4 |

P1 만으로 베타 출시 가능 (스펙 §18.2).

---

## 성공 기준 (P1 한정)

| # | 스펙 SC | P1 검증 |
|---|---|---|
| SC-1 | 5초 안에 연습 시작 가능 | Task 7.2 Step 1 e2e |
| SC-3 | PracticeService 4 경로 통합 | Task 7.2 Step 2 grep |
| SC-4 | 학생 UI origin 라벨 0 | Task 7.2 Step 3 grep |
| SC-12 | 신규 엔티티 5개 (스펙 §6 정의) | Job 1 entities — P1=3 (StudentQuest, GrowthHeatmap, Student 확장). PracticeEvidence 와 QuestOrigin enum 은 보조 value object/enum, SC-12 의 "5 엔티티" 카운트 외. SpotlightPrompt, StreakFreeze, LeaderboardPreferences 는 P2~P4. |

P1 SC 비율: 12/12 중 **3 완전 충족 (SC-1, SC-3, SC-4) + SC-12 부분 (5 도메인 엔티티 중 3 신규 = 60%)**. SC-2 / SC-5~SC-11 은 P2~P4.

---

## 변경 이력

| 날짜 | 변경 | 비고 |
|---|---|---|
| 2026-06-11 | 초안 작성 | 스펙 §18.1 P1 Foundation 기반 |
