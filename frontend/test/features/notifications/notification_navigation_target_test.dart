import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/notifications/presentation/navigation/notification_navigation_target.dart';

void main() {
  AppNotification notification({
    required NotificationType type,
    required String? actionUrl,
  }) {
    return AppNotification(
      id: 'n1',
      userId: 'u1',
      type: type,
      priority: NotificationPriority.normal,
      title: 'title',
      body: 'body',
      createdAt: DateTime(2026, 5, 5),
      actionUrl: actionUrl,
    );
  }

  test('teacher subscription notification opens teacher detail context', () {
    final target = resolveNotificationNavigationTarget(
      notification(
        type: NotificationType.scheduleChangeRequested,
        actionUrl: '/subscriptions/sub_pkg_01?session=6',
      ),
      viewerRole: 'teacher',
    );

    expect(target?.location, '/subscriptions/sub_pkg_01?session=6');
    expect(target?.extra, {'viewerRole': 'teacher'});
  });

  test('student subscription notification opens student detail context', () {
    final target = resolveNotificationNavigationTarget(
      notification(
        type: NotificationType.scheduleChangeApproved,
        actionUrl: '/subscriptions/sub_pkg_01',
      ),
      viewerRole: 'student',
    );

    expect(target?.extra, {'viewerRole': 'student'});
  });

  test('non role-specific notification keeps plain action URL', () {
    final target = resolveNotificationNavigationTarget(
      notification(
        type: NotificationType.connectionRequestAccepted,
        actionUrl: '/teachers/teacher_1',
      ),
      viewerRole: 'student',
    );

    expect(target?.location, '/teachers/teacher_1');
    expect(target?.extra, isNull);
  });
}
