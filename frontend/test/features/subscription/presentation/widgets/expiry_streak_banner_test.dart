import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/expiry_streak_banner.dart';

void main() {
  testWidgets('ExpiryStreakBanner renders title and body (smoke)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExpiryStreakBanner())),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.scheduleChangeExpiredBannerTitle),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.scheduleChangeExpiredBannerBody),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
}
