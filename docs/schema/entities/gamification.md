# Gamification 엔티티

> 마지막 업데이트: 2026-03-11
> 관련 스펙: [gamification_spec.md](../../specs/practice/gamification_spec.md)

## 개요

학생의 게이미피케이션 프로필 (포인트, 레벨, 뱃지) 및 포인트 이력을 관리합니다.
Hive 어노테이션 없이 순수 Dart 클래스로 구현되어 있습니다.

---

## StudentGamification

학생별 게이미피케이션 프로필.

### 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `studentId` | String | ✅ | 학생 ID |
| `totalPoints` | int | ✅ | 총 획득 포인트 |
| `level` | int | ✅ | 현재 레벨 |
| `levelTitle` | String | ✅ | 레벨 칭호 (예: '열정 연습생') |
| `pointsToNextLevel` | int | ✅ | 다음 레벨까지 남은 포인트 |
| `currentLevelMinPoints` | int | ✅ | 현재 레벨 최소 포인트 |
| `nextLevelMinPoints` | int | ✅ | 다음 레벨 최소 포인트 |
| `earnedBadges` | List\<PracticeBadge\> | - | 획득한 뱃지 목록 (기본: []) |
| `recentHistory` | List\<PointHistory\> | - | 최근 포인트 이력 (기본: []) |

### 계산 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `levelProgress` | double | 다음 레벨 진행률 (0.0 ~ 1.0) |

---

## PointHistory

포인트 획득 이력 항목.

### 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | 고유 ID |
| `studentId` | String | ✅ | 학생 ID |
| `points` | int | ✅ | 획득 포인트 |
| `type` | PointType | ✅ | 포인트 유형 |
| `description` | String | ✅ | 설명 |
| `earnedAt` | DateTime | ✅ | 획득 일시 |

---

## PracticeBadge

학생이 획득할 수 있는 뱃지.

### 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | 고유 ID |
| `name` | String | ✅ | 뱃지 이름 |
| `description` | String | ✅ | 뱃지 설명 |
| `icon` | String | ✅ | 아이콘 |
| `rarity` | BadgeRarity | ✅ | 희귀도 |
| `earnedAt` | DateTime? | - | 획득 일시 |
| `isEarned` | bool | - | 획득 여부 (기본: false) |

---

## LevelDefinition

레벨 정의 (칭호, 필요 포인트).

### 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `level` | int | ✅ | 레벨 번호 |
| `title` | String | ✅ | 레벨 칭호 |
| `minPoints` | int | ✅ | 필요 최소 포인트 |

### 레벨 테이블

| 레벨 | 칭호 | 최소 포인트 |
|------|------|------------|
| 1 | 초보 연습생 | 0 |
| 2 | 열정 연습생 | 100 |
| 3 | 꾸준한 연주자 | 300 |
| 4 | 실력파 연주자 | 600 |
| 5 | 음악 마스터 | 1000 |
| 6 | 전설의 연주자 | 1500 |

---

## Enum

### PointType

포인트 획득 활동 유형.

| 값 | 설명 |
|-----|------|
| `practiceComplete` | 연습 완료 |
| `streakBonus` | 연속 연습 보너스 |
| `lessonAttendance` | 레슨 출석 |
| `goalAchieved` | 목표 달성 |
| `badgeEarned` | 뱃지 획득 |

### BadgeRarity

뱃지 희귀도 등급.

| 값 | 설명 |
|-----|------|
| `common` | 일반 |
| `rare` | 희귀 |
| `epic` | 영웅 |
| `legendary` | 전설 |

---

## 관련 파일

- Entity: `features/gamification/domain/entities/gamification.dart`
- Provider: `features/gamification/presentation/providers/`

## 변경 이력

- 2026-03-11: 초기 스키마 문서 생성
