import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification_preferences.dart';
import 'package:lessonaza/features/notifications/presentation/providers/notification_preferences_provider.dart';
import 'package:lessonaza/features/notifications/presentation/screens/notification_settings_screen.dart';

void main() {
  setUp(() async {
    await Hive.initFlutter('test_hive_notification');
    if (!Hive.isBoxOpen('notification_settings')) {
      await Hive.openBox('notification_settings');
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('NotificationSettingsScreen renders without exception',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationPreferencesNotifierProvider.overrideWith(
            () => _FakeNotificationPreferencesNotifier(),
          ),
        ],
        child: const MaterialApp(
          home: NotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('NotificationSettingsScreen shows master toggle',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationPreferencesNotifierProvider.overrideWith(
            () => _FakeNotificationPreferencesNotifier(),
          ),
        ],
        child: const MaterialApp(
          home: NotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('전체 알림'), findsOneWidget);
    expect(find.text('레슨 알림'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeNotificationPreferencesNotifier
    extends NotificationPreferencesNotifier {
  @override
  NotificationPreferences build() => NotificationPreferences.defaults;
}
