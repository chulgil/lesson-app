import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification_preferences.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification_type_group.dart';
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

  testWidgets(
    'marketing category (no NotificationType members) shows no expand '
    'affordance',
    (tester) async {
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

      final marketingTile = find.widgetWithText(SwitchListTile, '마케팅');
      // Descend from the tile's row to confirm no expand chevron sits beside
      // the switch — mirrors the icon this screen uses when a category does
      // carry groups (see the expand test below).
      expect(
        find.descendant(
          of: marketingTile,
          matching: find.byIcon(Icons.expand_more),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('expanding the 레슨 알림 category reveals its type-group toggles, '
      'unset groups default to the inherited (category-on) state', (
    tester,
  ) async {
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

    // Group labels are not yet in the tree — collapsed by default.
    expect(find.text('취소·변경'), findsNothing);

    // Lesson is the first category tile in the list, so its expand
    // button is the first '세부 설정 펼치기'-tooltipped IconButton.
    final expandButtons = find.byTooltip('세부 설정 펼치기');
    expect(expandButtons, findsWidgets);
    await tester.tap(expandButtons.first);
    await tester.pump();

    // All four lesson groups now render, each inheriting ON (category ON,
    // no override set yet) — spec §3 "그룹 미설정 시 카테고리 값 승계".
    for (final label in ['레슨 리마인더', '레슨 시작', '취소·변경', '완료·노트']) {
      final tile = find.widgetWithText(SwitchListTile, label);
      expect(tile, findsOneWidget, reason: label);
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'toggling a single group off leaves its sibling groups untouched',
    (tester) async {
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
      await tester.tap(find.byTooltip('세부 설정 펼치기').first);
      await tester.pump();

      final cancelChangeTile = find.widgetWithText(SwitchListTile, '취소·변경');
      expect(tester.widget<SwitchListTile>(cancelChangeTile).value, isTrue);

      await tester.tap(cancelChangeTile);
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.widget<SwitchListTile>(cancelChangeTile).value, isFalse);
      // Sibling group in the same category is unaffected.
      final startingTile = find.widgetWithText(SwitchListTile, '레슨 시작');
      expect(tester.widget<SwitchListTile>(startingTile).value, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('collapsing the category hides its group toggles again', (
    tester,
  ) async {
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

    final expandButton = find.byTooltip('세부 설정 펼치기').first;
    await tester.tap(expandButton);
    await tester.pump();
    expect(find.text('레슨 시작'), findsOneWidget);

    await tester.tap(expandButton);
    await tester.pump();
    expect(find.text('레슨 시작'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category OFF disables its (still expanded) group toggles for '
      'interaction — inheritance made visually obvious per spec §2 IA', (
    tester,
  ) async {
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

    await tester.tap(find.byTooltip('세부 설정 펼치기').first);
    await tester.pump();

    // Tap the tile's own Switch directly (not the whole row) so the tap
    // can't be intercepted by the nested expand IconButton in the title.
    final lessonCategoryTile = find.widgetWithText(SwitchListTile, '레슨 알림');
    final lessonCategorySwitch = find.descendant(
      of: lessonCategoryTile,
      matching: find.byType(Switch),
    );
    await tester.tap(lessonCategorySwitch);
    await tester.pump(const Duration(milliseconds: 300));

    final startingTile = find.widgetWithText(SwitchListTile, '레슨 시작');
    expect(tester.widget<SwitchListTile>(startingTile).onChanged, isNull);
    expect(tester.takeException(), isNull);
  });
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

  @override
  void setGroupOverride(NotificationTypeGroup group, bool enabled) {
    final updated = Map<NotificationTypeGroup, bool>.from(state.groupOverrides);
    updated[group] = enabled;
    state = state.copyWith(groupOverrides: updated);
  }
}

/// In-memory fake for the teacher-only expiry reminder settings — skips Hive.
class _FakeExpiryReminderSettingsNotifier
    extends SubscriptionExpiryReminderSettingsNotifier {
  @override
  SubscriptionExpiryReminderSettings build() =>
      SubscriptionExpiryReminderSettings.defaults;
}
