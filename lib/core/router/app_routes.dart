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

  // Teacher onboarding routes
  static const teacherPhoneVerification = '/onboarding/phone-verification';
  static const teacherProfileSetup = '/onboarding/profile-setup';
  static const teacherTutorial = '/onboarding/tutorial';

  // Home routes
  static const home = '/home';
  static const studentHome = '/student-home';
  static const parentHome = '/parent-home';

  // Student management routes
  static const students = '/students';
  static const addStudentMethod = '/students/add-method';
  static const addStudent = '/students/add';
  static const studentDetail = '/students/:id';
  static const editStudent = '/students/:id/edit';

  // Lesson routes
  static const lessons = '/lessons';
  static const addLesson = '/lessons/add';
  static const lessonDetail = '/lessons/:id';
  static const editLesson = '/lessons/:id/edit';

  // Practice routes
  static const practice = '/practice';
  static const practiceRepertoire = '/practice/repertoire';
  static const addRepertoire = '/practice/repertoire/add';
  static const repertoireDetail = '/practice/repertoire/:id';
  static const practiceRecording = '/practice/recording/:repertoireId';
  static const addSection = '/practice/section/add';
  static const sectionDetail = '/practice/section/:id';
  static const practiceArchive = '/practice/archive';
  static const practiceNotes = '/practice/section/:sectionId/notes';
  static const practiceGoalSettings = '/practice/goal/settings';
  static const practiceStats = '/practice/stats';

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

  // Schedule routes
  static const selectTeacher = '/schedule/teachers';
  static const lessonTypeSelect = '/schedule/lesson/type';
  static const pendingBookings = '/schedule/pending';
  static const trialLessonRequest = '/schedule/trial/request';
  static const regularLessonRequest = '/schedule/regular/request';
  static const registerRegularLesson = '/schedule/regular/register';
  static const bookingList = '/schedule/bookings';
  static const bookingDetail = '/schedule/booking/:id';

  // Parent routes
  static const childProfiles = '/parent/children';
  static const addChildProfile = '/parent/children/add';
  static const editChildProfile = '/parent/children/:id/edit';

  // Search routes
  static const teacherSearch = '/search/teachers';
  static const teacherDetail = '/teachers/:id';

  // Invite routes
  static const invite = '/invite';
  static const inviteScan = '/invite/scan';
  static const inviteCode = '/invite/code';
  static const inviteConfirm = '/invite/confirm';
  static const inviteHistory = '/invite/history';
  static const pendingRequests = '/invite/requests';
  static const myConnections = '/connections';
}
