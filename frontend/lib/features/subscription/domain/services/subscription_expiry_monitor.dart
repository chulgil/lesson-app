import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../notifications/domain/entities/notification.dart';
import '../entities/subscription.dart';
import '../../presentation/providers/subscription_providers.dart';

part 'subscription_expiry_monitor.g.dart';

@riverpod
SubscriptionExpiryMonitor subscriptionExpiryMonitor(Ref ref) {
  return SubscriptionExpiryMonitor(ref);
}

/// Monitors subscription expiry and generates in-app notifications.
///
/// Like an automated reminder system that checks all active subscriptions
/// and creates alerts when they're about to expire or have already expired.
class SubscriptionExpiryMonitor {
  final Ref _ref;

  SubscriptionExpiryMonitor(this._ref);

  /// Check all subscriptions and return notifications that should be shown.
  /// Called on app startup and periodically.
  Future<List<AppNotification>> checkAndGenerateAlerts() async {
    final alerts = <AppNotification>[];

    try {
      final expiringSoon = await _ref.read(
        expiringSoonSubscriptionsProvider.future,
      );
      final expired = await _ref.read(
        expiredSubscriptionsProvider.future,
      );

      // Generate alerts for expiring soon subscriptions
      for (final sub in expiringSoon) {
        final days = sub.daysUntilExpiration;
        final remaining = sub.remainingLessons;

        if (days != null && (days == 7 || days == 3 || days == 1)) {
          alerts.add(_createExpiringAlert(sub, days));
        } else if (remaining != null && remaining <= 1) {
          alerts.add(_createLowLessonsAlert(sub, remaining));
        }
      }

      // Generate alerts for already expired subscriptions
      for (final sub in expired) {
        alerts.add(_createExpiredAlert(sub));
      }
    } catch (e) {
      debugPrint('[SubscriptionExpiryMonitor] Error checking subscriptions: $e');
    }

    return alerts;
  }

  AppNotification _createExpiringAlert(Subscription sub, int daysLeft) {
    return AppNotification(
      id: 'sub_expiring_${sub.id}_d$daysLeft',
      userId: sub.studentId,
      type: NotificationType.subscriptionExpiringSoon,
      priority: daysLeft <= 1
          ? NotificationPriority.urgent
          : NotificationPriority.high,
      title: '수강권이 $daysLeft일 후 만료됩니다',
      body: '남은 횟수 ${sub.remainingLessons ?? 0}회 · 갱신 요청을 보내보세요',
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      actionUrl: '/subscriptions/${sub.id}',
      actionLabel: '수강권 확인',
      data: {
        'subscriptionId': sub.id,
        'daysLeft': daysLeft,
        'studentId': sub.studentId,
      },
    );
  }

  AppNotification _createLowLessonsAlert(Subscription sub, int remaining) {
    return AppNotification(
      id: 'sub_low_${sub.id}',
      userId: sub.studentId,
      type: NotificationType.lessonsRunningLow,
      priority: NotificationPriority.high,
      title: remaining == 0 ? '수강권 횟수를 모두 사용했습니다' : '수강권이 마지막 1회 남았습니다',
      body: '갱신 요청을 보내 레슨을 이어가세요',
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      actionUrl: '/subscriptions/${sub.id}',
      actionLabel: '갱신 요청',
      data: {
        'subscriptionId': sub.id,
        'remainingLessons': remaining,
        'studentId': sub.studentId,
      },
    );
  }

  AppNotification _createExpiredAlert(Subscription sub) {
    return AppNotification(
      id: 'sub_expired_${sub.id}',
      userId: sub.studentId,
      type: NotificationType.subscriptionExpired,
      priority: NotificationPriority.high,
      title: '수강권이 만료되었습니다',
      body: '갱신 요청을 보내 레슨을 이어가세요',
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      actionUrl: '/subscriptions/${sub.id}',
      actionLabel: '갱신 요청',
      data: {
        'subscriptionId': sub.id,
        'studentId': sub.studentId,
      },
    );
  }
}
