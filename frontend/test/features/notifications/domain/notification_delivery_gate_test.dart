import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/notifications/data/services/local_notification_service.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification_preferences.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification_type_group.dart';
import 'package:lessonaza/features/notifications/domain/services/notification_delivery_gate.dart';

AppNotification _notification(NotificationType type) {
  return AppNotification(
    id: 'n_${type.name}',
    userId: 'user_1',
    type: type,
    priority: NotificationPriority.normal,
    title: 't',
    body: 'b',
    createdAt: DateTime(2026, 7, 1, 12),
  );
}

void main() {
  // Noon, outside any sane quiet-hours window.
  final noon = DateTime(2026, 7, 1, 12);

  group('shouldDeliverNotification', () {
    test(
      'master kill switch off blocks everything, including critical types',
      () {
        const prefs = NotificationPreferences(masterEnabled: false);

        expect(
          shouldDeliverNotification(
            prefs,
            _notification(NotificationType.practiceReminder),
            now: noon,
          ),
          isFalse,
        );
        // lessonStarting is bypassDnd-critical but master off still wins.
        expect(
          shouldDeliverNotification(
            prefs,
            _notification(NotificationType.lessonStarting),
            now: noon,
          ),
          isFalse,
        );
      },
    );

    test('category toggle off drops that category only', () {
      const prefs = NotificationPreferences(practiceEnabled: false);

      expect(
        shouldDeliverNotification(
          prefs,
          _notification(NotificationType.practiceReminder),
          now: noon,
        ),
        isFalse,
      );
      expect(
        shouldDeliverNotification(
          prefs,
          _notification(NotificationType.lessonBooked),
          now: noon,
        ),
        isTrue,
      );
    });

    test('critical types bypass a disabled category (spec §2.2)', () {
      const prefs = NotificationPreferences(lessonEnabled: false);

      // Non-critical lesson notification is dropped...
      expect(
        shouldDeliverNotification(
          prefs,
          _notification(NotificationType.lessonBooked),
          now: noon,
        ),
        isFalse,
      );
      // ...but lessonStarting / lessonCancelled always deliver.
      expect(
        shouldDeliverNotification(
          prefs,
          _notification(NotificationType.lessonStarting),
          now: noon,
        ),
        isTrue,
      );
      expect(
        shouldDeliverNotification(
          prefs,
          _notification(NotificationType.lessonCancelled),
          now: noon,
        ),
        isTrue,
      );
    });

    test('quiet hours drop normal types and spare critical types', () {
      // 22:00–08:00 crossover window.
      const prefs = NotificationPreferences(
        quietStartHour: 22,
        quietEndHour: 8,
      );
      final lateNight = DateTime(2026, 7, 1, 23, 30);
      final earlyMorning = DateTime(2026, 7, 2, 7, 59);

      expect(
        shouldDeliverNotification(
          prefs,
          _notification(NotificationType.paymentRequested),
          now: lateNight,
        ),
        isFalse,
      );
      expect(
        shouldDeliverNotification(
          prefs,
          _notification(NotificationType.paymentRequested),
          now: earlyMorning,
        ),
        isFalse,
      );
      expect(
        shouldDeliverNotification(
          prefs,
          _notification(NotificationType.paymentRequested),
          now: noon,
        ),
        isTrue,
      );
      expect(
        shouldDeliverNotification(
          prefs,
          _notification(NotificationType.noshowWarning),
          now: lateNight,
        ),
        isTrue,
      );
    });

    test('marketing category is opt-in (default off)', () {
      const prefs = NotificationPreferences();
      expect(prefs.isCategoryEnabled(NotificationCategory.marketing), isFalse);
    });
  });

  group('NotificationTypeCategory mapping', () {
    test('spec §2.1 representative rows hold', () {
      expect(
        NotificationType.lessonBooked.category,
        NotificationCategory.lesson,
      );
      expect(
        NotificationType.cancellationDeadline.category,
        NotificationCategory.lesson,
      );
      expect(
        NotificationType.scheduleChangeRequested.category,
        NotificationCategory.schedule,
      );
      expect(
        NotificationType.makeupLessonExpiring.category,
        NotificationCategory.schedule,
      );
      expect(
        NotificationType.scheduleConfirmationRequired.category,
        NotificationCategory.schedule,
      );
      expect(
        NotificationType.paymentPendingD7Final.category,
        NotificationCategory.subscription,
      );
      expect(
        NotificationType.proposalReminder72h.category,
        NotificationCategory.subscription,
      );
      expect(
        NotificationType.generalAnnouncement.category,
        NotificationCategory.announcement,
      );
      expect(
        NotificationType.profileReminder7d.category,
        NotificationCategory.announcement,
      );
      expect(
        NotificationType.streakWarning.category,
        NotificationCategory.practice,
      );
      expect(
        NotificationType.recordingFeedbackReceived.category,
        NotificationCategory.practice,
      );
    });

    test('every type resolves to a category', () {
      for (final type in NotificationType.values) {
        expect(() => type.category, returnsNormally, reason: type.name);
      }
    });
  });

  group('NotificationTypeGroup mapping (#1272)', () {
    test('every type resolves to exactly one group', () {
      for (final type in NotificationType.values) {
        expect(() => type.group, returnsNormally, reason: type.name);
      }
    });

    test('every group resolves to exactly one category', () {
      for (final group in NotificationTypeGroup.values) {
        expect(() => group.category, returnsNormally, reason: group.name);
      }
    });

    test("a type's group always belongs to that same type's category — "
        'group cannot silently cross category boundaries', () {
      for (final type in NotificationType.values) {
        expect(
          type.group.category,
          type.category,
          reason:
              '${type.name}: group ${type.group.name} belongs to '
              '${type.group.category.name}, but type maps to '
              '${type.category.name}',
        );
      }
    });

    test('every NotificationTypeGroup is reachable from at least one type', () {
      final reachable = NotificationType.values.map((t) => t.group).toSet();
      for (final group in NotificationTypeGroup.values) {
        expect(reachable.contains(group), isTrue, reason: group.name);
      }
    });

    test('representative rows hold', () {
      expect(
        NotificationType.lessonBooked.group,
        NotificationTypeGroup.lessonReminder,
      );
      expect(
        NotificationType.lessonStarting.group,
        NotificationTypeGroup.lessonStarting,
      );
      expect(
        NotificationType.lessonCancelled.group,
        NotificationTypeGroup.lessonCancelChange,
      );
      expect(
        NotificationType.lessonCompleted.group,
        NotificationTypeGroup.lessonCompletedNote,
      );
      expect(
        NotificationType.connectionDisconnected.group,
        NotificationTypeGroup.connectionDisconnect,
      );
      expect(
        NotificationType.connectionRequestReceived.group,
        NotificationTypeGroup.connectionRequest,
      );
      expect(
        NotificationType.streakMilestone.group,
        NotificationTypeGroup.streakAndGoal,
      );
      expect(
        NotificationType.recordingFeedbackReceived.group,
        NotificationTypeGroup.recordingFeedback,
      );
    });

    test('NotificationCategory.groups covers every group exactly once', () {
      final allGrouped =
          NotificationCategory.values.expand((c) => c.groups).toList();
      expect(allGrouped.toSet(), NotificationTypeGroup.values.toSet());
      expect(allGrouped.length, NotificationTypeGroup.values.length);
    });
  });

  group('shouldDeliverNotification — group override matrix (#1272)', () {
    // practiceReminder → NotificationTypeGroup.practiceReminder → practice category.
    const type = NotificationType.practiceReminder;
    final group = type.group;

    test('category ON, group unset → deliver (inherits category)', () {
      const prefs = NotificationPreferences();
      expect(
        shouldDeliverNotification(prefs, _notification(type), now: noon),
        isTrue,
      );
    });

    test('category ON, group explicitly OFF → drop', () {
      final prefs = NotificationPreferences(groupOverrides: {group: false});
      expect(
        shouldDeliverNotification(prefs, _notification(type), now: noon),
        isFalse,
      );
    });

    test('category ON, group explicitly ON → deliver', () {
      final prefs = NotificationPreferences(groupOverrides: {group: true});
      expect(
        shouldDeliverNotification(prefs, _notification(type), now: noon),
        isTrue,
      );
    });

    test('category OFF wins over a group explicitly ON — category off silences '
        'every group beneath it', () {
      final prefs = NotificationPreferences(
        practiceEnabled: false,
        groupOverrides: {group: true},
      );
      expect(
        shouldDeliverNotification(prefs, _notification(type), now: noon),
        isFalse,
      );
    });

    test(
      'a group override never affects a sibling group in the same category',
      () {
        final prefs = NotificationPreferences(
          groupOverrides: {NotificationTypeGroup.streakAndGoal: false},
        );
        // practiceReminder group is untouched — still inherits (category ON).
        expect(
          shouldDeliverNotification(prefs, _notification(type), now: noon),
          isTrue,
        );
        expect(
          shouldDeliverNotification(
            prefs,
            _notification(NotificationType.streakMilestone),
            now: noon,
          ),
          isFalse,
        );
      },
    );

    test('critical bypass type still bypasses even with its group off — '
        'DND-bypass precedes category and group checks', () {
      final lessonCancelledGroup = NotificationType.lessonCancelled.group;
      final prefs = NotificationPreferences(
        lessonEnabled: false,
        groupOverrides: {lessonCancelledGroup: false},
      );
      expect(
        shouldDeliverNotification(
          prefs,
          _notification(NotificationType.lessonCancelled),
          now: noon,
        ),
        isTrue,
      );
    });

    test('master OFF wins over a group explicitly ON', () {
      final prefs = NotificationPreferences(
        masterEnabled: false,
        groupOverrides: {group: true},
      );
      expect(
        shouldDeliverNotification(prefs, _notification(type), now: noon),
        isFalse,
      );
    });

    test('group ON does not bypass quiet hours (only DND-bypass types do)', () {
      final prefs = NotificationPreferences(
        quietStartHour: 22,
        quietEndHour: 8,
        groupOverrides: {group: true},
      );
      expect(
        shouldDeliverNotification(
          prefs,
          _notification(type),
          now: DateTime(2026, 7, 1, 23, 30),
        ),
        isFalse,
      );
    });
  });

  group('isGroupEffectivelyEnabled (#1272)', () {
    const type = NotificationType.streakMilestone;
    final group = type.group; // streakAndGoal, under practice category.

    test('unset override + category ON → true (inherits)', () {
      const prefs = NotificationPreferences();
      expect(isGroupEffectivelyEnabled(prefs, group), isTrue);
    });

    test('explicit override false persists regardless of category value', () {
      final prefs = NotificationPreferences(groupOverrides: {group: false});
      expect(isGroupEffectivelyEnabled(prefs, group), isFalse);
    });

    test('category OFF forces false even when group override is true', () {
      final prefs = NotificationPreferences(
        practiceEnabled: false,
        groupOverrides: {group: true},
      );
      expect(isGroupEffectivelyEnabled(prefs, group), isFalse);
    });

    test('master OFF forces false regardless of group override', () {
      final prefs = NotificationPreferences(
        masterEnabled: false,
        groupOverrides: {group: true},
      );
      expect(isGroupEffectivelyEnabled(prefs, group), isFalse);
    });
  });

  group('LocalNotificationService gate', () {
    test('blocked notification never reaches the platform plugin', () async {
      // In the test environment the flutter_local_notifications plugin is
      // unavailable, so reaching initialize() would throw. Completing without
      // an exception proves the gate early-returns before any plugin call.
      final service = LocalNotificationService(shouldDeliver: (_) => false);

      await service.showNotification(
        _notification(NotificationType.practiceReminder),
      );
      await service.scheduleNotification(
        _notification(NotificationType.practiceReminder),
      );
    });
  });

  group('NotificationPreferences.isInDndAt', () {
    test('same-day window (13–15) matches only inside', () {
      const prefs = NotificationPreferences(
        quietStartHour: 13,
        quietEndHour: 15,
      );
      expect(prefs.isInDndAt(DateTime(2026, 7, 1, 12, 59)), isFalse);
      expect(prefs.isInDndAt(DateTime(2026, 7, 1, 13)), isTrue);
      expect(prefs.isInDndAt(DateTime(2026, 7, 1, 14, 59)), isTrue);
      expect(prefs.isInDndAt(DateTime(2026, 7, 1, 15)), isFalse);
    });

    test('disabled when either hour is null', () {
      const prefs = NotificationPreferences(quietStartHour: 22);
      expect(prefs.isInDndAt(DateTime(2026, 7, 1, 23)), isFalse);
    });
  });
}
