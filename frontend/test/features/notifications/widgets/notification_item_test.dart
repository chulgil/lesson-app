import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/notifications/presentation/widgets/notification_item.dart';

/// Widget smoke test (HARD-GATE) for [NotificationItem] swipe-to-dismiss
/// (issue #669 — swipe consistency v2 D8).
///
/// Verifies:
/// - Renders without RenderBox / BoxConstraints crash.
/// - Without [onDelete], the swipe action is omitted (no SwipeActionTile wrapper).
/// - With [onDelete], the destructive [삭제] swipe action requires the
///   confirmation dialog before invoking the callback (3원칙 ③).
void main() {
  AppNotification fakeNotification() {
    return AppNotification(
      id: 'n_test_1',
      userId: 'u_test',
      type: NotificationType.lessonReminder,
      priority: NotificationPriority.normal,
      title: '레슨 알림',
      body: '내일 오후 3시 레슨이 있어요',
      createdAt: DateTime(2026, 5, 5),
    );
  }

  testWidgets('NotificationItem renders without onDelete (no swipe)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NotificationItem(notification: fakeNotification()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('레슨 알림'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'NotificationItem with onDelete shows confirmation dialog and invokes callback',
    (tester) async {
      var deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NotificationItem(
              notification: fakeNotification(),
              onDelete: () async {
                deleteCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag the row to reveal the destructive [삭제] swipe button.
      // 2026-06-12 방향 정책 — 관리(삭제) 액션은 우→좌 스와이프.
      await tester.drag(find.text('레슨 알림'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.swipeActionDelete), findsOneWidget);

      await tester.tap(find.text(AppStrings.swipeActionDelete));
      await tester.pumpAndSettle();

      // Confirmation dialog appears (3원칙 ③).
      expect(
        find.text(AppStrings.swipeActionDeleteNotificationConfirmTitle),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.swipeActionDeleteNotificationConfirmBody),
        findsOneWidget,
      );

      // Confirm — destructive 액션 호출 검증.
      await tester.tap(find.text(AppStrings.delete).last);
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'NotificationItem with onDelete — cancel keeps the notification (no callback)',
    (tester) async {
      var deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NotificationItem(
              notification: fakeNotification(),
              onDelete: () async {
                deleteCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('레슨 알림'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.swipeActionDelete));
      await tester.pumpAndSettle();

      // Cancel confirmation dialog.
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(deleteCalled, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
