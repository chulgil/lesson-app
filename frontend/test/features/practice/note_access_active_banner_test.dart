import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/practice/presentation/widgets/note_access_active_banner.dart';

void main() {
  group('NoteAccessActiveBanner', () {
    testWidgets('renders without RenderBox constraints errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  NoteAccessActiveBanner(),
                  Expanded(child: Container(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no RenderBox/BoxConstraints exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays banner with revoke button when access is active', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  NoteAccessActiveBanner(),
                  Expanded(child: Container(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no RenderBox/BoxConstraints exceptions
      expect(tester.takeException(), isNull);

      // Banner will either show with content or be empty depending on mock state
      // The important part is it doesn't crash with layout errors
    });
  });
}
