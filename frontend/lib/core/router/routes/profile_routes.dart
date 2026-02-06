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
import '../../../features/profile/presentation/screens/certificate_edit_screen.dart';
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

  // Profile Visibility
  GoRoute(
    path: AppRoutes.profileVisibility,
    name: 'profileVisibility',
    builder: (context, state) => const ProfileVisibilityScreen(),
  ),
];
