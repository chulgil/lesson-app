# 연습 목표 시스템 스펙

> 작성일: 2026-01-03
> 상태: 설계 완료
> 엔티티 스키마: [practice_goal.md](../../schema/entities/practice_goal.md)
> 브레인스토밍: [practice_repertoire_enhancement.md](../../proposal/practice_repertoire_enhancement.md)

## 1. 개요

### 1.1 목적
학생이 일일/주간 연습 목표를 설정하고 달성률을 추적하여 동기부여를 높이는 시스템

### 1.2 핵심 결정사항
| 항목 | 결정 |
|------|------|
| 목표 설정 주체 | 학생 본인만 설정 |
| 일일 목표 | 연습 시간 + 완료 섹션 수 |
| 주간 목표 | 연습 시간 + 연습 일수 |
| 달성 보상 | 알림 + 스트릭 연계 + 뱃지 |

---

## 2. 데이터 모델

> 📦 **엔티티 정의**: [practice_goal.md](../../schema/entities/practice_goal.md)

### 모델 요약

| 모델 | 설명 | 저장 |
|------|------|:----:|
| PracticeGoal | 연습 목표 설정 | ⭕ Hive |
| DailyPracticeProgress | 일일 진행률 계산 | ❌ |
| WeeklyPracticeProgress | 주간 진행률 계산 | ❌ |

### PracticeGoal 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| dailyTimeMinutes | int? | 일일 연습 시간 목표 (분) |
| dailySectionCount | int? | 일일 완료 섹션 수 목표 |
| weeklyTimeMinutes | int? | 주간 연습 시간 목표 (분) |
| weeklyDayCount | int? | 주간 연습 일수 목표 |
| isActive | bool | 목표 활성화 여부 |

---

## 3. UI 설계

### 3.1 학생 홈 화면 목표 위젯
```
┌─────────────────────────────────────────┐
│ 🎯 오늘의 목표                     [⚙️] │
├─────────────────────────────────────────┤
│ ⏱️ 연습 시간                            │
│ 15분 / 30분                             │
│ [████████████░░░░░░░░░░░░] 50%          │
├─────────────────────────────────────────┤
│ ✅ 완료 섹션                            │
│ 2개 / 3개                               │
│ [████████████████░░░░░░░░] 67%          │
├─────────────────────────────────────────┤
│ 📊 이번 주                              │
│ 시간: 1시간 45분 / 3시간 (58%)          │
│ 연습일: 4일 / 5일 (80%)                 │
└─────────────────────────────────────────┘
```

**상태별 표시:**
- 목표 미설정: "연습 목표를 설정해보세요" + 설정 버튼
- 목표 달성: 축하 메시지 + 체크 아이콘
- 진행 중: 프로그레스 바 + 남은 시간/개수

### 3.2 목표 설정 화면 (PracticeGoalSettingScreen)
```
┌─────────────────────────────────────────┐
│ ← 연습 목표 설정                        │
├─────────────────────────────────────────┤
│ 📅 일일 목표                            │
│ ┌─────────────────────────────────────┐ │
│ │ ⏱️ 연습 시간                        │ │
│ │ [  15  ] [  30  ] [  45  ] [  60  ] │ │
│ │                              분     │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ ✅ 완료 섹션 수                     │ │
│ │ [  1  ] [  2  ] [  3  ] [  5  ]    │ │
│ │                              개     │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ 📊 주간 목표                            │
│ ┌─────────────────────────────────────┐ │
│ │ ⏱️ 총 연습 시간                     │ │
│ │ [  1  ] [  2  ] [  3  ] [  5  ]    │ │
│ │                             시간    │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 📆 연습 일수                        │ │
│ │ [  3  ] [  4  ] [  5  ] [  7  ]    │ │
│ │                              일     │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│                [저장]                   │
└─────────────────────────────────────────┘
```

**동작:**
- 칩 선택 방식으로 빠른 설정
- 사용자 지정 값 입력 가능
- 항목별 비활성화 가능 (설정 안함)

### 3.3 목표 달성 알림

**일일 목표 달성 시:**
```
┌─────────────────────────────────────────┐
│         🎉 오늘 목표 달성!              │
│                                         │
│    연습 시간: 32분 (목표: 30분) ✅      │
│    완료 섹션: 3개 (목표: 3개) ✅        │
│                                         │
│         🔥 5일 연속 스트릭!             │
│                                         │
│              [확인]                     │
└─────────────────────────────────────────┘
```

**주간 목표 달성 시:**
```
┌─────────────────────────────────────────┐
│       🏆 이번 주 목표 달성!             │
│                                         │
│    총 연습: 3시간 15분 ✅               │
│    연습일: 5일 ✅                       │
│                                         │
│       새로운 뱃지를 획득했어요!         │
│           🎖️ "꾸준한 연습가"           │
│                                         │
│              [확인]                     │
└─────────────────────────────────────────┘
```

---

## 4. 스트릭 연계 로직

### 4.1 기존 스트릭과의 관계
```dart
/// 스트릭 증가 조건
/// 기존: 오늘 연습 완료 (아무 섹션이나 완료)
/// 변경: 오늘 목표 달성 시 (목표 미설정 시 기존 로직 유지)
bool shouldIncrementStreak({
  required PracticeGoal? goal,
  required DailyPracticeProgress todayProgress,
  required bool hasAnyPracticeToday,
}) {
  // 목표가 없으면 기존 로직: 연습만 하면 스트릭 증가
  if (goal == null || !goal.hasAnyGoal) {
    return hasAnyPracticeToday;
  }

  // 목표가 있으면: 일일 목표 달성 시만 스트릭 증가
  return todayProgress.isDailyGoalAchieved(goal);
}
```

### 4.2 스트릭 관련 안내
- 목표 설정 화면에서 안내: "목표를 설정하면 목표 달성 시에만 스트릭이 유지됩니다"
- 목표 미달성 시 경고: "오늘 목표를 달성하지 못하면 스트릭이 끊어질 수 있어요"

---

## 5. Repository 인터페이스

```dart
abstract class PracticeGoalRepository {
  /// 학생의 현재 활성 목표 조회
  Future<PracticeGoal?> getActiveGoal(String studentId);

  /// 목표 생성/업데이트
  Future<PracticeGoal> saveGoal(PracticeGoal goal);

  /// 목표 비활성화
  Future<void> deactivateGoal(String goalId);

  /// 일일 진행률 계산
  Future<DailyPracticeProgress> getDailyProgress(
    String studentId,
    DateTime date,
  );

  /// 주간 진행률 계산
  Future<WeeklyPracticeProgress> getWeeklyProgress(
    String studentId,
    DateTime weekStart,
  );
}
```

---

## 6. Provider 설계

```dart
/// 학생의 현재 목표
final practiceGoalProvider = FutureProvider.family<PracticeGoal?, String>(
  (ref, studentId) async {
    final repository = ref.watch(practiceGoalRepositoryProvider);
    return repository.getActiveGoal(studentId);
  },
);

/// 오늘의 진행률
final todayProgressProvider = FutureProvider.family<DailyPracticeProgress, String>(
  (ref, studentId) async {
    final repository = ref.watch(practiceGoalRepositoryProvider);
    return repository.getDailyProgress(studentId, DateTime.now());
  },
);

/// 이번 주 진행률
final weeklyProgressProvider = FutureProvider.family<WeeklyPracticeProgress, String>(
  (ref, studentId) async {
    final repository = ref.watch(practiceGoalRepositoryProvider);
    final now = DateTime.now();
    // 이번 주 월요일 계산
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return repository.getWeeklyProgress(studentId, weekStart);
  },
);

/// 목표 CRUD Notifier
class PracticeGoalNotifier extends AsyncNotifier<void> {
  Future<PracticeGoal> saveGoal(PracticeGoal goal) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceGoalRepositoryProvider);
      final result = await repository.saveGoal(goal);

      // 관련 provider 무효화
      ref.invalidate(practiceGoalProvider(goal.studentId));
      ref.invalidate(todayProgressProvider(goal.studentId));

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
```

---

## 7. 알림 연동

```dart
/// 목표 달성 알림 (LocalNotification)
void showGoalAchievedNotification({
  required bool isDaily,
  required bool isWeekly,
  required int streakDays,
}) {
  if (isDaily) {
    LocalNotification.show(
      title: '🎉 오늘 목표 달성!',
      body: '멋져요! 연습 목표를 달성했어요. 스트릭 ${streakDays}일 🔥',
    );
  }

  if (isWeekly) {
    LocalNotification.show(
      title: '🏆 주간 목표 달성!',
      body: '이번 주 목표를 모두 달성했어요! 새로운 뱃지를 확인해보세요.',
    );
  }
}
```

---

## 8. 파일 구조

```
lib/features/practice/
├── domain/
│   └── entities/
│       └── practice_goal.dart          # PracticeGoal 모델
├── data/
│   └── repositories/
│       └── practice_goal_repository.dart
├── presentation/
│   ├── providers/
│   │   └── practice_goal_provider.dart
│   ├── screens/
│   │   └── practice_goal_setting_screen.dart
│   └── widgets/
│       ├── goal_progress_widget.dart   # 홈 화면 목표 위젯
│       ├── goal_achieved_dialog.dart   # 달성 알림 다이얼로그
│       └── goal_setting_chips.dart     # 목표 선택 칩
```

---

## 9. 구현 체크리스트

- [ ] PracticeGoal 모델 생성 (Hive 어댑터 포함)
- [ ] DailyPracticeProgress, WeeklyPracticeProgress 모델
- [ ] PracticeGoalRepository 인터페이스 및 Mock 구현
- [ ] Provider 구현
- [ ] 홈 화면 목표 위젯 구현
- [ ] 목표 설정 화면 구현
- [ ] 달성 알림 다이얼로그 구현
- [ ] 스트릭 연계 로직 수정
- [ ] 뱃지 시스템 연동 (뱃지 시스템 구현 후)
- [ ] 테스트

---

## 10. 기본값 제안

| 항목 | 추천 기본값 | 옵션 |
|------|:----------:|------|
| 일일 시간 | 30분 | 15, 30, 45, 60분 |
| 일일 섹션 | 3개 | 1, 2, 3, 5개 |
| 주간 시간 | 3시간 | 1, 2, 3, 5시간 |
| 주간 일수 | 5일 | 3, 4, 5, 7일 |
