import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/practice/presentation/screens/note_access_request_screen.dart';

void main() {
  group('NoteAccessRequestScreen', () {
    testWidgets('renders without RenderBox constraints errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NoteAccessRequestScreen(requestId: 'test-req-001'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no RenderBox/BoxConstraints exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays note access request with all fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: NoteAccessRequestScreen(requestId: 'req-002')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title is displayed
      expect(find.text('노트 접근 동의'), findsOneWidget);

      // Verify buttons are present for pending requests (req-002 is pending)
      expect(find.text('동의'), findsOneWidget);
      expect(find.text('거절'), findsOneWidget);
    });
  });
}
