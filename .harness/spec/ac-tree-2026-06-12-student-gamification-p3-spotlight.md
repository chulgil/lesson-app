# AC Tree — 학생 게이미피케이션 P3 Spotlight

> 최종 갱신: 2026-06-12 — **모든 AC passed** (Job 9 베타 게이트 통과)
> 누적 테스트 (P3 신규): 110+ PASS / gamification 전체: 316/316 PASS / analyze 0 issue
> 베타 게이트 grep: 푸시 알림 호출 0건, SC-4 origin 라벨 0건, 메시징 §7.4 위반 0건
> 스펙: `.harness/spec/2026-06-11-student-gamification.md` (§5.2 + §6.2 + §7 + §9.1 + §10.2 + §17)
> 플랜: `.harness/decomposition/2026-06-12-student-gamification-p3-spotlight.md`
> 상태 어휘: `pending` | `in_progress` | `passed` | `failed`

---

## AC-0 [P3 Spotlight] 전체 기능 (passed)
- **설명**: 학생 축하 overlay 안 1슬롯에 가끔(주 1-2회) Spotlight prompt 표시. "지금 볼래"/"다음에" 동등 비중. 거절 학습 (7일 cooldown → 5회 시 8주 hide → 6회 시 영구 hide). 푸시 알림 0건. 14세 미만 부모 동의 X 시 일괄 hide (P4 의존 안전 분기).
- **만족 조건**: AC-1 ~ AC-8 모두 `passed`
- **담당 job**: 전체 (Job 0 ~ Job 9)

### AC-1 [도메인 모델] SpotlightPrompt entity + SpotlightType (passed)
- **만족 조건**: AC-1.1 ~ AC-1.3 모두 `passed`
- **담당 job**: Job 1

  #### AC-1.1 [enum] SpotlightType 3종 + fromName 안정 직렬화 (passed)
  - **만족 조건**: teacherRec / seasonEvent / routineSuggestion + unknown 시 ArgumentError
  - **담당 job**: Job 1 Task 1.1
  - **관련 테스트**: `test/features/gamification/domain/entities/spotlight_type_test.dart` (4/4)

  #### AC-1.2 [entity] SpotlightPrompt 12 필드 + priority + isHiddenAt + JSON round-trip (passed)
  - **만족 조건**: priority §7.2 (mandatory=0/teacher=10/season=20/routine=30) + isHiddenAt (permanent or hideUntil>now) + copyWith clearHideUntil/clearLastShownAt
  - **담당 job**: Job 1 Task 1.2
  - **관련 테스트**: `test/features/gamification/domain/entities/spotlight_prompt_test.dart` (15/15)

  #### AC-1.3 [글로서리] SpotlightPrompt + SpotlightType + 정책 용어 7종 등록 (passed)
  - **만족 조건**: `.harness/knowledge/glossary.md` §15 P3 섹션 + `docs/specs/glossary.md` §13 동기화
  - **담당 job**: Job 0 Step 2

### AC-2 [데이터 레이어] SpotlightPromptRepository (passed)
- **만족 조건**: AC-2.1 ~ AC-2.3 모두 `passed`
- **담당 job**: Job 2

  #### AC-2.1 [인터페이스] 7 메서드 (enqueue / listForStudent / getById / markShown / incrementDecline / setHideUntil / markPermanentlyHidden) (passed)
  - **만족 조건**: `flutter analyze` 0 issue
  - **담당 job**: Job 2 Task 2.1

  #### AC-2.2 [Mock 구현] in-memory + 20ms latency 시뮬 + unknown id throw (passed)
  - **만족 조건**: 8 round-trip + cross-student isolation + StateError on missing
  - **담당 job**: Job 2 Task 2.2
  - **관련 테스트**: `test/features/gamification/data/repositories/mock_spotlight_prompt_repository_test.dart` (8/8)

  #### AC-2.3 [Hive 구현] Box<String> + JSON + key prefix scan + corrupted decode resilience (passed)
  - **만족 조건**: `spotlight_prompt_v1` 단일 box / key `{studentId}::{id}` / 다른 학생 record 누출 0 / corrupted JSON 한 key skip
  - **담당 job**: Job 2 Task 2.3
  - **관련 테스트**: `test/features/gamification/data/repositories/hive_spotlight_prompt_repository_test.dart` (9/9)

### AC-3 [노출 조건] SpotlightEligibilityService §7.1 (passed)
- **만족 조건**: AC-3.1 ~ AC-3.3 모두 `passed`
- **담당 job**: Job 3

  #### AC-3.1 [순수 함수] SpotlightEligibilityContext → SpotlightEligibilityResult (passed)
  - **만족 조건**: 7 입력 → eligible/reason 결정적 평가
  - **담당 job**: Job 3
  - **관련 테스트**: `test/features/gamification/domain/services/spotlight_eligibility_service_test.dart` (14/14)

  #### AC-3.2 [6 조건 단조 평가] session 5분 / daily=1 / weekly=2 / queue / 14세분기 (passed)
  - **만족 조건**: 거절 사유 reason 노출 (session_too_short / daily_cap_hit / weekly_cap_hit / queue_empty / parent_consent_required)
  - **담당 job**: Job 3

  #### AC-3.3 [14세 미만 안전 분기] !hasParentConsent → deny (passed)
  - **만족 조건**: hasParentConsent=true 면 14세 미만도 allow (P4 부모 동의 시스템 호환)
  - **담당 job**: Job 3

### AC-4 [큐 우선순위] SpotlightQueueService §7.2 (passed)
- **만족 조건**: AC-4.1 ~ AC-4.3 모두 `passed`
- **담당 job**: Job 4

  #### AC-4.1 [우선순위 정렬] priority asc + queuedAt asc tie-break (passed)
  - **만족 조건**: mandatory teacherRec > 일반 teacherRec > seasonEvent > routineSuggestion
  - **담당 job**: Job 4
  - **관련 테스트**: `test/features/gamification/domain/services/spotlight_queue_service_test.dart` (13/13)

  #### AC-4.2 [hidden filter] isHiddenAt 자동 필터 (passed)
  - **만족 조건**: hideUntil > now 또는 permanentlyHidden 인 prompt skip + 다른 후보 fallback

  #### AC-4.3 [cross-student isolation] (passed)
  - **만족 조건**: listForStudent prefix scan 결과만 평가

### AC-5 [거절 학습] SpotlightDeclineLearningService §7.3 / SC-9 (passed)
- **만족 조건**: AC-5.1 ~ AC-5.4 모두 `passed`
- **담당 job**: Job 5

  #### AC-5.1 [1~4회 거절] 7일 cooldown (passed)
  - **만족 조건**: 거절 prompt 만 setHideUntil(now + 7d)
  - **담당 job**: Job 5
  - **관련 테스트**: `test/features/gamification/domain/services/spotlight_decline_learning_service_test.dart` (12/12)

  #### AC-5.2 [5회 거절] 8주 hide — 같은 type 모든 prompt (passed)
  - **만족 조건**: setHideUntil(now + 56d) — type 전체 hide (스펙 §5.2 "해당 type")
  - **담당 job**: Job 5

  #### AC-5.3 [6회 거절] 영구 hide — 같은 type 모든 prompt (passed/SC-9)
  - **만족 조건**: markPermanentlyHidden — type 전체 permanent (학생 재활성은 P4)
  - **담당 job**: Job 5

  #### AC-5.4 [type 격리] 다른 type / 다른 학생 카운터 영향 0 (passed)
  - **만족 조건**: teacherRec 5회 ≠ seasonEvent 카운터, 학생 간 카운터 격리

### AC-6 [Riverpod Provider] SpotlightProvider + currentSpotlightForCelebration (passed)
- **만족 조건**: AC-6.1 ~ AC-6.2 모두 `passed`
- **담당 job**: Job 6

  #### AC-6.1 [provider 등록] 4 keepAlive provider (repo / eligibility / queue / declineLearning) (passed)
  - **만족 조건**: Mock 우선 + provider override 패턴
  - **담당 job**: Job 6

  #### AC-6.2 [통합 평가] Queue → Eligibility → null/candidate 반환 (passed)
  - **만족 조건**: KST 자정/월요일 기준 daily/weekly 카운터 도출 + 6 시나리오 통과
  - **담당 job**: Job 6
  - **관련 테스트**: `test/features/gamification/presentation/providers/spotlight_provider_test.dart` (8/8)

### AC-7 [UI 통합] PracticeCelebrationOverlay Spotlight 슬롯 (passed)
- **만족 조건**: AC-7.1 ~ AC-7.3 모두 `passed`
- **담당 job**: Job 7

  #### AC-7.1 [SpotlightSlot 위젯] 3 type 헤더 + 동등 비중 버튼 + §7.4 메시징 (passed)
  - **만족 조건**: AppStrings 5 SSOT + Expanded 동일 폭 + "꼭 해야"/"필수" 미노출 grep
  - **담당 job**: Job 7 Task 7.1
  - **관련 테스트**: `test/features/gamification/presentation/widgets/spotlight_slot_test.dart` (9/9)

  #### AC-7.2 [PracticeCelebrationOverlay surgical 확장] spotlightPrompt null → 회귀 0 (passed)
  - **만족 조건**: prompt=null 시 P1 SC-1 5초 게이트 회귀 (기존 5/5 테스트 PASS)
  - **담당 job**: Job 7 Task 7.2

  #### AC-7.3 [통합 흐름] 1.5초 축하 → SpotlightSlot phase → accept/decline → onDismiss (passed)
  - **만족 조건**: 콜백 호출 + dismiss 1회 + slot 표시 동안 dismiss 보류
  - **담당 job**: Job 7 Task 7.2
  - **관련 테스트**: `practice_celebration_overlay_test.dart::P3 SpotlightSlot 통합` (5/5)

### AC-8 [큐 시드 + 베타 게이트] SpotlightSeedingService + SC-9 검증 (passed)
- **만족 조건**: AC-8.1 ~ AC-8.4 모두 `passed`
- **담당 job**: Job 8 + Job 9

  #### AC-8.1 [3 generator] teacherRec / seasonEvent / routineSuggestion + deterministic id (passed)
  - **만족 조건**: 중복 차단 (`teacher_rec:{id}` / `season:{key}` / `routine:{studentId}`) + isMandatory 옵션
  - **담당 job**: Job 8
  - **관련 테스트**: `test/features/gamification/domain/services/spotlight_seeding_service_test.dart` (13/13)

  #### AC-8.2 [routineSuggestion P3 placeholder] recentStreakDays >= 30 시 1회 시드 (passed)
  - **만족 조건**: < 30 → no-op, 학생당 1 record (재시드 시 false), 정밀 패턴 분석은 P4
  - **담당 job**: Job 8

  #### AC-8.3 [SC-9 베타 게이트] 거절 5회 → 8주 hide + 6회 → 영구 hide (passed)
  - **만족 조건**: AC-5.2 + AC-5.3 + 단위 테스트 boundary 검증
  - **담당 job**: Job 9

  #### AC-8.4 [비기능 게이트] 푸시 알림 0건 / origin 라벨 0건 / §7.4 메시징 0건 (passed)
  - **만족 조건**: grep 검증 3건 (FirebaseMessaging/sendPush 0건, Text(.*origin) 0건, "꼭 해야"/"필수입니다" UI 0건)
  - **담당 job**: Job 9 grep 검증 (2026-06-12)

---

## 검증 grep 명령 (Job 9 베타 게이트)

```bash
# 푸시 알림 호출 0건
grep -rn "FirebaseMessaging\|sendPush\|fcm.send\|pushNotification" \
  frontend/lib/features/gamification/ --include="*.dart"

# origin 라벨 누출 0건 (SC-4)
grep -rn -E "Text\(.*origin\.|Text\(.*Origin\." \
  frontend/lib/features/gamification/presentation/ --include="*.dart"

# 메시징 §7.4 위반 0건 (UI 텍스트 — 코드 주석 제외)
grep -rn "꼭 해야\|필수입니다" \
  frontend/lib/features/gamification/ --include="*.dart" | grep -v "^.*///"
```

모두 0건 (실측 2026-06-12 — spotlight_slot.dart 의 doc comment 안 §7.4 규칙 설명만 hit, UI 텍스트 0건).

---

## 누적 테스트 카운트 (P3 신규)

| Job | 테스트 파일 | PASS |
|---|---|---|
| Job 1 Task 1.1 | spotlight_type_test.dart | 4 |
| Job 1 Task 1.2 | spotlight_prompt_test.dart | 15 |
| Job 2 Task 2.2 | mock_spotlight_prompt_repository_test.dart | 8 |
| Job 2 Task 2.3 | hive_spotlight_prompt_repository_test.dart | 9 |
| Job 3 | spotlight_eligibility_service_test.dart | 14 |
| Job 4 | spotlight_queue_service_test.dart | 13 |
| Job 5 | spotlight_decline_learning_service_test.dart | 12 |
| Job 6 | spotlight_provider_test.dart | 8 |
| Job 7 Task 7.1 | spotlight_slot_test.dart | 9 |
| Job 7 Task 7.2 | practice_celebration_overlay_test.dart (P3 추가) | 5 |
| Job 8 | spotlight_seeding_service_test.dart | 13 |
| **누적 P3** | **11 파일** | **110** |
| **gamification 전체** | (P1 + P2 + P3) | **316** |

---

## 후속 P4 차단점

- 영구 hide 후 학생 옵션에서 명시적 재활성 UI (스펙 §7.3)
- routineSuggestion 정밀 패턴 분석 (자가 routine 30일+ 시점 + 변형 패턴 자동 추출)
- 14세 미만 부모 동의 흐름 (P4 §9.2) — SpotlightEligibilityService 의 hasParentConsent 가 실제 동의 시점 반영
- LeaderboardPreferences + 비교 보기 + 글로벌 익명 (스펙 §6.4 / §9.3)
- Spotlight "1주 이내 queued" 만료 정책 (스펙 §7.2 #2) — 현재는 Seeding service 가 시드 시 만료 갱신, P4 에서 정밀 정책 검토
