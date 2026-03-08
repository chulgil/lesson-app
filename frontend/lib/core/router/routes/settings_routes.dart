// Settings route definitions

import 'package:go_router/go_router.dart';

import '../../../features/settings/presentation/screens/all_recordings_screen.dart';
import '../../../features/settings/presentation/screens/backup_settings_screen.dart';
import '../../../features/student_home/presentation/screens/app_info_screen.dart';
import '../../../features/student_home/presentation/screens/help_screen.dart';
import '../../../features/student_home/presentation/screens/notification_settings_screen.dart';
import '../app_routes.dart';

/// Settings routes
List<GoRoute> settingsRoutes = [
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
];
