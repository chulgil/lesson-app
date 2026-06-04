import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/presentation/widgets/youtube/ad_notice_overlay.dart';

void main() {
  group('AdNoticeOverlay — §3.5 #509', () {
    testWidgets('renders ad title, hint, and resume button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AdNoticeOverlay(onResume: () {})),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.youtubeAdDetected), findsOneWidget);
      expect(find.text(AppStrings.youtubeAdHint), findsOneWidget);
      expect(find.text(AppStrings.youtubeAdSkippable), findsOneWidget);
      expect(find.text(AppStrings.youtubeAdResume), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping resume invokes onResume callback', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AdNoticeOverlay(onResume: () => tapped += 1)),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(AppStrings.youtubeAdResume));
      await tester.pump();

      expect(tapped, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders inside narrow container without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: AdNoticeOverlay(onResume: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
