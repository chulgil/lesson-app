import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/home/presentation/widgets/review_prompt_card.dart';
import 'package:lessonaza/features/settings/domain/repositories/app_release_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/app_release_provider.dart';

class FakeReviewClient implements AppReviewClient {
  FakeReviewClient({this.canRequest = true});

  final bool canRequest;
  bool requested = false;

  @override
  Future<bool> canRequestReview() async => canRequest;

  @override
  Future<void> requestReview() async {
    requested = true;
  }
}

void main() {
  group('ReviewPromptCard', () {
    testWidgets('hides when completed lessons are below threshold', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ReviewPromptCard(completedLessonCount: 9)),
          ),
        ),
      );

      await tester.pump();

      expect(find.text(AppStrings.reviewPromptTitle), findsNothing);
    });

    testWidgets('shows and calls review client when user can request', (
      tester,
    ) async {
      final fakeClient = FakeReviewClient(canRequest: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appReviewClientProvider.overrideWithValue(fakeClient)],
          child: const MaterialApp(
            home: Scaffold(body: ReviewPromptCard(completedLessonCount: 10)),
          ),
        ),
      );

      await tester.pump();

      expect(find.text(AppStrings.reviewPromptTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.reviewPromptAction));
      await tester.pumpAndSettle();

      expect(fakeClient.requested, isTrue);
      expect(find.text(AppStrings.reviewPromptThanks), findsOneWidget);
    });
  });
}
