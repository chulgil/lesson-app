# Teacher Settings Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (recommended) or superpowers:executing-plans 으로 task-by-task 실행. checkbox (`- [ ]`) 단위 추적.

> **워크플로우 강제 (HARD-GATE)**: 모든 Job(W1~W6)은 `.claude/rules/worktree-parallel-workflow.md` 룰에 따라 별도 git worktree + tmux 에서 진행. 검증 통과 후만 main merge. main 직접 작업 금지.

> 스펙: `.harness/spec/2026-06-11-teacher-settings-redesign.md`
> 글로서리: `.harness/knowledge/glossary.md` §14 (2026-06-11 신설)
> 형식: writing-plans 스킬 표준 + cg-harness Phase 4 decomposition 융합

**Goal:** 선생님 설정화면을 행동/의도 중심 5묶음 IA 로 재정의 + 운영시간 데이터 SSOT 일원화 + 퀘스트 보드 자연 졸업 메커니즘 도입.

**Architecture:** 6 worktree 병렬 진행 — W1 데이터 통일이 critical path (W2/W3/W5 dependency). W4 는 W2 dependency. W6 는 W2+W4 dependency. 각 worktree 검증 후 순차 PR merge.

**Tech Stack:** Flutter 3.29.0 / Riverpod (codegen) / Hive / Go Router / pytest + flutter_test

---

## 사전 결정 (O1~O6 — PLAN 검토 시 변경 가능)

본 PLAN 의 추천안. 사용자가 PLAN 검토 시 변경 가능. W0 첫 task 에서 spec/glossary 확정 반영.

| # | 항목 | 추천 결정 | 근거 |
|---|---|---|---|
| O1 | 시험 레슨 정책 위치 | `SubscriptionTemplatesScreen` 내부 "시험 레슨" 섹션 (별도 화면 신설 X) | 화면 수 최소화, 첫 수강권 발급 흐름과 한 화면에서 결정 |
| O2 | 가격표 화면 명칭 | `PriceTableScreen` | 직관적 — "가격표"가 유비쿼터스 용어 |
| O3 | 5묶음 카테고리 카드 진행 라벨 데이터 소스 | FE 클라이언트에서 entity 직접 계산 (BE API 변경 X) | 빠른 구현 + 오프라인 동작 |
| O4 | 마이그레이션 overlay 트리거 | `onboardingCategoryShownProvider`(`SharedPreferences`) — 기존+신규 사용자 통합 | 한 플래그로 onboarding/마이그레이션 동시 처리 |
| O5 | 검색 진입로 매핑 (spec §10.3) | **생략** — 현재 검색 진입로 없음. 대신 5묶음 카드 NEW 배지로 인지 유도 | YAGNI |
| O6 | 퀘스트 졸업 카드 dismiss 카운트 시작 | **기존 `User.quest_celebrated_at` 재사용** — 의미 재정의: "Q1~Q10 100% 완료 (졸업) 시점". Q11 보너스 표시는 별도 FE Hive flag | architect 검토 반영 (2026-06-11) — BE 컬럼 신설 없음 (spec §14 비범위 준수). 의미상 "11/11 완료" → "10/10 졸업" 으로 변경, 보너스 분리 |
| O7 | `lessonDurationMinutes` 마이그레이션 시점 | 앱 부팅 시 1회 (`teacher_settings_provider` init) | 마이그레이션 코드 단일 위치 |
| O8 | "운영시간" 라벨 변경 시점 | W2 (메뉴 재배치) 단계에서 일괄 변경 | i18n key 단일 변경 |

---

## DAG (Worktree 의존 관계)

```
                W0 (사전 정리: glossary 확정 + ADR)
                         │
                         ▼
                W1 (데이터/엔티티 통일 + 마이그레이션)
                         │
            ┌────────────┼────────────┐
            ▼            ▼            ▼
           W2          W3          W5
        (메뉴      (수업방식/    (퀘스트
         재배치)    가격 화면)   졸업·게이지)
            │            │
            ▼            │
           W4            │
        (Step 2.5 +      │
         spotlight)      │
            │            │
            └────┬───────┘
                 ▼
                W6 (기존 사용자 마이그레이션 overlay)
```

병렬 가능 시점:
- W1 완료 후 W2/W3/W5 동시 시작 (W3 는 W1 의 `lessonDurationMinutes` 필드 의존 — W1 머지 필수)
- W2 완료 후 W4 시작
- W2+W4 완료 후 W6 시작 (W6 의 overlay 는 W4 의 `OnboardingCategoryPreviewScreen` 재사용)

---

## 파일 구조 (생성/수정 매핑)

### W1 — 데이터 통일
| 액션 | 파일 |
|---|---|
| Modify | `frontend/lib/features/profile/domain/entities/teacher_settings.dart` — `availableSlots`/`breakTimeBetweenLessons` deprecated 마킹 + `lessonDurationMinutes` 추가 + `defaultLessonDuration` deprecated |
| Modify | `frontend/lib/features/schedule/domain/entities/teacher_availability.dart` — `breakTimeBetweenLessons` SSOT 명시 + `slotDurationMinutes` deprecated (TeacherSettings로 이동) |
| Create | `frontend/lib/features/settings/data/migrations/teacher_settings_migration.dart` |
| Create | `frontend/test/features/settings/data/migrations/teacher_settings_migration_test.dart` |
| Modify | `frontend/lib/features/settings/presentation/providers/teacher_settings_provider.dart` — 부팅 시 마이그레이션 1회 호출 (line 54, 229 의 `availableSlots` 참조 정리) |
| Modify | `frontend/lib/features/settings/data/repositories/remote_settings_repository.dart` — `availableSlots` consumer (line 21, 32, 40, 105, 111, 125, 169) 를 `weeklySchedules` 로 migrate |
| Modify | `frontend/lib/features/settings/data/repositories/mock_settings_repository.dart` — `availableSlots` consumer (line 12, 83, 211, 221, 229, 239, 247) 를 `weeklySchedules` 로 migrate |
| Modify | `frontend/lib/features/home/presentation/providers/teacher_profile_completion_provider.dart` — 완성도 계산에서 `availableSlots` → `weeklySchedules` 로 source 변경 |

### W2 — 5묶음 메뉴 재배치
| 액션 | 파일 |
|---|---|
| Modify | `frontend/lib/features/profile/presentation/screens/profile_tab.dart` — 5묶음 카드 그리드 + 기존 섹션 매핑 |
| Create | `frontend/lib/features/profile/presentation/widgets/category_card.dart` — 5묶음 카드 위젯 |
| Create | `frontend/lib/features/profile/presentation/providers/category_status_provider.dart` — 각 묶음 진행 상태 계산 |
| Create | `frontend/test/features/profile/presentation/widgets/category_card_test.dart` |
| Modify | `frontend/lib/core/router/app_routes.dart` — `lessonTimeSettings` deprecated + `lessonStyleSettings`/`priceTable` 추가 |
| Modify | `frontend/lib/core/l10n/app_strings.dart` — "운영시간" 라벨 단일화 + 5묶음 라벨 |

### W3 — 신규 화면
| 액션 | 파일 |
|---|---|
| Create | `frontend/lib/features/profile/presentation/screens/lesson_style_settings_screen.dart` |
| Create | `frontend/lib/features/profile/presentation/screens/price_table_screen.dart` |
| Modify | `frontend/lib/features/profile/presentation/screens/subscription_templates_screen.dart` — "시험 레슨" 섹션 추가 (O1) |
| Delete | `frontend/lib/features/profile/presentation/screens/lesson_time_settings_screen.dart` — 해체 (W2 의 메뉴 제거와 동기) |
| Create | `frontend/test/features/profile/presentation/screens/lesson_style_settings_screen_test.dart` |
| Create | `frontend/test/features/profile/presentation/screens/price_table_screen_test.dart` |

### W4 — Step 2.5 + Spotlight
| 액션 | 파일 |
|---|---|
| Create | `frontend/lib/features/onboarding/presentation/screens/onboarding_category_preview_screen.dart` |
| Create | `frontend/lib/features/onboarding/presentation/providers/onboarding_category_shown_provider.dart` |
| Modify | `frontend/lib/features/onboarding/presentation/screens/first_availability_setup_screen.dart` — 완료 후 `OnboardingCategoryPreviewScreen` 라우팅 |
| Create | `frontend/lib/features/home/presentation/widgets/next_mission_spotlight.dart` |
| Modify | `frontend/lib/features/home/presentation/widgets/dashboard_tab.dart` — spotlight 1회 노출 로직 |
| Create | `frontend/test/features/onboarding/presentation/screens/onboarding_category_preview_screen_test.dart` |
| Create | `frontend/test/features/home/presentation/widgets/next_mission_spotlight_test.dart` |

### W5 — 퀘스트 졸업 + 게이지 정합성
| 액션 | 파일 |
|---|---|
| Modify | `frontend/lib/features/profile/presentation/providers/quest_celebration_provider.dart` — **기존 `quest_celebrated_at` 의미 재정의** (Q1~Q10 100% 완료 시점) + 7일 dismiss. **BE 컬럼 신설 없음** (architect P0 #2 + O6 결정) |
| Modify | `frontend/lib/features/home/presentation/widgets/quest_board_card.dart` — 졸업 후 hide 로직 |
| Modify | `frontend/lib/features/home/presentation/providers/teacher_profile_completion_provider.dart` — 퀘스트 100% = 게이지 100% 1:1 매핑 (실제 위치는 `home/`, architect P0 #1) |
| Create | `frontend/lib/features/profile/presentation/screens/guide_reshow_screen.dart` — ⚙️ 정책·알림·지원 → "가이드 다시 보기" |
| Create | `frontend/test/features/profile/presentation/providers/quest_celebration_provider_test.dart` |
| Create | `frontend/test/features/home/presentation/providers/teacher_profile_completion_provider_test.dart` |
| (NEW) | Q11 보너스 표시는 FE Hive flag — `frontend/lib/features/profile/presentation/providers/quest_bonus_shown_provider.dart` (architect 권장) |

### W6 — 기존 사용자 마이그레이션
| 액션 | 파일 |
|---|---|
| Create | `frontend/lib/core/constants/durations.dart` — `kQuestGraduationGrace` / `kCategoryNewBadgeWindow` 7일 상수 추출 (architect P1 #5) |
| Modify | `frontend/lib/features/profile/presentation/screens/profile_tab.dart` — 첫 진입 시 `OnboardingCategoryPreviewScreen` overlay (`onboardingCategoryShownProvider == false`) |
| Modify | `frontend/lib/features/profile/presentation/widgets/category_card.dart` — NEW 배지 7일 (`kCategoryNewBadgeWindow`) |
| Create | `frontend/lib/features/profile/presentation/providers/category_new_badge_provider.dart` — 카드별 NEW dismiss 상태 |
| Create | `frontend/test/features/profile/presentation/providers/category_new_badge_provider_test.dart` |

---

## W0 — 사전 정리 (main 직접, 1 커밋)

**Worktree 불필요** — glossary/spec 확정만, 검증 없음.

### Task 0.1: spec OPEN 결정 (O1~O8) + architect 검토 반영 본문 반영

- [ ] **Step 1**: `.harness/spec/2026-06-11-teacher-settings-redesign.md` §6.3 "시험 레슨 정책" 위치 확정 (O1 결정)
- [ ] **Step 2**: spec §14 신규 항목 추가 — O7/O8 결정 (마이그레이션 시점/i18n key 일괄 변경 시점)
- [ ] **Step 3**: spec §5.2/§5.4 `minBookingHours` 정합성 — TeacherSettings 단일 SSOT + 마이그레이션 시 `minBookingHours` 만 profile 우선 (architect P1 #3)
- [ ] **Step 4**: spec §14 (비범위) 명시 — O6 변경: BE 컬럼 신설 없음, `quest_celebrated_at` 의미 재정의
- [ ] **Step 5**: glossary §13 `quest_celebrated_at` 의미 재정의 ("11/11 완료" → "Q1~Q10 졸업 시점") + Q11 보너스 분리 명시
- [ ] **Step 6**: glossary §14 `minBookingHours` 매핑 명확화 (`TeacherAvailability.minBookingHours` deprecated → `TeacherSettings.minBookingHours` SSOT)
- [ ] **Step 7**: 커밋

```bash
git add .harness/spec/2026-06-11-teacher-settings-redesign.md .harness/knowledge/glossary.md
git commit -m "docs(spec): teacher-settings-redesign OPEN 결정 O1~O8 + architect 검토 반영"
```

---

## W1 — 데이터/엔티티 통일 + 마이그레이션 (worktree: `teacher-settings-w1-data`)

### Task 1.1: worktree 생성 + 브랜치

- [ ] **Step 1**: worktree 진입

```
EnterWorktree({name: "teacher-settings-w1-data"})
```

기대 결과: `.claude/worktrees/teacher-settings-w1-data` 에 origin/main 기반 신규 브랜치 생성.

### Task 1.2: TeacherSettings 엔티티 — `lessonDurationMinutes` 추가

**Files:**
- Modify: `frontend/lib/features/profile/domain/entities/teacher_settings.dart`
- Test: `frontend/test/features/profile/domain/entities/teacher_settings_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('lessonDurationMinutes 기본값 50분', () {
  final settings = TeacherSettings();
  expect(settings.lessonDurationMinutes, 50);
});

test('defaultLessonDuration 은 deprecated — lessonDurationMinutes 로 fallback', () {
  // ignore: deprecated_member_use_from_same_package
  final settings = TeacherSettings(defaultLessonDuration: 60);
  expect(settings.lessonDurationMinutes, 60); // 마이그레이션 미수행 상태
});
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
cd frontend && flutter test test/features/profile/domain/entities/teacher_settings_test.dart
```
Expected: FAIL — `lessonDurationMinutes` 필드 없음

- [ ] **Step 3: 최소 구현** — `@HiveField` 신규 할당 + `@Deprecated('Use lessonDurationMinutes')` 마킹

- [ ] **Step 4: 코드 생성**

```bash
cd frontend && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: 테스트 통과 확인 + 커밋**

```bash
flutter test test/features/profile/domain/entities/teacher_settings_test.dart
git add frontend/lib/features/profile/domain/entities/teacher_settings.dart
git add frontend/lib/features/profile/domain/entities/teacher_settings.g.dart
git add frontend/test/features/profile/domain/entities/teacher_settings_test.dart
git commit -m "feat(profile): TeacherSettings.lessonDurationMinutes 추가 + defaultLessonDuration deprecated"
```

### Task 1.3: TeacherSettings — `availableSlots` / `breakTimeBetweenLessons` deprecated

**Files:**
- Modify: `frontend/lib/features/profile/domain/entities/teacher_settings.dart`

- [ ] **Step 1: 테스트 작성** — deprecated 사용 시 analyzer warning 검증 (analyzer rule 또는 lint 회귀 테스트)
- [ ] **Step 2~5**: deprecated 마킹 + build_runner + 커밋

```bash
git commit -m "feat(profile): availableSlots/breakTimeBetweenLessons deprecated 마킹 — TeacherAvailability SSOT"
```

### Task 1.4: 마이그레이션 로직 — `teacher_settings_migration.dart`

**Files:**
- Create: `frontend/lib/features/profile/data/migrations/teacher_settings_migration.dart`
- Create: `frontend/test/features/profile/data/migrations/teacher_settings_migration_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성** (3 시나리오)

```dart
group('TeacherSettingsMigration', () {
  test('신규 선생님 — profile.availableSlots 있고 schedule.weeklySchedules 비어있음 → 복사', () async {
    final settings = TeacherSettings(availableSlots: [mockSlot]);
    final availability = TeacherAvailability(weeklySchedules: []);
    final result = await TeacherSettingsMigration.migrate(settings, availability);
    expect(result.availability.weeklySchedules, [mockWeeklySchedule]);
    expect(result.settings.availableSlots, isEmpty);
  });

  test('기존 선생님 — 둘 다 있음 → schedule 우선', () async {
    final settings = TeacherSettings(availableSlots: [mockSlot]);
    final availability = TeacherAvailability(weeklySchedules: [otherSchedule]);
    final result = await TeacherSettingsMigration.migrate(settings, availability);
    expect(result.availability.weeklySchedules, [otherSchedule]);
    expect(result.settings.availableSlots, isEmpty);
  });

  test('이미 마이그레이션 완료 — settings.availableSlots 비어있음 → 무영향', () async {
    final settings = TeacherSettings(availableSlots: []);
    final availability = TeacherAvailability(weeklySchedules: [schedule]);
    final result = await TeacherSettingsMigration.migrate(settings, availability);
    expect(result.availability.weeklySchedules, [schedule]);
    expect(result.settings.availableSlots, isEmpty);
  });
});
```

- [ ] **Step 2: 테스트 실패 확인**
- [ ] **Step 3: 구현**

```dart
class TeacherSettingsMigration {
  static Future<MigrationResult> migrate(
    TeacherSettings settings,
    TeacherAvailability availability,
  ) async {
    if (settings.availableSlots.isEmpty) {
      return MigrationResult(settings, availability);
    }
    final newAvailability = availability.weeklySchedules.isEmpty
        ? availability.copyWith(weeklySchedules: settings.availableSlots.toWeeklySchedules())
        : availability;
    final newSettings = settings.copyWith(availableSlots: []);
    return MigrationResult(newSettings, newAvailability);
  }
}
```

- [ ] **Step 4: 테스트 통과 + 커밋**

```bash
git commit -m "feat(profile): teacher_settings_migration — availableSlots→weeklySchedules 1회 복사"
```

### Task 1.5: Provider 부팅 시 마이그레이션 호출

**Files:**
- Modify: `frontend/lib/features/settings/presentation/providers/teacher_settings_provider.dart` (architect 검토 — 실제 위치는 `settings/` 도메인)

- [ ] **Step 1**: Provider init 단계에서 `TeacherSettingsMigration.migrate()` 호출 + 결과 저장 + flag 영속
- [ ] **Step 2~5**: 통합 테스트 + 커밋

```bash
git commit -m "feat(settings): teacher_settings_provider — 부팅 시 마이그레이션 1회"
```

### Task 1.5a: Repository consumer migration (architect 누락 task #1)

**Files:**
- Modify: `frontend/lib/features/settings/data/repositories/remote_settings_repository.dart` (7곳)
- Modify: `frontend/lib/features/settings/data/repositories/mock_settings_repository.dart` (7곳)
- Modify: `frontend/lib/features/home/presentation/providers/teacher_profile_completion_provider.dart`

- [ ] **Step 1: 회귀 테스트 (3 시나리오)**

```dart
test('remote repository read — weeklySchedules 에서 가져옴 (availableSlots 무시)', () async {
  // ...
});
test('mock repository write — weeklySchedules 만 갱신, availableSlots 변경 없음', () async {
  // ...
});
test('teacher_profile_completion_provider — weeklySchedules 1개 이상 시 운영시간 완료 계산', () async {
  // ...
});
```

- [ ] **Step 2**: 테스트 실패 확인
- [ ] **Step 3**: 7곳 × 2 = 14곳 + 완성도 provider 1곳 migration. `availableSlots` 사용을 `TeacherAvailability.weeklySchedules` 로 redirect (또는 deprecated 호출 경로 유지하되 SSOT 는 schedule)
- [ ] **Step 4**: `grep -rn "\.availableSlots" frontend/lib/features/settings/` → SSOT 명세 외 0 hit
- [ ] **Step 5**: 커밋

```bash
git commit -m "feat(settings): availableSlots consumer → weeklySchedules SSOT 마이그레이션 (14곳)"
```

### Task 1.6: 검증 + W1 종료 + PR

- [ ] **Step 1**: 전체 테스트

```bash
cd frontend && flutter test
flutter analyze
```

- [ ] **Step 2**: Playwright 스크린샷 회귀 (frontend-verify.md 룰)
- [ ] **Step 3**: PR 생성

```bash
gh pr create --title "feat(settings): W1 데이터 통일 — lessonDurationMinutes + 마이그레이션" --body "$(cat <<'EOF'
## Summary
- TeacherSettings.lessonDurationMinutes 신설 (기본 50분)
- availableSlots / breakTimeBetweenLessons / defaultLessonDuration / slotDurationMinutes deprecated
- 부팅 시 1회 마이그레이션 (availableSlots → weeklySchedules)
- Settings repository consumer 14곳 + completion provider 1곳 migration

## Spec
.harness/spec/2026-06-11-teacher-settings-redesign.md §5

## Test plan
- [ ] flutter test pass
- [ ] flutter analyze pass
- [ ] 마이그레이션 3 시나리오 PASS
- [ ] grep -rn "\.availableSlots" frontend/lib/features/settings/ → SSOT 명세 외 0

Directive: TeacherAvailability(schedule) 운영시간 SSOT 단일화
Rejected: TeacherSettings 측 통일 — schedule 도메인이 휴무/휴가 풍부, 마스터 스펙 방향

Signed-off-by: 🐙 Autopus
EOF
)"
```

- [ ] **Step 4**: 머지 후 worktree 정리

```
ExitWorktree({action: "remove"})
```

---

## W2 — 5묶음 메뉴 재배치 (worktree: `teacher-settings-w2-menu`)

W1 머지 후 시작. W3/W5 와 병렬 가능.

### Task 2.1: worktree 진입

```
EnterWorktree({name: "teacher-settings-w2-menu"})
```

### Task 2.2: `category_status_provider` — 각 묶음 진행 상태 계산

**Files:**
- Create: `frontend/lib/features/profile/presentation/providers/category_status_provider.dart`
- Create: `frontend/test/features/profile/presentation/providers/category_status_provider_test.dart`

- [ ] **Step 1: 실패 테스트**

```dart
test('운영시간 묶음 — weeklySchedules 1개 + breakTime → 설정완료', () {
  final status = CategoryStatusCalculator.operatingHours(
    availability: TeacherAvailability(weeklySchedules: [mock], breakTimeBetweenLessons: 10),
  );
  expect(status, CategoryStatus.complete);
});

test('수업방식 묶음 — 3 항목 중 2 → "2/3 항목"', () {
  final status = CategoryStatusCalculator.lessonStyle(
    settings: TeacherSettings(lessonDurationMinutes: 50, minBookingHours: 2, studentGuideMessage: null),
  );
  expect(status, CategoryStatus.partial(filled: 2, total: 3));
});
```

- [ ] **Step 2~5**: 5 묶음 모두 계산 로직 + 테스트 + 커밋

```bash
git commit -m "feat(profile): category_status_provider — 5묶음 진행 상태 계산"
```

### Task 2.3: `CategoryCard` 위젯

**Files:**
- Create: `frontend/lib/features/profile/presentation/widgets/category_card.dart`
- Create: `frontend/test/features/profile/presentation/widgets/category_card_test.dart`

- [ ] **Step 1: widget smoke test** (rule: design-principles.md HARD-GATE)

```dart
testWidgets('CategoryCard — 미설정 시 노란 점 표시', (tester) async {
  await tester.pumpWidget(MaterialApp(home: CategoryCard(
    title: '수강권·정산', icon: Icons.payments,
    status: CategoryStatus.empty, route: '/test',
  )));
  expect(find.byKey(Key('category_card_dot_warning')), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2~5**: 위젯 구현 + 테스트 + 커밋

```bash
git commit -m "feat(profile): CategoryCard — 5묶음 카드 위젯 + 진행 라벨/노란점/NEW 배지 슬롯"
```

### Task 2.4: `ProfileTab` 메뉴 재배치 (5묶음)

**Files:**
- Modify: `frontend/lib/features/profile/presentation/screens/profile_tab.dart` — 기존 8개 섹션 → 5묶음 카드 그리드
- Modify: `frontend/lib/core/l10n/app_strings.dart` — i18n 라벨 단일화 ("운영시간")

- [ ] **Step 1: 회귀 테스트 작성** — 5묶음 카드 노출 + 기존 "레슨 시간 설정" 메뉴 부재
- [ ] **Step 2~3**: ProfileTab 리팩토링 + AppStrings 갱신
- [ ] **Step 4**: i18n hardcoded 텍스트 + 동명이의 변수 grep 검증

```bash
# i18n: 폐기 메뉴 라벨 0 hit
grep -rn "Text('레슨 시간 설정')" frontend/lib/ # 0 hit 기대
grep -rn "Text('가용 요일/시간')" frontend/lib/  # 0 hit

# 정확한 패턴: TeacherSettings 필드 access 만 검출 (booking_repository.dart:495 의 로컬 변수 `final availableSlots` 은 동명이의 — 오탐)
grep -rn "settings\.availableSlots\|TeacherSettings.*availableSlots" frontend/lib/ # SSOT 명세 외 0
grep -rn "\.copyWith(availableSlots:" frontend/lib/ # SSOT 명세 외 0
```

- [ ] **Step 5**: 커밋

```bash
git commit -m "feat(profile): ProfileTab 5묶음 메뉴 재배치 + AppStrings 라벨 단일화"
```

### Task 2.5: `LessonTimeSettingsScreen` 라우트 deprecated

**Files:**
- Modify: `frontend/lib/core/router/app_routes.dart` — `lessonTimeSettings` 라우트 표시 deprecated

- [ ] **Step 1~5**: deprecated + redirect 로직 (legacy URL → 5묶음 메인) + 커밋

### Task 2.6: W2 검증 + PR + 머지

W1 와 동일 패턴 (test + analyze + screenshot + PR).

```bash
git commit -m "feat(profile): W2 5묶음 메뉴 재배치"
gh pr create --title "feat(profile): W2 5묶음 메뉴 재배치"
ExitWorktree({action: "remove"})
```

---

## W3 — 신규 화면 (worktree: `teacher-settings-w3-screens`)

W1 머지 후 W2 와 병렬 가능. (W2 의 라우트 deprecated 와 충돌 회피 — W3 가 신규 화면만 추가)

### Task 3.1: worktree 진입

### Task 3.2: `LessonStyleSettingsScreen` (수업방식)

**Files:**
- Create: `frontend/lib/features/profile/presentation/screens/lesson_style_settings_screen.dart`
- Create: `frontend/test/features/profile/presentation/screens/lesson_style_settings_screen_test.dart`

- [ ] **Step 1: widget smoke test**

```dart
testWidgets('LessonStyleSettingsScreen — 3 섹션 렌더', (tester) async {
  await tester.pumpWidget(MaterialApp(home: LessonStyleSettingsScreen()));
  expect(find.text('레슨 1회 시간'), findsOneWidget);
  expect(find.text('최소 사전 예약 시간'), findsOneWidget);
  expect(find.text('학생 안내 메시지'), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: 동작 테스트** — 30/45/50/60 선택 → `lessonDurationMinutes` 업데이트
- [ ] **Step 3~5**: 구현 + 커밋

### Task 3.3: `PriceTableScreen` (가격표)

**Files:**
- Create: `frontend/lib/features/profile/presentation/screens/price_table_screen.dart`
- Create: `frontend/test/features/profile/presentation/screens/price_table_screen_test.dart`

- [ ] **Step 1**: widget smoke + 악기·레벨별 가격 입력 동작 테스트
- [ ] **Step 2~5**: 구현 + 커밋

### Task 3.4: `SubscriptionTemplatesScreen` 시험 레슨 섹션 (O1)

**Files:**
- Modify: `frontend/lib/features/profile/presentation/screens/subscription_templates_screen.dart`

- [ ] **Step 1**: 회귀 테스트 — 시험 레슨 토글 추가, 기존 템플릿 리스트 보존
- [ ] **Step 2~5**: 구현 + 커밋

### Task 3.5: `LessonTimeSettingsScreen` 파일 삭제

**Files:**
- Delete: `frontend/lib/features/profile/presentation/screens/lesson_time_settings_screen.dart`

- [ ] **Step 1**: import 의존 grep — 0 hit 확인

```bash
grep -rn "lesson_time_settings_screen" frontend/lib/
```

- [ ] **Step 2**: 파일 삭제 + 라우트 entry 정리 (W2 의 deprecated 결과 + 본 삭제)
- [ ] **Step 3**: 전체 테스트 + 커밋

```bash
git commit -m "chore(profile): LessonTimeSettingsScreen 해체 — 5묶음으로 흩어짐"
```

### Task 3.6: W3 검증 + PR + 머지

---

## W5 — 퀘스트 졸업 + 게이지 1:1 (worktree: `teacher-settings-w5-quest`)

W1 머지 후 시작. W2/W3 와 병렬.

### Task 5.1: worktree 진입

### Task 5.2: `quest_celebrated_at` 의미 재정의 (BE 컬럼 신설 없음 — architect P0 #2)

**의도 변경**: 기존 `User.quest_celebrated_at` (`backend/app/models/user.py:61`) 은 원래 "Q1~Q11 모두 완료 (11/11) 시 1회 축하 카드" 트리거. 본 변경에서 **"Q1~Q10 (필수 10개) 100% 완료 = 졸업" 시점으로 의미 재정의**. Q11 보너스 표시는 별도 FE Hive flag.

**Files (BE 변경 없음)**:
- Create: `frontend/lib/features/profile/presentation/providers/quest_bonus_shown_provider.dart` — Q11 보너스 표시 1회 (SharedPreferences)
- Modify: `frontend/lib/features/profile/presentation/providers/quest_celebration_provider.dart` — 필수 10개 완료 시 `quest_celebrated_at` 영속 (기존 mutation 트리거 변경)

- [ ] **Step 1: 테스트 작성 (의미 변경 검증)**

```dart
test('Q1~Q10 모두 완료 (Q11 미완료) → quest_celebrated_at 자동 기록 (졸업)', () async {
  await container.read(questCelebrationProvider.notifier).onRequiredCompleted();
  expect(mockUser.questCelebratedAt, isNotNull);
});

test('Q11 만 완료 → quest_celebrated_at 변경 없음 (졸업 트리거 아님)', () async {
  await container.read(questCelebrationProvider.notifier).onBonusCompleted();
  expect(mockUser.questCelebratedAt, isNull);
});

test('Q11 보너스 완료 시 별도 FE flag — quest_bonus_shown 1회 영속', () async {
  await container.read(questBonusShownProvider.notifier).markShown();
  expect(await container.read(questBonusShownProvider.future), true);
});
```

- [ ] **Step 2~5**: 구현 + 커밋

```bash
git commit -m "feat(profile): quest_celebrated_at 의미 재정의 — Q1~Q10 졸업 시점 + Q11 보너스 분리"
```

### Task 5.3: FE — `quest_celebration_provider` 7일 dismiss + 졸업 hide

**Files:**
- Modify: `frontend/lib/features/profile/presentation/providers/quest_celebration_provider.dart`

- [ ] **Step 1: 테스트**

```dart
test('celebratedAt 후 7일 경과 → 졸업 카드 hide', () async {
  mockUser.questCelebratedAt = DateTime.now().subtract(kQuestGraduationGrace + Duration(hours: 1));
  expect(container.read(questCelebrationProvider).visible, false);
});

test('celebratedAt 후 6일 경과 → 졸업 카드 visible', () async {
  mockUser.questCelebratedAt = DateTime.now().subtract(Duration(days: 6));
  expect(container.read(questCelebrationProvider).visible, true);
});
```

- [ ] **Step 2~5**: 구현 (`kQuestGraduationGrace` 상수 W6 Task 6.0 에서 정의) + 커밋

### Task 5.4: 메인 hide 로직 + `QuestBoardCard`

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/quest_board_card.dart`

- [ ] **Step 1**: 회귀 테스트 — 졸업 상태에서 보드 렌더링 0
- [ ] **Step 2~5**: 구현 + 커밋

### Task 5.5: 게이지 1:1 정합성 — `teacher_profile_completion_provider` (architect P0 #1 — 실제 위치 정정)

**Files:**
- Modify: `frontend/lib/features/home/presentation/providers/teacher_profile_completion_provider.dart`

- [ ] **Step 1: 정합성 테스트 (필수, spec SC-6)**

```dart
test('Q1~Q10 모두 완료 → 게이지 100%', () {
  final result = ProfileCompletenessCalculator.from(
    questState: questAllCompleted(),
  );
  expect(result.percent, 100);
});

test('Q11 만 완료 (보너스) → 게이지 0%', () {
  final result = ProfileCompletenessCalculator.from(
    questState: questOnlyBonus(),
  );
  expect(result.percent, 0);
});

test('Q1~Q10 + Q11 완료 → 게이지 100% (Q11 보너스 표시만)', () {
  final result = ProfileCompletenessCalculator.from(
    questState: questAllPlusBonus(),
  );
  expect(result.percent, 100);
  expect(result.bonusBadgeVisible, true);
});
```

- [ ] **Step 2~5**: 구현 + 커밋

### Task 5.6: "가이드 다시 보기" 화면 (⚙️ 정책·알림·지원 → 진입)

**Files:**
- Create: `frontend/lib/features/profile/presentation/screens/guide_reshow_screen.dart`
- Modify: ⚙️ 정책·알림·지원 카테고리 내 메뉴 추가

- [ ] **Step 1~5**: widget smoke + 진입 테스트 + 커밋

### Task 5.7: W5 검증 + PR + 머지

---

## W4 — Step 2.5 + Spotlight (worktree: `teacher-settings-w4-onboarding`)

W2 머지 후 시작 (5묶음 카드 위젯 dependency).

### Task 4.1: worktree 진입

### Task 4.2: `OnboardingCategoryPreviewScreen` (Step 2.5)

**Files:**
- Create: `frontend/lib/features/onboarding/presentation/screens/onboarding_category_preview_screen.dart`
- Create: `frontend/lib/features/onboarding/presentation/providers/onboarding_category_shown_provider.dart`

- [ ] **Step 1: widget smoke + 동작 테스트**

```dart
testWidgets('OnboardingCategoryPreviewScreen — 5묶음 아이콘 표시 + 시작/건너뛰기', (tester) async {
  await tester.pumpWidget(MaterialApp(home: OnboardingCategoryPreviewScreen()));
  expect(find.byIcon(Icons.access_time), findsOneWidget); // 운영시간
  expect(find.byIcon(Icons.school), findsOneWidget); // 수업방식
  expect(find.byIcon(Icons.payments), findsOneWidget); // 수강권·정산
  expect(find.byIcon(Icons.person), findsOneWidget); // 내 프로필
  expect(find.byIcon(Icons.settings), findsOneWidget); // 정책
  expect(find.text('시작하기'), findsOneWidget);
  expect(find.text('건너뛰기'), findsOneWidget);
});

test('[시작하기] 탭 → onboardingCategoryShownProvider true 영속', () async {
  // ...
});
```

- [ ] **Step 2~5**: 구현 + 영속 (SharedPreferences) + 커밋

### Task 4.3: `FirstAvailabilitySetupScreen` 완료 후 라우팅 변경

**Files:**
- Modify: `frontend/lib/features/onboarding/presentation/screens/first_availability_setup_screen.dart`

- [ ] **Step 1**: 회귀 테스트 — 완료 후 `/onboarding/category-preview` 로 push
- [ ] **Step 2~5**: 구현 + 커밋

### Task 4.4: `NextMissionSpotlight` (메인 첫 진입 1회)

**Files:**
- Create: `frontend/lib/features/home/presentation/widgets/next_mission_spotlight.dart` — **widget only, 신규 provider 금지**
- Modify: `frontend/lib/features/home/presentation/widgets/dashboard_tab.dart`
- Reuse: `frontend/lib/features/profile/presentation/providers/quest_first_shown_provider.dart` — **기존 provider 재사용** (architect P1 #4 반영 — 두 spotlight 시스템 공존 방지)

**중요**: 기존 `questFirstShownProvider` 의 `isWithin` static method + 5분 윈도우 로직 그대로 활용. 새 provider 만들지 않음.

- [ ] **Step 1: 회귀 테스트**

```dart
testWidgets('첫 진입 — spotlight 1회 노출', (tester) async {
  mockQuestFirstShown(false);
  await tester.pumpWidget(MaterialApp(home: DashboardTab()));
  await tester.pumpAndSettle();
  expect(find.byType(NextMissionSpotlight), findsOneWidget);
});

testWidgets('두 번째 진입 — spotlight 없음', (tester) async {
  mockQuestFirstShown(true);
  await tester.pumpWidget(MaterialApp(home: DashboardTab()));
  await tester.pumpAndSettle();
  expect(find.byType(NextMissionSpotlight), findsNothing);
});

testWidgets('spotlight [시작] → spotlight 종료 + 미션 화면 push', (tester) async {
  // ...
});
```

- [ ] **Step 2~5**: 구현 + 커밋

### Task 4.5: W4 검증 + PR + 머지

---

## W6 — 기존 사용자 마이그레이션 overlay (worktree: `teacher-settings-w6-migration`)

W2 + W4 머지 후 시작.

### Task 6.1: worktree 진입

### Task 6.0a: `durations.dart` 상수 추출 (architect P1 #5)

**Files:**
- Create: `frontend/lib/core/constants/durations.dart`
- Create: `frontend/test/core/constants/durations_test.dart`

- [ ] **Step 1: 테스트**

```dart
test('kQuestGraduationGrace == 7 days', () {
  expect(kQuestGraduationGrace, Duration(days: 7));
});

test('kCategoryNewBadgeWindow == 7 days', () {
  expect(kCategoryNewBadgeWindow, Duration(days: 7));
});
```

- [ ] **Step 2~5**: 구현

```dart
const Duration kQuestGraduationGrace = Duration(days: 7);
const Duration kCategoryNewBadgeWindow = Duration(days: 7);
```

- [ ] **Step 5**: 커밋

```bash
git commit -m "feat(core): durations.dart — 7일 상수 추출 (퀘스트 졸업/NEW 배지 공통)"
```

### Task 6.2: `category_new_badge_provider` — 7일 NEW 배지

**Files:**
- Create: `frontend/lib/features/profile/presentation/providers/category_new_badge_provider.dart`
- Create: `frontend/test/features/profile/presentation/providers/category_new_badge_provider_test.dart`

- [ ] **Step 1: 테스트**

```dart
test('새 카테고리 7일간 NEW 표시', () async {
  await provider.markCategoryIntroduced('운영시간', DateTime.now());
  expect(provider.shouldShowNew('운영시간'), true);
});

test('${kCategoryNewBadgeWindow.inDays + 1}일 경과 후 자동 dismiss', () async {
  await provider.markCategoryIntroduced('운영시간', DateTime.now().subtract(kCategoryNewBadgeWindow + Duration(days: 1)));
  expect(provider.shouldShowNew('운영시간'), false);
});

test('한 번 진입 시 해당 카드만 dismiss', () async {
  await provider.markEntered('운영시간');
  expect(provider.shouldShowNew('운영시간'), false);
  expect(provider.shouldShowNew('수업방식'), true);
});
```

- [ ] **Step 2~5**: 구현 + 커밋

### Task 6.3: `ProfileTab` 첫 진입 overlay (`OnboardingCategoryPreviewScreen` 재사용)

**Files:**
- Modify: `frontend/lib/features/profile/presentation/screens/profile_tab.dart`

- [ ] **Step 1: 회귀 테스트**

```dart
testWidgets('기존 사용자 첫 진입 — overlay 1회 노출', (tester) async {
  mockOnboardingCategoryShown(false);
  await tester.pumpWidget(MaterialApp(home: ProfileTab()));
  await tester.pumpAndSettle();
  expect(find.byType(OnboardingCategoryPreviewScreen), findsOneWidget);
});

testWidgets('두 번째 진입 — overlay 없음', (tester) async {
  mockOnboardingCategoryShown(true);
  await tester.pumpWidget(MaterialApp(home: ProfileTab()));
  await tester.pumpAndSettle();
  expect(find.byType(OnboardingCategoryPreviewScreen), findsNothing);
});
```

- [ ] **Step 2~5**: 구현 + 커밋

### Task 6.4: `CategoryCard` NEW 배지 노출

**Files:**
- Modify: `frontend/lib/features/profile/presentation/widgets/category_card.dart`

- [ ] **Step 1~5**: NEW 배지 wiring + 테스트 + 커밋

### Task 6.5: W6 검증 + PR + 머지

---

## 통합 회귀 (모든 PR 머지 후, 1 응답)

main 에서 직접 (예외: 검증 read-only 명령).

- [ ] **Step 1**: 통합 테스트

```bash
cd frontend && flutter test
flutter analyze
cd ../backend && pytest
```

- [ ] **Step 2**: Playwright 스크린샷 (frontend-verify.md)

```bash
auto verify --viewport mobile
auto verify --viewport desktop
```

- [ ] **Step 3**: spec SC-1~7 체크리스트 검증

```
SC-1 카테고리 미리보기 1회 노출 — widget test 자동화 (`onboarding_category_preview_screen_test.dart` mock provider 시나리오) + 신규 가입 manual QA 보조
SC-2 availableSlots 필드 read/write 0개 — grep 확인
SC-3 LessonTimeSettingsScreen 라우트 deprecated — flutter analyze
SC-4 운영시간 메뉴 라벨 1개 — i18n key grep
SC-5 퀘스트 100% 완료 시 hide — Q1~Q10 manual 완료 후 7일 지나도록 시간 mock
SC-6 퀘스트 100% = 게이지 100% — 테스트 통과 확인 (W5 Task 5.5)
SC-7 마이그레이션 무손실 — 3 시나리오 테스트 통과 확인 (W1 Task 1.4)
```

- [ ] **Step 4**: Phase 6 평가 (rubric)

| 기준 | 가중치 | 점수 (자가) | 근거 |
|---|---|---|---|
| 완성도 | 40% | TBD | SC-1~7 통과 |
| 견고성 | 30% | TBD | 마이그레이션 3 시나리오 + 게이지 정합성 3 시나리오 |
| 일관성 | 20% | TBD | 도메인 린터/UX 룰/glossary 위반 0건 |
| 간결성 | 10% | TBD | 새 화면 3개 + 1개 라우트 deprecated + 800줄 초과 0 |

PASS 조건: 가중 평균 7.5+ AND 최소 점수 5+ 모두.

- [ ] **Step 5**: 마스터 스펙 머지 (spec §12)

| 마스터 스펙 | 갱신 |
|---|---|
| `docs/specs/profile/profile_master.md` | §2 메뉴 5묶음 IA + §3 화면 목록 갱신 |
| `docs/specs/schedule/availability_settings_ux_redesign_spec.md` | "운영시간" 라벨 + SSOT 명시 |
| `docs/specs/design/settings_information_architecture_spec.md` | 5묶음 IA 채택 |
| `docs/specs/design/teacher_quest_audit_2026-06-08.md` | 졸업 메커니즘 추가 |
| `docs/specs/onboarding/teacher_first_availability_setup.md` | Step 2.5 추가 |
| `docs/specs/subscription/lesson_policy_settings.md` | 시험 레슨 정책 위치 (O1) |
| `docs/specs/glossary.md` | `.harness/knowledge/glossary.md` §14 사용자 열람용 부분 복사 |

```bash
git commit -m "docs(specs): teacher-settings-redesign — 마스터 스펙 머지 (Phase 6 PASS)"
```

---

## 위험 및 완화

| 위험 | 영향 | 완화 |
|---|---|---|
| 마이그레이션 실패 (기존 선생님 데이터 손실) | 높음 | 테스트 3 시나리오 + 백엔드 API 변경 X → 로컬 데이터만 변경 |
| Q1~Q10 100% 완료 판정 실수로 졸업 | 중 | `User.questGraduatedAt` BE 영속 + 7일 grace |
| ProfileTab 5묶음 재배치로 기존 메뉴 missing | 중 | i18n hardcoded grep + 통합 스크린샷 회귀 |
| W1 머지 지연으로 W2/W3/W5 블로킹 | 중 | W1 우선 dispatch + 검토 ultra 모드 |
| `lesson_time_settings_screen.dart` 삭제 시 의존 코드 잔재 | 낮음 | W3 Task 3.5 의 grep 0 hit 검증 |

---

## 다음 단계

1. **사용자 PLAN 검토** — O1~O8 결정 변경 의견 받기
2. **PLAN 승인 시** — W0 → W1 시작 (`EnterWorktree`)
3. **W1 PR 머지** → W2/W3/W5 병렬 dispatch
4. **W2 머지** → W4 dispatch
5. **W2+W4 머지** → W6 dispatch
6. **모든 worktree PR 머지 후 통합 회귀** → Phase 6 평가 → 마스터 스펙 머지
