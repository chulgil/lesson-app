import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/analytics/presentation/widgets/analytics_error_view.dart';

void main() {
  testWidgets('AnalyticsErrorView renders error affordance without exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AnalyticsErrorView(onRetry: () {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text(AppStrings.cannotLoadData), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('AnalyticsErrorView retry button fires onRetry (C7)', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AnalyticsErrorView(onRetry: () => retried = true)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(OutlinedButton));
    expect(retried, isTrue);
  });
}
