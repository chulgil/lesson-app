/// 공통 Duration 상수 — feature 경계에 묶이지 않는 시간 단위.
///
/// SSOT: `.harness/spec/2026-06-11-teacher-settings-redesign.md` §9.4
library;

/// 퀘스트 졸업 후 졸업 카드 자동 dismiss 까지의 grace period.
///
/// `User.quest_celebrated_at` 기준 — 졸업 시점부터 7일 경과하면 졸업 카드
/// (`QuestCelebrationCard`) 와 퀘스트 보드 (`QuestBoardCard`) 가 메인에서
/// 완전히 사라진다.
///
/// 사용자는 "⚙️ 정책·알림·지원 → 가이드 다시 보기" 메뉴로 졸업한 보드를
/// 재노출할 수 있다.
const Duration kQuestGraduationGrace = Duration(days: 7);

/// 새 5묶음 카테고리 카드 NEW 점 표시 윈도우.
///
/// 마이그레이션 대상 (기존 가입 선생님) 의 `ProfileTab` 카테고리 카드는
/// 최초 노출 시점부터 7일간 NEW 점을 표시한다. 사용자가 한 번 카드를 진입
/// (탭) 하면 즉시 dismiss; 7일 경과 시 자동 dismiss.
///
/// 상수 SSOT: `.harness/spec/2026-06-11-teacher-settings-redesign.md` §10.2
const Duration kCategoryNewBadgeWindow = Duration(days: 7);
