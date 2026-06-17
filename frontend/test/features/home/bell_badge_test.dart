import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/notifications/presentation/providers/notification_providers.dart';

/// Smoke tests for the bell icon unread badge in DashboardTab._buildMasthead.
///
/// Rather than pumping the full DashboardTab (which requires many provider
/// overrides), we isolate the badge widget logic directly via a minimal
/// ConsumerWidget that mirrors _buildMasthead's badge rendering.
Widget _buildTestBell(int unreadCount) {
  return ProviderScope(
    overrides: [unreadNotificationCountProvider.overrideWithValue(unreadCount)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(unreadNotificationCountProvider);
              return IconButton(
                onPressed: () {},
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.ink,
                      size: 22,
                    ),
                    if (count > 0)
                      Positioned(
                        top: -2,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paperAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppStrings.unreadBadgeCount(count),
                            style: const TextStyle(
                              color: AppColors.paper,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              );
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('bell badge hidden when unread count is 0', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    await tester.pumpWidget(_buildTestBell(0));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    // No badge text rendered when count == 0
    expect(find.text(AppStrings.unreadBadgeCount(0)), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bell badge shows count when unread > 0', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    await tester.pumpWidget(_buildTestBell(3));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bell badge shows 9+ when unread count exceeds 9', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    await tester.pumpWidget(_buildTestBell(15));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.text('9+'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bell badge shows exactly 9 (not 9+) at boundary', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    await tester.pumpWidget(_buildTestBell(9));
    await tester.pumpAndSettle();

    expect(find.text('9'), findsOneWidget);
    expect(find.text('9+'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
