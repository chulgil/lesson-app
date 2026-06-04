import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/loop_bookmark.dart';
import 'package:lessonaza/features/practice/presentation/widgets/youtube/loop_controls.dart';

void main() {
  group('LoopControls — §4.2', () {
    testWidgets('renders 5 speed chips + repeat toggle without exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoopControls(
              repeatEnabled: true,
              onRepeatChanged: (_) {},
              speed: 1.0,
              onSpeedChanged: (_) {},
              onReset: () {},
              countInEnabled: false,
              onCountInChanged: (_) {},
              countInSoundEnabled: true,
              onCountInSoundChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('0.25x'), findsOneWidget);
      expect(find.text('0.5x'), findsOneWidget);
      expect(find.text('0.75x'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
      expect(find.text('1.25x'), findsOneWidget);
    });

    testWidgets('count-in description shows only when count-in enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoopControls(
              repeatEnabled: true,
              onRepeatChanged: (_) {},
              speed: 0.75,
              onSpeedChanged: (_) {},
              onReset: () {},
              countInEnabled: true,
              onCountInChanged: (_) {},
              countInSoundEnabled: false,
              onCountInSoundChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3-2-1 후 재생'), findsOneWidget);
    });

    testWidgets(
      'bookmark dropdown lists every entry and forwards selection (#511)',
      (tester) async {
        String? lastSelected = 'noop';
        const bookmarks = [
          LoopBookmark(
            id: 'b1',
            name: '도입',
            startSeconds: 0,
            endSeconds: 12,
            colorIndex: 0,
          ),
          LoopBookmark(
            id: 'b2',
            name: '엔딩',
            startSeconds: 60,
            endSeconds: 90,
            colorIndex: 1,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoopControls(
                repeatEnabled: false,
                onRepeatChanged: (_) {},
                speed: 1.0,
                onSpeedChanged: (_) {},
                onReset: () {},
                countInEnabled: false,
                onCountInChanged: (_) {},
                countInSoundEnabled: false,
                onCountInSoundChanged: (_) {},
                bookmarks: bookmarks,
                activeBookmarkId: 'b1',
                onBookmarkSelected: (id) => lastSelected = id,
                onManageBookmarks: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.bookmarkManage), findsOneWidget);

        await tester.tap(find.byType(DropdownButton<String?>));
        await tester.pumpAndSettle();

        // The menu surfaces both items (current selection appears in both the
        // button face and the dropdown overlay).
        expect(find.text('엔딩'), findsWidgets);
        await tester.tap(find.text('엔딩').last);
        await tester.pumpAndSettle();

        expect(lastSelected, 'b2');
      },
    );

    testWidgets(
      'manage button invokes onManageBookmarks when no bookmarks exist (#511)',
      (tester) async {
        var managed = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoopControls(
                repeatEnabled: false,
                onRepeatChanged: (_) {},
                speed: 1.0,
                onSpeedChanged: (_) {},
                onReset: () {},
                countInEnabled: false,
                onCountInChanged: (_) {},
                countInSoundEnabled: false,
                onCountInSoundChanged: (_) {},
                bookmarks: const [],
                activeBookmarkId: null,
                onManageBookmarks: () => managed++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.bookmarkManage));
        await tester.pumpAndSettle();
        expect(managed, 1);
      },
    );

    testWidgets('narrow column does not throw', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: LoopControls(
                repeatEnabled: false,
                onRepeatChanged: (_) {},
                speed: 1.0,
                onSpeedChanged: (_) {},
                onReset: () {},
                countInEnabled: false,
                onCountInChanged: (_) {},
                countInSoundEnabled: true,
                onCountInSoundChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
