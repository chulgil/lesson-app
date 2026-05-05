import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/auth/presentation/providers/user_role_provider.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';

void main() {
  test(
    'student mock notifications do not show false D-day expiry alerts',
    () async {
      final container = ProviderContainer(
        overrides: [
          currentUserRoleProvider.overrideWith((ref) => UserRole.student),
        ],
      );
      addTearDown(container.dispose);

      final notifications = await container.read(
        userNotificationsProvider.future,
      );

      final expiryNotifications = notifications.where(
        (notification) =>
            notification.type == NotificationType.subscriptionExpiringSoon,
      );

      expect(
        expiryNotifications,
        isEmpty,
        reason: '학생 mock 알림은 실제 수강권 endDate와 다른 D-day 만료 문구를 표시하면 안 됩니다.',
      );
    },
  );

  test(
    'student low-lessons mock notification points to matching subscription',
    () async {
      final container = ProviderContainer(
        overrides: [
          currentUserRoleProvider.overrideWith((ref) => UserRole.student),
        ],
      );
      final subscriptionRepository = MockSubscriptionRepository();
      addTearDown(container.dispose);

      final notifications = await container.read(
        userNotificationsProvider.future,
      );
      final lowLessons = notifications.firstWhere(
        (notification) =>
            notification.type == NotificationType.lessonsRunningLow,
      );
      final subscriptionId = lowLessons.data?['subscriptionId'] as String?;
      final subscription = await subscriptionRepository.getById(
        subscriptionId!,
      );

      expect(subscription, isNotNull);
      expect(lowLessons.actionUrl, '/subscriptions/$subscriptionId');
      expect(
        lowLessons.data?['remainingLessons'],
        subscription!.remainingLessons,
      );
      expect(lowLessons.title, contains('${subscription.remainingLessons}회'));
      expect(lowLessons.body, isNot(contains('일 후 만료')));
    },
  );
}
