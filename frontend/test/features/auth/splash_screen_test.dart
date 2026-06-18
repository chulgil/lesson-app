import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/auth/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders a loading indicator without error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SplashScreen())),
    );
    // Single frame only — CircularProgressIndicator animates forever, so
    // pumpAndSettle would time out.
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
