// R2 #318 — StudentSummaryScreen widget smoke test (ux-rules HARD-GATE).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/share/presentation/screens/student_summary_screen.dart';

void main() {
  testWidgets('renders without exception and shows token', (tester) async {
    const token = 'sample-share-token-abc123';

    await tester.pumpWidget(
      const MaterialApp(home: StudentSummaryScreen(token: token)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(token), findsOneWidget);
  });

  testWidgets('handles empty token gracefully', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: StudentSummaryScreen(token: '')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
