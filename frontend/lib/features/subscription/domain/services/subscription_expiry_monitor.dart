import 'dart:developer' as developer;

import '../../../notifications/domain/entities/notification.dart';
import '../entities/subscription.dart';

typedef LoadExpiringSubscriptions = Future<List<Subscription>> Function();
typedef TriggerSubscriptionRenewal = void Function(Subscription subscription);

/// Monitors subscription expiry and generates in-app notifications.
///
/// Like an automated reminder system that checks all active subscriptions
/// and creates alerts when they're about to expire or have already expired.
class SubscriptionExpiryMonitor {
  final LoadExpiringSubscriptions _loadExpiringSoonSubscriptions;
  final LoadExpiringSubscriptions _loadExpiredSubscriptions;
  final TriggerSubscriptionRenewal _triggerSubscriptionRenewal;
  final SubscriptionExpiryCopy _copy;

  const SubscriptionExpiryMonitor({
    required LoadExpiringSubscriptions loadExpiringSoonSubscriptions,
    required LoadExpiringSubscriptions loadExpiredSubscriptions,
    required TriggerSubscriptionRenewal triggerSubscriptionRenewal,
    required SubscriptionExpiryCopy copy,
  }) : _loadExpiringSoonSubscriptions = loadExpiringSoonSubscriptions,
       _loadExpiredSubscriptions = loadExpiredSubscriptions,
       _triggerSubscriptionRenewal = triggerSubscriptionRenewal,
       _copy = copy;

  /// Check all subscriptions and return notifications that should be shown.
  /// Called on app startup and periodically.
  Future<List<AppNotification>> checkAndGenerateAlerts() async {
    final alerts = <AppNotification>[];

    try {
      final expiringSoon = await _loadExpiringSoonSubscriptions();
      final expired = await _loadExpiredSubscriptions();

      // Generate alerts for expiring soon subscriptions
      for (final sub in expiringSoon) {
        final days = sub.daysUntilExpiration;
        final remaining = sub.remainingLessons;

        if (days != null && (days == 7 || days == 3 || days == 1)) {
          alerts.add(_createExpiringAlert(sub, days));
        } else if (remaining != null && remaining <= 1) {
          alerts.add(_createLowLessonsAlert(sub, remaining));
        }

        // Trigger renewal service for subscriptions needing renewal
        if ((remaining != null && remaining <= 2) ||
            (days != null && days <= 7)) {
          _triggerRenewal(sub);
        }
      }

      // Generate alerts for already expired subscriptions
      for (final sub in expired) {
        alerts.add(_createExpiredAlert(sub));
      }
    } catch (e) {
      developer.log(
        '[SubscriptionExpiryMonitor] Error checking subscriptions: $e',
      );
    }

    return alerts;
  }

  AppNotification _createExpiringAlert(Subscription sub, int daysLeft) {
    return AppNotification(
      id: 'sub_expiring_${sub.id}_d$daysLeft',
      userId: sub.studentId,
      type: NotificationType.subscriptionExpiringSoon,
      priority:
          daysLeft <= 1
              ? NotificationPriority.urgent
              : NotificationPriority.high,
      title: _copy.expiringTitle(daysLeft),
      body: _copy.expiringBody(
        _copy.subscriptionKindLabel(sub),
        sub.remainingLessons ?? 0,
      ),
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      actionUrl: '/subscriptions/${sub.id}',
      actionLabel: _copy.viewActionLabel,
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
      title:
          remaining == 0 ? _copy.lessonsExhaustedTitle : _copy.lastLessonTitle,
      body: _copy.renewalRequestBody(_copy.subscriptionKindLabel(sub)),
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      actionUrl: '/subscriptions/${sub.id}',
      actionLabel: _copy.renewalActionLabel,
      data: {
        'subscriptionId': sub.id,
        'remainingLessons': remaining,
        'studentId': sub.studentId,
      },
    );
  }

  /// Trigger renewal service for a subscription that is running low.
  /// Best-effort: failures are silently logged (renewal is an enhancement, not critical).
  void _triggerRenewal(Subscription sub) {
    try {
      _triggerSubscriptionRenewal(sub);
    } catch (e) {
      developer.log('[ExpiryMonitor] Renewal trigger failed: $e');
    }
  }

  AppNotification _createExpiredAlert(Subscription sub) {
    return AppNotification(
      id: 'sub_expired_${sub.id}',
      userId: sub.studentId,
      type: NotificationType.subscriptionExpired,
      priority: NotificationPriority.high,
      title: _copy.expiredTitle,
      body: _copy.renewalRequestBody(_copy.subscriptionKindLabel(sub)),
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      actionUrl: '/subscriptions/${sub.id}',
      actionLabel: _copy.renewalActionLabel,
      data: {'subscriptionId': sub.id, 'studentId': sub.studentId},
    );
  }
}

class SubscriptionExpiryCopy {
  final String Function(int daysLeft) expiringTitle;
  final String Function(String kind, int remaining) expiringBody;
  final String viewActionLabel;
  final String lessonsExhaustedTitle;
  final String lastLessonTitle;
  final String Function(String kind) renewalRequestBody;
  final String renewalActionLabel;
  final String expiredTitle;

  /// 어느 수강권인지 밝히는 종류 라벨 (그룹=클래스명/그룹 라벨, 1:1=수강권 종류).
  /// 표시 문구는 presentation 이 주입한다 — domain 은 문자열을 만들지 않는다.
  final String Function(Subscription subscription) subscriptionKindLabel;

  const SubscriptionExpiryCopy({
    required this.expiringTitle,
    required this.expiringBody,
    required this.viewActionLabel,
    required this.lessonsExhaustedTitle,
    required this.lastLessonTitle,
    required this.renewalRequestBody,
    required this.renewalActionLabel,
    required this.expiredTitle,
    required this.subscriptionKindLabel,
  });
}
