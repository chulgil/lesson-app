// Test for ConnectionNotificationService — Bug #727 dead /profile route fix.
//
// Problem: sendConnectionRequestReceivedNotification built
// actionUrl = AppRoutes.profile ('/profile') — a dead route removed W2 2026-06-11.
// Any teacher tapping the notification got "Page not found".
//
// Fix: route to AppRoutes.pendingRequests ('/invite/requests') — the screen
// where teachers actually review and act on incoming connection requests.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/notifications/domain/services/connection_notification_service.dart';
import 'package:lessonaza/features/notifications/domain/services/notification_service.dart';

/// Captures the last notification passed to showNotification.
class _CapturingNotificationService implements NotificationService {
  AppNotification? last;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showNotification(AppNotification notification) async {
    last = notification;
  }

  @override
  Future<void> scheduleNotification(AppNotification notification) async {}

  @override
  Future<void> cancelNotification(String id) async {}

  @override
  Future<void> cancelAllNotifications() async {}

  @override
  Stream<AppNotification> get onNotificationTapped => const Stream.empty();
}

void main() {
  late _CapturingNotificationService capture;
  late ConnectionNotificationService service;

  setUp(() {
    capture = _CapturingNotificationService();
    service = ConnectionNotificationService(capture);
  });

  group('ConnectionNotificationService — Bug #727 dead /profile route', () {
    test(
      'sendConnectionRequestReceivedNotification: actionUrl points to pendingRequests, not /profile',
      () async {
        await service.sendConnectionRequestReceivedNotification(
          targetId: 'teacher-1',
          requesterName: '김학생',
          requestId: 'req-abc-123',
        );

        final url = capture.last?.actionUrl;
        expect(url, isNotNull);
        expect(
          url,
          isNot(equals(AppRoutes.profile)),
          reason: '/profile is a dead route — GoRouter returns Page-not-found',
        );
        expect(
          url,
          equals(AppRoutes.pendingRequests),
          reason:
              '/invite/requests is where teachers review incoming connection requests',
        );
      },
    );

    test(
      'sendConnectionRequestReceivedNotification: actionUrl is a real registered route',
      () async {
        await service.sendConnectionRequestReceivedNotification(
          targetId: 'teacher-2',
          requesterName: '박학부모',
          requestId: 'req-xyz-456',
        );

        final url = capture.last?.actionUrl;
        // pendingRequests does not contain path params — no ':id' literal
        expect(url, isNot(contains(':')));
        expect(url, equals('/invite/requests'));
      },
    );
  });
}
