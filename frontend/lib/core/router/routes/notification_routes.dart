// Notification route definitions

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/notebook/notebook_surfaces.dart';
import '../../../features/academy/domain/entities/academy_announcement.dart';
import '../../../features/academy/domain/entities/academy_inquiry.dart';
import '../../../features/inbox/presentation/screens/academy_inquiry_detail_screen.dart';
import '../../../features/inbox/presentation/screens/academy_inquiry_screen.dart';
import '../../../features/notifications/presentation/screens/academy_announcement_detail_screen.dart';
import '../../../features/notifications/presentation/screens/academy_announcements_screen.dart';
import '../../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../app_routes.dart';
import '../../l10n/generated/app_localizations.dart';

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
        return NotebookScreenScaffold(
          body: Center(
            child: Text(
              AppLocalizations.of(context).notificationAnnouncementLoadError,
            ),
          ),
        );
      }
      return AcademyAnnouncementDetailScreen(announcement: announcement);
    },
  ),

  // Academy Inquiries List (G19/#400)
  GoRoute(
    path: AppRoutes.academyInquiries,
    name: 'academyInquiries',
    builder: (context, state) {
      final academyId = state.pathParameters['academyId'] ?? '';
      return AcademyInquiryScreen(academyId: academyId);
    },
  ),

  // Academy Inquiry Detail (G19/#400)
  GoRoute(
    path: AppRoutes.academyInquiryDetail,
    name: 'academyInquiryDetail',
    builder: (context, state) {
      final academyId = state.pathParameters['academyId'] ?? '';
      final inquiry = state.extra;
      if (inquiry is! AcademyInquiry) {
        return NotebookScreenScaffold(
          body: Center(
            child: Text(
              AppLocalizations.of(context).notificationInquiryLoadError,
            ),
          ),
        );
      }
      return AcademyInquiryDetailScreen(inquiry: inquiry, academyId: academyId);
    },
  ),
];
