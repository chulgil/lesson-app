// Settings route definitions

import 'package:go_router/go_router.dart';

import '../../../features/settings/presentation/screens/backup_settings_screen.dart';
import '../app_routes.dart';

/// Settings routes
List<GoRoute> settingsRoutes = [
  // Backup Settings
  GoRoute(
    path: AppRoutes.backupSettings,
    name: 'backupSettings',
    builder: (context, state) => const BackupSettingsScreen(),
  ),
];
