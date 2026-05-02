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
