// Gamification feature public UI boundary.
library;

export 'presentation/widgets/gamification_header.dart' show GamificationHeader;
// 학생 P2 — 오늘의 연습 목표 + 잔디 연동 (doc 46 §4).
export 'presentation/widgets/daily_goal_card.dart' show DailyGoalCard;
// 학생 P3a — 오늘의 미션(고정1+로테이션2, doc 46 §4④).
export 'presentation/widgets/daily_missions_card.dart' show DailyMissionsCard;
// 학생 P1 — student_home 대시보드가 [연습 시작] 카드 + onboarding 트리거를 배치.
export 'presentation/widgets/practice_start_section.dart'
    show PracticeStartSection;
export 'presentation/widgets/student_gamification_onboarding_trigger.dart'
    show StudentGamificationOnboardingTrigger;
