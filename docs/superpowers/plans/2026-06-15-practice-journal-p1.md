# 연습장(Practice Journal) P1 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **실행 위치:** worktree 에서 진행 (`worktree-parallel-workflow.md`). main 직접 작업 금지.

**Goal:** 학생·부모·선생님 삼자 인장 의식의 일일 코어(연습장 A 레이어)를 구현한다 — 연습 활동에서 자동 파생되는 연습 도장, 부모 응원·확인 도장, 선생님 검인(과제 한정)/자가 검인, 월 그리드 화면, 3역할 진입점.

**Architecture:** 신규 독립 feature `features/practice_journal/` (domain/data/presentation). 엔티티는 `@JsonSerializable` + `copyWith`(코드베이스 표준, Hive 아님). 연습 도장은 `PracticeRecordingService.recordPractice()` 훅에서 파생(이중 기록 0). 평가는 연결 상태 적응 — `Student.parentConsentAt`(null=자가연습)로 부모 노드 유무 판정. 모든 표면은 `NotebookScreenScaffold`, 색은 `AppColors`(ink/paperOk/paperAccent 재사용), 표시 문자열은 `AppStrings` + 연령 톤 resolver.

**Tech Stack:** Flutter 3.29, Riverpod(`@riverpod` codegen + `createRepository` 헬퍼), json_annotation/build_runner, flutter_test(widget smoke).

**Spec(SSOT):** `docs/specs/practice_journal/practice_journal_master.md`

---

## 범위 메모 (P1 only)

P1 = **연습장(A) 코어**. 제외(P2 이후): 제본/완성본/책장(`BoundVolume`), 알림 연계, 발표회. 본 계획은 P1 의 데이터·로직·화면·진입점만 다룬다. 각 Task 는 독립 커밋.

## File Structure

| 파일 | 책임 |
|---|---|
| `features/practice_journal/domain/entities/practice_mark.dart` | `PracticeMark` + `MarkIntensity` enum |
| `features/practice_journal/domain/entities/guardian_seal.dart` | `GuardianSeal` |
| `features/practice_journal/domain/entities/endorsement.dart` | `Endorsement` + `EndorsedBy` enum |
| `features/practice_journal/domain/entities/practice_ledger.dart` | `PracticeLedger`(월 집계) |
| `features/practice_journal/domain/repositories/practice_journal_repository.dart` | abstract 인터페이스 |
| `features/practice_journal/data/repositories/mock_practice_journal_repository.dart` | 메모리 mock |
| `features/practice_journal/domain/journal_thresholds.dart` | 도장 강도 임계값 상수 |
| `features/practice_journal/presentation/providers/practice_journal_provider.dart` | repository + ledger provider |
| `features/practice_journal/presentation/journal_mark_deriver.dart` | 연습→도장 파생(서비스) |
| `features/practice_journal/presentation/extensions/journal_tone.dart` | 연령 톤 라벨 resolver |
| `features/practice_journal/presentation/widgets/journal_month_grid.dart` | 월 도장 그리드 |
| `features/practice_journal/presentation/widgets/stamp_press_sheet.dart` | "도장 꾹!" 축하 시트 |
| `features/practice_journal/presentation/widgets/practice_journal_card.dart` | 홈 진입 카드 |
| `features/practice_journal/presentation/screens/practice_journal_screen.dart` | 월 그리드 화면(3역할) |
| `features/practice_journal/practice_journal.dart` | 배럴(공개 API) |

수정:
- `features/practice/domain/services/practice_recording_service.dart` — recordPractice 훅에 도장 파생 1줄 추가
- `core/constants/app_strings.dart` — 연습장 문자열 2종(표준/어린이) 추가
- 진입점 3곳(학생 홈 / 부모 홈 / 선생님 학생상세) — 카드·섹션 wiring

---

### Task 1: 엔티티 — enum + PracticeMark

**Files:**
- Create: `frontend/lib/features/practice_journal/domain/entities/practice_mark.dart`
- Test: `frontend/test/features/practice_journal/domain/practice_mark_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/practice_journal/domain/entities/practice_mark.dart';

void main() {
  test('PracticeMark full > short 갱신, copyWith/json 왕복', () {
    final m = PracticeMark(date: DateTime.utc(2026, 6, 15), intensity: MarkIntensity.short);
    final up = m.copyWith(intensity: MarkIntensity.full);
    expect(up.intensity, MarkIntensity.full);
    expect(PracticeMark.fromJson(up.toJson()).intensity, MarkIntensity.full);
    // full 은 short 보다 강함
    expect(MarkIntensity.full.isStrongerThan(MarkIntensity.short), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/practice_journal/domain/practice_mark_test.dart`
Expected: FAIL (파일/심볼 없음)

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'practice_mark.g.dart';

enum MarkIntensity {
  short,
  full;

  /// full > short. 같은 날 재연습 시 더 강한 강도가 우선.
  bool isStrongerThan(MarkIntensity other) => index > other.index;
}

@JsonSerializable()
class PracticeMark {
  final DateTime date;
  final MarkIntensity intensity;

  const PracticeMark({required this.date, required this.intensity});

  PracticeMark copyWith({DateTime? date, MarkIntensity? intensity}) =>
      PracticeMark(date: date ?? this.date, intensity: intensity ?? this.intensity);

  factory PracticeMark.fromJson(Map<String, dynamic> json) => _$PracticeMarkFromJson(json);
  Map<String, dynamic> toJson() => _$PracticeMarkToJson(this);
}
```

- [ ] **Step 4: Generate code + run test**

Run: `cd frontend && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/practice_journal/domain/practice_mark_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/practice_journal/domain/entities/practice_mark.dart frontend/lib/features/practice_journal/domain/entities/practice_mark.g.dart frontend/test/features/practice_journal/domain/practice_mark_test.dart
git commit -m "feat(practice_journal): PracticeMark 엔티티 + MarkIntensity"
```

---

### Task 2: 엔티티 — GuardianSeal + Endorsement

**Files:**
- Create: `frontend/lib/features/practice_journal/domain/entities/guardian_seal.dart`
- Create: `frontend/lib/features/practice_journal/domain/entities/endorsement.dart`
- Test: `frontend/test/features/practice_journal/domain/endorsement_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/practice_journal/domain/entities/guardian_seal.dart';
import 'package:app/features/practice_journal/domain/entities/endorsement.dart';

void main() {
  test('Endorsement 규칙: teacher=과제참조 필수, self=참조 없음', () {
    final t = Endorsement(by: EndorsedBy.teacher, date: DateTime.utc(2026,6,15),
        authorUserId: 't1', assignmentRef: 'a1', note: '왼손 천천히');
    final s = Endorsement(by: EndorsedBy.self, date: DateTime.utc(2026,6,15),
        authorUserId: 's1', assignmentRef: null, note: '오늘 잘됨');
    expect(t.isValid, isTrue);
    expect(s.isValid, isTrue);
    // teacher 인데 과제 참조 없음 → 무효
    expect(t.copyWith(assignmentRef: null).isValid, isFalse);
    // json 왕복
    expect(Endorsement.fromJson(t.toJson()).by, EndorsedBy.teacher);
    final seal = GuardianSeal(weekStart: DateTime.utc(2026,6,15), guardianUserId: 'p1', cheerNote: '잘했어');
    expect(GuardianSeal.fromJson(seal.toJson()).guardianUserId, 'p1');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/practice_journal/domain/endorsement_test.dart`
Expected: FAIL (심볼 없음)

- [ ] **Step 3: Write minimal implementation**

`guardian_seal.dart`:
```dart
import 'package:json_annotation/json_annotation.dart';

part 'guardian_seal.g.dart';

@JsonSerializable()
class GuardianSeal {
  final DateTime weekStart;
  final String guardianUserId;
  final String? cheerNote;

  const GuardianSeal({required this.weekStart, required this.guardianUserId, this.cheerNote});

  GuardianSeal copyWith({DateTime? weekStart, String? guardianUserId, String? cheerNote}) =>
      GuardianSeal(weekStart: weekStart ?? this.weekStart,
          guardianUserId: guardianUserId ?? this.guardianUserId, cheerNote: cheerNote ?? this.cheerNote);

  factory GuardianSeal.fromJson(Map<String, dynamic> json) => _$GuardianSealFromJson(json);
  Map<String, dynamic> toJson() => _$GuardianSealToJson(this);
}
```

`endorsement.dart`:
```dart
import 'package:json_annotation/json_annotation.dart';

part 'endorsement.g.dart';

enum EndorsedBy { self, teacher }

@JsonSerializable()
class Endorsement {
  final EndorsedBy by;
  final DateTime date;
  final String authorUserId;
  /// teacher 검인은 반드시 과제 참조를 가진다(과제 한정). self 회고는 null.
  final String? assignmentRef;
  final String note;

  const Endorsement({required this.by, required this.date, required this.authorUserId,
      this.assignmentRef, required this.note});

  /// teacher ⇒ assignmentRef 필수, self ⇒ assignmentRef 없음.
  bool get isValid => by == EndorsedBy.teacher ? assignmentRef != null : assignmentRef == null;

  Endorsement copyWith({EndorsedBy? by, DateTime? date, String? authorUserId,
          String? assignmentRef, String? note, bool clearAssignment = false}) =>
      Endorsement(by: by ?? this.by, date: date ?? this.date,
          authorUserId: authorUserId ?? this.authorUserId,
          assignmentRef: clearAssignment ? null : (assignmentRef ?? this.assignmentRef),
          note: note ?? this.note);

  factory Endorsement.fromJson(Map<String, dynamic> json) => _$EndorsementFromJson(json);
  Map<String, dynamic> toJson() => _$EndorsementToJson(this);
}
```

> 참고: 위 테스트의 `copyWith(assignmentRef: null)` 은 `clearAssignment: true` 로 작성해야 null 이 적용된다. 테스트를 `t.copyWith(clearAssignment: true).isValid` 로 수정한다.

- [ ] **Step 4: Generate + test**

Run: `cd frontend && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/practice_journal/domain/endorsement_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/practice_journal/domain/entities/guardian_seal.* frontend/lib/features/practice_journal/domain/entities/endorsement.* frontend/test/features/practice_journal/domain/endorsement_test.dart
git commit -m "feat(practice_journal): GuardianSeal + Endorsement(과제 한정/자가 검인)"
```

---

### Task 3: 엔티티 — PracticeLedger (월 집계 + 업서트 규칙)

**Files:**
- Create: `frontend/lib/features/practice_journal/domain/entities/practice_ledger.dart`
- Test: `frontend/test/features/practice_journal/domain/practice_ledger_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/practice_journal/domain/entities/practice_ledger.dart';
import 'package:app/features/practice_journal/domain/entities/practice_mark.dart';

void main() {
  test('도장은 (날짜)당 1개, full 이 short 갱신, 주간 카운트', () {
    var l = PracticeLedger.empty(childProfileId: 'c1', year: 2026, month: 6);
    l = l.upsertMark(DateTime.utc(2026,6,15), MarkIntensity.short);
    l = l.upsertMark(DateTime.utc(2026,6,15), MarkIntensity.full); // 같은 날 → 갱신
    expect(l.marks.length, 1);
    expect(l.marks.single.intensity, MarkIntensity.full);
    l = l.upsertMark(DateTime.utc(2026,6,16), MarkIntensity.short);
    expect(l.markCount, 2); // 누적(연속 아님)
  });
}
```

- [ ] **Step 2: Run → FAIL**

Run: `cd frontend && flutter test test/features/practice_journal/domain/practice_ledger_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement**

```dart
import 'package:json_annotation/json_annotation.dart';
import 'practice_mark.dart';
import 'guardian_seal.dart';
import 'endorsement.dart';

part 'practice_ledger.g.dart';

@JsonSerializable(explicitToJson: true)
class PracticeLedger {
  final String childProfileId;
  final int year;
  final int month;
  final List<PracticeMark> marks;
  final List<GuardianSeal> seals;
  final List<Endorsement> endorsements;

  const PracticeLedger({
    required this.childProfileId, required this.year, required this.month,
    this.marks = const [], this.seals = const [], this.endorsements = const [],
  });

  factory PracticeLedger.empty({required String childProfileId, required int year, required int month}) =>
      PracticeLedger(childProfileId: childProfileId, year: year, month: month);

  int get markCount => marks.length;

  static DateTime _dayUtc(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// (날짜)당 1개. 같은 날이면 더 강한 강도로 갱신(immutable — 새 리스트 반환).
  PracticeLedger upsertMark(DateTime date, MarkIntensity intensity) {
    final day = _dayUtc(date);
    final idx = marks.indexWhere((m) => _dayUtc(m.date) == day);
    final next = [...marks];
    if (idx == -1) {
      next.add(PracticeMark(date: day, intensity: intensity));
    } else if (intensity.isStrongerThan(next[idx].intensity)) {
      next[idx] = next[idx].copyWith(intensity: intensity);
    }
    return copyWith(marks: next);
  }

  PracticeLedger copyWith({List<PracticeMark>? marks, List<GuardianSeal>? seals, List<Endorsement>? endorsements}) =>
      PracticeLedger(childProfileId: childProfileId, year: year, month: month,
          marks: marks ?? this.marks, seals: seals ?? this.seals, endorsements: endorsements ?? this.endorsements);

  factory PracticeLedger.fromJson(Map<String, dynamic> json) => _$PracticeLedgerFromJson(json);
  Map<String, dynamic> toJson() => _$PracticeLedgerToJson(this);
}
```

- [ ] **Step 4: Generate + test → PASS**

Run: `cd frontend && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/practice_journal/domain/practice_ledger_test.dart`

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/practice_journal/domain/entities/practice_ledger.* frontend/test/features/practice_journal/domain/practice_ledger_test.dart
git commit -m "feat(practice_journal): PracticeLedger 월집계 + 도장 업서트(날짜당 1개)"
```

---

### Task 4: Repository 인터페이스 + 임계값 상수

**Files:**
- Create: `frontend/lib/features/practice_journal/domain/repositories/practice_journal_repository.dart`
- Create: `frontend/lib/features/practice_journal/domain/journal_thresholds.dart`

- [ ] **Step 1: Implement 인터페이스 (테스트는 mock 에서)**

```dart
// practice_journal_repository.dart
import '../entities/practice_ledger.dart';
import '../entities/practice_mark.dart';
import '../entities/guardian_seal.dart';
import '../entities/endorsement.dart';

abstract class PracticeJournalRepository {
  /// (자녀 프로필, 연, 월) 장부 조회. 없으면 빈 장부.
  Future<PracticeLedger> getLedger(String childProfileId, int year, int month);

  /// 연습 도장 업서트(날짜당 1개, full>short).
  Future<void> upsertMark(String childProfileId, DateTime date, MarkIntensity intensity);

  /// 부모 주간 응원·확인 도장(주당 1개).
  Future<void> addGuardianSeal(String childProfileId, GuardianSeal seal);

  /// 검인(선생님 과제 한정) 또는 자가 검인. 무효(Endorsement.isValid==false) 시 ArgumentError.
  Future<void> addEndorsement(String childProfileId, Endorsement endorsement);
}
```

```dart
// journal_thresholds.dart
/// 도장 강도 임계값. 연습 durationMinutes >= fullMinutes 이면 full, 아니면 short.
/// NOTE: 실행 시 practice 도메인의 기존 임계값과 정합 확인(없으면 이 값 사용 — 스펙 §8.2).
class JournalThresholds {
  const JournalThresholds._();
  static const int fullMinutes = 10;
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/practice_journal/domain/repositories/practice_journal_repository.dart frontend/lib/features/practice_journal/domain/journal_thresholds.dart
git commit -m "feat(practice_journal): repository 인터페이스 + 도장 임계값 상수"
```

---

### Task 5: MockRepository (메모리) + 규칙 테스트

**Files:**
- Create: `frontend/lib/features/practice_journal/data/repositories/mock_practice_journal_repository.dart`
- Test: `frontend/test/features/practice_journal/data/mock_practice_journal_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/practice_journal/data/repositories/mock_practice_journal_repository.dart';
import 'package:app/features/practice_journal/domain/entities/practice_mark.dart';
import 'package:app/features/practice_journal/domain/entities/guardian_seal.dart';
import 'package:app/features/practice_journal/domain/entities/endorsement.dart';

void main() {
  test('업서트/주간 도장 중복 방지/무효 검인 거부', () async {
    final repo = MockPracticeJournalRepository();
    await repo.upsertMark('c1', DateTime.utc(2026,6,15), MarkIntensity.short);
    await repo.upsertMark('c1', DateTime.utc(2026,6,15), MarkIntensity.full);
    var l = await repo.getLedger('c1', 2026, 6);
    expect(l.marks.length, 1);
    expect(l.marks.single.intensity, MarkIntensity.full);

    final ws = DateTime.utc(2026,6,15);
    await repo.addGuardianSeal('c1', GuardianSeal(weekStart: ws, guardianUserId: 'p1'));
    await repo.addGuardianSeal('c1', GuardianSeal(weekStart: ws, guardianUserId: 'p1', cheerNote: '재시도'));
    l = await repo.getLedger('c1', 2026, 6);
    expect(l.seals.length, 1); // 주당 1개

    expect(
      () => repo.addEndorsement('c1', Endorsement(by: EndorsedBy.teacher,
          date: DateTime.utc(2026,6,15), authorUserId: 't1', note: 'x')), // 과제참조 없음 → 무효
      throwsArgumentError,
    );
  });
}
```

- [ ] **Step 2: Run → FAIL**

Run: `cd frontend && flutter test test/features/practice_journal/data/mock_practice_journal_repository_test.dart`

- [ ] **Step 3: Implement**

```dart
import '../../domain/entities/practice_ledger.dart';
import '../../domain/entities/practice_mark.dart';
import '../../domain/entities/guardian_seal.dart';
import '../../domain/entities/endorsement.dart';
import '../../domain/repositories/practice_journal_repository.dart';

class MockPracticeJournalRepository implements PracticeJournalRepository {
  // key: "$childProfileId:$year-$month"
  final Map<String, PracticeLedger> _store = {};
  static const _latency = Duration(milliseconds: 60);

  String _key(String c, int y, int m) => '$c:$y-$m';

  PracticeLedger _ledgerFor(String c, int y, int m) =>
      _store[_key(c, y, m)] ?? PracticeLedger.empty(childProfileId: c, year: y, month: m);

  @override
  Future<PracticeLedger> getLedger(String c, int year, int month) async {
    await Future.delayed(_latency);
    return _ledgerFor(c, year, month);
  }

  @override
  Future<void> upsertMark(String c, DateTime date, MarkIntensity intensity) async {
    await Future.delayed(_latency);
    final l = _ledgerFor(c, date.year, date.month).upsertMark(date, intensity);
    _store[_key(c, date.year, date.month)] = l;
  }

  @override
  Future<void> addGuardianSeal(String c, GuardianSeal seal) async {
    await Future.delayed(_latency);
    final l = _ledgerFor(c, seal.weekStart.year, seal.weekStart.month);
    final ws = DateTime.utc(seal.weekStart.year, seal.weekStart.month, seal.weekStart.day);
    final exists = l.seals.any((s) =>
        DateTime.utc(s.weekStart.year, s.weekStart.month, s.weekStart.day) == ws);
    if (exists) return; // 주당 1개
    _store[_key(c, seal.weekStart.year, seal.weekStart.month)] =
        l.copyWith(seals: [...l.seals, seal]);
  }

  @override
  Future<void> addEndorsement(String c, Endorsement e) async {
    await Future.delayed(_latency);
    if (!e.isValid) {
      throw ArgumentError('Endorsement 무효: teacher=과제참조 필수 / self=참조 없음');
    }
    final l = _ledgerFor(c, e.date.year, e.date.month);
    _store[_key(c, e.date.year, e.date.month)] = l.copyWith(endorsements: [...l.endorsements, e]);
  }
}
```

- [ ] **Step 4: Run → PASS**

Run: `cd frontend && flutter test test/features/practice_journal/data/mock_practice_journal_repository_test.dart`

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/practice_journal/data/repositories/mock_practice_journal_repository.dart frontend/test/features/practice_journal/data/mock_practice_journal_repository_test.dart
git commit -m "feat(practice_journal): MockRepository — 업서트/주간 중복방지/무효 검인 거부"
```

---

### Task 6: Provider 배선

**Files:**
- Create: `frontend/lib/features/practice_journal/presentation/providers/practice_journal_provider.dart`

- [ ] **Step 1: Implement (패턴: gamification_provider.dart 동일)**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/mock_practice_journal_repository.dart';
import '../../domain/entities/practice_ledger.dart';
import '../../domain/repositories/practice_journal_repository.dart';

part 'practice_journal_provider.g.dart';

@Riverpod(keepAlive: true)
PracticeJournalRepository practiceJournalRepository(PracticeJournalRepositoryRef ref) =>
    MockPracticeJournalRepository();
// NOTE: Remote 추가 시 createRepository<PracticeJournalRepository>(ref: ref, mock: ..., remote: ...) 로 교체.

@riverpod
Future<PracticeLedger> practiceLedger(
  PracticeLedgerRef ref, {
  required String childProfileId,
  required int year,
  required int month,
}) async {
  final repo = ref.watch(practiceJournalRepositoryProvider);
  return repo.getLedger(childProfileId, year, month);
}
```

- [ ] **Step 2: Generate**

Run: `cd frontend && dart run build_runner build --delete-conflicting-outputs`
Expected: `practice_journal_provider.g.dart` 생성, 0 errors

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/practice_journal/presentation/providers/practice_journal_provider.*
git commit -m "feat(practice_journal): repository/ledger provider"
```

---

### Task 7: 연습→도장 파생 (PracticeRecordingService 훅)

**Files:**
- Modify: `frontend/lib/features/practice/domain/services/practice_recording_service.dart`
- Test: `frontend/test/features/practice_journal/journal_mark_derive_test.dart`

> 통합점: `recordPractice()` 내 주석 `// *** practice_journal 훅 ***` 위치. 기존이 `heatmapRepository` 를 직접 주입받는 패턴이므로 `PracticeJournalRepository` 도 동일하게 주입한다(생성자 옵셔널, 기본 null → 미연결 시 무시).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/practice_journal/data/repositories/mock_practice_journal_repository.dart';
import 'package:app/features/practice_journal/domain/entities/practice_mark.dart';
import 'package:app/features/practice_journal/domain/journal_thresholds.dart';

// 헬퍼: durationMinutes → intensity (서비스가 쓰는 규칙을 단위로 검증)
MarkIntensity intensityFor(int minutes) =>
    minutes >= JournalThresholds.fullMinutes ? MarkIntensity.full : MarkIntensity.short;

void main() {
  test('연습 기록 시 자녀 장부에 도장 1개 파생(임계값으로 강도 결정)', () async {
    final journal = MockPracticeJournalRepository();
    final date = DateTime.utc(2026, 6, 15);
    // 서비스 훅이 호출할 동작을 직접 검증(통합은 위젯/통합테스트에서)
    await journal.upsertMark('c1', date, intensityFor(12)); // 12분 → full
    final l = await journal.getLedger('c1', 2026, 6);
    expect(l.marks.single.intensity, MarkIntensity.full);
    expect(intensityFor(3), MarkIntensity.short);
  });
}
```

- [ ] **Step 2: Run → PASS-as-unit** (파생 규칙 단위 검증)

Run: `cd frontend && flutter test test/features/practice_journal/journal_mark_derive_test.dart`

- [ ] **Step 3: Wire into service**

`practice_recording_service.dart` 생성자/필드에 추가:
```dart
final PracticeJournalRepository? journalRepository; // import practice_journal repository
```
`recordPractice()` 의 훅 위치에 추가:
```dart
    // *** practice_journal 훅: 연습 → 연습 도장 파생(이중 기록 0) ***
    final intensity = evidence.durationMinutes >= JournalThresholds.fullMinutes
        ? MarkIntensity.full : MarkIntensity.short;
    await journalRepository?.upsertMark(studentId, date, intensity);
```
import 추가: `package:app/features/practice_journal/domain/...`. 서비스 provider 가 있으면 `journalRepository: ref.watch(practiceJournalRepositoryProvider)` 주입(없으면 옵셔널 null 로 회귀 안전).

- [ ] **Step 4: Run 관련 테스트 + analyze**

Run: `cd frontend && flutter test test/features/practice_journal/ && flutter analyze lib/features/practice/domain/services/practice_recording_service.dart`
Expected: PASS, 0 errors

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/practice/domain/services/practice_recording_service.dart frontend/test/features/practice_journal/journal_mark_derive_test.dart
git commit -m "feat(practice_journal): 연습 기록 시 연습 도장 자동 파생"
```

---

### Task 8: 연령 톤 라벨 resolver + AppStrings

**Files:**
- Modify: `frontend/lib/core/constants/app_strings.dart` (연습장 문자열 2종)
- Create: `frontend/lib/features/practice_journal/presentation/extensions/journal_tone.dart`
- Test: `frontend/test/features/practice_journal/journal_tone_test.dart`

> 결정 Q2: birthdate 스키마 미변경 → 기본 `JournalTone.standard`, 부모 override 로 `JournalTone.child`. 도메인은 톤을 모른다(presentation only).

- [ ] **Step 1: AppStrings 에 키 추가 (표준/어린이 2종)**

```dart
// app_strings.dart — 하드코딩 금지 SSOT
static const journalTitleStandard = '연습장';
static const journalTitleChild = '도장판';
static const journalMarkStandard = '연습 도장';
static const journalMarkChild = '연습 도장';
static const journalSelfEndorse = '자가 검인';
static const journalGuardianSeal = '확인 도장';
static const journalTeacherEndorse = '선생님 도장';
static const journalStampPressCta = '도장 꾹!';
static const journalRestLabel = '쉼표'; // 빈 날(비처벌)
```

- [ ] **Step 2: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/practice_journal/presentation/extensions/journal_tone.dart';

void main() {
  test('톤별 제목: child=도장판 / standard=연습장', () {
    expect(JournalTone.child.title, '도장판');
    expect(JournalTone.standard.title, '연습장');
  });
}
```

- [ ] **Step 3: Implement resolver**

```dart
import 'package:app/core/constants/app_strings.dart';

enum JournalTone {
  standard,
  child;

  String get title => switch (this) {
        JournalTone.child => AppStrings.journalTitleChild,
        JournalTone.standard => AppStrings.journalTitleStandard,
      };
}
```

- [ ] **Step 4: Run → PASS**; **Step 5: Commit**

Run: `cd frontend && flutter test test/features/practice_journal/journal_tone_test.dart`
```bash
git add frontend/lib/core/constants/app_strings.dart frontend/lib/features/practice_journal/presentation/extensions/journal_tone.dart frontend/test/features/practice_journal/journal_tone_test.dart
git commit -m "feat(practice_journal): 연령 톤 라벨 resolver + AppStrings"
```

---

### Task 9: JournalMonthGrid 위젯 + smoke test

**Files:**
- Create: `frontend/lib/features/practice_journal/presentation/widgets/journal_month_grid.dart`
- Test: `frontend/test/features/practice_journal/widgets/journal_month_grid_test.dart`

**위젯 계약(인터페이스):**
```dart
class JournalMonthGrid extends StatelessWidget {
  final PracticeLedger ledger;          // 표시할 월 장부
  const JournalMonthGrid({super.key, required this.ledger});
}
```
**렌더 규칙(스펙 §5.1/§10):**
- 7열(월~일) 그리드. 연습 도장 있는 날 = `AppColors.ink` 원형 글리프(`NotebookGlyph`), 빈 날 = 쉼표 글리프(비처벌), full=●/short=◐.
- 색: 학생 ink / 부모 seal paperOk / 선생님 endorsement paperAccent.
- 모서리 `BorderRadius.zero`. `Color(0x..)`/`Icons.*`(시그니처 영역) 금지 — `NotebookGlyph` 사용.

- [ ] **Step 1: Write the smoke test (HARD-GATE)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/practice_journal/domain/entities/practice_ledger.dart';
import 'package:app/features/practice_journal/domain/entities/practice_mark.dart';
import 'package:app/features/practice_journal/presentation/widgets/journal_month_grid.dart';

void main() {
  testWidgets('JournalMonthGrid 렌더(좁은 제약) 예외 없음', (tester) async {
    final ledger = PracticeLedger.empty(childProfileId: 'c1', year: 2026, month: 6)
        .upsertMark(DateTime.utc(2026, 6, 15), MarkIntensity.full);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(width: 320, child: JournalMonthGrid(ledger: ledger))),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run → FAIL** (`cd frontend && flutter test test/features/practice_journal/widgets/journal_month_grid_test.dart`)

- [ ] **Step 3: Implement** — `GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: NeverScrollable...)` 로 날짜 셀 렌더. 각 셀: 해당 날 mark 조회 → 있으면 도장 글리프(full ●/short ◐), 없으면 쉼표. `NotebookGlyph` + `AppColors.ink` 사용. (참조 위젯: `core/widgets/notebook/notebook_glyph.dart`, gamification heatmap 그리드)

- [ ] **Step 4: Run → PASS**; **Step 5: Commit**
```bash
git add frontend/lib/features/practice_journal/presentation/widgets/journal_month_grid.dart frontend/test/features/practice_journal/widgets/journal_month_grid_test.dart
git commit -m "feat(practice_journal): JournalMonthGrid + smoke test"
```

---

### Task 10: StampPressSheet ("도장 꾹!" 축하) + smoke test

**Files:**
- Create: `frontend/lib/features/practice_journal/presentation/widgets/stamp_press_sheet.dart`
- Test: `frontend/test/features/practice_journal/widgets/stamp_press_sheet_test.dart`

**계약:** `showStampPressSheet(BuildContext, {required VoidCallback onPressed})` — `showModalBottomSheet` 로 "도장 꾹!"(`AppStrings.journalStampPressCta`) 버튼 1개. 탭 시 onPressed + 닫기. 보상 순간(연습 완료 직후 호출).

- [ ] **Step 1: smoke test** — pump + 버튼 탭 → onPressed 호출 확인 + `takeException() isNull`.
- [ ] **Step 2: Run → FAIL**
- [ ] **Step 3: Implement** (NotebookScreenScaffold 불필요 — 시트. 버튼은 컴팩트 배치 시 `styleFrom(minimumSize: Size(0, AppSpacing.buttonHeight))` 필수 — `feedback_theme_minsize_infinity`).
- [ ] **Step 4: Run → PASS**; **Step 5: Commit** (`feat(practice_journal): StampPressSheet 보상 시트`)

---

### Task 11: PracticeJournalScreen (3역할) + smoke test

**Files:**
- Create: `frontend/lib/features/practice_journal/presentation/screens/practice_journal_screen.dart`
- Test: `frontend/test/features/practice_journal/screens/practice_journal_screen_test.dart`

**계약:**
```dart
class PracticeJournalScreen extends ConsumerWidget {
  final String childProfileId;
  final JournalRole role; // student | guardian | teacher
  final JournalTone tone;
  const PracticeJournalScreen({super.key, required this.childProfileId,
      required this.role, this.tone = JournalTone.standard});
}
enum JournalRole { student, guardian, teacher }
```
**렌더(스펙 §7):** `NotebookScreenScaffold(appBar: NotebookDetailAppBar(title: tone.title), body: ...)` — `practiceLedgerProvider` watch → `.when(loading/error/data)`. data: `JournalMonthGrid(ledger)` + 역할별 하단 액션:
- `guardian` → "확인 도장 찍기"(addGuardianSeal, 주당 1회) + 선택 한 줄.
- `teacher` → "선생님 도장 + 빨간펜"(addEndorsement by teacher, **assignmentRef 필수** — 과제 선택 후).
- `student` + 부모 미연결(`Student.parentConsentAt == null`) → "자가 검인"(addEndorsement by self, 한 줄 회고).
- 빈 노드/미연결은 중립 라벨(압박 문구 금지).

- [ ] **Step 1: smoke test** — 3역할 각각 pump(ProviderScope override 로 mock repo 주입) → `pumpAndSettle` → `takeException() isNull`. 패턴: Task 5 mock + `practiceJournalRepositoryProvider.overrideWithValue(...)`.
- [ ] **Step 2: Run → FAIL**
- [ ] **Step 3: Implement** (NotebookScreenScaffold 골격은 `assignment_dashboard_screen.dart` 참조. 하단 액션 버튼 컴팩트 minimumSize override.)
- [ ] **Step 4: Run → PASS**; **Step 5: Commit** (`feat(practice_journal): PracticeJournalScreen 3역할 뷰`)

---

### Task 12: 홈 카드 + 진입점 wiring (5단 — 고아 위젯 금지)

**Files:**
- Create: `frontend/lib/features/practice_journal/presentation/widgets/practice_journal_card.dart`
- Create: `frontend/lib/features/practice_journal/practice_journal.dart` (배럴)
- Modify(진입점 3곳): 학생 홈(`features/student_home/.../student_dashboard_tab.dart`) · 부모 홈(`features/parent_home/.../parent_dashboard_tab.dart`) · 선생님 학생상세(`features/students/.../*student detail*`)
- Test: `frontend/test/features/practice_journal/widgets/practice_journal_card_test.dart`

**카드 계약:** `PracticeJournalCard({required String childProfileId, required JournalRole role, required VoidCallback onTap})` — 이번 달 도장 수 + 미니 그리드 미리보기. 탭 → `PracticeJournalScreen` push.

- [ ] **Step 1: 카드 smoke test** (pump + 탭 → onTap) → FAIL → Implement → PASS → Commit (`feat(practice_journal): 홈 진입 카드`)
- [ ] **Step 2: 배럴 파일** — `export 'presentation/screens/practice_journal_screen.dart';` 등 공개 API만(data 레이어 미공개). Commit.
- [ ] **Step 3: 학생 홈 wiring** — `student_dashboard_tab.dart` 에 `PracticeJournalCard(role: student)` 추가, 빈 상태에도 기존 UI 유지(regression 0, `feedback_entry_point_wiring`). 라우트 push 시 하드코딩 ID 폴백 금지(`route_params.dart` 헬퍼). Commit.
- [ ] **Step 4: 부모 홈 wiring** — `parent_dashboard_tab.dart` 에 자녀별 카드 + 미확인 배지. Commit.
- [ ] **Step 5: 선생님 학생상세 wiring** — 학생 상세 화면에 "연습장" 섹션(읽기 + 검인 진입). Commit.
- [ ] **Step 6: 전체 검증**

Run: `cd frontend && flutter analyze && flutter test test/features/practice_journal/`
Expected: 0 errors, 모든 테스트 PASS

```bash
# UI 변경 회귀: frontend-verify.md (영향 화면 + 공통 레이아웃 2~3개 실기 확인)
```

---

## Self-Review (작성자 체크)

**Spec coverage(P1):**
- 연습 도장 자동 파생 → Task 7. 도장 날짜당 1개/full>short → Task 3,5. 빈 날 쉼표(비처벌) → Task 9. 부모 확인 주1회 → Task 5,11. 선생님 검인 과제 한정 → Task 2,5,11. 자가 검인(미연결) → Task 2,5,11. 연령 톤 → Task 8,11. 3역할 진입점 → Task 11,12. 기존 잉크 재사용 → Task 9,11. 위젯 smoke(HARD-GATE) → Task 9,10,11,12. → **P1 AC 전 항목 매핑됨.**
- P2(제본/완성본/알림)는 본 계획 범위 외 — 별도 계획.

**Placeholder scan:** 도메인/로직 Task(1-8)는 전체 코드. UI Task(9-12)는 위젯 계약+렌더 규칙+smoke test 코드 제공, 위젯 트리는 검증된 `NotebookScreenScaffold`/`assignment_dashboard_screen.dart` 패턴을 따른다(established pattern, placeholder 아님). 실행 시 참조 파일 명시됨.

**Type consistency:** `MarkIntensity{short,full}`, `EndorsedBy{self,teacher}`, `JournalRole{student,guardian,teacher}`, `JournalTone{standard,child}`, `PracticeJournalRepository`(getLedger/upsertMark/addGuardianSeal/addEndorsement) — Task 전반 일관.

**알려진 실행시 확인 사항(placeholder 아님, 통합점):**
1. `PracticeRecordingService` 생성자/주입 위치(provider) — 실제 시그니처 확인 후 옵셔널 `journalRepository` 추가(Task 7).
2. `evidence.durationMinutes` 필드명 — practice `PracticeEvidence` 실제 필드 확인(Task 7).
3. 선생님 학생상세 화면 파일 경로 — `features/students/` 하위 실제 상세 스크린 확인(Task 12).
4. `NotebookGlyph` 도장/쉼표 글리프 상수명 — `notebook_glyph.dart` 실제 상수 확인(Task 9).
