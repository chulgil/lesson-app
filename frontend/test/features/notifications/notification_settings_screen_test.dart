import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification_preferences.dart';
import 'package:lessonaza/features/notifications/domain/entities/subscription_expiry_reminder_settings.dart';
import 'package:lessonaza/features/notifications/presentation/providers/notification_preferences_provider.dart';
import 'package:lessonaza/features/notifications/presentation/providers/subscription_expiry_providers.dart';
import 'package:lessonaza/features/notifications/presentation/screens/notification_settings_screen.dart';

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('test_hive_notification_');
    Hive.init(hiveDir.path);
    if (!Hive.isBoxOpen('notification_settings')) {
      await Hive.openBox('notification_settings');
    }
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  List<Override> overrides() => [
    notificationPreferencesNotifierProvider.overrideWith(
      () => _FakeNotificationPreferencesNotifier(),
    ),
    subscriptionExpiryReminderSettingsNotifierProvider.overrideWith(
      () => _FakeExpiryReminderSettingsNotifier(),
    ),
  ];

  testWidgets('NotificationSettingsScreen renders without exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: NotificationSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('NotificationSettingsScreen shows master toggle', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: NotificationSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('전체 알림'), findsOneWidget);
    expect(find.text('레슨 알림'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'NotificationSettingsScreen toggles marketing category without exception',
    (tester) async {
      // Enlarge viewport so all category tiles are built (lazy ListView).
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: const MaterialApp(home: NotificationSettingsScreen()),
        ),
      );
      await tester.pump();

      // Marketing category tile — default OFF per spec §3.2.
      final marketingTile = find.widgetWithText(SwitchListTile, '마케팅');
      expect(marketingTile, findsOneWidget);
      expect(tester.widget<SwitchListTile>(marketingTile).value, isFalse);

      // Toggle ON and verify state propagates back to the tile.
      await tester.tap(marketingTile);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<SwitchListTile>(marketingTile).value, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}

/// In-memory fake: overrides toggle methods to skip Hive writes.
/// Real file I/O inside testWidgets' FakeAsync zone never completes and
/// deadlocks `Hive.close()` in tearDown.
class _FakeNotificationPreferencesNotifier
    extends NotificationPreferencesNotifier {
  @override
  NotificationPreferences build() => NotificationPreferences.defaults;

  @override
  void toggleMaster(bool enabled) {
    state = state.copyWith(masterEnabled: enabled);
  }

  @override
  void toggleCategory(NotificationCategory category, bool enabled) {
    state = switch (category) {
      NotificationCategory.lesson => state.copyWith(lessonEnabled: enabled),
      NotificationCategory.schedule => state.copyWith(scheduleEnabled: enabled),
      NotificationCategory.subscription => state.copyWith(
        subscriptionEnabled: enabled,
      ),
      NotificationCategory.announcement => state.copyWith(
        announcementEnabled: enabled,
      ),
      NotificationCategory.practice => state.copyWith(practiceEnabled: enabled),
      NotificationCategory.marketing => state.copyWith(
        marketingEnabled: enabled,
      ),
    };
  }

  @override
  void setQuietHours({required int? startHour, required int? endHour}) {
    state = state.copyWith(quietStartHour: startHour, quietEndHour: endHour);
  }
}

/// In-memory fake for the teacher-only expiry reminder settings — skips Hive.
class _FakeExpiryReminderSettingsNotifier
    extends SubscriptionExpiryReminderSettingsNotifier {
  @override
  SubscriptionExpiryReminderSettings build() =>
      SubscriptionExpiryReminderSettings.defaults;
}
