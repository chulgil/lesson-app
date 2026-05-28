import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/search/presentation/screens/academy_detail_screen.dart';

void main() {
  group('AcademyDetailScreen', () {
    testWidgets('renders loading state without exception', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AcademyDetailScreen(organizationId: 'acad_1'),
          ),
        ),
      );

      // Initial frame: providers in loading state.
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Drain pending Mock repository timers (150 ms) so the test doesn't
      // dispose with pending Timer assertion.
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('resolves to academy content without exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AcademyDetailScreen(organizationId: 'acad_1'),
          ),
        ),
      );

      // Mock repository simulated delay (150ms); pump until settled.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles unknown organizationId without exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AcademyDetailScreen(organizationId: 'unknown_id'),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });
}
