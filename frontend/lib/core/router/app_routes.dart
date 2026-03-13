// App route path constants

/// App route paths - centralized route definitions
class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const splash = '/';
  static const login = '/login';
  static const roleSelect = '/role-select';
  static const termsAgreement = '/terms-agreement';
  static const parentInviteCode = '/parent/invite-code';
  static const studentInviteCode = '/student/invite-code';

  // Teacher onboarding routes
  static const teacherPhoneVerification = '/onboarding/phone-verification';
  static const teacherProfileSetup = '/onboarding/profile-setup';
  static const teacherTutorial = '/onboarding/tutorial';

  // Student onboarding routes
  static const studentProfileSetup = '/student/onboarding/profile-setup';
  static const studentTutorial = '/student/onboarding/tutorial';

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
  static const repertoireHistory = '/practice/history';
  static const tuner = '/practice/tuner';

  // Profile routes
  static const profile = '/profile';
  static const instrumentManagement = '/profile/instruments';
  static const repertoireManagement = '/profile/repertoire';
  static const lessonTimeSettings = '/profile/lesson-time';
  static const paymentManagement = '/profile/payments';
  static const tipTemplateManagement = '/profile/templates';
  static const extendedProfile = '/profile/extended';
  static const educationEdit = '/profile/education/edit';
  static const careerEdit = '/profile/career/edit';
  static const certificateEdit = '/profile/certificate/edit';
  static const profileVisibility = '/profile/visibility';
  static const outstandingPayments = '/profile/outstanding-payments';

  // Student routes
  static const myTeachers = '/student/my-teachers';
  static const addManualTeacher = '/student/my-teachers/add';

  // Settings routes
  static const backupSettings = '/settings/backup';
  static const allRecordings = '/settings/recordings';
  static const help = '/settings/help';
  static const appInfo = '/settings/app-info';
  static const notificationSettings = '/settings/notifications';
  static const profileEdit = '/settings/profile-edit';
  static const termsOfService = '/settings/terms';
  static const privacyPolicy = '/settings/privacy';

  // Follow routes
  static const followList = '/profile/following';

  // Schedule routes
  static const selectTeacher = '/schedule/teachers';
  static const lessonTypeSelect = '/schedule/lesson/type';
  static const pendingBookings = '/schedule/pending';
  static const trialLessonRequest = '/schedule/trial/request';
  static const regularLessonRequest = '/schedule/regular/request';
  static const registerRegularLesson = '/schedule/regular/register';
  static const bookingList = '/schedule/bookings';
  static const bookingDetail = '/schedule/booking/:id';
  static const lessonBooking = '/schedule/book-lesson';
  static const lessonRequest = '/schedule/lesson-request';
  static const lessonRequests = '/schedule/lesson-requests';
  static const myBookings = '/schedule/my-bookings';
  static const teacherAvailability = '/schedule/availability';
  static const groupClassDetail = '/schedule/group-class/:id';
  static const groupClassAttendance = '/schedule/group-class/:id/attendance';

  // Subscription routes
  static const subscriptions = '/subscriptions';
  static const subscriptionDetail = '/subscriptions/:id';
  static const expiringSubscriptions = '/subscriptions/expiring';
  static const issueSubscription = '/subscriptions/issue';
  static const lessonPolicy = '/subscriptions/policy';
  static const subscriptionTemplates = '/subscriptions/templates';

  // Proposal routes
  static const proposalCreate = '/proposals/create';
  static const proposalConfirm = '/proposals/confirm';
  static const proposalSettings = '/proposals/settings';
  static const proposalDetail = '/proposals/:id';

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

  // Gamification routes
  static const badgeCollection = '/gamification/badges';

  // Assignment routes
  static const assignmentDashboard = '/assignments';
}
