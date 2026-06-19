import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/sync/presentation/providers/connectivity_banner_provider.dart';
import 'package:lessonaza/core/widgets/offline_banner.dart';

void main() {
  group('OfflineBannerWrapper', () {
    Widget buildSubject({required bool isOffline}) {
      return ProviderScope(
        overrides: [
          offlineBannerProvider.overrideWith((ref) => Stream.value(isOffline)),
        ],
        child: const MaterialApp(
          home: OfflineBannerWrapper(child: Scaffold(body: Text('content'))),
        ),
      );
    }

    testWidgets('renders without exceptions when online', (tester) async {
      await tester.pumpWidget(buildSubject(isOffline: false));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exceptions when offline', (tester) async {
      await tester.pumpWidget(buildSubject(isOffline: true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows offline message when offline', (tester) async {
      await tester.pumpWidget(buildSubject(isOffline: true));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.offlineBannerMessage), findsOneWidget);
    });

    testWidgets('hides offline message when online', (tester) async {
      await tester.pumpWidget(buildSubject(isOffline: false));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.offlineBannerMessage), findsNothing);
    });

    testWidgets('banner appears when connectivity toggles offline', (
      tester,
    ) async {
      final controller = StreamController<bool>.broadcast();
      addTearDown(controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineBannerProvider.overrideWith((ref) => controller.stream),
          ],
          child: const MaterialApp(
            home: OfflineBannerWrapper(child: Scaffold(body: Text('content'))),
          ),
        ),
      );

      // Start online — no banner.
      controller.add(false);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.offlineBannerMessage), findsNothing);

      // Go offline — banner appears.
      controller.add(true);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.offlineBannerMessage), findsOneWidget);

      // Back online — banner disappears.
      controller.add(false);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.offlineBannerMessage), findsNothing);
    });

    testWidgets('still renders content child regardless of connectivity', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(isOffline: true));
      await tester.pumpAndSettle();
      expect(find.text('content'), findsOneWidget);
    });
  });
}
