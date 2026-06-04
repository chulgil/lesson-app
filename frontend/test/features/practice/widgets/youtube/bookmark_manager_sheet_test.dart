import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/loop_bookmark.dart';
import 'package:lessonaza/features/practice/presentation/widgets/youtube/bookmark_manager_sheet.dart';

void main() {
  group('BookmarkManagerSheet — #511', () {
    testWidgets('renders the empty state hint when no bookmarks exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BookmarkManagerSheet(
              bookmarks: [],
              activeBookmarkId: null,
              currentStartSeconds: 0,
              currentEndSeconds: 30,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.bookmarkEmpty), findsOneWidget);
      expect(find.textContaining(AppStrings.bookmarkAdd), findsOneWidget);
    });

    testWidgets('lists existing bookmarks with their range labels', (
      tester,
    ) async {
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
        const MaterialApp(
          home: Scaffold(
            body: BookmarkManagerSheet(
              bookmarks: bookmarks,
              activeBookmarkId: 'b2',
              currentStartSeconds: 30,
              currentEndSeconds: 45,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('도입'), findsOneWidget);
      expect(find.text('엔딩'), findsOneWidget);
      expect(find.textContaining('0:00 – 0:12'), findsOneWidget);
      expect(find.textContaining('1:00 – 1:30'), findsOneWidget);
    });

    testWidgets(
      'disables the add button and shows the limit hint when at the cap',
      (tester) async {
        final atCap = List.generate(
          5,
          (i) => LoopBookmark(
            id: 'b$i',
            name: 'name $i',
            startSeconds: i,
            endSeconds: i + 5,
            colorIndex: i,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookmarkManagerSheet(
                bookmarks: atCap,
                activeBookmarkId: null,
                currentStartSeconds: 30,
                currentEndSeconds: 45,
                onAdd:
                    ({
                      required String name,
                      required int startSeconds,
                      required int endSeconds,
                    }) async {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text(AppStrings.bookmarkLimitReached), findsOneWidget);
        final addButton = tester.widget<FilledButton>(
          find.ancestor(
            of: find.textContaining(AppStrings.bookmarkAdd),
            matching: find.byType(FilledButton),
          ),
        );
        expect(addButton.onPressed, isNull);
      },
    );

    testWidgets('tapping a row invokes onSelect with that bookmark', (
      tester,
    ) async {
      LoopBookmark? selected;
      const bookmarks = [
        LoopBookmark(
          id: 'b1',
          name: '도입',
          startSeconds: 0,
          endSeconds: 12,
          colorIndex: 0,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookmarkManagerSheet(
              bookmarks: bookmarks,
              activeBookmarkId: null,
              currentStartSeconds: 0,
              currentEndSeconds: 0,
              onSelect: (b) => selected = b,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('도입'));
      await tester.pump();

      expect(selected?.id, 'b1');
    });

    testWidgets('add flow forwards the captured range to onAdd', (
      tester,
    ) async {
      String? capturedName;
      int? capturedStart;
      int? capturedEnd;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookmarkManagerSheet(
              bookmarks: const [],
              activeBookmarkId: null,
              currentStartSeconds: 42,
              currentEndSeconds: 75,
              onAdd: ({
                required String name,
                required int startSeconds,
                required int endSeconds,
              }) async {
                capturedName = name;
                capturedStart = startSeconds;
                capturedEnd = endSeconds;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining(AppStrings.bookmarkAdd));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '도입부');
      await tester.tap(find.text(AppStrings.bookmarkSave));
      await tester.pumpAndSettle();

      expect(capturedName, '도입부');
      expect(capturedStart, 42);
      expect(capturedEnd, 75);
    });
  });
}
