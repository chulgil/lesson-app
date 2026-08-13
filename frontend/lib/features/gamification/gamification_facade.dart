/// Gamification facade — public entry point for cross-feature gamification use.
library;

export 'domain/entities/gamification.dart' show PointHistory, PointType;
// 표시용 스트릭 SSOT — 학생 화면의 모든 스트릭 숫자가 이 provider 를 통한다
// (streak_ssot.md §1 Phase 3). freeze 로 이어진 공백을 건너뛴 값을 반환.
export 'domain/services/streak_with_freeze_calculator.dart'
    show StreakWithFreezeResult;
export 'presentation/providers/effective_streak_provider.dart'
    show effectiveStreakProvider;
export 'presentation/providers/point_award_service.dart'
    show PointAwardNotifier, pointAwardNotifierProvider;
// 학생 P1 — practice 녹음 종료 시 heatmap/quest 기록 wiring 이 소비.
export 'presentation/providers/growth_heatmap_provider.dart'
    show growthHeatmapRepositoryProvider, growthHeatmapProvider;
// 학생 P2 — 오늘 연습 분 파생 (doc 46 §4). #1269: 목표 값 자체는
// features/practice 의 원격 영속 PracticeGoal 로 통합됨 — practice_facade.dart
// 의 effectiveDailyGoalMinutesProvider 참조.
export 'presentation/providers/today_practice_minutes_provider.dart'
    show todayPracticeMinutesProvider;
export 'presentation/providers/student_quest_provider.dart'
    show studentQuestRepositoryProvider;
// 학생 P3a — 오늘의 미션(고정1+로테이션2, doc 46 §4④).
export 'presentation/providers/daily_missions_provider.dart'
    show dailyMissionsProvider;
