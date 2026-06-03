// Regression tests for QuestBoardCard board-dismissal SSOT. (#4 / #482)
//
// The progress gauge (profileCompletionPercent) sums the 10 mandatory quests
// to 100%. Phone verification is the optional Phase C reward quest (weight 0,
// see phone_verification_policy.md §2). A previous fix added phone verification
// to the board's `allDone` condition but not to the percent, so the gauge could
// read 100% while the board lingered. These tests pin the two to the same SSOT:
// when all 10 mandatory quests are done, the gauge is 100 AND the board hides,
// regardless of phone verification.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/home/presentation/providers/home_lesson_summary_provider.dart';
import 'package:lessonaza/features/home/presentation/providers/teacher_profile_completion_provider.dart';
import 'package:lessonaza/features/home/presentation/widgets/quest_board_card.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';

/// Overrides that complete all 10 mandatory quests. Phone verification is
/// controlled separately so each test can toggle just that flag.
List<Override> _allMandatoryDone({required bool phoneVerified}) => [
      hasAvailableSlotsProvider.overrideWithValue(true),
      hasProfileImageProvider.overrideWithValue(true),
      hasIntroductionProvider.overrideWithValue(true),
      hasPriceTableProvider.overrideWithValue(true),
      hasBankAccountProvider.overrideWithValue(true),
      hasIssuedSubscriptionProvider.overrideWithValue(true),
      hasWrittenLessonNoteProvider.overrideWithValue(true),
      hasAssignedPracticeProvider.overrideWithValue(true),
      homeHasCompletedLessonProvider.overrideWithValue(true),
      homeTeacherPhoneVerifiedProvider.overrideWithValue(phoneVerified),
      homeStudentsProvider.overrideWith(
        (ref) async => [
          Student(
            id: 's1',
            name: '학생',
            instrument: '피아노',
            createdAt: DateTime.utc(2026, 5, 1),
          ),
        ],
      ),
    ];

Future<void> _pump(WidgetTester tester, List<Override> overrides) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: QuestBoardCard()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'gauge reaches 100 with all 10 mandatory quests done (phone unverified)',
    () async {
      final container = ProviderContainer(
        overrides: _allMandatoryDone(phoneVerified: false),
      );
      addTearDown(container.dispose);
      // Keep derived inputs alive.
      container.listen(profileCompletionPercentProvider, (_, __) {});
      await container.read(homeStudentsProvider.future);

      expect(container.read(profileCompletionPercentProvider), 100);
    },
  );

  testWidgets(
    'board hides at 100% even when phone verification is incomplete',
    (tester) async {
      await _pump(tester, _allMandatoryDone(phoneVerified: false));

      expect(tester.takeException(), isNull);
      // Board is collapsed — no header, no quest rows.
      expect(find.text(AppStrings.questBoardTitle), findsNothing);
      expect(find.text(AppStrings.questTitleSlots), findsNothing);
    },
  );

  testWidgets('board is still shown while a mandatory quest is incomplete', (
    tester,
  ) async {
    final overrides = _allMandatoryDone(phoneVerified: true);
    // Knock out one mandatory quest.
    overrides[0] = hasAvailableSlotsProvider.overrideWithValue(false);

    await _pump(tester, overrides);

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.questBoardTitle), findsOneWidget);
  });
}
