// Settings route definitions

import 'package:go_router/go_router.dart';

import '../../../features/follow/presentation/screens/follow_list_screen.dart';
import '../../../features/settings/presentation/screens/all_recordings_screen.dart';
import '../../../features/settings/presentation/screens/backup_settings_screen.dart';
import '../../../features/student_home/presentation/screens/app_info_screen.dart';
import '../../../features/student_home/presentation/screens/help_screen.dart';
import '../../../features/student_home/presentation/screens/legal_document_screen.dart';
import '../../../features/student_home/presentation/screens/my_teachers_screen.dart';
import '../../../features/student_home/presentation/screens/notification_settings_screen.dart';
import '../../../features/student_home/presentation/screens/student_profile_edit_screen.dart';
import '../app_routes.dart';

/// Settings routes
List<GoRoute> settingsRoutes = [
  // My Teachers (student)
  GoRoute(
    path: AppRoutes.myTeachers,
    name: 'myTeachers',
    builder: (context, state) => const MyTeachersScreen(),
  ),
  // Backup Settings
  GoRoute(
    path: AppRoutes.backupSettings,
    name: 'backupSettings',
    builder: (context, state) => const BackupSettingsScreen(),
  ),
  // All Recordings
  GoRoute(
    path: AppRoutes.allRecordings,
    name: 'allRecordings',
    builder: (context, state) => const AllRecordingsScreen(),
  ),
  // Help
  GoRoute(
    path: AppRoutes.help,
    name: 'help',
    builder: (context, state) => const HelpScreen(),
  ),
  // App Info
  GoRoute(
    path: AppRoutes.appInfo,
    name: 'appInfo',
    builder: (context, state) => const AppInfoScreen(),
  ),
  // Notification Settings
  GoRoute(
    path: AppRoutes.notificationSettings,
    name: 'notificationSettings',
    builder: (context, state) => const NotificationSettingsScreen(),
  ),
  // Profile Edit
  GoRoute(
    path: AppRoutes.profileEdit,
    name: 'profileEdit',
    builder: (context, state) => const StudentProfileEditScreen(),
  ),
  // Terms of Service
  GoRoute(
    path: AppRoutes.termsOfService,
    name: 'termsOfService',
    builder: (context, state) => const LegalDocumentScreen(
      title: '이용약관',
      content: termsOfServiceContent,
    ),
  ),
  // Privacy Policy
  GoRoute(
    path: AppRoutes.privacyPolicy,
    name: 'privacyPolicy',
    builder: (context, state) => const LegalDocumentScreen(
      title: '개인정보처리방침',
      content: privacyPolicyContent,
    ),
  ),
  // Follow List
  GoRoute(
    path: AppRoutes.followList,
    name: 'followList',
    builder: (context, state) => const FollowListScreen(),
  ),
];
