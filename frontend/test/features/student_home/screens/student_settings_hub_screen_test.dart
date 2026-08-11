import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_settings_hub_screen.dart';

/// Settings sub-hub split out of [StudentProfileTab] (Hick's Law — daily-use
/// "메뉴" vs. rarely-changed settings). Widget smoke test required for new
/// top-level screens per ux-rules HARD-GATE.
void main() {
  Future<void> pumpHub(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.studentSettingsHub,
      routes: [
        GoRoute(
          path: AppRoutes.studentSettingsHub,
          builder: (context, state) => const StudentSettingsHubScreen(),
        ),
        GoRoute(
          path: AppRoutes.notificationSettings,
          builder: (context, state) =>
              const Scaffold(body: Text('notification settings')),
        ),
        GoRoute(
          path: AppRoutes.backupSettings,
          builder: (context, state) =>
              const Scaffold(body: Text('backup settings')),
        ),
        GoRoute(
          path: AppRoutes.help,
          builder: (context, state) => const Scaffold(body: Text('help')),
        ),
        GoRoute(
          path: AppRoutes.appInfo,
          builder: (context, state) => const Scaffold(body: Text('app info')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders without exceptions and shows all 6 settings rows', (
    tester,
  ) async {
    await pumpHub(tester);

    expect(
      find.text(AppStrings.studentHomeMenuNotificationSettings),
      findsOneWidget,
    );
    expect(find.text(AppStrings.studentHomePracticeReminder), findsOneWidget);
    expect(find.text(AppStrings.studentHomeMenuLanguage), findsOneWidget);
    expect(
      find.text(AppStrings.studentHomeMenuRecordingBackup),
      findsOneWidget,
    );
    expect(find.text(AppStrings.studentHomeHelpTitle), findsOneWidget);
    expect(find.text(AppStrings.studentHomeAppInfoTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app bar shows the settings hub title', (tester) async {
    await pumpHub(tester);

    expect(find.text(AppStrings.studentHomeSettingsTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a row navigates to its destination route', (
    tester,
  ) async {
    String? landed;

    final router = GoRouter(
      initialLocation: AppRoutes.studentSettingsHub,
      routes: [
        GoRoute(
          path: AppRoutes.studentSettingsHub,
          builder: (context, state) => const StudentSettingsHubScreen(),
        ),
        GoRoute(
          path: AppRoutes.help,
          builder: (context, state) {
            landed = 'help';
            return const Scaffold(body: Text('help'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.studentHomeHelpTitle));
    await tester.pumpAndSettle();

    expect(landed, 'help');
    expect(find.text('help'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
