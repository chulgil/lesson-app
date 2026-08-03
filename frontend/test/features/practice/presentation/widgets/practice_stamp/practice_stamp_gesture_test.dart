// Widget tests for the scratch-stamp practice-marking interaction (P1).
//
// Covers: tap-to-scratch completion (coverage threshold via grid sampling),
// long-press instant fill, quick-check mode escape hatch (no popup), and
// reentry guards (rapid double-tap, filled-slot long-press reset).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_scratch_mode_storage_provider.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_stamp/practice_stamp_gesture.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_stamp/scratch_stamp_sheet.dart';

void main() {
  Future<void> pumpGesture(
    WidgetTester tester, {
    required int completedCount,
    required int totalCount,
    required VoidCallback onIncrement,
    bool quickMode = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        // Real Hive is never initialized in widget tests (matches the
        // existing GoalAchievementStorage test convention) — always
        // override the storage provider instead of relying on its
        // try/catch fallback.
        overrides: [
          practiceScratchModeStorageProvider(
            'student-1',
          ).overrideWith(() => _FakeScratchModeStorage(quickMode)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: PracticeStampGesture(
                studentId: 'student-1',
                completedCount: completedCount,
                totalCount: totalCount,
                onIncrement: onIncrement,
                child: const SizedBox(
                  width: 100,
                  height: 40,
                  child: Text('paws'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Densely sweeps the whole scratch canvas so coverage reaches the
  /// completion threshold regardless of the exact stamp template geometry.
  Future<void> sweepScratch(WidgetTester tester) async {
    final origin = tester.getTopLeft(find.byKey(scratchStampCanvasKey));
    for (var row = 0; row < 12; row++) {
      final y = origin.dy + 6 + row * 18.0;
      final gesture = await tester.startGesture(Offset(origin.dx + 6, y));
      for (var col = 1; col <= 11; col++) {
        final x = origin.dx + 6 + col * 19.0;
        await gesture.moveTo(Offset(x, y));
        await tester.pump(const Duration(milliseconds: 4));
      }
      await gesture.up();
      await tester.pump();
    }
  }

  testWidgets(
    'tap opens the sheet; scratching to threshold fires onIncrement exactly once',
    (tester) async {
      var count = 0;
      await pumpGesture(
        tester,
        completedCount: 0,
        totalCount: 5,
        onIncrement: () => count++,
      );

      await tester.tap(find.byType(PracticeStampGesture));
      await tester.pumpAndSettle();

      expect(find.byType(ScratchStampSheet), findsOneWidget);
      expect(count, 0, reason: 'sheet must not increment until completed');

      await sweepScratch(tester);
      await tester.pumpAndSettle();

      expect(
        find.byType(ScratchStampSheet),
        findsNothing,
        reason: 'sheet pops itself once coverage threshold is reached',
      );
      expect(count, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('long-press on the stamp area instant-fills', (tester) async {
    var count = 0;
    await pumpGesture(
      tester,
      completedCount: 1,
      totalCount: 5,
      onIncrement: () => count++,
    );

    await tester.tap(find.byType(PracticeStampGesture));
    await tester.pumpAndSettle();
    expect(find.byType(ScratchStampSheet), findsOneWidget);

    await tester.longPress(find.byKey(scratchStampCanvasKey));
    await tester.pumpAndSettle();

    expect(find.byType(ScratchStampSheet), findsNothing);
    expect(count, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rapid double-tap before the sheet opens does not open two sheets',
    (tester) async {
      var count = 0;
      await pumpGesture(
        tester,
        completedCount: 0,
        totalCount: 5,
        onIncrement: () => count++,
      );

      // Two taps back-to-back, no pump in between: the first `_handleTap`
      // sets its `_busy` guard synchronously before its first `await`, so
      // the second tap must be a no-op.
      await tester.tap(find.byType(PracticeStampGesture));
      await tester.tap(find.byType(PracticeStampGesture));
      await tester.pumpAndSettle();

      expect(find.byType(ScratchStampSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'quick-check mode enabled: tap increments directly without opening the sheet',
    (tester) async {
      var count = 0;
      await pumpGesture(
        tester,
        completedCount: 0,
        totalCount: 5,
        onIncrement: () => count++,
        quickMode: true,
      );

      await tester.tap(find.byType(PracticeStampGesture));
      await tester.pumpAndSettle();

      expect(find.byType(ScratchStampSheet), findsNothing);
      expect(count, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fully-filled row: tap is a no-op, long-press confirms before resetting',
    (tester) async {
      var count = 0;
      await pumpGesture(
        tester,
        completedCount: 5,
        totalCount: 5,
        onIncrement: () => count++,
      );

      await tester.tap(find.byType(PracticeStampGesture));
      await tester.pumpAndSettle();
      expect(find.byType(ScratchStampSheet), findsNothing);
      expect(count, 0);

      await tester.longPress(find.byType(PracticeStampGesture));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.practiceStampResetConfirmTitle),
        findsOneWidget,
      );
      await tester.tap(find.text(AppStrings.confirm));
      await tester.pumpAndSettle();

      expect(count, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeScratchModeStorage extends PracticeScratchModeStorage {
  final bool value;

  _FakeScratchModeStorage(this.value);

  @override
  Future<bool> build(String studentId) async => value;
}
