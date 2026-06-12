# AC Tree — 학생 게이미피케이션 P2 Visual Growth

> 최종 갱신: 2026-06-12 — **모든 AC passed** (Job 10 Task 10.2 베타 게이트 통과)
> 누적 테스트: 224/224 PASS, analyze 0 issue
> 베타 게이트 grep: SC-4 origin 라벨 0건, Trophy 카테고리 라벨 0건, 한글 하드코딩 0건
> 스펙: `.harness/spec/2026-06-11-student-gamification.md` (§6.3 GrowthHeatmap + §6.5 StreakFreeze + §9.4/§14 안티-피로 + §17 비기능 + §18.3 마이그레이션)
> 플랜: `.harness/decomposition/2026-06-11-student-gamification-p2-visual-growth.md`
> 상태 어휘: `pending` | `in_progress` | `passed` | `failed`

---

## AC-0 [P2 Visual Growth] 전체 기능 (passed)
- **설명**: 학생이 자기 진척을 시각적으로 확인 (1년 히트맵 + 트로피) + 스트릭 안티-피로 (StreakFreeze) + 30분 휴식 권고. P1 의 PracticeRecordingService 결과를 Hive 13 box chunk 로 1년 캐시, P95 < 500ms 응답.
- **만족 조건**: AC-1 ~ AC-7 모두 `passed`
- **담당 job**: 전체 (Job 0 ~ Job 10)

### AC-1 [도메인 모델] StreakFreeze entity (passed)
- **만족 조건**: AC-1.1 ~ AC-1.3 모두 `passed`
- **담당 job**: Job 1

  #### AC-1.1 [entity] StreakFreeze 5 필드 + 불변 + json round-trip (passed)
  - **만족 조건**: balance/usedAt/examModeUntil 보존 + clamp 0-4 + canApply getter
  - **담당 job**: Job 1 Task 1.1
  - **관련 테스트**: `test/features/gamification/domain/entities/streak_freeze_test.dart`

  #### AC-1.2 [Hive 직렬화 전략] Box<String> + JSON 채택 — TypeAdapter 0 (passed)
  - **만족 조건**: Box name `streak_freeze_v1` 정책 명시 + 신규 TypeAdapter 등록 0 + Job 3 Task 3.3 에서 빈 box 첫 진입 정상 처리
  - **담당 job**: Job 1 Task 1.2 (정책 결정 완료) + Job 3 Task 3.3 (실제 구현)
  - **관련 테스트**: `test/features/gamification/data/repositories/hive_streak_freeze_repository_test.dart::test_emptyBoxFirstEntry` (Job 3 에서 작성)
  - **결정 trail**: Job 1 Task 1.2 정책 변경 (2026-06-12) — Task 2.1 GrowthHeatmapChunkCache 와 JSON 직렬화 일관성

  #### AC-1.3 [글로서리] StreakFreeze/FreezeBalance/ExamMode/ComebackBonus 등록 (passed)
  - **만족 조건**: `.harness/knowledge/glossary.md` + `docs/specs/glossary.md` 동기화
  - **담당 job**: Job 0 Step 2

### AC-2 [성능] GrowthHeatmap 1년 캐시 P95 < 500ms (passed)
- **만족 조건**: AC-2.1 ~ AC-2.3 모두 `passed`. 스펙 §17.
- **담당 job**: Job 2

  #### AC-2.1 [chunk 매핑] chunkIndex(date) 결정적 30일 단위 (passed)
  - **만족 조건**: epoch 기준 boundary 정확 (day 29 / day 30 분리)
  - **담당 job**: Job 2 Task 2.1
  - **관련 테스트**: `test/features/gamification/data/services/growth_heatmap_chunk_cache_test.dart::test_chunkIndex_boundary`

  #### AC-2.2 [캐시 적중] 13 box read = 1년 데이터 병합 (passed)
  - **만족 조건**: `loadYear(studentId, asOf)` 13 chunk 병합 결과 = `Map<DateTime, DailyPractice>` 365 키
  - **담당 job**: Job 2 Task 2.1
  - **관련 테스트**: `test/features/gamification/data/services/growth_heatmap_chunk_cache_test.dart::test_loadYear`

  #### AC-2.3 [invalidation 격리] upsertDay 단일 chunk write (passed)
  - **만족 조건**: `upsertDay` 호출 시 해당 chunk box 만 write. 다른 12 chunk untouched
  - **담당 job**: Job 2 Task 2.1
  - **관련 테스트**: chunk write count assertion

### AC-3 [데이터 레이어] StreakFreezeRepository CRUD (passed)
- **만족 조건**: AC-3.1 ~ AC-3.3 모두 `passed`
- **담당 job**: Job 3

  #### AC-3.1 [인터페이스] 4 메서드 정의 (getOrCreate, grantWeekly, apply, setExamMode) (passed)
  - **만족 조건**: `flutter analyze` 0 issue + 인터페이스 컴파일
  - **담당 job**: Job 3 Task 3.1

  #### AC-3.2 [Mock 구현] 메모리 저장소 4 메서드 검증 (passed)
  - **만족 조건**: 단위 테스트 5/5 통과 (clamp, examMode 분기 포함)
  - **담당 job**: Job 3 Task 3.2

  #### AC-3.3 [Hive 구현] 학생별 단일 record + 빈 box 정상 init (passed)
  - **만족 조건**: 첫 진입 시 balance=0, usedAt=[], examModeUntil=null + grantWeekly 후 영속
  - **담당 job**: Job 3 Task 3.3
  - **관련 테스트**: `test/features/gamification/data/repositories/hive_streak_freeze_repository_test.dart`

### AC-4 [도메인 서비스] StreakFreezeService 자동 발급/적용 (passed)
- **만족 조건**: AC-4.1 ~ AC-4.4 모두 `passed`. **SC-10 (스펙 §2)** 충족.
- **담당 job**: Job 4

  #### AC-4.1 [자동 발급] Sunday 00:00 KST → +2, max 4 (passed)
  - **만족 조건**: weeklyGrantIfDue 결정적. 이번 주 grant 후 재호출 no-op
  - **담당 job**: Job 4 Task 4.1
  - **관련 테스트**: `test/features/gamification/domain/services/streak_freeze_service_test.dart::test_weeklyGrant`

  #### AC-4.2 [자동 적용] 결석일 freeze 1개 차감 (passed)
  - **만족 조건**: applyOnAbsence balance -1 + usedAt 추가. balance=0 → no-op
  - **담당 job**: Job 4 Task 4.1
  - **관련 테스트**: `::test_applyOnAbsence`

  #### AC-4.3 [시험 모드] examModeUntil 활성 동안 차감 0 (passed)
  - **만족 조건**: examMode 활성 → applyOnAbsence no-op
  - **담당 job**: Job 4 Task 4.1
  - **관련 테스트**: `::test_examMode_blocks_apply`

  #### AC-4.4 [Riverpod provider] StreakFreezeNotifier (passed)
  - **만족 조건**: build + grantWeekly/apply/setExamMode 메서드 + codegen 통과
  - **담당 job**: Job 4 Task 4.2

### AC-5 [통합 + 마이그레이션] practice_streak + StreakFreeze (passed)
- **만족 조건**: AC-5.1 ~ AC-5.3 모두 `passed`
- **담당 job**: Job 5

  #### AC-5.1 [streak 통합] 결석 + freeze 차감 시 streak 유지 (passed)
  - **만족 조건**: 4 시나리오 (활동+balance2 / 결석+balance2 / 결석+balance0 / 결석+examMode) 모두 검증
  - **담당 job**: Job 5 Task 5.1
  - **관련 테스트**: `test/features/practice/presentation/providers/practice_streak_provider_test.dart`

  #### AC-5.2 [D-day 마이그레이션] 1회 실행 + flag idempotent (passed)
  - **만족 조건**: 모든 학생 balance=2 + 재실행 시 no-op + flag 영속
  - **담당 job**: Job 5 Task 5.2
  - **관련 테스트**: `test/features/gamification/data/services/streak_freeze_migration_test.dart`

  #### AC-5.3 [안내 토스트] 학생당 1회 표시 + dismiss flag (passed)
  - **만족 조건**: 토스트 노출 후 Hive `streak_freeze_migration_toast_shown` 영속. 재진입 무노출
  - **담당 job**: Job 5 Task 5.2
  - **관련 테스트**: 통합 위젯 테스트

### AC-6 [UI] 1년 히트맵 + 트로피 + 더 보기 화면 (passed)
- **만족 조건**: AC-6.1 ~ AC-6.4 모두 `passed`
- **담당 job**: Job 6, 7, 9

  #### AC-6.1 [YearHeatmapGrid] 365 칸 + 5단계 색 + 색맹 친화 (passed)
  - **만족 조건**: 가로 스크롤 + 12달 365 칸 정확 + 0/1-15/16-30/31-60/61+ 분 색 매핑 + 패턴 텍스처
  - **담당 job**: Job 6 Task 6.1
  - **관련 테스트**: `test/features/gamification/presentation/widgets/year_heatmap_grid_test.dart`

  #### AC-6.2 [HeatmapDayDetailSheet] 셀 tap → 일별 분해 (passed)
  - **만족 조건**: metronome/tuner/youtube/manual 분 + 녹음 수 표시
  - **담당 job**: Job 6 Task 6.2

  #### AC-6.3 [TrophyCollectionCard] 카테고리 분류 노출 0 (passed)
  - **만족 조건**: `Text("카테고리")` / 카테고리명 직접 grep 0건 + 빈 상태 메시지 ("곧 첫 트로피!")
  - **담당 job**: Job 7 Task 7.1
  - **관련 테스트**: 위젯 smoke test + grep 자동 검증

  #### AC-6.4 [StudentGrowthDetailScreen] 통합 + 점점점 라우팅 (passed)
  - **만족 조건**: PracticeStartSection 점점점 탭 → `context.go('/student/growth-detail')` (spy mock) + P3/P4 placeholder 영역에 NO-OP 버튼 0개
  - **담당 job**: Job 9
  - **관련 테스트**: 통합 위젯 테스트 (spy mock 패턴)

### AC-7 [SC-11 휴식 권고] 30분 토스트 + 14세 미만 분기 (passed)
- **만족 조건**: AC-7.1 ~ AC-7.3 모두 `passed`. **SC-11 (스펙 §2)** 충족.
- **담당 job**: Job 8

  #### AC-7.1 [세션 30분] 토스트 1회 (반복 0) (passed)
  - **만족 조건**: 29/30/31분 호출 → 1회만 노출
  - **담당 job**: Job 8 Task 8.1
  - **관련 테스트**: `test/features/practice/presentation/widgets/rest_recommendation_toast_test.dart`

  #### AC-7.2 [일일 누적 3시간] 별도 차분 토스트 1회 (passed)
  - **만족 조건**: 같은 날 반복 0 (Hive `lastShownDate`)
  - **담당 job**: Job 8 Task 8.1

  #### AC-7.3 [14세 미만 분기] 15분 임계값 강화 (passed)
  - **만족 조건**: Student.birthDate < 14년 → 15분 도달 시 토스트
  - **담당 job**: Job 8 Task 8.1
  - **관련 테스트**: `::test_14_under_threshold`

### AC-8 [E2E + 출시 게이트] (passed)
- **만족 조건**: AC-8.1 ~ AC-8.4 모두 `passed`
- **담당 job**: Job 10

  #### AC-8.1 [E2E A] 스트릭 7일 + 8일째 결석 → freeze 차감 + streak 유지 (passed)
  - **만족 조건**: integration_test 시나리오 A 통과
  - **담당 job**: Job 10 Task 10.1
  - **관련 테스트**: `integration_test/student_gamification_p2_e2e_test.dart::scenario_a`

  #### AC-8.2 [E2E B] 1년 히트맵 + 트로피 + P95 < 500ms (passed)
  - **만족 조건**: integration_test 시나리오 B 통과 + perf 측정 결과 ≤ 500ms (P99 ≤ 1000ms)
  - **담당 job**: Job 10 Task 10.1 + Task 10.2 Step 4
  - **관련 테스트**: `::scenario_b`

  #### AC-8.3 [E2E C] 30분 토스트 1회 + 14세 미만 15분 (passed)
  - **만족 조건**: integration_test 시나리오 C 통과
  - **담당 job**: Job 10 Task 10.1
  - **관련 테스트**: `::scenario_c`

  #### AC-8.4 [회귀 + grep] 전체 flutter test 통과 + SC-4 라벨 0건 (passed)
  - **만족 조건**: `flutter test` 0 fail + `flutter analyze` 0 issue + P1 e2e (#690) 회귀 + `grep -E "Text\(.*origin\.|Text\(.*Origin\."` 0건
  - **담당 job**: Job 10 Task 10.2 Step 5-6

---

## 상태 전파 규칙

- 자식이 모두 `passed` → 부모를 `passed` 로 승격
- 자식 중 하나라도 `failed` → 부모도 `failed`
- 자식 중 하나라도 `in_progress` → 부모를 `in_progress`
- 리프(leaf) AC 만 관련 테스트에 바인딩 (중간 노드는 집계 전용)

## SC 매핑

| SC | 정의 (스펙 §2) | 검증 AC |
|---|---|---|
| SC-10 | Streak freeze 자동 발급 주 2회 (Sunday 00:00 KST 자동 +2, max 4) | AC-4.1 + AC-8.1 |
| SC-11 | 연습 30분 초과 휴식 권고 토스트 (sessionMinutes > 30 시 1회, 푸시 X) | AC-7.1 + AC-8.3 |
| SC-12 (부분) | 신규 엔티티 5개 — P2 에서 StreakFreeze 추가 (P1 누적 4/5) | AC-1.1 |
| 비기능 §17 | 히트맵 1년 P95 < 500ms / P99 < 1000ms | AC-8.2 |
| 비기능 §17 | Hive 캐시 (StreakFreeze, LeaderboardPreferences 로컬) | AC-1.2 + AC-3.3 |

## 변경 이력

| 날짜 | 변경 | 비고 |
|---|---|---|
| 2026-06-12 | 초안 작성 | Job 0~10 decomposition 1:1 매핑 |
