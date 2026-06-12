# 학생 게이미피케이션 — 1년 retention 자가 연습 시스템 스펙

> 작성일: 2026-06-11
> 스펙: locked at commit 6262f03d (PR #680 merged 2026-06-11)
> P1 머지: PR #683 (85584f0a), #687 (b8582df6), #689 (50a709f2), #690 (1a74efc7)
> P2 진입: main @ 7069665f (2026-06-12) — `.harness/decomposition/2026-06-11-student-gamification-p2-visual-growth.md`
> 단계: cg-harness Phase 2 — 스펙 초안 (Phase 6 통과 후 마스터 스펙으로 머지)
> 입력 자료:
> - [`docs/specs/gamification/gamification_master.md`](../../docs/specs/gamification/gamification_master.md) (2026-04-17 Phase 1~3 완료, 기존 인프라)
> - [`docs/specs/_archive/old/gamification_spec.md`](../../docs/specs/_archive/old/gamification_spec.md) (2026-03-11 원안)
> - [`docs/specs/student_home/student_home_master.md`](../../docs/specs/student_home/student_home_master.md) (2026-03-07 학생 홈 10섹션)
> - [`docs/specs/design/teacher_quest_audit_2026-06-08.md`](../../docs/specs/design/teacher_quest_audit_2026-06-08.md) (선생님 quest 와 분리 원칙)
> 글로서리: [`.harness/knowledge/glossary.md`](../knowledge/glossary.md)
> 시장조사: 2026-06-11 deep-research workflow — 26 출처, 학술 5건 인용 (Springer 2024 §11528, PMC12658397, PMC11769689, arxiv 2512.15630, arxiv 2203.16175)

---

## 1. 배경 — 자가 연습 시간이 80%인데 시스템은 선생님 과제 중심

### 1.1 현실 진단

학생의 주간 연습 시간 분포:

| Practice 종류 | 빈도 | 누가 결정 |
|---|---|---|
| 선생님이 명시적으로 할당한 과제 | 1-2회 (레슨 직후) | 선생님 |
| 학생이 레슨 메모로 self-derive | 매일 | 학생 (선생님 힌트 참고) |
| 학생 개인 목표 (이 곡 해보고 싶다) | 매일 | 학생 |
| 일상 routine (스케일 5분 등) | 매일 | 학생 (습관) |
| YouTube 탐색·반복재생 | 주 2-3회 | 학생 |

**~80% 의 연습 시간은 학생 자기 결정.** 현재 시스템(선생님 quest 보드, practice_assignments)은 작은 일부만 다룬다.

### 1.2 1년 retention 목표 — 학술 근거

1년 지속 동기는 통제적 외부 보상으로 만들어지지 않는다. 음악 학습 SDT 연구 (Springer 2024 §11528 §11528) 가 직접 경고: 통제적 교사 + 정밀도 강조 + 잦은 평가 환경에서는 음악의 아름다움을 위해 시작한 아동조차 외부 규제로 퇴행하여 외부 압력이 사라지면 그만둘 수 있다.

청소년 게이밍 연구 (PMC12658397):
- 유능감(competence) 만족이 retention 과 가장 강한 상관 (r=0.182~0.308)
- 사회적 연결(관계성) 효과 가장 큼 (g=0.67)
- 욕구 좌절(NF) > 욕구 만족(NS) — gaming disorder 마커
- 한국 청소년 IGD 유병률 9.9% (홍콩 15.6%)

성장 마인드셋 1년 추적 (PMC11769689): 자기 통제력에 대한 성장 믿음은 gaming disorder 감소 (b=0.070, p=.006) → 메시징 직접 시사.

### 1.3 UX 문제 — 복잡하면 학생이 앱을 외면

학생이 매번 "오늘 뭘 할까?" quest 카드 결정 부담을 가지면:
- Hick's Law 위반: 매번 인지 부하
- 결정 마찰 → 연습 시작 자체가 friction
- 결국 메트로놈만 쓰고 게이미피케이션은 외면
- 1년 retention 실패

따라서 **앱 = 연습 도구**, 게이미피케이션 = 자동 백그라운드 + 짧은 축하 (Strava 모델).

---

## 2. 성공 기준

| # | 기준 | 측정 |
|---|---|---|
| SC-1 | 학생이 quest 를 "결정" 하지 않고도 시스템이 자동 기록·축하 | 홈 첫 탭 후 5초 안에 연습 시작 가능 (결정 단계 0) |
| SC-2 | 1년 retention D365 ≥ 30% (D7 60%, D30 45%) | 5단계 retention 곡선 6개월 후 측정 |
| SC-3 | 자가 연습 (메트로놈/튜너/YouTube/수동) 4 경로 모두 record() 통합 | PracticeService 단일 진입점 |
| SC-4 | 학생이 quest 출처(선생님·시스템·자작)를 의식하지 않음 | 학생 UI 에 origin 라벨 노출 0개 (detail view 제외) |
| SC-5 | 14세 미만 부모 동의 미완료 시 경쟁 레이어 자동 hide | 부모 동의 confirmedAt 필드 검증 |
| SC-6 | 푸시 알림 0건 | 알림 시스템 비활성 + 첫 onboarding 시 안내 |
| SC-7 | 글로벌 익명 리더보드 실명·프로필 사진 노출 0건 | 닉네임만 보임, 이미지 fallback 추상 아바타 |
| SC-8 | "랭킹 N등" 표시 0개 — 티어만 (Gold/Silver/Bronze) | 모든 leaderboard 컴포넌트 |
| SC-9 | Spotlight prompt 거절 5회 후 자동 hide | promptDeclineCount ≥ 5 시 8주 cooldown |
| SC-10 | Streak freeze 자동 발급 주 2회 | Sunday 00:00 KST 자동 +2 (max 4) |
| SC-11 | 연습 30분 초과 시 휴식 권고 토스트 | sessionMinutes > 30 시 1회 표시, 푸시 X |
| SC-12 | 기존 인프라 (WeeklyRanking, Challenge, point_award_service) 재사용, 신규 엔티티 5개 | 기존 코드 변경 최소화 |

---

## 3. 핵심 철학 — "Strava 모델"

> **앱 = 연습 도구. 게이미피케이션 = 자동 백그라운드 + 1.5초 축하.**

| 원칙 | 적용 |
|---|---|
| **자가 결정 우선 (SDT 자율성)** | 학생이 "연습 시작" → 그 외 결정 부담 0. quest 출처 라벨 X |
| **유능감 가시화 (PMC12658397 r=0.182-0.308)** | 히트맵·스트릭·트로피 = 매번 진척 가시 |
| **관계성 옵션 (PMC12658397 g=0.67)** | 비교 보기 OFF 디폴트, 학생이 켤 때만 친구/학원/세계 등장 |
| **NF 회피 (gaming disorder 마커)** | 푸시 X, 강요 X, 거절 페널티 0, 옵트아웃 즉시 |
| **성장 마인드셋 메시징 (PMC11769689 b=0.070)** | "12분 했어요", "어제보다 5분 더" — "이긴다" X |

---

## 4. UX — Strava 모델 화면 흐름

### 4.1 홈 (앱 첫 진입)

```
┌─────────────────────────────────────┐
│       🎵 {이름}의 연습                │
│                                       │
│        🔥 {N}일 (작은 텍스트)          │
│                                       │
│      ┌───────────────────┐           │
│      │   ▶ 연습 시작        │           │
│      └───────────────────┘           │
│                                       │
│      어제 {N}분 했어요                 │
│                                       │
│      · · ·  (더 보기, 작게)            │
└─────────────────────────────────────┘
```

- Hick's Law: 큰 버튼 1개, 결정 0개
- 스트릭 한 줄, 어제 한 줄 — 시각 노이즈 최소
- 더 보기 = 점점점, 호기심 있는 학생만 탭

### 4.2 연습 화면 (Practice Mode)

기존 메트로놈/튜너/YouTube/녹음 UI 거의 그대로 + 자동 트래킹:

```
┌─────────────────────────────────────┐
│  [×]                       {타이머}   │
│                                       │
│       ♩ 120 BPM                     │
│      ●●●●●●●●                       │
│   ─── 메트로놈 컨트롤 ───              │
│                                       │
│   탭: [튜너] [영상] [녹음]              │
└─────────────────────────────────────┘
```

- 좌상단 [×] = 연습 끝내기
- 우상단 timer = 이번 세션 누적 (passive)
- 학생이 UI를 의식하지 않음 — 평소 메트로놈 사용처럼

### 4.3 축하 화면 (1.5초 자동 fade)

```
┌─────────────────────────────────────┐
│              ✨                       │
│         {N}분 했어요!                 │
│         🔥 {N}일 연속                  │
│   (1.5초 후 자동 fade → 홈)            │
└─────────────────────────────────────┘
```

가끔 (주 1-2회) Spotlight prompt 1슬롯 추가 (§7 룰):

```
│   ─── 또는 ───                       │
│   "선생님 추천 영상 있어요"            │
│       [지금 볼래]  [다음에]            │
```

### 4.4 더 보기 (점점점 탭, 옵션)

```
┌─────────────────────────────────────┐
│  1년 동안                              │
│  [GitHub 스타일 히트맵 7×52]            │
│                                       │
│  내 트로피 ({N})                      │
│  🏆 🏆 🏆                            │
│                                       │
│  추천 ({N}) ●                         │
│                                       │
│  비교 보기   [OFF]                    │
└─────────────────────────────────────┘
```

### 4.5 비교 보기 (옵션 ON, 주 1회 요약)

```
┌─────────────────────────────────────┐
│  이번 주 비교                          │
│                                       │
│  나 ▮▮▮▮▮▮▯  {N}일 / {M}분          │
│                                       │
│  ─ 선생님 친구들 ▮▮▮▮▯▯▯  (L4a)    │
│  ─ 학원 친구들   ▮▮▮▮▮▯▯  (L4b)    │
│  ─ 친구 그룹     ▮▮▮▮▯▯▯  (L4c)    │
│  ─ 세계 익명     ▮▮▮▯▯▯▯  (L4d)    │
│                                       │
│  너의 티어: 🥇 Gold                   │
│                                       │
│  (다음 주 일요일 갱신)                  │
└─────────────────────────────────────┘
```

- 4 레이어 모두 UI 노출 (L4a~L4d), 각각 독립 opt-in
- 학생이 비활성 한 레이어 = 회색·hidden 표시
- 일일 비교 X, **주간 1회** — 매일 자극 회피
- 숫자 순위 X, 티어만 (Tonara 학습)
- 14세 미만 자동 hide, "비교 보기" 토글도 자동 OFF
- L4c 친구 그룹 미사용 (친구 추가 X) 학생 → 행 자동 hide

### 4.6 Onboarding (1 화면)

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

이름·연락처는 선생님 초대/부모 동의에서 자동 채움 — 학생 입력 0.

---

## 5. Quest 분류 — Ambient vs Spotlight

### 5.1 Ambient (90%) — 학생 의식하지 않음

| Quest type | 자동 트래킹 | 진척 시각화 |
|---|---|---|
| 일별 연습 시간 누적 | PracticeService 자동 | 히트맵 +1 |
| 연속 연습일 스트릭 | 자동 + freeze 적용 | 🔥{N}일 |
| 곡 마스터리 (반복재생 + 녹음) | YouTube 시청 + 녹음 수 | 곡 트로피 |
| 악기 컬렉션 | 첫 시도 + 누적 시간 | 컬렉션 카드 |
| 시즌 누적 분 | 분기별 | 시즌 배지 |

학생 UI 에 "이 quest 진행중" 표시 X. 진척 자체가 ambient.

### 5.1.b Quest Origin × Type 매트릭스

기존 `ChallengeType` (6종: practiceDays, practiceMinutes, recordings, lessons, streak, pointsEarned) 를 재사용하되, origin 별로 가능한 type 만 허용:

| Origin | 가능한 ChallengeType | 누가 작성 |
|---|---|---|
| `ambient` | practiceDays, practiceMinutes, streak (자동 누적) | 시스템 (학생 의식 X) |
| `selfCreated` | practiceMinutes, recordings, custom title | 학생 직접 |
| `systemRoutine` | practiceMinutes, practiceDays | 시스템 추천 (학생 채택) |
| `lessonDerived` | recordings, lessons, pointsEarned | 학생이 레슨 노트에서 변환 |
| `teacherRec` | practiceMinutes, recordings, lessons | 선생님이 발급 |
| `seasonEvent` | practiceDays, pointsEarned | 시즌 큐레이션 |

**금칙 조합**:
- `selfCreated` × `streak`: streak 은 시스템만 계산 (학생 작성 의미 없음)
- `teacherRec` × `pointsEarned`: 외부 보상 의존 회피 (선생님이 P 목표 부여 X)
- `ambient` × `recordings`: 녹음 횟수는 학생 의식 액션 필요

### 5.2 Spotlight (10%) — 의식적 결정 1회

| Spotlight 종류 | 출처 | 노출 위치 |
|---|---|---|
| 선생님 추천 영상·곡 | 선생님이 teaching_resource 추가 | 연습 후 축하 슬롯 |
| 시즌 이벤트 (봄/추석/크리스마스) | 시스템 큐레이션 | 연습 후 축하 슬롯 |
| 새로운 routine 제안 | 학생 패턴 분석 (자가 routine 30일 시) | 연습 후 축하 슬롯 |

**노출 빈도**: 주 1-2회 최대. 매번 X.

**거절 처리**:
- "다음에" → cooldown 7일 (해당 Spotlight)
- 5회 거절 → 8주 자동 hide (해당 type)
- 페널티·재시도 강요 0

**선생님 "필수" 플래그** (rare):
- 선생님 UI 에서만 토글 → BE 상 priority +10 부여 (Spotlight 큐 우선순위 §7.2 1번 진입)
- **학생 UI 에는 "필수" 라벨 미노출** (SC-4 origin 라벨 0 유지)
- 학생이 보는 것: 동일한 "선생님이 추천했어요" prompt — 단, 노출 빈도가 다른 추천보다 자주
- 거절 시 BE 가 자동으로 선생님 알림 발송 (학생 UI 에는 알림 발송 사실 미표시 — 스트레스 방지)
- 시스템 강제 X (거절 가능)

---

## 6. 데이터 모델 — 신규 엔티티 5개

기존 인프라 (WeeklyRanking, Challenge, point_award_service, badge_award_provider, practice_streak_provider) 는 변경 없이 재사용.

### 6.0 의존성 그래프 (단방향 보장)

```
[Practice 활동 발생] (메트로놈/튜너/YouTube/녹음/수동)
       ↓
PracticeService.record(studentId, type, minutes, metadata)
       ↓
       ├──────────────────────────────────────┐
       │                                       │
       ▼                                       ▼
GrowthHeatmap.upsert(date, evidence)    StudentQuest.checkProgress(studentId)
       │                                       │
       ▼                                       ▼
StreakFreeze.checkAutoApply(studentId)    SpotlightPrompt.enqueue(if eligible)
       │                                       │
       ▼                                       ▼
(스트릭 갱신)                            축하 화면에 prompt 슬롯
       │                                       │
       └──────────────┬────────────────────────┘
                      ▼
       LeaderboardUpdater (if opt-in + 일요일 batch)
                      ↓
                WeeklyRanking
```

**규칙**:
- PracticeService = 단일 진입점 (SC-3)
- StudentQuest, SpotlightPrompt, LeaderboardPreferences 는 GrowthHeatmap·Practice 직접 참조 금지 — PracticeService 결과만 받음
- LeaderboardUpdater 는 학생이 명시적 opt-in 한 경우에만 호출 (일요일 일괄 batch)
- 순환 의존 없음 (Quest ↛ Spotlight, Spotlight ↛ Quest)

### 6.1 StudentQuest (자가 quest + 채택된 Spotlight)

```dart
class StudentQuest {
  final String id;
  final String studentId;
  final QuestOrigin origin; // ambient | selfCreated | systemRoutine | lessonDerived | teacherRec | seasonEvent
  final String title;
  final ChallengeType? type; // 기존 Challenge 재사용
  final int targetValue;
  final int currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final DateTime? completedAt;
}
```

### 6.2 SpotlightPrompt (축하 후 가벼운 prompt 큐)

```dart
class SpotlightPrompt {
  final String id;
  final String studentId;
  final SpotlightType type; // teacherRec | seasonEvent | routineSuggestion
  final String title;
  final String? videoId;
  final String? ctaRoute;
  final DateTime queuedAt;
  final int declineCount;
  final DateTime? hideUntil; // 8주 cooldown 시 설정
}
```

### 6.3 GrowthHeatmap (1년 캘린더)

```dart
class GrowthHeatmap {
  final String studentId;
  final Map<DateTime, DailyPractice> days; // key = UTC midnight, value = 통합 evidence
}

class DailyPractice {
  final int metronomeMinutes;
  final int tunerMinutes;
  final int youtubeMinutes;
  final int recordingCount;
  final int manualMinutes;
  int get totalMinutes => metronomeMinutes + tunerMinutes + youtubeMinutes + manualMinutes;
}
```

### 6.4 LeaderboardPreferences (4단 레이어 독립)

```dart
class LeaderboardPreferences {
  final String studentId;
  final LeaderboardVisibility l4aTeacherClass; // hidden | nameAndTier | nicknameOnly
  final LeaderboardVisibility l4bAcademy;
  final LeaderboardVisibility l4cFriends;
  final LeaderboardVisibility l4dGlobal; // 디폴트 visible (저자극)
  final bool hideIfBottom50Percent; // 옵션
}

enum LeaderboardVisibility { hidden, nameAndTier, nicknameOnly }
```

### 6.5 StreakFreeze (안티-피로)

```dart
class StreakFreeze {
  final String studentId;
  final int balance; // 일요일 자동 +2, max 4
  final List<DateTime> usedAt; // 자동 적용 이력
  final DateTime? examModeUntil; // 시험 모드 (학부모/선생님 발급)
}
```

### 6.6 Student 엔티티 확장 (기존 수정)

```dart
class Student {
  // ... 기존 필드
  final String? nickname; // 신규 — 글로벌 unique
  final DateTime? parentConsentAt; // 14세 미만 부모 동의 시점
  final bool comparisonViewEnabled; // 디폴트 false
}
```

---

## 7. Spotlight Prompt 룰 + 페이스 알고리즘

### 7.1 노출 조건

```
if (
  연습 종료됨 AND
  세션 시간 ≥ 5분 AND
  오늘 첫 prompt AND
  주간 prompt 횟수 ≤ 2 AND
  큐에 promptable item 있음 AND
  학생 14세 미만이면 부모 동의 완료
) → 축하 후 1슬롯 prompt
```

### 7.2 큐 우선순위

1. 선생님 "필수" 플래그 (rare, but top)
2. 선생님 일반 추천 (1주 이내 queued)
3. 시즌 이벤트 (활성 시즌 한정)
4. routine 제안 (자가 routine 30일+ 시)

### 7.3 거절 학습

- "다음에" → cooldown 7일
- 같은 type 5회 거절 → 8주 hide
- 8주 후 1회 재시도 → 또 거절 → 영구 hide (학생이 옵션에서 명시적 재활성)

### 7.4 Spotlight 노출 메시지 룰

- "선생님이 추천했어요" (감사 X), "이거 어때요?" 권유형
- "꼭 해야 해요" "필수입니다" 사용 금지
- 거절 버튼이 "지금 볼래" 와 같은 비중·동일 색

---

## 8. 1년 retention KPI

| KPI | 측정 | 목표 |
|---|---|---|
| D1 retention | 가입 다음날 앱 진입 | 80% |
| D7 retention | 가입 7일 후 | 60% |
| D30 retention | 30일 후 | 45% |
| D90 retention | 90일 후 | 35% |
| D365 retention | 365일 후 | 30% |
| 주간 평균 연습 분 | per student, active | 90분/주 (D30+) |
| 자가 quest 작성 비율 | self/total quests | ≥ 60% (SDT 자율성 지표) |
| Spotlight 채택률 | accepted/shown | 25-40% (낮으면 학생 페이스 존중 OK, 너무 높으면 강제 의심) |
| 비교 보기 OFF 유지율 | 14세 이상 | 50%+ (OFF 디폴트 존중) |
| Streak freeze 사용률 | 자동 적용 / 발급 | 30-50% (시험 모드 등) |
| 푸시 알림 발송 건수 | 시스템 전체 | **0** |

### 8.1 위험 지표 (조기 경고)

| 지표 | 위험 신호 |
|---|---|
| 7일 평균 세션 길이 > 60분 | 사용 시간 과다 → 휴식 권고 |
| Spotlight 거절률 > 80% | 큐레이션 잘못됨, 알고리즘 재검토 |
| 비교 보기 ON 학생 D30 retention < 평균 | 경쟁 스트레스 → UX 점검 |
| streak freeze 사용률 < 5% | freeze 안내 부족 |

---

## 9. 14세 미만 부모 동의 + 안전·프라이버시

### 9.1 자동 분기 (학생 birthDate 기반)

```
if (현재 - birthDate < 14년):
  - 비교 보기 = 강제 hide (디폴트 OFF + 부모 unlock 필요)
  - 글로벌 익명 L4d = 강제 hide
  - 부모 동의 모달 1회 (가입 직후)
  - 30분 세션 휴식 권고 강화 (15분 → 30분)
```

### 9.2 부모 동의 흐름

```
가입 학생 birthDate < 14년
       ↓
앱 진입 시 모달 — "부모님께 동의 받기" (학생에게 보임)
       ↓
부모 이메일 입력 또는 부모 휴대전화 입력 (학원 등록 시 이미 있으면 자동 채움)
       ↓
parentConsentToken 발급 (UUID v4, BE 저장, 만료 7일)
       ↓
부모에게 동의 링크 (이메일 또는 SMS) — https://app/parent-consent?token=...
       ↓
부모가 OAuth 로그인 후 동의 → 매핑 키 검증:
  - student.parentName + student.parentPhone (또는 학원 등록 부모) 와 비교
  - Mismatch 시 거절 + 학원/선생님 알림
       ↓
승인 → Student.parentConsentAt 기록 + parentConsentRevokedAt = null
       ↓
경쟁 레이어 활성 가능 (단, 디폴트는 여전히 OFF)
```

**토큰 만료**: 7일. 만료 시 학생 모달 재진입 → 재발급 가능. 발급 후 매주 일요일 미사용 토큰 자동 만료.

**Grace Period (동의 대기 중)**:
- 14일 동안 학생은 자가 연습 + 시각 진척 (히트맵·스트릭·트로피) 사용 가능 — 비교 보기·글로벌 익명 강제 hide
- 14일 경과 후 동의 미완료 → 추가 14일 grace 1회 연장 가능 (총 28일)
- 28일 후 미동의 → 앱 진입 시 부모 동의 모달이 routine 안내로 변경 (페널티 없음)
  - 학생 상태: **영구 grace mode** (자가 연습 + 시각 진척만, 경쟁 레이어 강제 hide 유지)
  - 재시도 경로: 학생이 "더 보기 → 비교 보기 활성" 시 또는 부모가 직접 동의 url 진입 시 → 토큰 재발급 + grace 재개
  - 학원 등록 학생 → 학원 관리자가 부모 연락 1회 권유 (자동 알림 1회)

**동의 철회 (Revocation)**:
- 부모가 별도 url 접근하여 철회 가능 → `parentConsentRevokedAt` 기록
- 철회 즉시: 경쟁 레이어 강제 hide + 닉네임 hide (글로벌 익명 포함) + Spotlight prompt 일시 정지
- 자가 연습 + 시각 진척은 계속 사용 가능 (학생 동기 보호)
- 학생에게는 "비교 보기가 잠시 꺼졌어요" 한 줄 안내 (이유 미공개)
- 부모가 다시 동의 → 즉시 복구

**매핑 키 (parent-child)**:
- 우선순위 ① 학원 등록 부모 (academy 도메인) ② Student.parentPhone ③ Student.parentName + Student 자기보고 이메일
- 동의 url 의 token + 부모 OAuth identity 검증 (부모도 본인 가입)
- 매핑 불일치 시 자동 거절 + 학원 관리자에게 alert

**KISA + COPPA-K + 정보통신망법 §50의5** 준수. 법무 review (P4 시점).

### 9.3 글로벌 익명 (말해보카 모델)

- **표시**: 닉네임 + 티어만. 프로필 이미지 = 추상 아바타 (학생 본인 이미지 노출 X)
- **닉네임 unique**: BE 에서 글로벌 unique 보장 (재로그인 시 동일 닉)
- **금칙어 필터**: 욕설·차별·개인정보 자동 거절
- **위치/학교 정보 X**: 익명 표시에 어떤 식별자도 포함 X
- **어뷰징 방지**:
  - 메트로놈 사용 시간만 인정 (BPM 변화 모니터링 — 1초마다 클릭 봇 거절)
  - 일일 인정 시간 cap (4시간)
  - 의심 패턴 자동 검토 (관리자)

### 9.4 휴식 권고

- 단일 세션 30분 도달 → "잠깐 쉬는 게 어때요?" 토스트 1회
- 일일 누적 3시간 도달 → 차분한 메시지 + 오늘 종료 권유 (강제 X)

---

## 10. 시즌 + 명절 이벤트

### 10.1 분기 시즌

- 봄 (3-5월): 클래식 테마
- 여름 (6-8월): 즉흥/팝 테마
- 가을 (9-11월): 합주 테마
- 겨울 (12-2월): 자신 곡 테마

시즌은 **시각 테마만** 적용 (악기 스킨·뱃지·프레임). 시즌 quest 자동 부여 X.

### 10.2 명절 이벤트 (Spotlight 큐 진입)

- 추석 1주 (음력 8/15 기준 1주)
- 크리스마스 (12/20-12/26)
- 어린이날 (5/1-5/7)
- 음악의 날 (10/1, 세계 음악의 날)

이벤트는 Spotlight 로 들어오며 거절 가능. 자동 부여 X.

### 10.3 시즌 종료

- 분기 마지막 일요일 23:59 KST
- 시즌 테마 자동 종료 → 다음 시즌 테마로
- 시즌 quest 미완료 시 페널티 0 (단순 종료)

---

## 11. YouTube 트래킹 상세

### 11.1 트래킹 항목

| 항목 | 메커니즘 | 인정 |
|---|---|---|
| 시청 시간 | `youtube_player_iframe` `getCurrentTime()` polling (1초) | 누적 1분+ = practice 시간 인정 |
| 완주 | `onEnded` event | 완주 시 보너스 P (작게) |
| 반복재생 | playerStateChange `playing` 트리거 카운트 (같은 영상) | ≥3회 = "집중 연습 마커" 트로피 |
| 영상 종류 | 선생님 추천 (`teaching_resource`) vs 자가 검색 | 둘 다 동등 인정 |

### 11.2 일일 cap

| 종류 | cap | 이유 |
|---|---|---|
| 선생님 추천 시청 | cap 없음 | 협력 가점, SDT 관계성 |
| 자가 검색 시청 | 일 30분 | 무한 스크롤 회피 |
| 자동 재생 (autoplay) | 인정 X | 능동적 시청만 인정 |

### 11.3 프라이버시

- video ID 만 BE 전송, PII 0
- 14세 미만 부모 동의 후 트래킹 활성
- 시청 기록 30일 후 자동 삭제 (집계 통계만 유지)

### 11.4 YAGNI

- ❌ YouTube 영상 내용 평가 (AI 분석)
- ❌ "이 영상 봐야 합니다" 강제
- ❌ 영상 추천 알고리즘 (우리가 영상 만들기)
- ❌ 시청 도중 광고 삽입

---

## 12. 닉네임 시스템

### 12.1 등록 시점

- 비교 보기 첫 활성 시 1회 모달
- "글로벌 익명" 자동 활성 시 자동 생성 (기본 = 익명#{4자리})

### 12.2 룰

- 길이: 2-12자 (한글/영문/숫자/일부 기호)
- 글로벌 unique
- 욕설·차별·개인정보 자동 필터
- 30일에 1회 변경 가능

### 12.3 가시성

| 레이어 | 표시 |
|---|---|
| L4a 선생님 친구 | 디폴트 hidden. ON 시 이름+닉 또는 닉만 선택 |
| L4b 학원 친구 | 닉네임 (개인정보 가림) |
| L4c 친구 그룹 | 닉네임 (서로 알지만 통일성) |
| L4d 글로벌 익명 | 닉네임만 (실명 강제 hide, 모달 보호) |

---

## 13. 글로벌 익명 리더보드 (말해보카 모델)

### 13.1 표시

- 일일 비교 X — **주간 요약 (일요일 갱신)**
- 티어 분포: Gold 30%, Silver 30%, Bronze 40%
- 본인 티어 + 위/아래 5명 (닉네임만)

### 13.2 어뷰징 방지 (위협 모델)

**위협 종류 + 대응**:

| 위협 | 탐지 | 대응 |
|---|---|---|
| 메트로놈 클릭 봇 (자동 tap) | BPM 변동 1초 분석: 동일 BPM 30분+ 지속 + 시작/종료 패턴 균일 | 의심 카운터 +1, 5회+ 시 14일 검토 모드 |
| 클라이언트 시간 조작 | 모든 timestamp = 서버 시간 (NTP 동기화 BE). 클라이언트 시간 비교 불일치 시 알람 | 즉시 검토 모드 + 의심 카운터 +3 |
| 다중 계정 | 디바이스 식별 = IDFV (iOS) + Android Advertising ID (Android, opt-out 시 SSAID fallback) + 앱 설치 UUID 조합 hash | 동일 hash 2계정 이상 시 검토. 학원·가족 예외 case 화이트리스트 (학원 관리자가 명시 신청) |
| 디바이스 ID 변경 (앱 재설치) | 동일 닉네임 + 동일 IP + 비슷한 BPM 패턴 결합 분석 | 14일 그레이리스트 (점수 50% reduced) 후 정상 |
| 의심 패턴 누적 | 의심 카운터 ≥ 5 또는 즉시 트리거 (시간 조작) | 14일 검토 모드 진입 |

**14일 검토 모드 SLA**:
- 진입: 의심 카운터 ≥ 5 또는 즉시 트리거 → BE flag `reviewModeUntil` 자동 설정 (now + 14일)
- 효과: 리더보드 자동 hide (학생 본인은 정상 사용 + 자기 진척 가시 — 격리식 처벌)
- 학생에게 메시지: "잠시 리더보드가 꺼졌어요" (사유 비공개)
- 출구: ① 14일 자동 만료 (의심 카운터 reset) 또는 ② 관리자 수동 해제 (false positive 확인)
- false positive 대응: 학생 또는 학원 관리자가 "appeal" 버튼 → 관리자 검토 SLA 48시간

**False Positive 처리**:
- 메트로놈 봇 탐지 false positive: 시각장애 학생·자동 tap 보조 도구 사용자 → 학원 관리자 수동 화이트리스트
- 다중 계정 false positive: 가족 공용 디바이스 → 학원 등록 시 가족 그룹 사전 등록
- 모든 false positive 케이스는 14일 검토 모드 진입 전 1회 학원/선생님 알림 + 학생에게는 알리지 않음 (스트레스 방지)

**화이트리스트 운영 주체**:
- 학원 등록 사용자: 학원 관리자 (academy 도메인) 신청 → 운영팀 승인 (SLA 48시간)
- 개인 사용자: 운영팀 직접 검토 (운영 contact 채널 별도)
- 자동 화이트리스트 X — 모두 수동 승인

**모니터링 메트릭**:
- 14일 검토 모드 진입율: 전체 학생 대비 < 0.5% 유지 (5% 초과 시 알고리즘 false-positive 의심)
- 자동 해제율: > 95% (관리자 수동 해제 < 5%)
- Appeal 처리 SLA: 48시간 이내 95%

**디바이스 식별자 프라이버시 정책**:
- 저장 형태: 평문 X. SHA-256 hash 만 BE 저장 (원본 IDFV/AAID 복원 불가)
- 보존 기간: 학생 계정 활성 동안 유지 + 탈퇴 시 30일 후 자동 삭제
- 키 갱신: IDFV 변경 시 (앱 재설치) — §13.2 의 디바이스 ID 변경 케이스 처리
- 정보통신망법 §29 (개인정보 파기) 준수
- 학생/부모 요청 시 30일 이내 즉시 삭제 가능

### 13.3 노출 정책

- 14세 미만: 강제 hide
- 14세 이상 디폴트: visible (저자극 baseline)
- 학생 명시적 OFF: 1탭으로 hide

---

## 14. 안티-피로 (Streak Freeze + 시험 모드)

### 14.1 자동 발급

- 매주 일요일 00:00 KST → freeze balance +2
- 최대 보유: 4개 (소진 안 하면 누적 X)
- 학부모/선생님 추가 발급 권한 (시험 기간 대응)

### 14.2 자동 적용

- 학생이 하루 연습 X → 자동으로 freeze 1개 차감, 스트릭 유지
- 학생에게 알림 토스트: "오늘 freeze 사용 — 스트릭 유지" (다음 진입 시)

### 14.3 시험 모드

- 학부모/선생님이 "시험 모드 N일" 발급
- 모드 활성 동안: 스트릭 동결 (freeze 차감 0)
- 종료 후 자동 해제

### 14.4 Comeback Bonus

- 7일+ 연속 미사용 후 복귀 → "다시 만나서 반가워요" 메시지 + 첫 세션 5분 보너스 P
- FOMO 메시지 X, 따뜻한 환영

---

## 15. 기존 인프라 재사용 매핑

| 기존 자산 | 재사용 방법 | 변경 |
|---|---|---|
| `Challenge` (6 type) | StudentQuest 내부 type 재사용 | type enum 그대로 |
| `WeeklyRanking` + `WeeklyRankingEntry` (Gold/Silver/Bronze) | L4a 선생님 학생 + L4b/c/d 모두 | classId → contextId (teacher/academy/global) 일반화 |
| `point_award_service` | 시각화 input 그대로 | "포인트" 메시징 → "성장 기록" 으로 점진 변경 (옵션) |
| `badge_award_provider` | Trophy 생성 | "보상" → "성장 마커" 메시징 |
| `practice_streak_provider` | 스트릭 + freeze 통합 | freeze 메커니즘 추가 |
| `youtube_player_iframe` | L1b 트래킹 | onTime/onEnded/onState 이벤트 핸들러 추가 |
| `teaching_resource` (선생님 추천) | Spotlight 큐 진입 | "할당" → "추천" 메시징 변경 |
| `Student` 엔티티 | nickname + parentConsentAt + comparisonViewEnabled 추가 | 후방 호환 (nullable) |
| `gamification_facade` | L1-L7 통합 API | facade 안쪽에 신규 5 엔티티 |
| `student_home_master` `GamificationHeader` | 홈 상단 1줄 (스트릭 + 어제) | 디자인 재활용 |

---

## 16. YAGNI — 만들지 않는 것

- ❌ 배틀패스 (구매 압박, 외부 보상 의존)
- ❌ 가차/랜덤박스 (도박성, 청소년 안전)
- ❌ "랭킹 N등" 표시 (티어만)
- ❌ 강제 푸시 알림 (FOMO)
- ❌ 일일 사용 시간 강요 (페널티)
- ❌ AI 피치 점수화 (다른 phase 보류)
- ❌ 모드 토글 (Self-First only)
- ❌ Workshop / Inbox 2-pane (홈 1화면)
- ❌ 시즌 자동 quest 부여 (Spotlight 추천만)
- ❌ "필수" 강제 (선생님 토글은 알림용)
- ❌ Quest 출처 라벨 노출 (학생 UI 에서)
- ❌ Trophy 카테고리 분류 노출 ("모음" 1 카드)
- ❌ 일일 비교 (주간 요약)
- ❌ YouTube 영상 평가
- ❌ 추천 영상 자체 제작
- ❌ 학생 작성 quest 글로벌 공유 (개인 데이터)

---

## 17. 비기능 요구사항

| 항목 | 기준 |
|---|---|
| 연습 화면 응답 | 메트로놈 시작 < 200ms (기존 기준) |
| 축하 화면 fade-in | < 100ms |
| 히트맵 로딩 (1년) | P95 < 500ms, P99 < 1000ms (캐시 hit). Hive 로컬 캐시 + 30일 단위 메모리 chunk 직렬화 |
| 비교 보기 갱신 | 일요일 00:00 KST 배치 (사용자 트리거 X) |
| 오프라인 연습 기록 | 로컬 저장 → 온라인 시 동기화 |
| 접근성 | VoiceOver/TalkBack 호환, 색맹 친화 (Gold/Silver/Bronze 패턴 추가) |
| Hive 캐시 | StreakFreeze, LeaderboardPreferences 로컬 캐시 |
| 다국어 | AppStrings 사용, 한국어 기본 + 영어 준비 |

---

## 18. 마이그레이션 + 출시 계획

### 18.1 단계 진행 (4 phase)

| Phase | 범위 | 성공 기준 |
|---|---|---|
| **P1. Foundation** | StudentQuest + GrowthHeatmap + PracticeService 통합 + 홈 1화면 | SC-1, SC-3, SC-4 |
| **P2. Visual Growth** | 1년 히트맵 + Trophy 모음 + 스트릭 freeze | SC-10, SC-12 |
| **P3. Spotlight** | SpotlightPrompt 큐 + 축하 화면 prompt + 거절 학습 | SC-9 |
| **P4. Competition** | LeaderboardPreferences + 비교 보기 + 글로벌 익명 + 부모 동의 | SC-5, SC-7, SC-8 |

### 18.2 출시 게이트

- P1 만으로 베타 출시 가능 (자가 연습 + 시각 진척 충분)
- P4 는 부모 동의 흐름 검토 + 법무 review 필수

### 18.3 데이터 마이그레이션

**Student 엔티티 확장**:
- nickname, parentConsentAt, parentConsentRevokedAt, parentConsentToken, comparisonViewEnabled 모두 nullable 추가
- 기존 데이터 마이그레이션 영향 0 (forward-compatible)

**기존 적립 데이터**:
- `point_award_service` 누적 데이터 그대로 사용 (변경 0)
- `WeeklyRanking` 기존 데이터 → L4a 첫 노출 시 그대로 표시

**Streak 정렬 (P0 — 정합 위험 핵심)**:
- 기존 `practice_streak_provider` 의 스트릭은 **학생 디바이스 로컬 timezone 기반 자정** 으로 계산
- 신규 freeze 시스템 적용 시점 = 본 spec 배포일 (D-day) → **D-day 이전 누락일은 freeze 적용 X** (retroactive 없음)
- D-day 이후만 freeze 자동 적용 → 학생에게 "freeze 시스템 시작" 1회 안내 토스트
- timezone 정렬: 신규 freeze 시스템은 모든 학생 = **KST (Asia/Seoul)** 자정 기준 (글로벌 익명 리더보드 동기화 위해)
- 기존 학생의 로컬 timezone 다른 경우 → D-day 1회 정렬 (학생에게 안내 X — 자정 차이 < 24h)
- D-day 마이그레이션 스크립트: `practice_streak_provider` → `StreakFreeze.balance = 2` (Sunday 자동 발급 첫 분량) + `usedAt = []`

**롤백 정책**:
- P3/P4 롤백 시 SpotlightPrompt, LeaderboardPreferences 데이터 → 90일 보존 후 자동 폐기
- StreakFreeze 데이터 → 영구 보존 (기존 streak 데이터와 동등)
- 학생 nickname → 영구 보존 (L4d 글로벌 익명 옵트인 학생만)

**테스트 시나리오**:
- 가입 1년 학생 (streak 30일 보유) → 마이그레이션 후 streak 동일 + freeze balance = 2
- 가입 1주 학생 (streak 5일) → 동일
- 신규 가입 학생 (streak 0) → freeze balance = 2 (즉시 사용 가능)

---

## 19. 후속 검증 (Phase 6 + 출시 후)

### 19.1 Phase 6 (cg-evaluation)

- code-critic: 5 신규 엔티티 + Repository + Provider 의존 그래프 spec 일치
- test-critic: SC-1~SC-12 검증 테스트 모두 spec 기반
- e2e: 신규 사용자 가입 → 5초 안에 연습 시작 가능 시나리오

### 19.2 출시 후 (3개월)

- D7/D30 retention 측정 → 목표 60%/45% 대비
- Spotlight 채택률 측정 → 25-40% 범위 확인
- 비교 보기 OFF 유지율 측정
- 학부모 부정 피드백 모니터링 (사용 시간, 부모 동의 흐름)

### 19.3 위험 시 롤백

- D7 retention < 50% (3주 연속) → P3/P4 roll-back, P1+P2 만 유지
- IGD 의심 사례 (Spotlight 의존 학생 > 5명) → P3 알고리즘 재설계

### 19.4 1년 retention 검증

- D365 retention 측정 후 학술 출판/공유 가능
- 데이터 = future 검증 자료

---

## 20. 참조

### 20.1 학술
- Springer 2024 §11528 — 음악 학습 SDT (바이올린 연구 직접 인용)
- PMC12658397 — 청소년 게이밍 욕구 만족/좌절 메타 분석
- PMC11769689 — 자기통제력 성장 마인드셋 1년 추적
- arxiv 2512.15630 — 청소년 게이미피케이션 윤리
- arxiv 2203.16175 — 게이미피케이션 오용 분석
- PMC10886329 — PRISMA 체계적 문헌고찰

### 20.2 산업 벤치마크
- Tonara (이스라엘) — "Compare Recording" + 또래 리더보드 (자체 마케팅)
- Duolingo — streak freeze 모델
- Habitica — task gamification + rest mode
- Strava — practice-first UX 영감
- 말해보카 — 익명 글로벌 모델
- Wordle / NYT Connections — 일일 비교 자제 패턴

### 20.3 프로젝트 내
- `docs/specs/gamification/gamification_master.md` (Phase 1~3 기존 인프라)
- `docs/specs/student_home/student_home_master.md` (학생 홈 10섹션)
- `docs/specs/glossary.md` (도메인 용어)
- `.harness/knowledge/glossary.md` (FE-BE 매핑 SSOT)

---

## 변경 이력

| 날짜 | 변경 | 비고 |
|---|---|---|
| 2026-06-11 | 초안 작성 | brainstorming 5회 iter (A→C→Self-First→One Card→Strava) |
