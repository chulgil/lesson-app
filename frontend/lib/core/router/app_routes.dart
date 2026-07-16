// App route path constants

/// App route paths - centralized route definitions
class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const splash = '/';
  static const login = '/login';
  static const roleSelect = '/role-select';
  static const parentInviteCode = '/parent/invite-code';
  static const studentInviteCode = '/student/invite-code';

  /// 분야(Discipline) 선택 — 멀티 Discipline 가입 첫 단계(#977).
  /// 등록 분야가 1개(music)면 RoleSelect 게이트에서 auto-skip 되어 도달하지
  /// 않는다. Phase 4 에서 2번째 분야 등록 시 활성화.
  static const disciplineSelection = '/discipline-select';

  // Teacher onboarding routes
  static const teacherPhoneVerification = '/onboarding/phone-verification';
  static const teacherProfileSetup = '/onboarding/profile-setup';
  // #422 — first availability quest (simple setup) per
  // docs/specs/onboarding/teacher_first_availability_setup.md
  static const teacherFirstAvailability = '/onboarding/first-availability';

  /// Step 2.5 카테고리 미리보기 (W4 Task 4.2).
  /// spec §9.2 — FirstAvailability 완료 후 1회 노출.
  static const onboardingCategoryPreview = '/onboarding/category-preview';

  /// "가이드 다시 보기" — 졸업 후 fallback 진입점 (W5 Task 5.6).
  /// spec §8.4 — ⚙️ 정책·알림·지원 → 메뉴에서만 접근.
  static const guideReshow = '/profile/guide-reshow';

  // Student onboarding routes
  static const studentProfileSetup = '/student/onboarding/profile-setup';
  static const studentTutorial = '/student/onboarding/tutorial';

  /// 임시 안전망 — 학생 직접 가입은 통신사 본인인증(PASS) 통합 전까지 차단.
  /// 정책: docs/specs/user/phone_verification_policy.md §3.2.
  /// PASS 통합 시점에 [teacherPhoneVerification] 와 같은 학생용 전화인증
  /// 화면 라우트로 교체될 placeholder.
  static const studentSignupBlocked = '/student/onboarding/signup-blocked';

  // Home routes
  static const home = '/home';
  static const studentHome = '/student-home';
  static const parentHome = '/parent-home';

  // Student management routes
  static const students = '/students';
  static const addStudentMethod = '/students/add-method';
  static const addStudent = '/students/add';
  static const studentDetail = '/students/:id';
  static const studentNotes = '/students/:id/notes';
  static const editStudent = '/students/:id/edit';

  // Lesson routes
  static const lessons = '/lessons';
  static const addLesson = '/lessons/add';
  static const lessonDetail = '/lessons/:id';
  static const editLesson = '/lessons/:id/edit';
  static const quickFeedbackList = '/lessons/quick-feedback';
  static const quickFeedback = '/lessons/quick-feedback/:id';
  static const bulkFeedback = '/lessons/bulk-feedback';

  // Practice routes
  static const practice = '/practice';
  static const practiceRepertoire = '/practice/repertoire';
  static const addRepertoire = '/practice/repertoire/add';
  static const quickAddRepertoire = '/practice/repertoire/quick-add';
  static const repertoireDetail = '/practice/repertoire/:id';
  static const editRepertoire = '/practice/repertoire/:id/edit';
  static const practiceRecording = '/practice/recording/:repertoireId';
  static const addSection = '/practice/section/add';
  static const editSection = '/practice/section/:id/edit';
  static const sectionDetail = '/practice/section/:id';
  static const practiceArchive = '/practice/archive';
  static const practiceNotes = '/practice/section/:sectionId/notes';
  static const practiceGoalSettings = '/practice/goal/settings';
  static const practiceStats = '/practice/stats';
  // #512 — teacher-side per-student YouTube loop repeat stats.
  static const practiceLoopStats = '/practice/loop-stats';
  static const repertoireHistory = '/practice/history';
  static const awaitingFeedback = '/practice/awaiting-feedback';

  // Profile routes
  static const profile = '/profile';
  static const instrumentManagement = '/profile/instruments';
  static const repertoireManagement = '/profile/repertoire';

  /// 5묶음 IA 로 흩어진 legacy 라우트.
  /// W2 (2026-06-11) 에서 ProfileTab 메뉴 진입로는 제거됨.
  /// W3 Task 3.5 (2026-06-11) 에서 화면 파일도 해체. 라우트 자체는 redirect 로
  /// 유지하여 외부 진입(quest 카드/정책 화면 등)을 5묶음 메인(/profile) 으로
  /// 흘려보낸다.
  /// spec: .harness/spec/2026-06-11-teacher-settings-redesign.md §6.1
  @Deprecated('W3 2026-06-11 — 5묶음으로 흩어지고 화면 해체됨. redirect 만 유지.')
  static const lessonTimeSettings = '/profile/lesson-time';

  /// 🎓 수업방식 묶음 화면 (W3 Task 3.2).
  /// spec §6.2 — `LessonStyleSettingsScreen` 진입로.
  /// 3 항목: 레슨 1회 시간 + 최소 사전예약 + 학생 안내 메시지.
  static const lessonStyleSettings = '/profile/lesson-style';

  /// 💰 가격표 화면 (W3 Task 3.3).
  /// spec §6.3 — `PriceTableScreen` 진입로.
  /// `LessonTimeSettingsScreen` §6 가격표 섹션을 분리.
  static const priceTable = '/profile/price-table';

  // #765 — 복합 카테고리 BottomSheet → 정식 라우트 승격.
  /// 💰 수강권·정산 카테고리 메뉴 화면 (#765). teacherId 쿼리 파라미터 전달.
  static const subscriptionBillingCategory = '/profile/subscription-billing';

  /// 👤 내 프로필 카테고리 메뉴 화면 (#765).
  static const myProfileCategory = '/profile/my-profile';

  /// ⚙️ 알림·소식·지원 카테고리 메뉴 화면 (#765).
  static const policyNotificationsCategory = '/profile/policy-notifications';
  static const tipTemplateManagement = '/profile/templates';
  static const feedbackTemplateManagement = '/profile/feedback-templates';
  static const extendedProfile = '/profile/extended';
  static const educationEdit = '/profile/education/edit';
  static const careerEdit = '/profile/career/edit';
  static const certificateEdit = '/profile/certificate/edit';
  static const bankAccountEdit = '/profile/bank-account/edit';
  static const basicInfoEdit = '/profile/basic-info/edit';
  static const profileVisibility = '/profile/visibility';
  static const profilePreview = '/profile/preview';
  static const outstandingPayments = '/profile/outstanding-payments';
  // #424 — Teacher payment-pending dashboard list
  static const paymentPending = '/payments/pending';
  // #5 D-G3 Phase 2 — Teacher invite-pending dashboard list
  static const invitePending = '/invites/pending';
  static const cancellationDefaults = '/profile/cancellation-defaults';

  // Student routes
  static const myTeachers = '/student/my-teachers';
  static const addManualTeacher = '/student/my-teachers/add';

  // Settings routes
  static const backupSettings = '/settings/backup';
  static const allRecordings = '/settings/recordings';
  static const help = '/settings/help';
  static const appInfo = '/settings/app-info';
  static const newsRoadmap = '/settings/news-roadmap';
  static const notificationSettings = '/settings/notifications';
  static const profileEdit = '/settings/profile-edit';
  static const termsOfService = '/settings/terms';
  static const privacyPolicy = '/settings/privacy';

  // Follow routes
  static const followList = '/profile/following';
  static const followFeed = '/follow/feed';

  // Schedule routes
  static const selectTeacher = '/schedule/teachers';
  static const lessonTypeSelect = '/schedule/lesson/type';
  static const pendingBookings = '/schedule/pending';
  static const trialLessonRequest = '/schedule/trial/request';
  static const regularLessonRequest = '/schedule/regular/request';
  static const registerRegularLesson = '/schedule/regular/register';
  static const bookingList = '/schedule/bookings';
  static const lessonBooking = '/schedule/book-lesson';

  /// Student first-come direct slot booking (#580 student_direct_booking_spec).
  static const lessonDirectBooking = '/schedule/booking/direct';
  static const lessonRequest = '/schedule/lesson-request';
  static const lessonRequests = '/schedule/lesson-requests';
  static const myBookings = '/schedule/my-bookings';
  static const teacherAvailability = '/schedule/availability';
  static const teacherVacationMode = '/schedule/vacation';
  static const groupClassDetail = '/schedule/group-class/:id';
  static const groupClassAttendance = '/schedule/group-class/:id/attendance';
  static const requestCompletion = '/schedule/request-completion';
  static const requestDetail = '/schedule/request/:id';
  static const regularScheduleChange = '/schedule/change-regular';

  // Subscription routes
  static const subscriptions = '/subscriptions';
  static const subscriptionDetail = '/subscriptions/:id';
  static const expiringSubscriptions = '/subscriptions/expiring';
  static const issueSubscription = '/subscriptions/issue';
  static const lessonPolicy = '/subscriptions/policy';
  static const subscriptionTemplates = '/subscriptions/templates';
  static const teacherSubscriptions = '/subscriptions/teacher';
  static const makeupCredits = '/subscriptions/makeup-credits';
  static const scheduleChangeRequests = '/schedule-change-requests';

  // Proposal routes
  static const proposalCreate = '/proposals/create';
  static const proposalConfirm = '/proposals/confirm';
  static const proposalSettings = '/proposals/settings';
  static const proposalDetail = '/proposals/:id';
  static const renewalDetail = '/proposals/renewal/:id';

  // Parent routes
  static const childProfiles = '/parent/children';
  static const addChildProfile = '/parent/children/add';
  static const editChildProfile = '/parent/children/:id/edit';

  // Search routes
  static const teacherSearch = '/search/teachers';
  static const teacherDetail = '/teachers/:id';
  static const academyDetail = '/academies/:id';

  // Invite routes
  static const invite = '/invite';
  static const inviteScan = '/invite/scan';
  static const inviteCode = '/invite/code';
  static const inviteConfirm = '/invite/confirm';
  static const inviteHistory = '/invite/history';
  static const pendingRequests = '/invite/requests';
  static const myConnections = '/connections';

  // Notification routes
  static const notifications = '/notifications';

  // Lesson request routes
  static const myLessonRequests = '/lesson-requests';

  // Analytics routes
  static const analytics = '/analytics';
  static const teacherAttendance = '/analytics/attendance';

  // Gamification routes
  static const badgeCollection = '/gamification/badges';
  static const studentGrowthDetail = '/student/growth-detail';

  // Assignment routes
  static const assignmentDashboard = '/assignments';

  // Announcement routes
  static const announcementHistory = '/students/announcement-history';

  // Academy routes
  static const academyInviteAccept = '/academy/accept';
  static const academyInviteExpired = '/academy/expired';
  static const academyAnnouncements = '/academy/:academyId/announcements';
  static const academyAnnouncementDetail =
      '/academy/:academyId/announcements/:announcementId';
  static const academyInquiries = '/academy/:academyId/inquiries';
  static const academyInquiryDetail =
      '/academy/:academyId/inquiries/:inquiryId';
  // G15 학원장 일괄 휴강 (강사 시점)
  // 정책 SSOT: docs/specs/web/academy/owner_bulk_closure_spec.md §5
  static const academyBulkClosureDetail =
      '/academy/:academyId/closures/:closureId';
  static const academyMakeupInput =
      '/academy/:academyId/closures/:closureId/makeup';
  // 강사 시점 활동 타임라인 (academy_master.md §6.1 라우트 등록)
  static const academyActivityTimeline =
      '/academy/:academyId/teachers/:actorMemberId/activity';
  static const noteAccessRequest = '/note-access/:requestId';

  // Public sharing routes (R2 #318 — 토큰 기반 읽기 전용 요약)
  static const studentSummary = '/student/summary/:token';
}
