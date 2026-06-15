// Profile and settings route definitions

import 'package:go_router/go_router.dart';

import '../../../features/profile/presentation/screens/instrument_management_screen.dart';
// W2 Task 2.5: lesson_time_settings_screen import 제거됨.
// 라우트는 redirect 로 대체 (W3 에서 화면 파일 자체 해체).
import '../../../features/profile/presentation/screens/lesson_style_settings_screen.dart';
import '../../../features/profile/presentation/screens/price_table_screen.dart';
import '../../../features/profile/presentation/screens/repertoire_management_screen.dart';
import '../../../features/profile/presentation/screens/feedback_template_management_screen.dart';
import '../../../features/profile/presentation/screens/tip_template_management_screen.dart';
import '../../../features/profile/presentation/screens/extended_profile_screen.dart';
import '../../../features/profile/presentation/screens/education_edit_screen.dart';
import '../../../features/profile/presentation/screens/career_edit_screen.dart';
import '../../../features/profile/presentation/screens/basic_info_edit_screen.dart';
import '../../../features/profile/presentation/screens/certificate_edit_screen.dart';
import '../../../features/profile/presentation/screens/bank_account_edit_screen.dart';
import '../../../features/profile/presentation/screens/cancellation_defaults_screen.dart';
import '../../../features/profile/presentation/screens/guide_reshow_screen.dart';
import '../../../features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../../../features/lessons/presentation/screens/teacher_attendance_screen.dart';
import '../../../features/profile/presentation/screens/invite_pending_list_screen.dart';
import '../../../features/profile/presentation/screens/outstanding_payments_screen.dart';
import '../../../features/profile/presentation/screens/profile_preview_screen.dart';
import '../../../features/profile/presentation/screens/profile_visibility_screen.dart';
import '../../../features/subscription/presentation/screens/payment_pending_list_screen.dart';
import '../app_routes.dart';

/// Profile and settings routes
List<GoRoute> profileRoutes = [
  // Instrument Management
  GoRoute(
    path: AppRoutes.instrumentManagement,
    name: 'instrumentManagement',
    builder: (context, state) => const InstrumentManagementScreen(),
  ),

  // Repertoire Management
  GoRoute(
    path: AppRoutes.repertoireManagement,
    name: 'repertoireManagement',
    builder: (context, state) => const RepertoireManagementScreen(),
  ),

  // Lesson Time Settings — deprecated W2 Task 2.5
  // 5묶음으로 흩어짐 (spec §6.1). 화면 해체는 W3.
  // Legacy URL 진입 시 5묶음 메인(ProfileTab)으로 무음 redirect.
  GoRoute(
    path: AppRoutes.lessonTimeSettings,
    name: 'lessonTimeSettings',
    redirect: (context, state) => AppRoutes.lessonStyleSettings,
  ),

  // Lesson Style Settings — W3 Task 3.2 (수업방식 묶음)
  // spec §6.2 — 3 항목 단일 화면 (레슨 1회 시간 + 사전예약 + 학생 안내).
  GoRoute(
    path: AppRoutes.lessonStyleSettings,
    name: 'lessonStyleSettings',
    builder: (context, state) => const LessonStyleSettingsScreen(),
  ),

  // Price Table — W3 Task 3.3 (수강권·정산 묶음, 가격표)
  // spec §6.3 — LessonTimeSettingsScreen §6 가격표 섹션 분리.
  GoRoute(
    path: AppRoutes.priceTable,
    name: 'priceTable',
    builder: (context, state) => const PriceTableScreen(),
  ),

  // Guide Reshow — W5 Task 5.6 (정책·알림·지원 묶음, 졸업 후 fallback)
  // spec §8.4 — ⚙️ 정책·알림·지원 → "가이드 다시 보기" 메뉴 진입점.
  GoRoute(
    path: AppRoutes.guideReshow,
    name: 'guideReshow',
    builder: (context, state) => const GuideReshowScreen(),
  ),

  // Tip Template Management
  GoRoute(
    path: AppRoutes.tipTemplateManagement,
    name: 'tipTemplateManagement',
    builder: (context, state) => const TipTemplateManagementScreen(),
  ),

  // Feedback Template Management
  GoRoute(
    path: AppRoutes.feedbackTemplateManagement,
    name: 'feedbackTemplateManagement',
    builder: (context, state) => const FeedbackTemplateManagementScreen(),
  ),

  // Extended Profile
  GoRoute(
    path: AppRoutes.extendedProfile,
    name: 'extendedProfile',
    builder: (context, state) => const ExtendedProfileScreen(),
  ),

  // Basic Info Edit
  GoRoute(
    path: AppRoutes.basicInfoEdit,
    name: 'basicInfoEdit',
    builder: (context, state) => const BasicInfoEditScreen(),
  ),

  // Education Edit
  GoRoute(
    path: AppRoutes.educationEdit,
    name: 'educationEdit',
    builder: (context, state) {
      final indexStr = state.uri.queryParameters['index'];
      final index = indexStr != null ? int.tryParse(indexStr) : null;
      return EducationEditScreen(index: index);
    },
  ),

  // Career Edit
  GoRoute(
    path: AppRoutes.careerEdit,
    name: 'careerEdit',
    builder: (context, state) {
      final indexStr = state.uri.queryParameters['index'];
      final index = indexStr != null ? int.tryParse(indexStr) : null;
      return CareerEditScreen(index: index);
    },
  ),

  // Certificate Edit
  GoRoute(
    path: AppRoutes.certificateEdit,
    name: 'certificateEdit',
    builder: (context, state) {
      final certificateId = state.uri.queryParameters['id'];
      return CertificateEditScreen(certificateId: certificateId);
    },
  ),

  // Bank Account Edit
  GoRoute(
    path: AppRoutes.bankAccountEdit,
    name: 'bankAccountEdit',
    builder: (context, state) => const BankAccountEditScreen(),
  ),

  // Profile Preview
  GoRoute(
    path: AppRoutes.profilePreview,
    name: 'profilePreview',
    builder: (context, state) => const ProfilePreviewScreen(),
  ),

  // Profile Visibility
  GoRoute(
    path: AppRoutes.profileVisibility,
    name: 'profileVisibility',
    builder: (context, state) => const ProfileVisibilityScreen(),
  ),

  // Outstanding Payments
  GoRoute(
    path: AppRoutes.outstandingPayments,
    name: 'outstandingPayments',
    builder: (context, state) => const OutstandingPaymentsScreen(),
  ),

  // Payment-pending dashboard list — #424
  GoRoute(
    path: AppRoutes.paymentPending,
    name: 'paymentPending',
    builder: (context, state) => const PaymentPendingListScreen(),
  ),

  // Invite-pending dashboard list — #5 D-G3 Phase 2
  GoRoute(
    path: AppRoutes.invitePending,
    name: 'invitePending',
    builder: (context, state) => const InvitePendingListScreen(),
  ),

  // Analytics Dashboard (Refs #354 — 3-tab: 월간요약/학생성장/수입분석)
  GoRoute(
    path: AppRoutes.analytics,
    name: 'analytics',
    builder: (context, state) => const AnalyticsDashboardScreen(),
  ),

  // Teacher Attendance Overview
  GoRoute(
    path: AppRoutes.teacherAttendance,
    name: 'teacherAttendance',
    builder: (context, state) => const TeacherAttendanceScreen(),
  ),

  // Cancellation Policy Defaults (G11/#392)
  GoRoute(
    path: AppRoutes.cancellationDefaults,
    name: 'cancellationDefaults',
    builder: (context, state) => const CancellationDefaultsScreen(),
  ),
];
