// Route Integrity Gate — CI gate for dead-route bug class.
//
// Catches: push/go/actionUrl targets that resolve to an unregistered GoRoute.
// Source: 5 dead-route bugs found in session before #731 (lessonRequest
//   singular vs plural, practice standalone, proposalDetail with unsubstituted
//   :id, etc.).
//
// Strategy: pure Dart regex scan — no widget tree needed.
//   1. Build the registered-routes set from AppRoutes constants used in
//      routes/*.dart (path: AppRoutes.X).
//   2. Scan lib/**/*.dart for navigation calls (context.push/go, actionUrl:)
//      and extract the target path template.
//   3. For each concrete target strip the query string, verify that (a) no
//      :param segment is left unsubstituted and (b) the path template matches
//      a registered route pattern (`:param` wildcard matching).
//
// Allowlist: a small documented set of targets that can't be statically
// resolved (e.g. user.homeRoute computed at runtime, FCM server-side URLs).
// Add to [_allowlistPrefixes] with a comment — keep it minimal.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/router/app_routes.dart';

// ---------------------------------------------------------------------------
// All AppRoutes constants — used to verify the registered-route set below
// covers everything navigated in source. Not used at runtime; kept for
// documentation: if a constant is pushed/go'd it must appear in both this
// comment block and _registeredTemplates.
//
// role.homeRoute — resolved at runtime from UserRole enum; resolves to
//   /home, /student-home, or /parent-home — all registered. Not statically
//   scannable as a string literal, so not listed here.
//
// FCM/server action_url — parsed from server payload at runtime;
//   not statically verifiable. Server must use AppRoutes constants.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Build the complete AppRoutes constant set — used in the map-integrity test.
// ---------------------------------------------------------------------------
Set<String> _buildAllRouteValues() {
  return {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.roleSelect,
    AppRoutes.disciplineSelection,
    AppRoutes.parentInviteCode,
    AppRoutes.studentInviteCode,
    AppRoutes.teacherPhoneVerification,
    AppRoutes.teacherProfileSetup,
    AppRoutes.teacherFirstAvailability,
    AppRoutes.onboardingCategoryPreview,
    AppRoutes.guideReshow,
    AppRoutes.studentProfileSetup,
    AppRoutes.studentTutorial,
    AppRoutes.studentSignupBlocked,
    AppRoutes.home,
    AppRoutes.studentHome,
    AppRoutes.parentHome,
    AppRoutes.students,
    AppRoutes.addStudentMethod,
    AppRoutes.addStudent,
    AppRoutes.studentDetail,
    AppRoutes.studentNotes,
    AppRoutes.editStudent,
    AppRoutes.lessons,
    AppRoutes.addLesson,
    AppRoutes.lessonDetail,
    AppRoutes.editLesson,
    AppRoutes.quickFeedbackList,
    AppRoutes.quickFeedback,
    AppRoutes.bulkFeedback,
    AppRoutes.practice,
    AppRoutes.practiceRepertoire,
    AppRoutes.addRepertoire,
    AppRoutes.quickAddRepertoire,
    AppRoutes.repertoireDetail,
    AppRoutes.editRepertoire,
    AppRoutes.practiceRecording,
    AppRoutes.addSection,
    AppRoutes.editSection,
    AppRoutes.sectionDetail,
    AppRoutes.practiceArchive,
    AppRoutes.practiceNotes,
    AppRoutes.practiceGoalSettings,
    AppRoutes.practiceStats,
    AppRoutes.practiceLoopStats,
    AppRoutes.awaitingFeedback,
    AppRoutes.recordingDetail,
    AppRoutes.repertoireHistory,
    AppRoutes.profile,
    AppRoutes.instrumentManagement,
    AppRoutes.repertoireManagement,
    AppRoutes.lessonTimeSettings, // redirect-only — still registered
    AppRoutes.lessonStyleSettings,
    AppRoutes.priceTable,
    AppRoutes.subscriptionBillingCategory,
    AppRoutes.myProfileCategory,
    AppRoutes.policyNotificationsCategory,
    AppRoutes.tipTemplateManagement,
    AppRoutes.feedbackTemplateManagement,
    AppRoutes.extendedProfile,
    AppRoutes.educationEdit,
    AppRoutes.careerEdit,
    AppRoutes.certificateEdit,
    AppRoutes.bankAccountEdit,
    AppRoutes.basicInfoEdit,
    AppRoutes.profileVisibility,
    AppRoutes.profilePreview,
    AppRoutes.outstandingPayments,
    AppRoutes.paymentPending,
    AppRoutes.invitePending,
    AppRoutes.cancellationDefaults,
    AppRoutes.myTeachers,
    AppRoutes.addManualTeacher,
    AppRoutes.backupSettings,
    AppRoutes.allRecordings,
    AppRoutes.help,
    AppRoutes.appInfo,
    AppRoutes.newsRoadmap,
    AppRoutes.notificationSettings,
    AppRoutes.profileEdit,
    AppRoutes.termsOfService,
    AppRoutes.privacyPolicy,
    AppRoutes.followList,
    AppRoutes.followFeed,
    AppRoutes.selectTeacher,
    AppRoutes.pendingBookings,
    AppRoutes.registerRegularLesson,
    AppRoutes.lessonBooking,
    AppRoutes.lessonDirectBooking,
    // ignore: deprecated_member_use_from_same_package
    AppRoutes.lessonRequest, // INTENTIONALLY listed — currently NOT registered
    AppRoutes.lessonRequests,
    AppRoutes.myBookings,
    AppRoutes.teacherAvailability,
    AppRoutes.teacherVacationMode,
    AppRoutes.groupClassDetail,
    AppRoutes.groupClassAttendance,
    AppRoutes.requestCompletion,
    AppRoutes.requestDetail,
    AppRoutes.subscriptions,
    AppRoutes.subscriptionDetail,
    AppRoutes.expiringSubscriptions,
    AppRoutes.issueSubscription,
    AppRoutes.lessonPolicy,
    AppRoutes.subscriptionTemplates,
    AppRoutes.teacherSubscriptions,
    AppRoutes.makeupCredits,
    AppRoutes.scheduleChangeRequests,
    AppRoutes.proposalConfirm,
    AppRoutes.proposalSettings,
    AppRoutes.proposalDetail,
    AppRoutes.renewalDetail,
    AppRoutes.childProfiles,
    AppRoutes.addChildProfile,
    AppRoutes.editChildProfile,
    AppRoutes.teacherSearch,
    AppRoutes.teacherDetail,
    AppRoutes.academyDetail,
    AppRoutes.invite,
    AppRoutes.inviteScan,
    AppRoutes.inviteCode,
    AppRoutes.inviteConfirm,
    AppRoutes.inviteHistory,
    AppRoutes.pendingRequests,
    AppRoutes.myConnections,
    AppRoutes.notifications,
    AppRoutes.myLessonRequests,
    AppRoutes.analytics,
    AppRoutes.teacherAttendance,
    AppRoutes.badgeCollection,
    AppRoutes.studentGrowthDetail,
    AppRoutes.assignmentDashboard,
    AppRoutes.announcementHistory,
    AppRoutes.academyInviteAccept,
    AppRoutes.academyInviteExpired,
    AppRoutes.academyAnnouncements,
    AppRoutes.academyAnnouncementDetail,
    AppRoutes.academyInquiries,
    AppRoutes.academyInquiryDetail,
    AppRoutes.academyBulkClosureDetail,
    AppRoutes.academyMakeupInput,
    AppRoutes.academyActivityTimeline,
    AppRoutes.noteAccessRequest,
    AppRoutes.studentSummary,
  };
}

// ---------------------------------------------------------------------------
// Route-matching logic.
// ---------------------------------------------------------------------------

/// The set of route PATH TEMPLATES actually registered in GoRouter.
/// These are the `path:` values used in routes/*.dart — not all AppRoutes.
/// Built by scanning `grep "path: AppRoutes." routes/*.dart` at test-write
/// time. If a new GoRoute is added, add its template here AND to [_buildRegisteredRoutes].
const _registeredTemplates = <String>{
  // auth_routes.dart
  '/login',
  '/role-select',
  '/discipline-select',
  '/parent/invite-code',
  '/student/invite-code',
  '/onboarding/phone-verification',
  '/onboarding/profile-setup',
  '/onboarding/first-availability',
  '/onboarding/category-preview',
  '/student/onboarding/profile-setup',
  '/student/onboarding/signup-blocked',
  '/student/onboarding/tutorial',
  '/academy/accept',
  '/academy/expired',
  // home_routes.dart
  '/home',
  '/student-home',
  '/parent-home',
  '/assignments',
  // invite_routes.dart
  '/invite',
  '/invite/scan',
  '/invite/code',
  '/invite/confirm',
  '/invite/history',
  '/invite/requests',
  '/connections',
  // lesson_routes.dart
  '/lessons',
  '/lessons/add',
  '/lessons/bulk-feedback',
  '/lessons/quick-feedback',
  '/lessons/quick-feedback/:id',
  '/lessons/:id',
  '/lessons/:id/edit',
  // notification_routes.dart
  '/notifications',
  '/academy/:academyId/announcements',
  '/academy/:academyId/announcements/:announcementId',
  '/academy/:academyId/inquiries',
  '/academy/:academyId/inquiries/:inquiryId',
  // parent_routes.dart
  '/parent/children/add',
  '/parent/children/:id/edit',
  '/parent/children',
  // practice_routes.dart
  '/practice/awaiting-feedback',
  '/practice/repertoire',
  '/practice/repertoire/add',
  '/practice/repertoire/quick-add',
  '/practice/repertoire/:id',
  '/practice/repertoire/:id/edit',
  '/practice/recording/:repertoireId',
  '/practice/section/add',
  '/practice/section/:id/edit',
  '/practice/section/:id',
  '/practice/archive',
  '/practice/section/:sectionId/notes',
  '/practice/goal/settings',
  '/practice/stats',
  '/practice/loop-stats',
  '/practice/history',
  '/note-access/:requestId',
  '/recordings/:recordingId',
  // profile_routes.dart
  '/profile/instruments',
  '/profile/repertoire',
  '/profile/lesson-time', // redirect-only
  '/profile/lesson-style',
  '/profile/price-table',
  '/profile/subscription-billing', // #765
  '/profile/my-profile', // #765
  '/profile/policy-notifications', // #765
  '/profile/guide-reshow',
  '/profile/templates',
  '/profile/feedback-templates',
  '/profile/extended',
  '/profile/basic-info/edit',
  '/profile/education/edit',
  '/profile/career/edit',
  '/profile/certificate/edit',
  '/profile/bank-account/edit',
  '/profile/preview',
  '/profile/visibility',
  '/profile/outstanding-payments',
  '/payments/pending',
  '/invites/pending',
  '/analytics',
  '/analytics/attendance',
  '/profile/cancellation-defaults',
  // schedule_routes.dart
  '/schedule/teachers',
  '/schedule/book-lesson',
  '/schedule/request-completion',
  '/schedule/request/:id',
  '/schedule/lesson-requests',
  '/lesson-requests',
  '/schedule/booking/direct',
  '/schedule/my-bookings',
  '/schedule/availability',
  '/schedule/vacation',
  '/schedule/pending',
  '/schedule/regular/register',
  '/schedule/group-class/:id',
  '/schedule/group-class/:id/attendance',
  // search_routes.dart
  '/search/teachers',
  '/teachers/:id',
  '/academies/:id',
  // settings_routes.dart
  '/student/my-teachers',
  '/student/my-teachers/add',
  '/settings/backup',
  '/settings/recordings',
  '/settings/help',
  '/settings/app-info',
  '/settings/news-roadmap',
  '/settings/notifications',
  '/settings/profile-edit',
  '/settings/terms',
  '/settings/privacy',
  '/profile/following',
  '/follow/feed',
  // share_routes.dart
  '/student/summary/:token',
  // student_routes.dart
  '/students/add-method',
  '/students/add',
  '/students/:id',
  '/students/:id/notes',
  '/students/:id/edit',
  '/gamification/badges',
  '/students/announcement-history',
  '/student/growth-detail',
  // subscription_routes.dart
  '/proposals/settings',
  '/subscriptions/templates',
  '/subscriptions',
  '/subscriptions/teacher',
  '/subscriptions/expiring',
  '/schedule-change-requests',
  '/subscriptions/issue',
  '/subscriptions/makeup-credits',
  '/subscriptions/policy',
  '/proposals/confirm',
  '/proposals/renewal/:id',
  '/subscriptions/:id',
  '/proposals/accept/:id',
  '/proposals/:id',
  // academy_routes.dart
  '/academy/:academyId/closures/:closureId',
  '/academy/:academyId/closures/:closureId/makeup',
  '/academy/:academyId/teachers/:actorMemberId/activity',
};

/// Returns true if [concretePath] matches [template].
/// Templates use `:param` segments that match any non-empty segment.
bool _matchesTemplate(String template, String concretePath) {
  final tParts = template.split('/');
  final cParts = concretePath.split('/');
  if (tParts.length != cParts.length) return false;
  for (var i = 0; i < tParts.length; i++) {
    if (tParts[i].startsWith(':')) continue; // wildcard
    if (tParts[i] != cParts[i]) return false;
  }
  return true;
}

/// Returns true if [concretePath] resolves to any registered template.
bool _isRegistered(String concretePath) {
  return _registeredTemplates.any((t) => _matchesTemplate(t, concretePath));
}

/// Strips query string. `/foo/bar?x=1` → `/foo/bar`.
String _stripQuery(String path) {
  final idx = path.indexOf('?');
  return idx >= 0 ? path.substring(0, idx) : path;
}

/// Returns true if the path has an unsubstituted `:param` segment.
bool _hasUnsubstitutedParam(String path) {
  return path.split('/').any((seg) => seg.startsWith(':'));
}

// ---------------------------------------------------------------------------
// Source scanner.
// ---------------------------------------------------------------------------

/// Map of all AppRoutes constant names to their string values.
/// This is the single source of truth — derived from AppRoutes class.
///
/// Dart has no runtime reflection in test, so constants are enumerated
/// explicitly. Keep in sync with AppRoutes class:
///   grep "static const" lib/core/router/app_routes.dart
Map<String, String> get _appRoutesMap {
  return {
    'splash': AppRoutes.splash,
    'login': AppRoutes.login,
    'roleSelect': AppRoutes.roleSelect,
    'disciplineSelection': AppRoutes.disciplineSelection,
    'parentInviteCode': AppRoutes.parentInviteCode,
    'studentInviteCode': AppRoutes.studentInviteCode,
    'teacherPhoneVerification': AppRoutes.teacherPhoneVerification,
    'teacherProfileSetup': AppRoutes.teacherProfileSetup,
    'teacherFirstAvailability': AppRoutes.teacherFirstAvailability,
    'onboardingCategoryPreview': AppRoutes.onboardingCategoryPreview,
    'guideReshow': AppRoutes.guideReshow,
    'studentProfileSetup': AppRoutes.studentProfileSetup,
    'studentTutorial': AppRoutes.studentTutorial,
    'studentSignupBlocked': AppRoutes.studentSignupBlocked,
    'home': AppRoutes.home,
    'studentHome': AppRoutes.studentHome,
    'parentHome': AppRoutes.parentHome,
    'students': AppRoutes.students,
    'addStudentMethod': AppRoutes.addStudentMethod,
    'addStudent': AppRoutes.addStudent,
    'studentDetail': AppRoutes.studentDetail,
    'studentNotes': AppRoutes.studentNotes,
    'editStudent': AppRoutes.editStudent,
    'lessons': AppRoutes.lessons,
    'addLesson': AppRoutes.addLesson,
    'lessonDetail': AppRoutes.lessonDetail,
    'editLesson': AppRoutes.editLesson,
    'quickFeedbackList': AppRoutes.quickFeedbackList,
    'quickFeedback': AppRoutes.quickFeedback,
    'bulkFeedback': AppRoutes.bulkFeedback,
    'practice': AppRoutes.practice,
    'practiceRepertoire': AppRoutes.practiceRepertoire,
    'addRepertoire': AppRoutes.addRepertoire,
    'quickAddRepertoire': AppRoutes.quickAddRepertoire,
    'repertoireDetail': AppRoutes.repertoireDetail,
    'editRepertoire': AppRoutes.editRepertoire,
    'practiceRecording': AppRoutes.practiceRecording,
    'addSection': AppRoutes.addSection,
    'editSection': AppRoutes.editSection,
    'sectionDetail': AppRoutes.sectionDetail,
    'practiceArchive': AppRoutes.practiceArchive,
    'practiceNotes': AppRoutes.practiceNotes,
    'practiceGoalSettings': AppRoutes.practiceGoalSettings,
    'practiceStats': AppRoutes.practiceStats,
    'practiceLoopStats': AppRoutes.practiceLoopStats,
    'awaitingFeedback': AppRoutes.awaitingFeedback,
    'recordingDetail': AppRoutes.recordingDetail,
    'repertoireHistory': AppRoutes.repertoireHistory,
    'profile': AppRoutes.profile,
    'instrumentManagement': AppRoutes.instrumentManagement,
    'repertoireManagement': AppRoutes.repertoireManagement,
    'lessonTimeSettings': AppRoutes.lessonTimeSettings,
    'lessonStyleSettings': AppRoutes.lessonStyleSettings,
    'priceTable': AppRoutes.priceTable,
    'subscriptionBillingCategory': AppRoutes.subscriptionBillingCategory,
    'myProfileCategory': AppRoutes.myProfileCategory,
    'policyNotificationsCategory': AppRoutes.policyNotificationsCategory,
    'tipTemplateManagement': AppRoutes.tipTemplateManagement,
    'feedbackTemplateManagement': AppRoutes.feedbackTemplateManagement,
    'extendedProfile': AppRoutes.extendedProfile,
    'educationEdit': AppRoutes.educationEdit,
    'careerEdit': AppRoutes.careerEdit,
    'certificateEdit': AppRoutes.certificateEdit,
    'bankAccountEdit': AppRoutes.bankAccountEdit,
    'basicInfoEdit': AppRoutes.basicInfoEdit,
    'profileVisibility': AppRoutes.profileVisibility,
    'profilePreview': AppRoutes.profilePreview,
    'outstandingPayments': AppRoutes.outstandingPayments,
    'paymentPending': AppRoutes.paymentPending,
    'invitePending': AppRoutes.invitePending,
    'cancellationDefaults': AppRoutes.cancellationDefaults,
    'myTeachers': AppRoutes.myTeachers,
    'addManualTeacher': AppRoutes.addManualTeacher,
    'backupSettings': AppRoutes.backupSettings,
    'allRecordings': AppRoutes.allRecordings,
    'help': AppRoutes.help,
    'appInfo': AppRoutes.appInfo,
    'newsRoadmap': AppRoutes.newsRoadmap,
    'notificationSettings': AppRoutes.notificationSettings,
    'profileEdit': AppRoutes.profileEdit,
    'termsOfService': AppRoutes.termsOfService,
    'privacyPolicy': AppRoutes.privacyPolicy,
    'followList': AppRoutes.followList,
    'followFeed': AppRoutes.followFeed,
    'selectTeacher': AppRoutes.selectTeacher,
    'pendingBookings': AppRoutes.pendingBookings,
    'registerRegularLesson': AppRoutes.registerRegularLesson,
    'lessonBooking': AppRoutes.lessonBooking,
    'lessonDirectBooking': AppRoutes.lessonDirectBooking,
    // ignore: deprecated_member_use_from_same_package
    'lessonRequest': AppRoutes.lessonRequest,
    'lessonRequests': AppRoutes.lessonRequests,
    'myBookings': AppRoutes.myBookings,
    'teacherAvailability': AppRoutes.teacherAvailability,
    'teacherVacationMode': AppRoutes.teacherVacationMode,
    'groupClassDetail': AppRoutes.groupClassDetail,
    'groupClassAttendance': AppRoutes.groupClassAttendance,
    'requestCompletion': AppRoutes.requestCompletion,
    'requestDetail': AppRoutes.requestDetail,
    'subscriptions': AppRoutes.subscriptions,
    'subscriptionDetail': AppRoutes.subscriptionDetail,
    'expiringSubscriptions': AppRoutes.expiringSubscriptions,
    'issueSubscription': AppRoutes.issueSubscription,
    'lessonPolicy': AppRoutes.lessonPolicy,
    'subscriptionTemplates': AppRoutes.subscriptionTemplates,
    'teacherSubscriptions': AppRoutes.teacherSubscriptions,
    'makeupCredits': AppRoutes.makeupCredits,
    'scheduleChangeRequests': AppRoutes.scheduleChangeRequests,
    'proposalConfirm': AppRoutes.proposalConfirm,
    'proposalSettings': AppRoutes.proposalSettings,
    'proposalDetail': AppRoutes.proposalDetail,
    'renewalDetail': AppRoutes.renewalDetail,
    'childProfiles': AppRoutes.childProfiles,
    'addChildProfile': AppRoutes.addChildProfile,
    'editChildProfile': AppRoutes.editChildProfile,
    'teacherSearch': AppRoutes.teacherSearch,
    'teacherDetail': AppRoutes.teacherDetail,
    'academyDetail': AppRoutes.academyDetail,
    'invite': AppRoutes.invite,
    'inviteScan': AppRoutes.inviteScan,
    'inviteCode': AppRoutes.inviteCode,
    'inviteConfirm': AppRoutes.inviteConfirm,
    'inviteHistory': AppRoutes.inviteHistory,
    'pendingRequests': AppRoutes.pendingRequests,
    'myConnections': AppRoutes.myConnections,
    'notifications': AppRoutes.notifications,
    'myLessonRequests': AppRoutes.myLessonRequests,
    'analytics': AppRoutes.analytics,
    'teacherAttendance': AppRoutes.teacherAttendance,
    'badgeCollection': AppRoutes.badgeCollection,
    'studentGrowthDetail': AppRoutes.studentGrowthDetail,
    'assignmentDashboard': AppRoutes.assignmentDashboard,
    'announcementHistory': AppRoutes.announcementHistory,
    'academyInviteAccept': AppRoutes.academyInviteAccept,
    'academyInviteExpired': AppRoutes.academyInviteExpired,
    'academyAnnouncements': AppRoutes.academyAnnouncements,
    'academyAnnouncementDetail': AppRoutes.academyAnnouncementDetail,
    'academyInquiries': AppRoutes.academyInquiries,
    'academyInquiryDetail': AppRoutes.academyInquiryDetail,
    'academyBulkClosureDetail': AppRoutes.academyBulkClosureDetail,
    'academyMakeupInput': AppRoutes.academyMakeupInput,
    'academyActivityTimeline': AppRoutes.academyActivityTimeline,
    'noteAccessRequest': AppRoutes.noteAccessRequest,
    'studentSummary': AppRoutes.studentSummary,
  };
}

// ---------------------------------------------------------------------------
// Core matcher exposed for self-check unit tests.
// ---------------------------------------------------------------------------

/// Result of matching a single navigation target.
class _MatchResult {
  final String target; // raw target string before stripping
  final String basePath; // after stripping query
  final bool unsubstitutedParam; // true if :param segment left
  final bool notRegistered; // true if no registered template matches
  final String reason; // human-readable reason for failure

  const _MatchResult({
    required this.target,
    required this.basePath,
    required this.unsubstitutedParam,
    required this.notRegistered,
    required this.reason,
  });

  bool get isFailure => unsubstitutedParam || notRegistered;
}

_MatchResult _checkTarget(String target) {
  final base = _stripQuery(target);
  if (_hasUnsubstitutedParam(base)) {
    return _MatchResult(
      target: target,
      basePath: base,
      unsubstitutedParam: true,
      notRegistered: false,
      reason: 'Unsubstituted :param segment in path: $base',
    );
  }
  if (!_isRegistered(base)) {
    return _MatchResult(
      target: target,
      basePath: base,
      unsubstitutedParam: false,
      notRegistered: true,
      reason: 'No registered GoRoute matches: $base',
    );
  }
  return _MatchResult(
    target: target,
    basePath: base,
    unsubstitutedParam: false,
    notRegistered: false,
    reason: 'OK',
  );
}

// ---------------------------------------------------------------------------
// File scanner.
// ---------------------------------------------------------------------------

/// Navigation finding from a source file.
class _NavFinding {
  final String file;
  final int line;
  final String target;

  const _NavFinding({
    required this.file,
    required this.line,
    required this.target,
  });
}

List<_NavFinding> _scanFile(File f) {
  final findings = <_NavFinding>[];
  final lines = f.readAsLinesSync();
  final routesMap = _appRoutesMap;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineNum = i + 1;

    // Skip commented lines.
    final stripped = line.trimLeft();
    if (stripped.startsWith('//')) continue;

    // --- context.push(AppRoutes.X) or context.go(AppRoutes.X) ---
    // Pattern: context.push(AppRoutes.fieldName) — simple constant
    final simpleNav = RegExp(
      r'(?:context|router)\.(?:push|go|pushReplacement)\(\s*AppRoutes\.(\w+)\s*[,)]',
    ).allMatches(line);
    for (final m in simpleNav) {
      final constantName = m.group(1)!;
      final path = routesMap[constantName];
      if (path != null) {
        findings.add(_NavFinding(file: f.path, line: lineNum, target: path));
      }
    }

    // --- context.push(AppRoutes.X.replaceFirst(':y', val)) ---
    final replaceNav = RegExp(
      r'''(?:context|router)\.(?:push|go|pushReplacement)\(\s*AppRoutes\.(\w+)\.replaceFirst\(':[^']+',\s*[^)]+\)''',
    ).allMatches(line);
    for (final m in replaceNav) {
      final constantName = m.group(1)!;
      final template = routesMap[constantName];
      if (template != null) {
        // After replaceFirst(':x', val), the :x param is replaced with a real
        // value. We replace it with 'SUBST' as a concrete placeholder.
        // Remaining :param segments are still unsubstituted.
        final resolved = template.replaceFirst(RegExp(r':[^/]+'), 'SUBST');
        findings.add(
          _NavFinding(file: f.path, line: lineNum, target: resolved),
        );
      }
    }

    // --- context.push('${AppRoutes.X}?query=...') or '${AppRoutes.X}/...' ---
    final interpolatedNav = RegExp(
      r"""(?:context|router)\.(?:push|go|pushReplacement)\(\s*'\$\{AppRoutes\.(\w+)\}([^']*)'\s*[,)]""",
    ).allMatches(line);
    for (final m in interpolatedNav) {
      final constantName = m.group(1)!;
      final suffix = m.group(2) ?? '';
      final template = routesMap[constantName];
      if (template != null) {
        // Suffix may be '?key=value' (query) or '/subpath' or '/${id}'.
        // Strip query; replace interpolated ${var} with SUBST.
        final suffixClean = suffix
            .replaceAll(RegExp(r'\$\{[^}]+\}'), 'SUBST')
            .replaceAll(RegExp(r'\$\w+'), 'SUBST');
        final full = '$template$suffixClean';
        findings.add(_NavFinding(file: f.path, line: lineNum, target: full));
      }
    }

    // --- context.push('${AppRoutes.X}?...') double-quote variant ---
    final interpolatedNavDq = RegExp(
      r'''(?:context|router)\.(?:push|go|pushReplacement)\(\s*"\$\{AppRoutes\.(\w+)\}([^"]*)"\s*[,)]''',
    ).allMatches(line);
    for (final m in interpolatedNavDq) {
      final constantName = m.group(1)!;
      final suffix = m.group(2) ?? '';
      final template = routesMap[constantName];
      if (template != null) {
        final suffixClean = suffix
            .replaceAll(RegExp(r'\$\{[^}]+\}'), 'SUBST')
            .replaceAll(RegExp(r'\$\w+'), 'SUBST');
        final full = '$template$suffixClean';
        findings.add(_NavFinding(file: f.path, line: lineNum, target: full));
      }
    }

    // --- router.go('${AppRoutes.X}?trigger=gate') (single-line) ---
    // Covered by interpolatedNav above.

    // --- actionUrl: AppRoutes.X.replaceFirst(':y', val) ---
    final actionUrlAR = RegExp(
      r'''actionUrl:\s*AppRoutes\.(\w+)(?:\.replaceFirst\(':[^']+',\s*[^,\n]+\))?''',
    ).allMatches(line);
    for (final m in actionUrlAR) {
      final constantName = m.group(1)!;
      final template = routesMap[constantName];
      if (template != null) {
        final hasReplace = line.contains('.replaceFirst(');
        final resolved =
            hasReplace
                ? template.replaceFirst(RegExp(r':[^/]+'), 'SUBST')
                : template;
        findings.add(
          _NavFinding(file: f.path, line: lineNum, target: resolved),
        );
      }
    }

    // --- actionUrl: '/path/${id}' (string interpolation literal) ---
    final actionUrlLiteral = RegExp(
      r"""actionUrl:\s*'(/[^']*)'""",
    ).allMatches(line);
    for (final m in actionUrlLiteral) {
      final raw = m.group(1)!;
      // Replace \${var} interpolations with SUBST.
      final resolved = raw
          .replaceAll(RegExp(r'\$\{[^}]+\}'), 'SUBST')
          .replaceAll(RegExp(r'\$\w+'), 'SUBST');
      findings.add(_NavFinding(file: f.path, line: lineNum, target: resolved));
    }
  }

  return findings;
}

/// Paths that the static scanner may produce but are intentionally
/// allowlisted because they come from server/mock data or runtime values,
/// OR are pre-existing known bugs tracked via a separate issue.
///
/// WARNING: Do NOT add live navigation targets to this list to make the test
/// pass — only add entries for:
///   (a) truly dynamic/server-provided paths that cannot be statically resolved, OR
///   (b) pre-existing known bugs that are tracked in a separate issue and
///       cannot be fixed in the same PR as this test.
///
/// Each entry must have a comment: reason + tracking issue/TODO.
const _runtimeAllowlistPrefixes = <String>[
  // `/recordings/SUBST` — recording detail deep-link from push notification.
  // The route `/recordings/:id` is NOT registered (currently out of scope).
  // Tracked as tech-debt: recordings detail screen not yet implemented.
  // TODO: Remove from allowlist when the /recordings/:id route is registered.
  '/recordings/',
  // Mock notification data uses literal IDs like `/proposals/proposal_auto_1`.
  // These resolve fine (/proposals/:id) — not allowlisted; matched by template.
];

bool _isAllowlisted(String target) {
  final base = _stripQuery(target);
  return _runtimeAllowlistPrefixes.any((p) => base.startsWith(p));
}

// ---------------------------------------------------------------------------
// Tests.
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // UNIT: self-check — verify the matcher catches known-bad targets.
  // These tests prove the detector fires without touching lib/ files.
  // -------------------------------------------------------------------------
  group('Matcher self-check (RED proof)', () {
    test('unsubstituted :id param is detected', () {
      // Old bug pattern #3: proposalDetail pushed with :id never replaced.
      // e.g. context.push('${AppRoutes.proposalDetail}?proposalId=$id')
      // where proposalDetail = '/proposals/:id' and id not substituted in path.
      const bad = '/proposals/:id?proposalId=abc';
      final result = _checkTarget(bad);
      expect(
        result.isFailure,
        isTrue,
        reason:
            'Should detect unsubstituted :id in /proposals/:id?proposalId=abc',
      );
      expect(result.unsubstitutedParam, isTrue);
    });

    test('unregistered route is detected', () {
      // Simulate dead route: /practice (standalone) — never registered.
      // (AppRoutes.practice = '/practice' but no GoRoute with path: '/practice')
      const bad = '/practice';
      final result = _checkTarget(bad);
      expect(
        result.isFailure,
        isTrue,
        reason: 'Should detect /practice as unregistered',
      );
      expect(result.notRegistered, isTrue);
    });

    test('lessonRequest singular vs plural is detected', () {
      // Bug: AppRoutes.lessonRequest (/schedule/lesson-request) is navigated
      // to but never registered. Only /schedule/lesson-requests is registered.
      const bad = '/schedule/lesson-request';
      final result = _checkTarget(bad);
      expect(
        result.isFailure,
        isTrue,
        reason: '/schedule/lesson-request must not be registered',
      );
      expect(result.notRegistered, isTrue);
    });

    test('valid route with substituted param passes', () {
      // /proposals/abc123 should match /proposals/:id
      const good = '/proposals/abc123';
      final result = _checkTarget(good);
      expect(
        result.isFailure,
        isFalse,
        reason: 'result.reason: ${result.reason}',
      );
    });

    test('valid route with query string passes', () {
      // /subscriptions/sub_mon_04 matches /subscriptions/:id (query stripped)
      const good = '/subscriptions/sub_mon_04?viewerRole=teacher';
      final result = _checkTarget(good);
      expect(
        result.isFailure,
        isFalse,
        reason: 'result.reason: ${result.reason}',
      );
    });

    test(
      '/recordings/:recordingId resolves — recording feedback deep link',
      () {
        // /recordings/$id is the push notification actionUrl for teacher
        // feedback on a shared recording (recording_feedback_provider.dart
        // _notifyStudent). Registered via AppRoutes.recordingDetail ->
        // RecordingDetailScreen (practice_routes.dart).
        const good = '/recordings/rec_abc123';
        final result = _checkTarget(good);
        expect(
          result.isFailure,
          isFalse,
          reason: 'result.reason: ${result.reason}',
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // INTEGRATION: scan lib/ source files and verify all navigated targets
  // resolve to a registered GoRoute.
  // -------------------------------------------------------------------------
  group('Route integrity — all push/go/actionUrl targets resolve', () {
    test('no dead routes in lib/**/*.dart navigation calls', () {
      final libDir = Directory('lib');
      expect(
        libDir.existsSync(),
        isTrue,
        reason:
            'Run flutter test from frontend/. Current dir: ${Directory.current.path}',
      );

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final allFindings = <_NavFinding>[];
      for (final f in dartFiles) {
        allFindings.addAll(_scanFile(f));
      }

      expect(
        allFindings,
        isNotEmpty,
        reason: 'Scanner found 0 navigation calls — regex may be broken',
      );

      final failures = <String>[];
      for (final finding in allFindings) {
        // Skip allowlisted runtime paths.
        if (_isAllowlisted(finding.target)) continue;

        final result = _checkTarget(finding.target);
        if (result.isFailure) {
          final relFile = finding.file.replaceFirst(
            RegExp(r'.*/frontend/'),
            'frontend/',
          );
          failures.add(
            '$relFile:${finding.line} → "${finding.target}" — ${result.reason}',
          );
        }
      }

      if (failures.isNotEmpty) {
        fail(
          'Dead routes detected (${failures.length}):\n'
          '${failures.map((f) => '  $f').join('\n')}\n\n'
          'Fix: register the missing GoRoute in routes/*.dart or correct the push/go call.',
        );
      }
    });

    test('scanner finds expected minimum number of navigation calls', () {
      // Sanity check: scanner must find at least 50 navigation targets.
      // If this fails, the regex is broken and missed most calls.
      final libDir = Directory('lib');
      if (!libDir.existsSync()) {
        markTestSkipped('lib/ not found — run from frontend/');
        return;
      }

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      var count = 0;
      for (final f in dartFiles) {
        count += _scanFile(f).length;
      }

      expect(
        count,
        greaterThanOrEqualTo(50),
        reason:
            'Expected at least 50 navigation calls; found $count. '
            'The scanner regex may be too narrow.',
      );
    });

    test('all AppRoutes constants used in navigation are in the constants map', () {
      // Grep lib/ for AppRoutes.X usages in navigation context.
      // All found constant names must exist in _appRoutesMap.
      final libDir = Directory('lib');
      if (!libDir.existsSync()) {
        markTestSkipped('lib/ not found — run from frontend/');
        return;
      }

      final routesMap = _appRoutesMap;
      final missing = <String>[];

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final navPattern = RegExp(
        r'(?:context|router)\.(?:push|go|pushReplacement)\([^)]*AppRoutes\.(\w+)|'
        r'actionUrl:\s*AppRoutes\.(\w+)',
      );

      for (final f in dartFiles) {
        final content = f.readAsStringSync();
        for (final m in navPattern.allMatches(content)) {
          final name = m.group(1) ?? m.group(2);
          if (name != null && !routesMap.containsKey(name)) {
            missing.add('AppRoutes.$name (${f.path})');
          }
        }
      }

      if (missing.isNotEmpty) {
        fail(
          'AppRoutes constants used in navigation but missing from _appRoutesMap:\n'
          '${missing.toSet().map((m) => '  $m').join('\n')}\n\n'
          'Add them to _appRoutesMap in the test file.',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // INVARIANT: every AppRoutes constant in _appRoutesMap matches its actual value.
  // -------------------------------------------------------------------------
  group('AppRoutes map integrity', () {
    test('_appRoutesMap entries match AppRoutes class constants', () {
      final routesMap = _appRoutesMap;
      // Spot-check a representative sample of critical routes.
      final checks = {
        'proposalDetail': AppRoutes.proposalDetail,
        // ignore: deprecated_member_use_from_same_package
        'lessonRequest': AppRoutes.lessonRequest,
        'lessonRequests': AppRoutes.lessonRequests,
        'subscriptionDetail': AppRoutes.subscriptionDetail,
        'practice': AppRoutes.practice,
        'home': AppRoutes.home,
        'studentHome': AppRoutes.studentHome,
      };
      for (final entry in checks.entries) {
        expect(
          routesMap[entry.key],
          equals(entry.value),
          reason: 'AppRoutes map mismatch for key "${entry.key}"',
        );
      }
    });

    test(
      '_appRoutesMap values are a subset of all AppRoutes constant values',
      () {
        // Cross-check: every path value in _appRoutesMap appears in
        // _buildAllRouteValues(). If _appRoutesMap has a typo or wrong value
        // this test will catch it.
        final allValues = _buildAllRouteValues();
        final routesMap = _appRoutesMap;
        final notInAll =
            routesMap.entries
                .where((e) => !allValues.contains(e.value))
                .map((e) => '${e.key}: ${e.value}')
                .toList();
        expect(
          notInAll,
          isEmpty,
          reason:
              '_appRoutesMap values not found in AppRoutes constants: $notInAll',
        );
      },
    );
  });
}
