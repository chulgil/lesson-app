// Notification route definitions

import 'package:go_router/go_router.dart';

import '../../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../app_routes.dart';

/// Notification routes
List<GoRoute> notificationRoutes = [
  GoRoute(
    path: AppRoutes.notifications,
    name: 'notifications',
    builder: (context, state) => const NotificationListScreen(),
  ),
];
