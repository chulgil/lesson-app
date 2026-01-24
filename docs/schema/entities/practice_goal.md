# PracticeGoal 엔티티

> 작성일: 2026-01-24
> 관련 스펙: [practice_goal_spec.md](../../specs/practice/practice_goal_spec.md)

---

## Hive TypeId 할당

| TypeId | 엔티티 |
|:------:|--------|
| 32 | PracticeGoal |

---

## PracticeGoal (연습 목표)

학생의 일일/주간 연습 목표를 저장하는 엔티티.

### Dart 엔티티

```dart
/// 연습 목표 모델
@HiveType(typeId: 32)
class PracticeGoal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  // === 일일 목표 ===
  @HiveField(2)
  final int? dailyTimeMinutes;     // 일일 연습 시간 목표 (분)

  @HiveField(3)
  final int? dailySectionCount;    // 일일 완료 섹션 수 목표

  // === 주간 목표 ===
  @HiveField(4)
  final int? weeklyTimeMinutes;    // 주간 연습 시간 목표 (분)

  @HiveField(5)
  final int? weeklyDayCount;       // 주간 연습 일수 목표

  // === 메타데이터 ===
  @HiveField(6)
  final bool isActive;             // 목표 활성화 여부

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  PracticeGoal({
    required this.id,
    required this.studentId,
    this.dailyTimeMinutes,
    this.dailySectionCount,
    this.weeklyTimeMinutes,
    this.weeklyDayCount,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// 일일 목표가 설정되어 있는지
  bool get hasDailyGoal =>
      dailyTimeMinutes != null || dailySectionCount != null;

  /// 주간 목표가 설정되어 있는지
  bool get hasWeeklyGoal =>
      weeklyTimeMinutes != null || weeklyDayCount != null;

  /// 목표가 하나라도 설정되어 있는지
  bool get hasAnyGoal => hasDailyGoal || hasWeeklyGoal;

  PracticeGoal copyWith({
    String? id,
    String? studentId,
    int? dailyTimeMinutes,
    int? dailySectionCount,
    int? weeklyTimeMinutes,
    int? weeklyDayCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDailyTime = false,
    bool clearDailySection = false,
    bool clearWeeklyTime = false,
    bool clearWeeklyDay = false,
  }) {
    return PracticeGoal(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      dailyTimeMinutes: clearDailyTime ? null : (dailyTimeMinutes ?? this.dailyTimeMinutes),
      dailySectionCount: clearDailySection ? null : (dailySectionCount ?? this.dailySectionCount),
      weeklyTimeMinutes: clearWeeklyTime ? null : (weeklyTimeMinutes ?? this.weeklyTimeMinutes),
      weeklyDayCount: clearWeeklyDay ? null : (weeklyDayCount ?? this.weeklyDayCount),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### 필드 설명

| 필드 | 타입 | 설명 | 필수 |
|------|------|------|:----:|
| id | String | 고유 식별자 | ⭕ |
| studentId | String | 학생 ID | ⭕ |
| dailyTimeMinutes | int? | 일일 연습 시간 목표 (분) | ❌ |
| dailySectionCount | int? | 일일 완료 섹션 수 목표 | ❌ |
| weeklyTimeMinutes | int? | 주간 연습 시간 목표 (분) | ❌ |
| weeklyDayCount | int? | 주간 연습 일수 목표 | ❌ |
| isActive | bool | 목표 활성화 여부 | ⭕ |
| createdAt | DateTime | 생성일 | ⭕ |
| updatedAt | DateTime? | 수정일 | ❌ |

---

## DailyPracticeProgress (일일 진행률)

> ⚠️ 저장하지 않음 - 실시간 계산용

```dart
/// 일일 연습 진행률 (저장 안함, 실시간 계산)
class DailyPracticeProgress {
  final DateTime date;
  final int practiceTimeSeconds;    // 오늘 연습 시간 (초)
  final int completedSectionCount;  // 오늘 완료한 섹션 수

  DailyPracticeProgress({
    required this.date,
    required this.practiceTimeSeconds,
    required this.completedSectionCount,
  });

  /// 연습 시간 (분)
  int get practiceTimeMinutes => practiceTimeSeconds ~/ 60;

  /// 일일 시간 목표 달성률 (0.0 ~ 1.0+)
  double timeProgressRate(int? goalMinutes) {
    if (goalMinutes == null || goalMinutes == 0) return 0.0;
    return practiceTimeMinutes / goalMinutes;
  }

  /// 일일 섹션 목표 달성률 (0.0 ~ 1.0+)
  double sectionProgressRate(int? goalCount) {
    if (goalCount == null || goalCount == 0) return 0.0;
    return completedSectionCount / goalCount;
  }

  /// 일일 목표 완전 달성 여부
  bool isDailyGoalAchieved(PracticeGoal goal) {
    final timeAchieved = goal.dailyTimeMinutes == null ||
        practiceTimeMinutes >= goal.dailyTimeMinutes!;
    final sectionAchieved = goal.dailySectionCount == null ||
        completedSectionCount >= goal.dailySectionCount!;
    return timeAchieved && sectionAchieved;
  }
}
```

---

## WeeklyPracticeProgress (주간 진행률)

> ⚠️ 저장하지 않음 - 실시간 계산용

```dart
/// 주간 연습 진행률 (저장 안함, 실시간 계산)
class WeeklyPracticeProgress {
  final DateTime weekStart;         // 주 시작일 (월요일)
  final int totalTimeSeconds;       // 주간 총 연습 시간
  final int practiceDayCount;       // 연습한 일수
  final List<DailyPracticeProgress> dailyProgress;  // 일별 상세

  WeeklyPracticeProgress({
    required this.weekStart,
    required this.totalTimeSeconds,
    required this.practiceDayCount,
    required this.dailyProgress,
  });

  /// 연습 시간 (분)
  int get totalTimeMinutes => totalTimeSeconds ~/ 60;

  /// 주간 시간 목표 달성률
  double timeProgressRate(int? goalMinutes) {
    if (goalMinutes == null || goalMinutes == 0) return 0.0;
    return totalTimeMinutes / goalMinutes;
  }

  /// 주간 일수 목표 달성률
  double dayProgressRate(int? goalDays) {
    if (goalDays == null || goalDays == 0) return 0.0;
    return practiceDayCount / goalDays;
  }

  /// 주간 목표 완전 달성 여부
  bool isWeeklyGoalAchieved(PracticeGoal goal) {
    final timeAchieved = goal.weeklyTimeMinutes == null ||
        totalTimeMinutes >= goal.weeklyTimeMinutes!;
    final dayAchieved = goal.weeklyDayCount == null ||
        practiceDayCount >= goal.weeklyDayCount!;
    return timeAchieved && dayAchieved;
  }
}
```

---

## 파일 위치

```
lib/features/practice/domain/entities/practice_goal.dart
```

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [practice_goal_spec.md](../../specs/practice/practice_goal_spec.md) | 연습 목표 시스템 스펙 |
| [practice_streak_spec.md](../../specs/practice/practice_streak_spec.md) | 스트릭 연계 로직 |
