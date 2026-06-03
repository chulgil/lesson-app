# 게이미피케이션 마스터 스펙

> 마지막 업데이트: 2026-04-17
> 구현 상태: ✅ Phase 1 완료 (포인트/레벨/뱃지 자동 수여)
> 관련 PR: #98, Refs #222

---

## 1. 개요

연습/레슨 활동에 대한 포인트 적립, 레벨업, 뱃지 획득 시스템.
학생의 연습 동기 부여와 성취감 제공이 목적.

## 2. 주요 기능

### 2.1 포인트 시스템
- 연습 완료, 스트릭 유지, 레슨 참석 등 활동별 포인트 적립
- 일일/주간 포인트 집계

### 2.2 레벨 시스템
- 누적 포인트 기반 레벨업
- 레벨별 칭호 부여

### 2.3 뱃지 시스템
- 특정 조건 달성 시 뱃지 획득 (9종 자동 수여 조건)
- 뱃지 컬렉션 화면에서 조회
- **자동 수여 흐름**: 포인트 적립 → 조건 재평가 → 신규 뱃지 영속화 → UI 토스트 트리거

자동 수여 조건 (9종): 첫 연습, 7/30/100일 스트릭, 첫 녹음, 과제 올클리어, 연습왕, 꾸준함의 힘, 레퍼토리 마스터.
상세 조건 함수는 `badge_award_provider.dart`의 `autoBadgeConditions` 리스트 참조.

## 3. 코드 위치

| 레이어 | 파일 |
|--------|------|
| 엔티티 | `features/gamification/domain/entities/gamification.dart` |
| Repository | `features/gamification/domain/repositories/gamification_repository.dart` — `awardBadges(studentId, badges)` 포함 |
| Mock 구현 | `features/gamification/data/repositories/mock_gamification_repository.dart` — 메모리 저장소 |
| 포인트 수여 | `features/gamification/presentation/providers/point_award_service.dart` — award* 메서드 후 `_triggerBadgeCheck` 자동 호출 |
| 뱃지 조건 | `features/gamification/presentation/providers/badge_award_provider.dart` — `autoBadgeConditions`, `checkBadgeEligibility`, `recentlyAwardedBadgesProvider` |
| Provider | `features/gamification/presentation/providers/gamification_provider.dart` |
| 화면 | `features/gamification/presentation/screens/badge_collection_screen.dart` |

### 뱃지 자동 수여 트리거 지점

| 트리거 | 호출 메서드 | 지급 포인트 |
|--------|-------------|-------------|
| 일일 연습 완료 | `awardPracticeComplete` | 30P |
| 과제 항목 완료 | `awardTaskComplete` | 20P |
| 목표 달성 | `awardGoalAchieved` | 50P |
| 스트릭 보너스 (7/30일) | `awardStreakBonus` | 100P / 500P |
| 녹음 저장 | `awardRecordingSaved` | 10P |

모든 award 메서드는 내부적으로 `_triggerBadgeCheck`를 호출하여:
1. `checkBadgeEligibilityProvider`로 수여 가능한 뱃지 목록 조회
2. `GamificationRepository.awardBadges`로 영속화
3. `recentlyAwardedBadgesProvider`에 푸시 (UI 토스트용)
4. `studentGamificationProvider` invalidate로 뱃지 목록 갱신

## 4. 엔티티 스키마

→ [docs/schema/entities/gamification.md](../../schema/entities/gamification.md)

## 5. 구현 현황

| Phase | 범위 | 상태 |
|-------|------|:----:|
| **Phase 1** | 포인트/레벨/뱃지 자동 수여 | ✅ 완료 |
| **Phase 2** | 리더보드 (주간 랭킹) | ✅ 구현 완료 (`weekly_ranking_card.dart`) |
| **Phase 3** | 도전 과제 (미션) | ✅ 구현 완료 (`challenges_card.dart`) |

---

## 코드 반영 추가 (2026-06-03)

> 코드에 구현되어 있으나 위 본문에 데이터 모델이 누락되어 있던 항목을 단방향(코드→스펙)으로 반영. 근거 경로 명시.

### 6. 엔티티 정의 (코드 반영 2026-06-03)

> 소스: `domain/entities/gamification.dart`

| 모델 | 핵심 필드 |
|------|-----------|
| `StudentGamification` | studentId, totalPoints, level, levelTitle, pointsToNextLevel, currentLevelMinPoints, nextLevelMinPoints, earnedBadges, recentHistory; `levelProgress`(0~1) |
| `PointHistory` | id, studentId, points, type(PointType), description, earnedAt |
| `PracticeBadge` | id, name, description, icon, rarity(BadgeRarity), earnedAt?, isEarned |
| `LevelDefinition` | level, title, minPoints; 정적 `levels`, `forPoints()`, `nextLevel()` |

#### PointType enum (코드 반영 2026-06-03)

`practiceComplete`, `streakBonus`, `lessonAttendance`, `goalAchieved`, `badgeEarned`

#### BadgeRarity enum (코드 반영 2026-06-03)

`common`, `rare`, `epic`, `legendary`

#### 레벨 정의 (LevelDefinition.levels, 코드 반영 2026-06-03)

| 레벨 | 칭호 | minPoints |
|:----:|------|:---------:|
| 1 | 초보 연습생 | 0 |
| 2 | 열정 연습생 | 100 |
| 3 | 꾸준한 연주자 | 300 |
| 4 | 실력파 연주자 | 600 |
| 5 | 음악 마스터 | 1000 |
| 6 | 전설의 연주자 | 1500 |

### 7. 포인트 적립 규칙 (PointAwardRule.rules, 코드 반영 2026-06-03)

> 소스: `presentation/providers/point_award_service.dart`

| source(PointType) | points | description | dailyLimit |
|-------------------|:------:|-------------|:----------:|
| practiceComplete | 30 | 일일 연습 완료 | 1 |
| practiceComplete | 20 | 과제 항목 완료 | - |
| goalAchieved | 50 | 연습 목표 달성 | 1 |
| streakBonus | 100 | 7일 스트릭 보너스 | - |
| streakBonus | 500 | 30일 스트릭 보너스 | - |
| practiceComplete | 10 | 녹음 등록 | - |

`PointAwardNotifier`: `awardPracticeComplete`/`awardTaskComplete`/`awardGoalAchieved`/`awardStreakBonus`(7→100P, 30→500P, 그 외 null)/`awardRecordingSaved`; 모두 `_triggerBadgeCheck` 호출. (본문 §3 표는 awardStreakBonus를 7/30일로 명시 — 코드와 일치)

### 8. 도전 과제 (Challenge) 데이터 모델 (코드 반영 2026-06-03)

> 소스: `domain/entities/challenge.dart`, `presentation/providers/challenge_provider.dart`

본문 §5의 "Phase 3 도전 과제 구현 완료"에 대한 데이터 모델 정의.

#### ChallengePeriod enum

`weekly`(주간), `monthly`(월간) — 각 `displayName`.

#### ChallengeType enum (6종)

| 값 | displayName | icon |
|----|-------------|:----:|
| practiceDays | 연습 일수 | 📅 |
| practiceMinutes | 연습 시간 | ⏱️ |
| recordings | 녹음 횟수 | 🎙️ |
| lessons | 레슨 완료 | 🎵 |
| streak | 연속 연습 | 🔥 |
| pointsEarned | 포인트 획득 | 💎 |

#### Challenge 모델

id, title, description, type, period, targetValue, currentValue, rewardPoints, startDate, endDate, rewardBadgeId?, isCompleted, completedAt?. 파생: `progress`(0~1), `remainingDays`, `isActive`, `targetDisplay`(타입별 단위), `copyWith`.

Provider: `studentChallengesProvider`(현재 mock 폴백, remote API 대기), `activeChallengesProvider`, `completedChallengesProvider`.

### 9. 주간 랭킹 (WeeklyRanking) 데이터 모델 (코드 반영 2026-06-03)

> 소스: `domain/entities/weekly_ranking.dart`

본문 §5의 "Phase 2 리더보드 구현 완료"에 대한 데이터 모델 정의.

#### RankingTier enum

`gold`(상위 30%), `silver`(다음 30%), `bronze`(나머지)

#### WeeklyRankingEntry

studentId, studentName, weeklyPoints, tier(RankingTier), rank

#### WeeklyRanking

classId, weekStartDate, entries; 파생: `totalStudents`, `entriesByTier(tier)`, `findStudent(id)`, `maxPoints`, `isEmpty`/`isNotEmpty`.

### 10. Repository / Provider 추가 (코드 반영 2026-06-03)

- `GamificationRepository`: `getStudentGamification(studentId)`, `awardBadges(studentId, badges)` — Mock/Remote 구현
- Providers: `badge_award_provider.dart`, `point_award_service.dart`, `challenge_provider.dart`, `gamification_provider.dart`
