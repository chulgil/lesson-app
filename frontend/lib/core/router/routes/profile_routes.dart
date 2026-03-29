// Profile and settings route definitions

import 'package:go_router/go_router.dart';

import '../../../features/profile/presentation/screens/instrument_management_screen.dart';
import '../../../features/profile/presentation/screens/lesson_time_settings_screen.dart';
import '../../../features/profile/presentation/screens/payment_management_screen.dart';
import '../../../features/profile/presentation/screens/repertoire_management_screen.dart';
import '../../../features/profile/presentation/screens/tip_template_management_screen.dart';
import '../../../features/profile/presentation/screens/extended_profile_screen.dart';
import '../../../features/profile/presentation/screens/education_edit_screen.dart';
import '../../../features/profile/presentation/screens/career_edit_screen.dart';
import '../../../features/profile/presentation/screens/basic_info_edit_screen.dart';
import '../../../features/profile/presentation/screens/certificate_edit_screen.dart';
import '../../../features/profile/presentation/screens/bank_account_edit_screen.dart';
import '../../../features/analytics/presentation/screens/teacher_dashboard_screen.dart';
import '../../../features/lessons/presentation/screens/teacher_attendance_screen.dart';
import '../../../features/profile/presentation/screens/outstanding_payments_screen.dart';
import '../../../features/profile/presentation/screens/profile_preview_screen.dart';
import '../../../features/profile/presentation/screens/profile_visibility_screen.dart';
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

  // Lesson Time Settings
  GoRoute(
    path: AppRoutes.lessonTimeSettings,
    name: 'lessonTimeSettings',
    builder: (context, state) => const LessonTimeSettingsScreen(),
  ),

  // Payment Management
  GoRoute(
    path: AppRoutes.paymentManagement,
    name: 'paymentManagement',
    builder: (context, state) => const PaymentManagementScreen(),
  ),

  // Tip Template Management
  GoRoute(
    path: AppRoutes.tipTemplateManagement,
    name: 'tipTemplateManagement',
    builder: (context, state) => const TipTemplateManagementScreen(),
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

  // Analytics Dashboard
  GoRoute(
    path: AppRoutes.analytics,
    name: 'analytics',
    builder: (context, state) => const TeacherDashboardScreen(),
  ),

  // Teacher Attendance Overview
  GoRoute(
    path: AppRoutes.teacherAttendance,
    name: 'teacherAttendance',
    builder: (context, state) => const TeacherAttendanceScreen(),
  ),
];
