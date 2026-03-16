# Mock → Remote 전환 구현 계획

> 확정일: 2026-03-17
> 상태: Phase 1 진행 중

## 개요

프론트엔드 Mock Repository를 Remote Repository로 전환하여 `USE_MOCK=false`로 전체 앱 동작 가능하게 함.

## Phase 1: 인프라 및 공통 준비 (현재 세션)

### 1.1 Entity JSON 직렬화 완성
- [ ] gamification entities (StudentGamification, PointHistory, PracticeBadge)
- [ ] analytics entities (TeacherMonthlyStats, MonthlyTrend, StudentPracticeRank)
- [ ] practice entities (PracticeStats, PracticeStreak, PracticeItem, Piece)
- [ ] lesson entities (TeachingResource, FeedbackPreset, TipTemplate)
- [ ] student_home entities (ManualTeacher)

### 1.2 Repository 인터페이스 정비
- [ ] 레거시 lib/repositories/ → features/[domain]/domain/repositories/ 마이그레이션
- [ ] 카테고리 C Mock에서 abstract 인터페이스 추출

## Phase 2: Remote Repository 작성

### 2.1 높은 우선순위
- [ ] SettingsRepository
- [ ] TeacherRepository
- [ ] TeacherSearchRepository
- [ ] TeacherProfileRepository
- [ ] LessonPolicyRepository
- [ ] ProposalSettingsRepository
- [ ] GamificationRepository

### 2.2 중간 우선순위
- [ ] PracticeGoalRepository
- [ ] PracticeNoteRepository
- [ ] PracticeStatsRepository
- [ ] FeedbackPresetRepository
- [ ] TeachingResourceRepository
- [ ] ScheduleConfirmationCardRepository

### 2.3 낮은 우선순위 (백엔드 의존)
- [ ] MembershipRepository, LocationRepository, LessonClassRepository
- [ ] PieceRepository, PracticeItemRepository, PracticeRepertoireRepository
- [ ] TipTemplateRepository, ManualTeacherRepository
- [ ] PaymentRepository, AnalyticsRepository

## Phase 3: Provider 스위칭 로직 정비
- [ ] 21개 provider 파일의 EnvironmentConfig 분기 통일

## Phase 4: 통합 테스트 및 검증
- [ ] USE_MOCK=false 전체 앱 실행 검증

## Phase 5: 인터페이스 추출 정리 (선택적)
- [ ] 카테고리 C Mock의 abstract 인터페이스 생성
