import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/sync/lost_writes_provider.dart';
import 'package:lessonaza/core/sync/presentation/providers/connectivity_banner_provider.dart';
import 'package:lessonaza/core/widgets/offline_banner.dart';

void main() {
  Widget subject() => ProviderScope(
    overrides: [
      offlineBannerProvider.overrideWith((ref) => Stream.value(false)),
    ],
    child: const MaterialApp(
      home: OfflineBannerWrapper(child: Scaffold(body: Text('content'))),
    ),
  );

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(OfflineBannerWrapper)),
        listen: false,
      );

  testWidgets(
    'shows a SnackBar and clears once when writes are dropped on logout',
    (tester) async {
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();

      final container = containerOf(tester);
      container
          .read(lostWritesProvider.notifier)
          .record(3, LostWritesReason.logout);
      await tester.pump(); // ref.listen fires
      await tester.pump(const Duration(milliseconds: 300)); // SnackBar in

      expect(find.text(AppStrings.lostWritesLogout(3)), findsOneWidget);
      expect(
        container.read(lostWritesProvider),
        isNull,
        reason: 'cleared after showing once',
      );
    },
  );

  testWidgets('shows the expired message for cleanup-dropped writes', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    final container = containerOf(tester);
    container
        .read(lostWritesProvider.notifier)
        .record(2, LostWritesReason.expired);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.lostWritesExpired(2)), findsOneWidget);
  });
}
