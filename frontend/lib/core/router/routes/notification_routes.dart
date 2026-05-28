// Notification route definitions

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/academy/domain/entities/academy_announcement.dart';
import '../../../features/notifications/presentation/screens/academy_announcement_detail_screen.dart';
import '../../../features/notifications/presentation/screens/academy_announcements_screen.dart';
import '../../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../app_routes.dart';

/// Notification routes
List<GoRoute> notificationRoutes = [
  GoRoute(
    path: AppRoutes.notifications,
    name: 'notifications',
    builder: (context, state) => const NotificationListScreen(),
  ),

  // Academy Announcements List (G18/#399)
  GoRoute(
    path: AppRoutes.academyAnnouncements,
    name: 'academyAnnouncements',
    builder: (context, state) {
      final academyId = state.pathParameters['academyId'] ?? '';
      return AcademyAnnouncementsScreen(academyId: academyId);
    },
  ),

  // Academy Announcement Detail (G18/#399)
  GoRoute(
    path: AppRoutes.academyAnnouncementDetail,
    name: 'academyAnnouncementDetail',
    builder: (context, state) {
      final announcement = state.extra;
      if (announcement is! AcademyAnnouncement) {
        return const Scaffold(body: Center(child: Text('공지사항을 불러올 수 없습니다.')));
      }
      return AcademyAnnouncementDetailScreen(announcement: announcement);
    },
  ),
];
