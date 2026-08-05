// Widget smoke + list contract test for GroupClassesScreen (J9b, P1-1).
//
// Contract (ux-rules.md HARD-GATE):
//   pumpWidget(MaterialApp(...)) + pumpAndSettle() + takeException() isNull,
//   plus the list behaviours the spec and consistency contracts pin down:
//     - C1: empty state is EmptyStateWidget, not a hand-rolled column
//     - C6: row management actions live in SwipeActionTile (right-to-left),
//           never in a trailing PopupMenuButton
//     - destructive (take down) goes through a confirm dialog
//
// Row tap is a spy callback: the detail screen needs a concrete session, which
// J12 resolves when it wires the route.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/empty_state_widget.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_group_class_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/group_class.dart';
import 'package:lessonaza/features/schedule/presentation/providers/group_class_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/group_classes_screen.dart';

const _kTeacherId = 'teacher_1';

Widget _host(
  MockGroupClassRepository repository, {
  void Function(GroupClass)? onOpenClass,
}) {
  return ProviderScope(
    overrides: [groupClassRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: GroupClassesScreen(
        teacherId: _kTeacherId,
        onOpenClass: onOpenClass ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('GroupClassesScreen', () {
    testWidgets('renders the seeded classes without exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(_host(MockGroupClassRepository()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.groupClassesTitle), findsOneWidget);
      expect(find.text('목요일 앙상블반'), findsOneWidget);
      expect(find.text('원데이 보잉 특강'), findsOneWidget);
      // 반 / 드롭인 are told apart by the existing badges.
      expect(find.text(AppStrings.groupClassRegular), findsOneWidget);
      expect(find.text(AppStrings.groupClassDropin), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses EmptyStateWidget when the teacher has no classes (C1)', (
      tester,
    ) async {
      await tester.pumpWidget(_host(MockGroupClassRepository(seed: false)));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text(AppStrings.groupClassesEmptyTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'row management actions are swipe actions, not popup menus (C6)',
      (tester) async {
        await tester.pumpWidget(_host(MockGroupClassRepository()));
        await tester.pumpAndSettle();

        expect(find.byType(SwipeActionTile), findsNWidgets(2));
        expect(find.byType(PopupMenuButton<dynamic>), findsNothing);

        final tile = tester.widget<SwipeActionTile>(
          find.byType(SwipeActionTile).first,
        );
        // Right-to-left carries exactly the two management actions.
        expect(tile.actions.map((a) => a.label), [
          AppStrings.swipeActionEdit,
          AppStrings.groupClassesDeactivateAction,
        ]);
        expect(tile.actions.last.tone, SwipeActionTone.destructive);
        expect(tile.startActions, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('tapping a row hands the class to the detail callback', (
      tester,
    ) async {
      final opened = <GroupClass>[];
      await tester.pumpWidget(
        _host(MockGroupClassRepository(), onOpenClass: opened.add),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('목요일 앙상블반'));
      await tester.pumpAndSettle();

      expect(opened, hasLength(1));
      expect(opened.single.name, '목요일 앙상블반');
      expect(tester.takeException(), isNull);
    });

    testWidgets('taking a class down asks for confirmation first', (
      tester,
    ) async {
      final repository = MockGroupClassRepository();
      await tester.pumpWidget(_host(repository));
      await tester.pumpAndSettle();

      final deactivate =
          tester
              .widget<SwipeActionTile>(find.byType(SwipeActionTile).first)
              .actions
              .last;
      deactivate.onPressed();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.groupClassesDeactivateTitle), findsOneWidget);

      // Backing out leaves the class alone.
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();
      expect(repository.storedClasses.every((c) => c.isActive), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('confirming take-down deactivates and refreshes the list', (
      tester,
    ) async {
      final repository = MockGroupClassRepository();
      await tester.pumpWidget(_host(repository));
      await tester.pumpAndSettle();

      // Newest first — the drop-in class is the top row.
      final deactivate =
          tester
              .widget<SwipeActionTile>(find.byType(SwipeActionTile).first)
              .actions
              .last;
      deactivate.onPressed();
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.groupClassesDeactivateAction));
      await tester.pumpAndSettle();

      final downed = repository.storedClasses.where((c) => !c.isActive);
      expect(downed, hasLength(1));
      expect(downed.single.name, '원데이 보잉 특강');
      // Soft delete — the owner still sees it, marked as taken down.
      expect(
        find.text(AppStrings.groupClassesInactiveBadge),
        findsOneWidget,
        reason: 'The read provider must be invalidated after the write.',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
