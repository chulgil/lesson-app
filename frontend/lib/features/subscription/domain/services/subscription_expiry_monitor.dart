import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../entities/subscription.dart';
import '../entities/subscription_proposal.dart';
import '../../presentation/providers/subscription_providers.dart';
import 'subscription_renewal_service.dart';

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
      final expired = await _ref.read(expiredSubscriptionsProvider.future);

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
      debugPrint(
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
      title: AppStrings.subscriptionExpiringTitle(daysLeft),
      body: AppStrings.subscriptionExpiringBody(sub.remainingLessons ?? 0),
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      actionUrl: '/subscriptions/${sub.id}',
      actionLabel: AppStrings.subscriptionViewAction,
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
          remaining == 0
              ? AppStrings.subscriptionLessonsExhaustedTitle
              : AppStrings.subscriptionLastLessonTitle,
      body: AppStrings.subscriptionRenewalRequestBody,
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      actionUrl: '/subscriptions/${sub.id}',
      actionLabel: AppStrings.subscriptionRenewalAction,
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
      final renewalService = _ref.read(subscriptionRenewalServiceProvider);
      // TODO: resolve teacherId from membership/class relationship
      // For now, this is a placeholder — actual teacherId resolution
      // requires membership → lessonClass → teacherId lookup
      renewalService.triggerOnSubscriptionLow(
        subscription: sub,
        teacherId: '', // Will be resolved in Phase 2
        initiator: RenewalInitiator.system,
      );
    } catch (e) {
      debugPrint('[ExpiryMonitor] Renewal trigger failed: $e');
    }
  }

  AppNotification _createExpiredAlert(Subscription sub) {
    return AppNotification(
      id: 'sub_expired_${sub.id}',
      userId: sub.studentId,
      type: NotificationType.subscriptionExpired,
      priority: NotificationPriority.high,
      title: AppStrings.subscriptionExpiredTitle,
      body: AppStrings.subscriptionRenewalRequestBody,
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      actionUrl: '/subscriptions/${sub.id}',
      actionLabel: AppStrings.subscriptionRenewalAction,
      data: {'subscriptionId': sub.id, 'studentId': sub.studentId},
    );
  }
}
