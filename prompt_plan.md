# Mock → Remote 전환 구현 계획

> 확정일: 2026-03-17
> 상태: ✅ 백엔드 지원 범위 내 전환 완료

## 개요

프론트엔드 Mock Repository를 Remote Repository로 전환하여 `USE_MOCK=false`로 전체 앱 동작 가능하게 함.

## Phase 1: 인프라 및 공통 준비 ✅ 완료

### 1.1 Entity JSON 직렬화 완성 (21개)
- [x] gamification (StudentGamification, PointHistory, PracticeBadge, LevelDefinition)
- [x] analytics (TeacherMonthlyStats, MonthlyTrend, StudentPracticeRank)
- [x] practice (PracticeStats, PracticeStreak, PracticeItem, PracticeGoal, PracticeNote)
- [x] lessons (TeachingResource, TipTemplate, Payment, TuitionSettings, PaymentSummary, FeedbackPreset)
- [x] profile (TeacherSettings, Teacher, TeacherProfile + 7 중첩타입)
- [x] student_home (ManualTeacher)

### 1.2 Repository 인터페이스 정비
- [x] 4개 abstract 인터페이스 추출 (Analytics, Gamification, FeedbackPreset, ManualTeacher)

## Phase 2: Remote Repository 작성 ✅ 완료 (백엔드 지원 범위)

### 2.1 높은 우선순위 — 모두 완료
- [x] SettingsRepository ✅ GET/PUT /settings/teacher (12 메서드)
- [x] TeacherRepository ✅ GET /teachers (중첩 UserResponse 매핑)
- [x] TeacherSearchRepository ✅ GET /teachers 검색/필터/페이지네이션
- [x] TeacherProfileRepository ✅ GET/PUT /teachers/{id}, /teachers/me/profile
- [x] ProposalSettingsRepository ✅ GET/PUT /settings/proposal
- [x] GamificationRepository ✅ GET /gamification/{student_id}
- [ ] LessonPolicyRepository — 백엔드 API 미구현

### 2.2 중간 우선순위 — 대부분 완료
- [x] PracticeGoalRepository ✅ GET/PUT /practice/goals
- [x] PracticeStatsRepository ✅ GET /practice/stats (monthly/weekly/daily 매핑)
- [x] FeedbackPresetRepository ✅ /settings/feedback-presets CRUD
- [x] TeachingResourceRepository ✅ /settings/teaching-resources CRUD
- [ ] PracticeNoteRepository — 백엔드 create만 지원
- [ ] ScheduleConfirmationCardRepository — 백엔드 API 미구현

### 2.3 낮은 우선순위 — 백엔드 의존
- [ ] MembershipRepository — 백엔드 API 미구현
- [ ] LocationRepository — 백엔드 API 미구현
- [ ] LessonClassRepository — 백엔드 API 미구현
- [ ] PieceRepository — 백엔드 API 미구현
- [ ] PracticeItemRepository — 백엔드 API 미구현
- [ ] PracticeRepertoireRepository — Hive 로컬 저장소 의존 (녹음 파일)
- [ ] TipTemplateRepository — 백엔드 API 미구현
- [ ] ManualTeacherRepository — 백엔드 API 미구현
- [ ] PaymentRepository — 백엔드 API 미구현
- [ ] AnalyticsRepository — 백엔드 API 미구현

## Phase 3: Provider 스위칭 로직 정비
- [x] 10개 완료 (Gamification, FeedbackPreset, TeachingResource, ProposalSettings, Settings, PracticeGoal, PracticeStats, Teacher, TeacherProfile, TeacherSearch)
- [x] 6개 TODO 주석 구체화 (백엔드 차단 사유 명시)

## 최종 요약

| 지표 | 값 |
|------|-----|
| 신규 Remote Repository | 11개 |
| Entity 직렬화 | 21+ 클래스 |
| Interface 추출 | 4개 |
| Provider 스위칭 | 10개 |
| 총 커밋 | 9개 (8세션) |
| 남은 항목 | 13개 (모두 백엔드 의존) |
