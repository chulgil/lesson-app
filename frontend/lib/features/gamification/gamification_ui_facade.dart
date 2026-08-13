// Gamification feature public UI boundary.
library;

export 'presentation/widgets/gamification_header.dart' show GamificationHeader;
// 학생 P2 — 오늘의 연습 목표(대시보드 요약, PracticeGoal 기준) + 잔디 연동
// (doc 46 §4). #1269: 목표 위젯 단일화 — practice 탭 GoalProgressWidget 과
// 동일 데이터를 컴팩트하게 보여준다.
export 'presentation/widgets/goal_progress_summary_card.dart'
    show GoalProgressSummaryCard;
// 학생 P3a — 오늘의 미션(고정1+로테이션2, doc 46 §4④).
export 'presentation/widgets/daily_missions_card.dart' show DailyMissionsCard;
// 학생 P1 — student_home 대시보드가 [연습 시작] 카드 + onboarding 트리거를 배치.
export 'presentation/widgets/practice_start_section.dart'
    show PracticeStartSection;
export 'presentation/widgets/student_gamification_onboarding_trigger.dart'
    show StudentGamificationOnboardingTrigger;
